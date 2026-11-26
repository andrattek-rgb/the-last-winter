const controls = document.querySelector("#touch-controls");
const stick = document.querySelector("#touch-stick");
const buttons = [...controls.querySelectorAll("[data-action]")];
const crouch = controls.querySelector('[data-action="crouch"]');
const interact = controls.querySelector('[data-action="interact"]');
const orientation = matchMedia("(orientation: landscape)");
const pointers = new Map();
const movement = { move_left: 0, move_right: 0, move_back: 0, move_forward: 0 };
let gameInput = null;
let stickPointer = null;

function setStickPosition(x, y, radius = 0) {
  stick.style.setProperty("--stick-x", `${x * radius}px`);
  stick.style.setProperty("--stick-y", `${y * radius}px`);
  const strengths = {
    move_left: -x,
    move_right: x,
    move_back: -y,
    move_forward: y,
  };
  for (const [action, component] of Object.entries(strengths)) {
    const strength = Math.max(0, Math.round(component * 50) / 50);
    if (strength !== movement[action]) {
      movement[action] = strength;
      gameInput?.(action, strength);
    }
  }
}

function moveStick(event) {
  if (event.pointerId !== stickPointer) return;
  const bounds = stick.getBoundingClientRect();
  const radius = bounds.width * 0.28;
  const x = (event.clientX - bounds.left - bounds.width / 2) / radius;
  const y = (event.clientY - bounds.top - bounds.height / 2) / radius;
  const magnitude = Math.max(1, Math.hypot(x, y));
  setStickPosition(x / magnitude, y / magnitude, radius);
}

function releaseStick() {
  if (stickPointer === null) return;
  const pointerId = stickPointer;
  stickPointer = null;
  setStickPosition(0, 0);
  if (stick.hasPointerCapture(pointerId)) stick.releasePointerCapture(pointerId);
}

stick.addEventListener("pointerdown", (event) => {
  if (!gameInput || controls.hidden || event.button !== 0 || stickPointer !== null) return;
  event.preventDefault();
  stickPointer = event.pointerId;
  stick.setPointerCapture(event.pointerId);
  moveStick(event);
});
stick.addEventListener("pointermove", moveStick);
for (const type of ["pointerup", "pointercancel", "lostpointercapture"]) {
  stick.addEventListener(type, (event) => {
    if (event.pointerId === stickPointer) releaseStick();
  });
}
stick.addEventListener("contextmenu", (event) => event.preventDefault());

function release(pointerId) {
  const button = pointers.get(pointerId);
  if (!button) return;
  pointers.delete(pointerId);
  if (![...pointers.values()].includes(button)) {
    button.classList.remove("active");
    gameInput?.(button.dataset.action, 0);
  }
}

function releaseAll() {
  releaseStick();
  for (const pointerId of pointers.keys()) release(pointerId);
}

for (const button of buttons) {
  button.addEventListener("pointerdown", (event) => {
    if (!gameInput || controls.hidden || button.hidden || event.button !== 0) return;
    event.preventDefault();
    if (pointers.has(event.pointerId)) return;
    const alreadyHeld = [...pointers.values()].includes(button);
    button.setPointerCapture(event.pointerId);
    pointers.set(event.pointerId, button);
    if (!alreadyHeld) {
      button.classList.add("active");
      gameInput(button.dataset.action, 1);
    }
  });
  for (const type of ["pointerup", "pointercancel", "lostpointercapture"]) {
    button.addEventListener(type, (event) => release(event.pointerId));
  }
  button.addEventListener("contextmenu", (event) => event.preventDefault());
}

window.addEventListener("blur", releaseAll);
window.addEventListener("pagehide", releaseAll);
document.addEventListener("fullscreenchange", releaseAll);
document.addEventListener("visibilitychange", () => {
  if (document.hidden) releaseAll();
});
orientation.addEventListener("change", releaseAll);

export const touchInput = {
  available: matchMedia("(pointer: coarse)").matches,
  bindGame(callback) {
    releaseAll();
    gameInput = callback;
  },
  setContext(playable, canCrouch, canInteract) {
    controls.hidden = !playable;
    crouch.hidden = !canCrouch;
    interact.hidden = !canInteract;
    if (!playable) {
      releaseAll();
    } else {
      for (const [pointerId, button] of pointers) {
        if (button.hidden) release(pointerId);
      }
    }
  },
};
