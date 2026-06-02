(function () {
  "use strict";

  var initialized = new WeakMap();
  var focusableSelector = [
    "a[href]",
    "area[href]",
    "button:not([disabled])",
    "input:not([disabled])",
    "select:not([disabled])",
    "textarea:not([disabled])",
    "iframe",
    "object",
    "embed",
    "[contenteditable]",
    "[tabindex]"
  ].join(",");

  function prefersReducedMotion() {
    return window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }

  function debounce(fn, delay) {
    var timer = null;
    return function () {
      var args = arguments;
      window.clearTimeout(timer);
      timer = window.setTimeout(function () {
        fn.apply(null, args);
      }, delay);
    };
  }

  function reelItems(scrollable) {
    return Array.prototype.slice.call(
      scrollable.querySelectorAll(".hyperdoc-reel__item, .inspector-pane, .inspector-pane-maximized")
    ).filter(function (item) {
      return item.parentElement === scrollable && !item.hidden;
    });
  }

  function supportsInert() {
    return "inert" in HTMLElement.prototype;
  }

  function disableFocusableDescendants(item) {
    item.querySelectorAll(focusableSelector).forEach(function (node) {
      if (!node.hasAttribute("data-hyperdoc-reel-tabindex")) {
        node.setAttribute(
          "data-hyperdoc-reel-tabindex",
          node.hasAttribute("tabindex") ? node.getAttribute("tabindex") : ""
        );
      }
      node.setAttribute("tabindex", "-1");
    });
  }

  function restoreFocusableDescendants(item) {
    item.querySelectorAll("[data-hyperdoc-reel-tabindex]").forEach(function (node) {
      var original = node.getAttribute("data-hyperdoc-reel-tabindex");
      if (original === "") {
        node.removeAttribute("tabindex");
      } else {
        node.setAttribute("tabindex", original);
      }
      node.removeAttribute("data-hyperdoc-reel-tabindex");
    });
  }

  function setItemInteractive(item, interactive) {
    item.setAttribute("data-hyperdoc-reel-visible", interactive ? "visible" : "partial");
    item.setAttribute("data-hyperdoc-reel-inert", interactive ? "false" : "true");

    if (supportsInert()) {
      item.inert = !interactive;
      return;
    }

    if (interactive) {
      restoreFocusableDescendants(item);
    } else {
      disableFocusableDescendants(item);
    }
  }

  function markItemsByGeometry(scrollable) {
    var scrollableRect = scrollable.getBoundingClientRect();
    reelItems(scrollable).forEach(function (item) {
      var rect = item.getBoundingClientRect();
      var visibleWidth = Math.max(
        0,
        Math.min(rect.right, scrollableRect.right) -
          Math.max(rect.left, scrollableRect.left)
      );
      var ratio = rect.width > 0 ? visibleWidth / rect.width : 1;
      setItemInteractive(item, ratio >= 0.5);
    });
  }

  function updateButtons(state) {
    var scrollable = state.scrollable;
    var maxScrollLeft = Math.max(0, scrollable.scrollWidth - scrollable.clientWidth);
    var current = Math.max(0, scrollable.scrollLeft);
    var tolerance = 2;

    if (state.prev) {
      state.prev.disabled = current <= tolerance;
    }
    if (state.next) {
      state.next.disabled = current >= maxScrollLeft - tolerance;
    }
  }

  function update(state) {
    updateButtons(state);
    if (!state.observer) {
      markItemsByGeometry(state.scrollable);
    }
  }

  function observeItems(state) {
    if (!("IntersectionObserver" in window)) {
      markItemsByGeometry(state.scrollable);
      return;
    }

    if (state.observer) {
      state.observer.disconnect();
    }

    state.observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        setItemInteractive(entry.target, entry.intersectionRatio >= 0.5);
      });
    }, {
      root: state.scrollable,
      threshold: [0, 0.5, 1]
    });

    reelItems(state.scrollable).forEach(function (item) {
      state.observer.observe(item);
    });
  }

  function ensureItemSemantics(scrollable) {
    reelItems(scrollable).forEach(function (item, index) {
      item.classList.add("hyperdoc-reel__item");
      item.setAttribute("role", "listitem");
      item.setAttribute("aria-label", "Inspector pane " + (index + 1));
    });
  }

  function scrollByHalfViewport(scrollable, direction) {
    var distance = Math.max(1, scrollable.clientWidth / 2) * direction;
    scrollable.scrollBy({
      left: distance,
      behavior: prefersReducedMotion() ? "auto" : "smooth"
    });
  }

  function initReel(reel) {
    var existing = initialized.get(reel);
    if (existing) {
      ensureItemSemantics(existing.scrollable);
      observeItems(existing);
      update(existing);
      return existing;
    }

    var scrollable = reel.querySelector(".hyperdoc-reel__scrollable");
    if (!scrollable) {
      return null;
    }

    var buttons = reel.querySelector(".hyperdoc-reel__buttons");
    var state = {
      reel: reel,
      buttons: buttons,
      scrollable: scrollable,
      prev: reel.querySelector(".hyperdoc-reel__prev"),
      next: reel.querySelector(".hyperdoc-reel__next"),
      observer: null,
      mutationObserver: null
    };

    initialized.set(reel, state);
    reel.setAttribute("data-hyperdoc-reel-enhanced", "true");
    scrollable.classList.add("hyperdoc-reel__list");
    scrollable.setAttribute("role", "list");
    if (!scrollable.hasAttribute("tabindex")) {
      scrollable.setAttribute("tabindex", "0");
    }

    if (buttons) {
      buttons.hidden = false;
    }

    if (state.prev) {
      state.prev.addEventListener("click", function () {
        scrollByHalfViewport(scrollable, -1);
      });
    }

    if (state.next) {
      state.next.addEventListener("click", function () {
        scrollByHalfViewport(scrollable, 1);
      });
    }

    var debouncedUpdate = debounce(function () {
      update(state);
    }, 80);

    scrollable.addEventListener("scroll", debouncedUpdate, { passive: true });
    window.addEventListener("resize", debouncedUpdate, { passive: true });

    state.mutationObserver = new MutationObserver(function () {
      ensureItemSemantics(scrollable);
      observeItems(state);
      update(state);
    });
    state.mutationObserver.observe(scrollable, {
      childList: true,
      attributes: true,
      attributeFilter: ["hidden", "class"]
    });

    ensureItemSemantics(scrollable);
    observeItems(state);
    update(state);
    return state;
  }

  function initAll(root) {
    var scope = root || document;
    scope.querySelectorAll(".hyperdoc-reel").forEach(initReel);
  }

  window.hyperdocReel = {
    init: initAll,
    initReel: initReel
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      initAll(document);
    }, { once: true });
  } else {
    initAll(document);
  }
}());
