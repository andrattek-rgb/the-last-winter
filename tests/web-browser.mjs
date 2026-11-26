import assert from "node:assert/strict";
import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { createServer } from "node:http";
import { extname } from "node:path";
import { test } from "node:test";
import { chromium } from "playwright";

const api = process.env.TEST_SUPABASE_URL ?? "https://test-winter.supabase.co";
const files = new URL("../dist/", import.meta.url);
const mime = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".css": "text/css",
  ".wasm": "application/wasm",
};

test("registo, progresso e controlos táteis na versão Web", { timeout: 180000 }, async (t) => {
  const server = createServer(async (request, response) => {
    const path = new URL(request.url, "http://localhost").pathname;
    const filename = path === "/" ? "index.html" : path.slice(1);
    const file = new URL(filename, files);
    try {
      const info = await stat(file);
      if (!file.href.startsWith(files.href) || !info.isFile()) throw new Error();
      response.writeHead(200, {
        "content-type": mime[extname(filename)] ?? "application/octet-stream",
        "content-length": info.size,
      });
      createReadStream(file).pipe(response);
    } catch {
      response.writeHead(404).end();
    }
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(() => server.close());
  const browser = await chromium.launch({
    executablePath: process.env.TEST_CHROMIUM_BIN,
    args: ["--enable-unsafe-swiftshader", "--use-angle=swiftshader"],
  });
  t.after(() => browser.close());
  const context = await browser.newContext();
  const accounts = new Map();
  const saves = new Map();
  const reported = [];
  const autoConfirmedEmail = "outra@example.com";
  const sessionPayload = (user) => ({
    access_token: user.id,
    refresh_token: user.id,
    expires_in: 3600,
    token_type: "bearer",
    user,
  });
  async function mockSupabase(route) {
    const request = route.request();
    const url = new URL(request.url());
    const headers = {
      "access-control-allow-origin": "*",
      "access-control-allow-headers": "*",
      "access-control-allow-methods": "GET, POST, OPTIONS",
    };
    const send = (json, status = 200) => route.fulfill({ status, headers, json });
    if (request.method() === "OPTIONS") return route.fulfill({ status: 204, headers });
    const publicUser = ({ id, email }) => ({ id, email, aud: "authenticated", app_metadata: {}, user_metadata: {} });
    const id = request.headers().authorization?.replace("Bearer ", "");
    if (url.pathname === "/auth/v1/signup") {
      const { email, password } = request.postDataJSON();
      const account = { id: crypto.randomUUID(), email, password, confirmed: email === autoConfirmedEmail };
      assert.equal(url.searchParams.get("redirect_to"), origin + "/");
      accounts.set(email, account);
      const user = publicUser(account);
      return send(account.confirmed ? sessionPayload(user) : user);
    }
    if (url.pathname === "/auth/v1/verify") {
      const account = [...accounts.values()].find((entry) => entry.id === url.searchParams.get("token"));
      assert.ok(account);
      account.confirmed = true;
      const fragment = new URLSearchParams({
        access_token: account.id, refresh_token: account.id, expires_in: "3600", token_type: "bearer", type: "signup",
      });
      return route.fulfill({ status: 303, headers: { ...headers, location: origin + "/#" + fragment } });
    }
    if (url.pathname === "/auth/v1/user") {
      const account = [...accounts.values()].find((entry) => entry.id === id && entry.confirmed);
      assert.ok(account);
      return send(publicUser(account));
    }
    if (url.pathname === "/auth/v1/token") {
      const { email, password } = request.postDataJSON();
      const account = accounts.get(email);
      if (account?.password !== password) {
        return send({ error_code: "invalid_credentials", msg: "Invalid login credentials" }, 400);
      }
      if (!account.confirmed) {
        return send({ error_code: "email_not_confirmed", msg: "Email not confirmed" }, 400);
      }
      return send(sessionPayload(publicUser(account)));
    }
    if (url.pathname === "/auth/v1/logout") return route.fulfill({ status: 204, headers });
    if (url.pathname === "/rest/v1/player_progress") {
      assert.equal(url.searchParams.get("user_id"), "eq." + id);
      return send(saves.has(id) ? [{ checkpoint: saves.get(id) }] : []);
    }
    if (url.pathname === "/rest/v1/rpc/save_player_checkpoint") {
      const { player_id, reached_checkpoint } = request.postDataJSON();
      assert.equal(id, player_id);
      const checkpoint = Math.max(saves.get(id) ?? 0, reached_checkpoint);
      saves.set(id, checkpoint);
      reported.push(reached_checkpoint);
      return send(checkpoint);
    }
    return send({ message: "Endpoint inesperado" }, 404);
  }
  await context.route(api + "/**", mockSupabase);

  const page = await context.newPage();
  context.on("page", (tab) => tab.on("pageerror", (error) => t.diagnostic(error.message)));
  page.on("pageerror", (error) => t.diagnostic(error.message));
  page.on("console", (message) => {
    if (message.type() === "error" || message.type() === "warning") t.diagnostic(message.text());
  });
  const origin = `http://127.0.0.1:${server.address().port}`;
  await page.goto(origin);
  const email = "jogador@example.com";
  const password = "Password de teste";
  async function enterRegistration(tab, address) {
    await tab.getByRole("form", { name: "Sign in" }).getByRole("button", { name: "Create account" }).click();
    const register = tab.getByRole("form", { name: "Create account" });
    assert.equal(await tab.getByRole("form", { name: "Sign in" }).count(), 0);
    await register.getByLabel("Email").fill(address);
    await register.getByLabel("Password", { exact: true }).fill(password);
    return register;
  }
  async function followConfirmation(tab, address) {
    await tab.goto(api + "/auth/v1/verify?token=" + accounts.get(address).id);
    await tab.getByRole("button", { name: "Play", exact: true }).waitFor();
    assert.equal(new URL(tab.url()).hash, "");
  }

  const login = page.getByRole("form", { name: "Sign in" });
  await login.waitFor();
  assert.equal(await login.locator("input").count(), 2);
  const register = await enterRegistration(page, email);
  await register.getByLabel("Confirm password").fill("different password");
  await register.getByRole("button", { name: "Create account" }).click();
  await page.getByText("The passwords do not match.").waitFor();
  assert.equal(accounts.size, 0);
  await register.getByLabel("Confirm password").fill(password);
  await register.getByRole("button", { name: "Create account" }).click();
  await page.getByText("Check your inbox for the confirmation link.").waitFor();
  assert.equal(await login.getByLabel("Email").inputValue(), email);
  assert.equal(await page.getByRole("button", { name: "Play", exact: true }).count(), 0);
  await login.getByLabel("Password").fill(password);
  await login.getByRole("button", { name: "Sign in", exact: true }).click();
  await page.getByText("Confirm your email before signing in.").waitFor();
  await followConfirmation(page, email);
  await page.getByRole("button", { name: "Play", exact: true }).click();
  await page.locator("#download").waitFor({ state: "hidden", timeout: 30000 });
  await page.keyboard.press("Enter");
  await page.keyboard.press("Enter");
  await page.getByText("Progress saved", { exact: true }).waitFor({ timeout: 30000 }).catch(async (error) => {
    t.diagnostic(await page.locator("body").innerText());
    throw error;
  });
  assert.equal(await page.getByRole("group", { name: "Touch controls" }).count(), 0);
  assert.deepEqual(reported, [0]);

  await page.keyboard.down("d");
  await page.waitForResponse((response) => {
    const request = response.request();
    return response.url().endsWith("/save_player_checkpoint")
      && request.postDataJSON().reached_checkpoint === 1 && response.ok();
  }, { timeout: 30000 });
  await page.keyboard.up("d");
  await page.getByText("Progress saved", { exact: true }).waitFor();

  await page.close();
  const reopened = await context.newPage();
  await reopened.goto(origin);
  await reopened.getByText("Last checkpoint · First courtyard").waitFor();
  await reopened.evaluate(() => {
    const original = window.winterProgress.checkpointReached;
    window.winterProgress.checkpointReached = (checkpoint) => {
      window.resumedCheckpoint = checkpoint;
      original(checkpoint);
    };
  });
  await reopened.getByRole("button", { name: "Play", exact: true }).click();
  await reopened.locator("#download").waitFor({ state: "hidden", timeout: 30000 });
  await reopened.keyboard.press("ArrowDown");
  await reopened.keyboard.press("Enter");
  await reopened.keyboard.press("Enter");
  await reopened.keyboard.press("Enter");
  await reopened.waitForFunction(() => window.resumedCheckpoint === 1, undefined, { timeout: 30000 });
  await reopened.getByRole("button", { name: "Sign out" }).click();
  await reopened.getByRole("button", { name: "Sign in", exact: true }).waitFor();
  const reopenedLogin = reopened.getByRole("form", { name: "Sign in" });
  await reopenedLogin.getByLabel("Email").fill(email);
  await reopenedLogin.getByLabel("Password").fill("palavra-passe incorreta");
  await reopened.getByRole("button", { name: "Sign in", exact: true }).click();
  await reopened.getByText("Check your email and password.").waitFor();
  await reopenedLogin.getByLabel("Password").fill(password);
  await reopened.getByRole("button", { name: "Sign in", exact: true }).click();
  await reopened.getByRole("button", { name: "Play", exact: true }).waitFor();
  await reopened.getByRole("button", { name: "Sign out" }).click();
  const secondRegister = await enterRegistration(reopened, autoConfirmedEmail);
  await secondRegister.getByLabel("Confirm password").fill(password);
  await secondRegister.getByRole("button", { name: "Create account" }).click();
  await reopened.getByText("The game starts in the barracks.").waitFor();
  await reopened.getByRole("button", { name: "Sign out" }).click();
  await reopenedLogin.getByLabel("Email").fill(autoConfirmedEmail);
  await reopenedLogin.getByLabel("Password").fill(password);
  await reopenedLogin.getByRole("button", { name: "Sign in", exact: true }).click();
  await reopened.getByText("The game starts in the barracks.").waitFor();
  assert.deepEqual(reported, [0, 1]);

  await t.test("telemóvel em retrato, paisagem e ecrã inteiro, com integração dos controlos", async () => {
    const phone = await browser.newContext({
      viewport: { width: 390, height: 844 },
      deviceScaleFactor: 2,
      isMobile: true,
      hasTouch: true,
    });
    try {
      await phone.route(api + "/**", mockSupabase);
      const phoneEmail = "telemovel@example.com";
      const id = crypto.randomUUID();
      accounts.set(phoneEmail, { id, email: phoneEmail, password, confirmed: true });
      saves.set(id, 2);
      const mobile = await phone.newPage();
      mobile.on("pageerror", (error) => t.diagnostic(error.message));
      await mobile.goto(origin);
      const mobileLogin = mobile.getByRole("form", { name: "Sign in" });
      await mobileLogin.getByLabel("Email").fill(phoneEmail);
      await mobileLogin.getByLabel("Password").fill(password);
      await mobile.getByRole("button", { name: "Sign in", exact: true }).tap();
      await mobile.evaluate(() => {
        const bindGame = window.winterTouch.bindGame;
        window.activeTouchStrengths = {};
        window.winterTouch.bindGame = (callback) => bindGame((action, strength) => {
          window.activeTouchStrengths[action] = strength;
          callback(action, strength);
        });
      });
      await mobile.getByRole("button", { name: "Play", exact: true }).tap();
      await mobile.locator("#download").waitFor({ state: "hidden", timeout: 30000 });
      const canvas = mobile.locator("#canvas");
      assert.equal(await canvas.getAttribute("width"), "960");
      assert.equal(await canvas.getAttribute("height"), "540");

      async function tapCanvas(fractionX, fractionY) {
        const bounds = await canvas.boundingBox();
        await mobile.touchscreen.tap(bounds.x + bounds.width * fractionX, bounds.y + bounds.height * fractionY);
      }
      await tapCanvas(0.15, 0.46);
      await tapCanvas(0.5, 0.27);
      await tapCanvas(0.5, 0.855);
      const controls = mobile.getByRole("group", { name: "Touch controls" });
      await controls.waitFor({ timeout: 6000 });
      const joystick = controls.getByRole("group", { name: "Movement joystick" });
      const crouch = controls.getByRole("button", { name: "Crouch" });
      const interact = mobile.locator('[data-action="interact"]');
      assert.equal(await interact.isVisible(), false);
      const portraitCanvas = await canvas.boundingBox();
      const portraitControls = await controls.boundingBox();
      assert.ok(portraitControls.y >= portraitCanvas.y + portraitCanvas.height);
      assert.ok(portraitCanvas.width >= 389);
      await mobile.getByText("Turn your phone sideways for a larger view.").waitFor();

      await mobile.setViewportSize({ width: 844, height: 390 });
      const landscapeCanvas = await canvas.boundingBox();
      const landscapeControls = await controls.boundingBox();
      assert.ok(landscapeControls.y < landscapeCanvas.y + landscapeCanvas.height);
      assert.ok(landscapeCanvas.height >= 389);
      assert.ok(Math.abs(landscapeCanvas.width / landscapeCanvas.height - 16 / 9) < 0.01);

      const fullscreen = mobile.getByRole("button", { name: "Fullscreen", exact: true });
      const exitFullscreen = mobile.getByRole("button", { name: "Exit fullscreen", exact: true });
      await fullscreen.tap();
      await mobile.waitForFunction(() => document.fullscreenElement?.id === "game");
      assert.equal(await exitFullscreen.getAttribute("aria-pressed"), "true");
      await exitFullscreen.tap();
      await mobile.waitForFunction(() => !document.fullscreenElement);
      await fullscreen.waitFor();

      await mobile.locator("#game").evaluate((stage) => {
        Object.defineProperties(stage, {
          requestFullscreen: { value: undefined },
          webkitRequestFullscreen: { value: undefined },
        });
      });
      await fullscreen.tap();
      assert.equal(await mobile.evaluate(() => document.fullscreenElement), null);
      assert.equal(await exitFullscreen.getAttribute("aria-pressed"), "true");
      assert.ok((await canvas.boundingBox()).height >= 389);

      const cdp = await phone.newCDPSession(mobile);
      async function point(button, id) {
        const bounds = await button.boundingBox();
        return { id, x: bounds.x + bounds.width / 2, y: bounds.y + bounds.height / 2 };
      }
      const stickCenter = await point(joystick, 1);
      const { width } = await joystick.boundingBox();
      const diagonalPoint = { ...stickCenter, x: stickCenter.x + width * 0.14, y: stickCenter.y + width * 0.14 };
      const rightPoint = { ...stickCenter, x: stickCenter.x + width * 0.32 };
      const crouchPoint = await point(crouch, 2);
      await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [stickCenter, crouchPoint] });
      await cdp.send("Input.dispatchTouchEvent", { type: "touchMove", touchPoints: [diagonalPoint, crouchPoint] });
      const diagonal = await mobile.evaluate(() => window.activeTouchStrengths);
      assert.ok(diagonal.move_right > 0.4 && diagonal.move_right < 0.6);
      assert.ok(diagonal.move_forward > 0.4 && diagonal.move_forward < 0.6);
      assert.ok(await crouch.evaluate((button) => button.classList.contains("active")));
      await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
      assert.equal(await crouch.evaluate((button) => button.classList.contains("active")), false);
      const released = await mobile.evaluate(() => window.activeTouchStrengths);
      assert.equal(released.move_right, 0);
      assert.equal(released.move_forward, 0);

      await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [rightPoint] });
      await interact.waitFor({ timeout: 12000 });
      await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
      await interact.tap();
      await controls.waitFor({ state: "hidden", timeout: 5000 });
      await tapCanvas(0.57, 0.91);
      await controls.waitFor({ timeout: 15000 });
      await exitFullscreen.tap();
      assert.equal(await fullscreen.getAttribute("aria-pressed"), "false");
    } finally {
      await phone.close();
    }
  });
});
