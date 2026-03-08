// Lightweight client behaviors without bundling requirements.

const COACH_KEY_PREFIX = "goalzone-mini-coach-dismissed:";

function coachStorageKey(page) {
  return `${COACH_KEY_PREFIX}${page}`;
}

function safeGetStorage(key) {
  try {
    return window.localStorage.getItem(key);
  } catch (_error) {
    return null;
  }
}

function safeSetStorage(key, value) {
  try {
    window.localStorage.setItem(key, value);
  } catch (_error) {
    // Ignore storage errors (private mode / disabled storage)
  }
}

function initMiniCoach(root) {
  const page = root.dataset.page;
  if (!page) return;

  if (safeGetStorage(coachStorageKey(page)) === "1") {
    root.remove();
    return;
  }

  const panel = root.querySelector("[data-mini-coach-panel]");
  const toggle = root.querySelector("[data-mini-coach-toggle]");
  const close = root.querySelector("[data-mini-coach-close]");
  const dismiss = root.querySelector("[data-mini-coach-dismiss]");

  if (!panel || !toggle) return;

  const setOpen = (open) => {
    panel.hidden = !open;
    toggle.setAttribute("aria-expanded", open ? "true" : "false");
    root.classList.toggle("mini-coach-open", open);
  };

  setOpen(true);

  toggle.addEventListener("click", () => {
    setOpen(panel.hidden);
  });

  if (close) {
    close.addEventListener("click", () => setOpen(false));
  }

  if (dismiss) {
    dismiss.addEventListener("click", () => {
      safeSetStorage(coachStorageKey(page), "1");
      root.remove();
    });
  }
}

function bootMiniCoach() {
  document.querySelectorAll("[data-mini-coach]").forEach((root) => {
    if (!root.dataset.miniCoachBooted) {
      root.dataset.miniCoachBooted = "1";
      initMiniCoach(root);
    }
  });
}

function submitMethodLink(link) {
  const method = (link.getAttribute("data-method") || "").toLowerCase();
  if (!method) return false;

  const to = link.getAttribute("data-to") || link.getAttribute("href");
  if (!to) return false;

  const csrf =
    link.getAttribute("data-csrf") ||
    document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") ||
    "";

  const form = document.createElement("form");
  form.method = "post";
  form.action = to;
  form.style.display = "none";

  const methodInput = document.createElement("input");
  methodInput.type = "hidden";
  methodInput.name = "_method";
  methodInput.value = method;
  form.appendChild(methodInput);

  if (csrf) {
    const csrfInput = document.createElement("input");
    csrfInput.type = "hidden";
    csrfInput.name = "_csrf_token";
    csrfInput.value = csrf;
    form.appendChild(csrfInput);
  }

  document.body.appendChild(form);
  form.submit();
  return true;
}

function handleMethodLinks(event) {
  const link = event.target.closest("a[data-method]");
  if (!link) return;

  if (submitMethodLink(link)) {
    event.preventDefault();
  }
}

window.addEventListener("DOMContentLoaded", () => {
  bootMiniCoach();
  document.addEventListener("click", handleMethodLinks);
});

window.addEventListener("phx:page-loading-stop", bootMiniCoach);
