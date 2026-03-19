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

  shell._feedTabsSync = syncState;
  requestAnimationFrame(syncState);
}

function bootFeedTabsScroller() {
  document.querySelectorAll("[data-feed-tabs-shell]").forEach((shell) => {
    if (!shell.dataset.feedTabsBooted) {
      shell.dataset.feedTabsBooted = "1";
      initFeedTabsScroller(shell);
      return;
    }

    if (typeof shell._feedTabsSync === "function") {
      shell._feedTabsSync();
    }
  });
}

window.addEventListener("DOMContentLoaded", bootFeedTabsScroller);
window.addEventListener("phx:page-loading-stop", bootFeedTabsScroller);
