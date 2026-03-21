(function () {
  function collapseWhitespace(text) {
    return (text || "").replace(/\s+/g, " ").trim();
  }

  function limitText(text, maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return text.slice(0, maxLength - 1) + "\u2026";
  }

  function cssEscape(value) {
    if (window.CSS && typeof window.CSS.escape === "function") {
      return window.CSS.escape(value);
    }
    return String(value).replace(/[^a-zA-Z0-9_-]/g, "\\$&");
  }

  function anchorCandidate(root, target) {
    if (!target) {
      return null;
    }
    var candidate = target.nodeType === 1 ? target : target.parentElement;
    while (candidate && candidate !== root) {
      if (!root.contains(candidate)) {
        return null;
      }
      if (candidate.closest("[data-hyperdoc-connect-ignore='true']")) {
        return null;
      }
      var tagName = candidate.tagName && candidate.tagName.toLowerCase();
      if (tagName &&
          ["script", "style", "link", "meta", "noscript"].indexOf(tagName) === -1) {
        return candidate;
      }
      candidate = candidate.parentElement;
    }
    return null;
  }

  function domPath(element, root) {
    var parts = [];
    var current = element;
    while (current && current !== root && current.nodeType === 1) {
      var tagName = current.tagName.toLowerCase();
      var index = 1;
      var sibling = current.previousElementSibling;
      while (sibling) {
        if (sibling.tagName === current.tagName) {
          index += 1;
        }
        sibling = sibling.previousElementSibling;
      }
      parts.unshift(tagName + ":nth-of-type(" + index + ")");
      current = current.parentElement;
    }
    return parts.join(" > ");
  }

  function anchorSelector(strategy, value) {
    if (strategy === "data-anchor") {
      return '[data-hyperdoc-anchor-id="' + cssEscape(value) + '"]';
    }
    if (strategy === "data-object-id") {
      return '[data-hyperdoc-object-id="' + cssEscape(value) + '"]';
    }
    if (strategy === "element-id") {
      return "#" + cssEscape(value);
    }
    return value;
  }

  function buildAnchor(element, root) {
    var anchorId = element.dataset.hyperdocAnchorId;
    var objectId = element.dataset.hyperdocObjectId;
    var elementId = element.id;
    var strategy = "dom-path";
    var value = domPath(element, root);
    if (anchorId) {
      strategy = "data-anchor";
      value = anchorId;
    } else if (objectId) {
      strategy = "data-object-id";
      value = objectId;
    } else if (elementId) {
      strategy = "element-id";
      value = elementId;
    }
    var label = collapseWhitespace(
      element.dataset.hyperdocAnchorLabel ||
      element.getAttribute("aria-label") ||
      element.innerText ||
      element.textContent ||
      value
    );
    return {
      strategy: strategy,
      value: value,
      selector: anchorSelector(strategy, value),
      label: limitText(label || value, 140),
      tagName: element.tagName.toLowerCase(),
      textSnippet: limitText(collapseWhitespace(element.textContent || ""), 220),
      objectId: objectId || null
    };
  }

  function anchorKey(anchor) {
    return anchor.strategy + "::" + anchor.value;
  }

  function relativePoint(surface, clientX, clientY) {
    var rect = surface.getBoundingClientRect();
    return {
      x: clientX - rect.left,
      y: clientY - rect.top
    };
  }

  function elementCenter(surface, element) {
    var rect = element.getBoundingClientRect();
    return relativePoint(surface, rect.left + rect.width / 2, rect.top + rect.height / 2);
  }

  function setLine(line, fromPoint, toPoint) {
    line.setAttribute("x1", String(fromPoint.x));
    line.setAttribute("y1", String(fromPoint.y));
    line.setAttribute("x2", String(toPoint.x));
    line.setAttribute("y2", String(toPoint.y));
  }

  function dispatchValue(input, value) {
    input.value = value;
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }

  var STORAGE_KEYS = {
    introDismissed: "hyperdoc.domConnect.introDismissed.v1",
    learned: "hyperdoc.domConnect.learned.v1"
  };

  function readPreference(key) {
    try {
      return window.localStorage && window.localStorage.getItem(key) === "1";
    } catch (error) {
      return false;
    }
  }

  function writePreference(key, value) {
    try {
      if (window.localStorage) {
        window.localStorage.setItem(key, value ? "1" : "0");
      }
    } catch (error) {
      // Ignore localStorage failures and keep the current-page behavior.
    }
  }

  function setStatus(state, text) {
    state.status.textContent = text;
  }

  function clearResetTimer(state) {
    if (state.resetTimer) {
      window.clearTimeout(state.resetTimer);
      state.resetTimer = null;
    }
  }

  function closeHelpPanel(state) {
    state.helpPanel.hidden = true;
    state.helpOpen = false;
  }

  function toggleHelpPanel(state) {
    state.helpOpen = !state.helpOpen;
    state.helpPanel.hidden = !state.helpOpen;
  }

  function setPhase(state, phase) {
    state.phase = phase;
    state.surface.dataset.connectState = phase;
    state.launcher.hidden = !(phase === "dormant" || phase === "coachmark");
    state.coachmark.hidden = phase !== "coachmark";
    state.strip.hidden = !(phase === "select-source" ||
      phase === "select-target" ||
      phase === "submitting");
    state.cancel.hidden = !(phase === "select-source" || phase === "select-target");

    if (phase === "select-source") {
      setStatus(state, "Connect mode - click source element");
    } else if (phase === "select-target") {
      setStatus(state, "Source selected - click target element");
    } else if (phase === "submitting") {
      setStatus(state, "Opening relation annotation...");
    }
  }

  function enterDormant(state) {
    clearResetTimer(state);
    state.enabled = false;
    state.surface.classList.remove("hyperdoc-dom-connect-active");
    state.toggle.dataset.mode = "inactive";
    setHoverElement(state, null);
    clearSource(state);
    closeHelpPanel(state);
    if (!state.learned && !state.introDismissed) {
      setPhase(state, "coachmark");
    } else {
      setPhase(state, "dormant");
    }
  }

  function markIntroDismissed(state) {
    state.introDismissed = true;
    writePreference(STORAGE_KEYS.introDismissed, true);
  }

  function markLearned(state) {
    state.learned = true;
    writePreference(STORAGE_KEYS.learned, true);
    markIntroDismissed(state);
  }

  function clearSource(state) {
    if (state.sourceElement) {
      state.sourceElement.classList.remove("hyperdoc-dom-connect-source");
    }
    state.source = null;
    state.sourceElement = null;
    state.overlay.hidden = true;
  }

  function setHoverElement(state, element) {
    if (state.hoverElement && state.hoverElement !== state.sourceElement) {
      state.hoverElement.classList.remove("hyperdoc-dom-connect-hover");
    }
    state.hoverElement = null;
    if (element && element !== state.sourceElement) {
      element.classList.add("hyperdoc-dom-connect-hover");
      state.hoverElement = element;
    }
  }

  function deactivate(state, resetStatus) {
    enterDormant(state);
  }

  function activate(state) {
    clearResetTimer(state);
    markIntroDismissed(state);
    state.enabled = true;
    state.surface.classList.add("hyperdoc-dom-connect-active");
    state.toggle.dataset.mode = "active";
    closeHelpPanel(state);
    setPhase(state, "select-source");
  }

  function beginConnection(state, element, anchor) {
    setHoverElement(state, null);
    clearSource(state);
    state.source = anchor;
    state.sourceElement = element;
    state.sourceElement.classList.add("hyperdoc-dom-connect-source");
    state.overlay.hidden = false;
    setPhase(state, "select-target");
  }

  function updateLineFromMouse(state, clientX, clientY) {
    if (!state.enabled || !state.source || !state.sourceElement) {
      return;
    }
    var fromPoint = elementCenter(state.surface, state.sourceElement);
    var toPoint = relativePoint(state.surface, clientX, clientY);
    setLine(state.line, fromPoint, toPoint);
  }

  function completeConnection(state, targetAnchor) {
    var sourceAnchor = state.source;
    markLearned(state);
    clearResetTimer(state);
    dispatchValue(state.sourceInput, JSON.stringify(state.source));
    dispatchValue(state.targetInput, JSON.stringify(targetAnchor));
    state.enabled = false;
    state.surface.classList.remove("hyperdoc-dom-connect-active");
    state.toggle.dataset.mode = "inactive";
    setHoverElement(state, null);
    clearSource(state);
    closeHelpPanel(state);
    setPhase(state, "submitting");
    var submitButton = state.submit.querySelector("button");
    if (submitButton) {
      submitButton.click();
    }
    state.resetTimer = window.setTimeout(function () {
      if (state.phase === "submitting") {
        enterDormant(state);
      }
    }, 900);
  }

  function invalidClick(state) {
    setStatus(
      state,
      "Click inside the rendered content, not the controls, to create a relation."
    );
  }

  function onRootClick(state, event) {
    if (!state.enabled) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    var element = anchorCandidate(state.root, event.target);
    if (!element) {
      invalidClick(state);
      return;
    }
    var anchor = buildAnchor(element, state.root);
    if (!state.source) {
      beginConnection(state, element, anchor);
      updateLineFromMouse(state, event.clientX, event.clientY);
      return;
    }
    if (anchorKey(anchor) === anchorKey(state.source)) {
      setStatus(
        state,
        "Source selected - click a different target element."
      );
      return;
    }
    completeConnection(state, anchor);
  }

  function initSurface(surface) {
    if (!surface || surface.dataset.hyperdocDomConnectInitialized === "true") {
      return;
    }
    var controls = surface.querySelector(".hyperdoc-dom-connect-controls");
    var chrome = surface.querySelector(".hyperdoc-dom-connect-chrome");
    var launcher = surface.querySelector(".hyperdoc-dom-connect-launcher");
    var coachmark = surface.querySelector(".hyperdoc-dom-connect-coachmark");
    var strip = surface.querySelector(".hyperdoc-dom-connect-strip");
    var root = surface.querySelector(".hyperdoc-dom-connect-root");
    var toggle = surface.querySelector(".hyperdoc-dom-connect-toggle");
    var helpToggles = surface.querySelectorAll(".hyperdoc-dom-connect-help-toggle");
    var tryButton = surface.querySelector(".hyperdoc-dom-connect-try");
    var dismissButton = surface.querySelector(".hyperdoc-dom-connect-dismiss");
    var cancel = surface.querySelector(".hyperdoc-dom-connect-cancel");
    var helpPanel = surface.querySelector(".hyperdoc-dom-connect-help-panel");
    var status = surface.querySelector(".hyperdoc-dom-connect-status");
    var overlay = surface.querySelector(".hyperdoc-dom-connect-overlay");
    var line = overlay && overlay.querySelector(".hyperdoc-dom-connect-line");
    if (!controls || !chrome || !launcher || !coachmark || !strip || !root ||
        !toggle || !tryButton || !dismissButton || !cancel || !helpPanel ||
        !status || !overlay || !line) {
      return;
    }
    var sourceInput = document.getElementById(controls.dataset.sourceInputId);
    var targetInput = document.getElementById(controls.dataset.targetInputId);
    var submit = controls.querySelector(".hyperdoc-dom-connect-submit");
    if (!sourceInput || !targetInput || !submit) {
      return;
    }
    var state = {
      surface: surface,
      chrome: chrome,
      launcher: launcher,
      coachmark: coachmark,
      strip: strip,
      root: root,
      toggle: toggle,
      cancel: cancel,
      helpPanel: helpPanel,
      status: status,
      overlay: overlay,
      line: line,
      sourceInput: sourceInput,
      targetInput: targetInput,
      submit: submit,
      enabled: false,
      phase: "dormant",
      introDismissed: readPreference(STORAGE_KEYS.introDismissed),
      learned: readPreference(STORAGE_KEYS.learned),
      helpOpen: false,
      hoverElement: null,
      source: null,
      sourceElement: null,
      resetTimer: null
    };
    surface.dataset.hyperdocDomConnectInitialized = "true";
    toggle.dataset.mode = "inactive";
    setPhase(state, state.learned || state.introDismissed ? "dormant" : "coachmark");
    toggle.addEventListener("click", function () {
      if (state.enabled) {
        deactivate(state, true);
      } else {
        activate(state);
      }
    });
    helpToggles.forEach(function (button) {
      button.addEventListener("click", function (event) {
        event.preventDefault();
        event.stopPropagation();
        toggleHelpPanel(state);
      });
    });
    tryButton.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      activate(state);
    });
    dismissButton.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      markIntroDismissed(state);
      enterDormant(state);
    });
    cancel.addEventListener("click", function () {
      deactivate(state, true);
    });
    root.addEventListener("click", function (event) {
      onRootClick(state, event);
    }, true);
    root.addEventListener("mousemove", function (event) {
      if (state.enabled) {
        setHoverElement(state, anchorCandidate(state.root, event.target));
      }
      updateLineFromMouse(state, event.clientX, event.clientY);
    }, true);
    root.addEventListener("mouseleave", function () {
      setHoverElement(state, null);
    }, true);
    document.addEventListener("click", function (event) {
      if (state.helpOpen && !state.chrome.contains(event.target)) {
        closeHelpPanel(state);
      }
    }, true);
    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && state.enabled) {
        deactivate(state, true);
      }
    });
    window.addEventListener("resize", function () {
      if (state.sourceElement) {
        var center = elementCenter(state.surface, state.sourceElement);
        setLine(state.line, center, center);
      }
    });
  }

  window.hyperdocDomConnect = {
    initCurrentView: function () {
      if (!window.currentInspectorView) {
        return;
      }
      var surface = window.currentInspectorView.querySelector(".hyperdoc-dom-connect-surface");
      initSurface(surface);
    }
  };
}());
