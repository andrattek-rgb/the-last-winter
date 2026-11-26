import { createClient } from "@supabase/supabase-js";
import { checkpoints, createProgressQueue, readCheckpoint } from "./progress.js";
import { touchInput } from "./touch-controls.js";

window.winterTouch = touchInput;

const account = document.querySelector("#account");
const loginForm = document.querySelector("#login-form");
const registerForm = document.querySelector("#register-form");
const profile = document.querySelector("#profile");
const notice = document.querySelector("#notice");
const play = document.querySelector("#play");
const game = document.querySelector("#game");
const canvas = document.querySelector("#canvas");
const download = document.querySelector("#download");
const fullscreen = document.querySelector("#game-fullscreen");
const sessionControls = document.querySelector("#session-controls");
const logout = document.querySelector("#logout");
const retry = document.querySelector("#retry");
const saveStatus = document.querySelector("#save-status");
const confirmationError = new URLSearchParams(location.hash.slice(1)).get("error_code")
  ?? new URL(location.href).searchParams.get("error_code");

const client = createClient(__SUPABASE_URL__, __SUPABASE_KEY__, {
  global: {
    fetch: (input, options) => {
      const timeout = AbortSignal.timeout(12000);
      const signal = options?.signal ? AbortSignal.any([options.signal, timeout]) : timeout;
      return fetch(input, { ...options, signal });
    },
  },
});
let userId = null;
let progress = null;
let gameStarting = false;

function nativeFullscreenElement() {
  return document.fullscreenElement ?? document.webkitFullscreenElement;
}

function setExpanded(expanded) {
  game.classList.toggle("expanded", expanded);
  document.body.classList.toggle("game-expanded", expanded);
  fullscreen.textContent = expanded ? "Exit fullscreen" : "Fullscreen";
  fullscreen.setAttribute("aria-pressed", String(expanded));
}

function restoreFromNativeFullscreen() {
  setExpanded(nativeFullscreenElement() === game);
}

document.addEventListener("fullscreenchange", restoreFromNativeFullscreen);
document.addEventListener("webkitfullscreenchange", restoreFromNativeFullscreen);
fullscreen.addEventListener("click", async () => {
  if (game.classList.contains("expanded")) {
    const exit = document.exitFullscreen ?? document.webkitExitFullscreen;
    if (nativeFullscreenElement() === game && exit) {
      try {
        await exit.call(document);
      } catch {
        if (nativeFullscreenElement() === game) return;
      }
    }
    setExpanded(false);
    return;
  }

  setExpanded(true);
  try {
    if (game.requestFullscreen) await game.requestFullscreen({ navigationUI: "hide" });
    else if (game.webkitRequestFullscreen) await game.webkitRequestFullscreen();
    if (nativeFullscreenElement() === game) await screen.orientation?.lock?.("landscape");
  } catch {
    // The expanded layout still fills the visible page when fullscreen or rotation is unavailable.
  }
});

function stateMessage(state) {
  saveStatus.textContent = {
    saving: "Saving progress…",
    saved: "Progress saved",
    error: "Your progress has not been saved yet.",
  }[state];
  retry.hidden = state !== "error";
  logout.disabled = state === "saving";
}

async function showAccount(session) {
  notice.textContent = "";
  userId = session?.user.id ?? null;
  profile.hidden = true;
  loginForm.hidden = Boolean(session);
  registerForm.hidden = true;
  sessionControls.hidden = !session;
  if (!session) return;

  try {
    const checkpoint = await readCheckpoint(client, userId);
    progress = createProgressQueue(client, userId, checkpoint, stateMessage);
    window.winterProgress = {
      accountId: userId,
      hasProgress: checkpoint !== null,
      startingCheckpoint: checkpoint ?? 0,
      checkpointReached: (value) => progress.reach(value),
      quitToPortal: () => location.reload(),
    };
    document.querySelector("#checkpoint").textContent = checkpoint === null
      ? "The game starts in the barracks."
      : `Last checkpoint · ${checkpoints[checkpoint]}`;
    profile.hidden = false;
  } catch {
    notice.textContent = "Could not load your progress. Reload the page to try again.";
  }
}

function showAuthForm(form, email) {
  const previous = form === loginForm ? registerForm : loginForm;
  previous.reset();
  previous.hidden = true;
  form.hidden = false;
  form.elements.email.value = email;
  form.elements.email.focus();
  notice.textContent = "";
}

document.querySelector("#show-register").addEventListener("click", () => {
  showAuthForm(registerForm, loginForm.elements.email.value);
});
document.querySelector("#show-login").addEventListener("click", () => {
  showAuthForm(loginForm, registerForm.elements.email.value);
});

async function submitAuth(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const registering = form === registerForm;
  const { email, password, confirmPassword } = Object.fromEntries(new FormData(form));
  if (registering && password !== confirmPassword) {
    notice.textContent = "The passwords do not match.";
    form.elements.confirmPassword.focus();
    return;
  }
  const buttons = form.querySelectorAll("button");
  buttons.forEach((button) => { button.disabled = true; });
  notice.textContent = registering ? "Creating your account…" : "Signing in…";
  try {
    const credentials = { email: email.trim(), password };
    const { data, error } = registering
      ? await client.auth.signUp({
        ...credentials,
        options: { emailRedirectTo: new URL(location.pathname, location.origin).href },
      })
      : await client.auth.signInWithPassword(credentials);
    if (error) {
      const messages = {
        invalid_credentials: "Check your email and password.",
        email_not_confirmed: "Confirm your email before signing in.",
        email_address_not_authorized: "Confirmation emails cannot be sent to this address.",
        over_email_send_rate_limit: "Too many emails were sent. Try again later.",
        weak_password: "Choose a stronger password.",
      };
      notice.textContent = messages[error.code] ?? "The request failed. Try again.";
      return;
    }
    if (data.session) {
      form.reset();
      await showAccount(data.session);
    } else if (registering) {
      showAuthForm(loginForm, credentials.email);
      notice.textContent = "Check your inbox for the confirmation link.";
    }
  } catch {
    notice.textContent = "Could not connect to the server. Try again.";
  } finally {
    buttons.forEach((button) => { button.disabled = false; });
  }
}

loginForm.addEventListener("submit", submitAuth);
registerForm.addEventListener("submit", submitAuth);

play.addEventListener("click", async () => {
  if (gameStarting) return;
  gameStarting = true;
  play.disabled = true;
  account.hidden = true;
  game.hidden = false;
  if (touchInput.available) {
    game.closest(".portal").classList.add("touch-playing");
    canvas.width = 960;
    canvas.height = 540;
    fullscreen.hidden = false;
  }
  try {
    const engine = new Engine(window.winterEngineConfig);
    await engine.startGame({
      canvas,
      canvasResizePolicy: 0,
      onProgress(current, total) {
        if (total > 0) {
          download.max = total;
          download.value = current;
        }
      },
    });
    download.hidden = true;
    canvas.focus();
  } catch {
    game.hidden = true;
    account.hidden = false;
    fullscreen.hidden = true;
    setExpanded(false);
    game.closest(".portal").classList.remove("touch-playing");
    notice.textContent = "Could not start the game. Check for WebGL 2 support and reload the page.";
  }
});

retry.addEventListener("click", () => { void progress?.retry(); });
window.addEventListener("online", () => { void progress?.retry(); });
window.addEventListener("beforeunload", (event) => {
  if (progress?.hasPending()) {
    event.preventDefault();
    event.returnValue = true;
  }
});
logout.addEventListener("click", async () => {
  logout.disabled = true;
  try {
    const { error } = await client.auth.signOut({ scope: "local" });
    if (error) throw error;
    location.reload();
  } catch {
    logout.disabled = false;
    saveStatus.textContent = "Could not sign out. Try again.";
  }
});

client.auth.onAuthStateChange((event, session) => {
  if (event !== "INITIAL_SESSION" && userId && session?.user.id !== userId) {
    location.reload();
  }
});

try {
  const { data, error } = await client.auth.getSession();
  if (error) throw error;
  await showAccount(data.session);
  if (!data.session && confirmationError === "otp_expired") {
    notice.textContent = "This confirmation link has expired or was already used. If you have confirmed your account, sign in.";
  }
} catch {
  notice.textContent = "Could not check your session. Reload the page to try again.";
}
