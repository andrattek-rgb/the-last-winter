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
    saving: "A guardar progresso…",
    saved: "Progresso guardado",
    error: "O progresso ainda não foi guardado.",
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
      startingCheckpoint: checkpoint ?? 0,
      checkpointReached: (value) => progress.reach(value),
    };
    document.querySelector("#checkpoint").textContent = checkpoint === null
      ? "O jogo começa na Sala 1."
      : `Último ponto de controlo · ${checkpoints[checkpoint]}`;
    play.textContent = checkpoint > 0 ? "Continuar" : "Jogar";
    profile.hidden = false;
  } catch {
    notice.textContent = "Não foi possível carregar o progresso. Recarrega a página para tentar de novo.";
  }
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const registering = event.submitter?.value === "register";
  const { email, password } = Object.fromEntries(new FormData(form));
  if (registering && password.length < 8) {
    notice.textContent = "Escolhe uma palavra-passe com pelo menos oito caracteres.";
    return;
  }
  const buttons = form.querySelectorAll("button");
  buttons.forEach((button) => { button.disabled = true; });
  notice.textContent = registering ? "A criar conta…" : "A iniciar sessão…";
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
        invalid_credentials: "Verifica o email e a palavra-passe.",
        email_not_confirmed: "Confirma o email antes de entrares.",
        over_email_send_rate_limit: "Atingiste o limite de envio. Tenta mais tarde.",
        weak_password: "Escolhe uma palavra-passe mais forte.",
      };
      notice.textContent = messages[error.code] ?? "O pedido falhou. Tenta novamente.";
      return;
    }
    form.reset();
    if (data.session) await showAccount(data.session);
    else notice.textContent = "Verifica a caixa de correio para confirmares a conta, depois entra.";
  } catch {
    notice.textContent = "Sem ligação ao servidor. Tenta novamente.";
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
    notice.textContent = "Não foi possível iniciar o jogo. Confirma o suporte a WebGL 2 e recarrega a página.";
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
    saveStatus.textContent = "Não foi possível terminar a sessão. Tenta novamente.";
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
  notice.textContent = "Não foi possível verificar a sessão. Recarrega a página para tentar novamente.";
}
