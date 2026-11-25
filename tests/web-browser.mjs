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

test("registo, login e progresso após reabrir o jogo Web", { timeout: 90000 }, async (t) => {
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
  await context.route(api + "/**", async (route) => {
    const request = route.request();
    const url = new URL(request.url());
    const headers = {
      "access-control-allow-origin": "*",
      "access-control-allow-headers": "*",
      "access-control-allow-methods": "GET, POST, OPTIONS",
    };
    const send = (json, status = 200) => route.fulfill({ status, headers, json });
    if (request.method() === "OPTIONS") return route.fulfill({ status: 204, headers });
    if (url.pathname === "/auth/v1/signup" || url.pathname === "/auth/v1/token") {
      const { email, password } = request.postDataJSON();
      if (url.pathname.endsWith("/signup")) {
        accounts.set(email, { id: crypto.randomUUID(), email, password });
      }
      const account = accounts.get(email);
      if (account?.password !== password) {
        return send({ error_code: "invalid_credentials", msg: "Invalid login credentials" }, 400);
      }
      return send({
        access_token: account.id,
        refresh_token: account.id,
        expires_in: 3600,
        token_type: "bearer",
        user: { id: account.id, email, aud: "authenticated", app_metadata: {}, user_metadata: {} },
      });
    }
    if (url.pathname === "/auth/v1/logout") return route.fulfill({ status: 204, headers });
    const id = request.headers().authorization?.replace("Bearer ", "");
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
  });

  const page = await context.newPage();
  context.on("page", (tab) => tab.on("pageerror", (error) => t.diagnostic(error.message)));
  page.on("pageerror", (error) => t.diagnostic(error.message));
  page.on("console", (message) => {
    if (message.type() === "error" || message.type() === "warning") t.diagnostic(message.text());
  });
  const origin = `http://127.0.0.1:${server.address().port}`;
  await page.goto(origin);
  const email = "jogador@example.com";
  const password = "Palavra-passe de teste";
  async function submit(address, secret, action) {
    await page.getByLabel("Email").fill(address);
    await page.getByLabel("Palavra-passe").fill(secret);
    await page.getByRole("button", { name: action, exact: true }).click();
  }
  await submit(email, password, "Criar conta");
  await page.getByRole("button", { name: "Jogar", exact: true }).click();
  await page.locator("#download").waitFor({ state: "hidden", timeout: 30000 });
  await page.keyboard.press("Enter");
  await page.keyboard.press("Enter");
  await page.getByText("Progresso guardado", { exact: true }).waitFor({ timeout: 30000 }).catch(async (error) => {
    t.diagnostic(await page.locator("body").innerText());
    throw error;
  });
  assert.deepEqual(reported, [0]);

  await page.keyboard.down("d");
  await page.waitForResponse((response) => {
    const request = response.request();
    return response.url().endsWith("/save_player_checkpoint")
      && request.postDataJSON().reached_checkpoint === 1 && response.ok();
  }, { timeout: 30000 });
  await page.keyboard.up("d");
  await page.getByText("Progresso guardado", { exact: true }).waitFor();

  await page.close();
  const reopened = await context.newPage();
  await reopened.goto(origin);
  await reopened.getByText("Último ponto de controlo · Primeiro pátio").waitFor();
  await reopened.evaluate(() => {
    const original = window.winterProgress.checkpointReached;
    window.winterProgress.checkpointReached = (checkpoint) => {
      window.resumedCheckpoint = checkpoint;
      original(checkpoint);
    };
  });
  await reopened.getByRole("button", { name: "Jogar", exact: true }).click();
  await reopened.locator("#download").waitFor({ state: "hidden", timeout: 30000 });
  await reopened.keyboard.press("ArrowDown");
  await reopened.keyboard.press("Enter");
  await reopened.keyboard.press("Enter");
  await reopened.keyboard.press("Enter");
  await reopened.waitForFunction(() => window.resumedCheckpoint === 1, undefined, { timeout: 30000 });
  await reopened.getByRole("button", { name: "Terminar sessão" }).click();
  await reopened.getByRole("button", { name: "Entrar", exact: true }).waitFor();
  await reopened.getByLabel("Email").fill(email);
  await reopened.getByLabel("Palavra-passe").fill("palavra-passe incorreta");
  await reopened.getByRole("button", { name: "Entrar", exact: true }).click();
  await reopened.getByText("Verifica o email e a palavra-passe.").waitFor();
  await reopened.getByLabel("Palavra-passe").fill(password);
  await reopened.getByRole("button", { name: "Entrar", exact: true }).click();
  await reopened.getByRole("button", { name: "Jogar", exact: true }).waitFor();
  await reopened.getByRole("button", { name: "Terminar sessão" }).click();
  await reopened.getByLabel("Email").fill("outra@example.com");
  await reopened.getByLabel("Palavra-passe").fill(password);
  await reopened.getByRole("button", { name: "Criar conta", exact: true }).click();
  await reopened.getByText("O jogo começa na Sala 1.").waitFor();
  assert.deepEqual(reported, [0, 1]);
});
