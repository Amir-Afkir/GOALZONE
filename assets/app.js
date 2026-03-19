import "phoenix_html";
import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";

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

function initFeedTabsScroller(shell) {
  const tabs = shell.querySelector("[data-feed-tabs]");
  const leftArrow = shell.querySelector('[data-feed-tabs-arrow="left"]');
  const rightArrow = shell.querySelector('[data-feed-tabs-arrow="right"]');

  if (!tabs || !leftArrow || !rightArrow) return;

  const syncState = () => {
    const maxScrollLeft = Math.max(0, tabs.scrollWidth - tabs.clientWidth);
    const overflowing = maxScrollLeft > 1;
    const canScrollLeft = tabs.scrollLeft > 1;
    const canScrollRight = tabs.scrollLeft < maxScrollLeft - 1;

    shell.dataset.overflowing = overflowing ? "true" : "false";
    shell.dataset.canScrollLeft = canScrollLeft ? "true" : "false";
    shell.dataset.canScrollRight = canScrollRight ? "true" : "false";

    leftArrow.disabled = !canScrollLeft;
    rightArrow.disabled = !canScrollRight;
  };

  shell._feedTabsSync = syncState;

  const scrollTabs = (direction) => {
    const distance = Math.max(160, Math.round(tabs.clientWidth * 0.72));

    tabs.scrollBy({
      left: direction === "left" ? -distance : distance,
      behavior: "smooth"
    });
  };

  leftArrow.addEventListener("click", () => scrollTabs("left"));
  rightArrow.addEventListener("click", () => scrollTabs("right"));
  tabs.addEventListener("scroll", syncState, {passive: true});

  if ("ResizeObserver" in window) {
    const observer = new ResizeObserver(syncState);
    observer.observe(tabs);
    shell._feedTabsObserver = observer;
  } else {
    window.addEventListener("resize", syncState);
  }

  requestAnimationFrame(syncState);
}

function bootFeedTabsScroller() {
  document.querySelectorAll("[data-feed-tabs-shell]").forEach((shell) => {
    if (!shell.dataset.feedTabsBooted) {
      shell.dataset.feedTabsBooted = "1";
      initFeedTabsScroller(shell);
      return;
    }

    shell._feedTabsSync?.();
  });
}

const Hooks = {
  MessagesWorkspace: {
    mounted() {
      this.handleKeydown = (event) => {
        const target = event.target;
        const tagName = target?.tagName;
        const isEditable =
          target?.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(tagName);

        if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
          event.preventDefault();
          const searchInput = this.el.querySelector("[data-messages-search-input]");

          if (searchInput) {
            searchInput.focus();
            searchInput.select?.();
          }

          return;
        }

        if (target?.matches?.("[data-messages-composer]") && event.key === "Enter" && !event.shiftKey) {
          event.preventDefault();
          target.form?.requestSubmit();
          return;
        }

        if (isEditable) return;

        if (event.key === "j") {
          event.preventDefault();
          this.pushEvent("messages_shortcut", {action: "next_thread"});
        }

        if (event.key === "k") {
          event.preventDefault();
          this.pushEvent("messages_shortcut", {action: "previous_thread"});
        }
      };

      this.el.addEventListener("keydown", this.handleKeydown);
    },

    destroyed() {
      this.el.removeEventListener("keydown", this.handleKeydown);
    }
  }
};

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks
});

window.addEventListener("DOMContentLoaded", () => {
  bootMiniCoach();
  bootFeedTabsScroller();
});

window.addEventListener("phx:page-loading-stop", () => {
  bootMiniCoach();
  bootFeedTabsScroller();
});

liveSocket.connect();
window.liveSocket = liveSocket;
