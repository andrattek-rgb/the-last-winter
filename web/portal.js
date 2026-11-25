import { createClient } from "@supabase/supabase-js";
import { checkpoints, createProgressQueue, readCheckpoint } from "./progress.js";

const account = document.querySelector("#account");
const form = document.querySelector("#auth-form");
const profile = document.querySelector("#profile");
const notice = document.querySelector("#notice");
const play = document.querySelector("#play");
const game = document.querySelector("#game");
const canvas = document.querySelector("#canvas");
const download = document.querySelector("#download");
const sessionControls = document.querySelector("#session-controls");
const logout = document.querySelector("#logout");
const retry = document.querySelector("#retry");
const saveStatus = document.querySelector("#save-status");

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
  form.hidden = Boolean(session);
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

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const registering = event.submitter?.value === "register";
  const { email, password } = Object.fromEntries(new FormData(form));
  if (registering && password.length < 8) {
    notice.textContent = "Choose a password with at least eight characters.";
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
        over_email_send_rate_limit: "Too many emails were sent. Try again later.",
        weak_password: "Choose a stronger password.",
      };
      notice.textContent = messages[error.code] ?? "The request failed. Try again.";
      return;
    }
    form.reset();
    if (data.session) await showAccount(data.session);
    else notice.textContent = "Check your inbox to confirm your account, then sign in.";
  } catch {
    notice.textContent = "Could not connect to the server. Try again.";
  } finally {
    buttons.forEach((button) => { button.disabled = false; });
  }
});

play.addEventListener("click", async () => {
  if (gameStarting) return;
  gameStarting = true;
  play.disabled = true;
  account.hidden = true;
  game.hidden = false;
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
} catch {
  notice.textContent = "Could not check your session. Reload the page to try again.";
}
