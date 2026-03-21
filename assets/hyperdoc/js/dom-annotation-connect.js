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

  function makeRequestId() {
    return "assoc-" + Date.now().toString(36) + "-" +
      Math.random().toString(36).slice(2, 8);
  }

  function anchorLogData(anchor) {
    return {
      label: anchor && anchor.label,
      strategy: anchor && anchor.strategy,
      value: anchor && anchor.value,
      objectId: anchor && anchor.objectId
    };
  }

  function logStage(requestId, stage, details) {
    if (details !== undefined) {
      console.log("[DOM-ASSOC]", requestId, stage, details);
    } else {
      console.log("[DOM-ASSOC]", requestId, stage);
    }
  }

  function setStatus(state, text) {
    state.status.textContent = text;
  }

  function clearFeedback(state) {
    state.feedback.hidden = true;
    state.feedback.textContent = "";
    delete state.feedback.dataset.kind;
  }

  function setFeedback(state, kind, text) {
    state.feedback.dataset.kind = kind;
    state.feedback.textContent = text;
    state.feedback.hidden = false;
  }

  function clearResetTimer(state) {
    if (state.resetTimer) {
      window.clearTimeout(state.resetTimer);
      state.resetTimer = null;
    }
  }

  function clearPendingRequest(state) {
    if (!state.pendingRequest) {
      return;
    }
    window.clearTimeout(state.pendingRequest.timeoutId);
    window.clearInterval(state.pendingRequest.connectionWatchId);
    state.pendingRequest = null;
  }

  function connectionClosed() {
    if (!("ws" in window)) {
      return false;
    }
    return !window.ws || (typeof window.ws.readyState === "number" &&
      window.ws.readyState > 1);
  }

  function failPendingRequest(state, message, detail) {
    if (!state.pendingRequest) {
      return;
    }
    var requestId = state.pendingRequest.id;
    logStage(requestId, "request-failed", {
      message: message,
      detail: detail || null
    });
    clearPendingRequest(state);
    enterDormant(state);
    setFeedback(
      state,
      "error",
      message + " See console/server log for request id " + requestId + "."
    );
  }

  function registerPendingRequest(state, requestId) {
    clearPendingRequest(state);
    state.pendingRequest = {
      id: requestId,
      timeoutId: window.setTimeout(function () {
        if (!state.pendingRequest || state.pendingRequest.id !== requestId) {
          return;
        }
        if (connectionClosed()) {
          failPendingRequest(
            state,
            "Connection closed before the association pane opened.",
            "WebSocket closed before any server acknowledgement for this request."
          );
        } else {
          failPendingRequest(
            state,
            "Association could not be opened.",
            "No server acknowledgement arrived before the request timed out."
          );
        }
      }, 5000),
      connectionWatchId: window.setInterval(function () {
        if (!state.pendingRequest || state.pendingRequest.id !== requestId) {
          return;
        }
        if (connectionClosed()) {
          failPendingRequest(
            state,
            "Connection closed before the association pane opened.",
            "WebSocket closed before any server acknowledgement for this request."
          );
        }
      }, 250)
    };
  }

  function handleServerResult(state, detail) {
    if (!detail || !detail.requestId || !state.pendingRequest ||
        state.pendingRequest.id !== detail.requestId) {
      return;
    }
    if (detail.status === "pane-open-succeeded") {
      logStage(detail.requestId, "pane-open-succeeded", detail);
      clearPendingRequest(state);
      clearFeedback(state);
      return;
    }
    failPendingRequest(
      state,
      detail.message || "Association could not be opened.",
      detail.detail || null
    );
  }

  function closeHelpPanel(state) {
    state.helpPanel.hidden = true;
    state.helpOpen = false;
  }

  function toggleHelpPanel(state) {
    state.helpOpen = !state.helpOpen;
    state.helpPanel.hidden = !state.helpOpen;
  }

  function activeSurfaceForPane(pane) {
    if (!pane) {
      return null;
    }
    var views = pane.querySelectorAll(".inspector-view");
    for (var i = 0; i < views.length; i += 1) {
      var view = views[i];
      if (view.hidden) {
        continue;
      }
      var surface = view.querySelector(".hyperdoc-dom-connect-surface");
      if (surface) {
        return surface;
      }
    }
    return null;
  }

  function ensurePaneControlMarkup(slot) {
    if (!slot || slot.dataset.hyperdocDomConnectControl === "true") {
      return;
    }
    slot.dataset.hyperdocDomConnectControl = "true";
    slot.innerHTML =
      '<div class="hyperdoc-dom-connect-control" data-hyperdoc-connect-ignore="true">' +
        '<button type="button" class="hyperdoc-dom-connect-toggle" ' +
                'title="Connect visible elements in this page to create an association.">Connect</button>' +
        '<span class="hyperdoc-dom-connect-status" hidden>Connect: choose source</span>' +
        '<button type="button" class="hyperdoc-dom-connect-cancel" hidden>Cancel</button>' +
        '<button type="button" class="hyperdoc-dom-connect-help-toggle" ' +
                'title="How DOM connect works" aria-label="How DOM connect works">?</button>' +
      '</div>' +
      '<div class="hyperdoc-dom-connect-coachmark" hidden>' +
        '<span class="hyperdoc-dom-connect-coachmark-copy">New: connect visible elements to create associations.</span>' +
        '<span class="hyperdoc-dom-connect-coachmark-actions">' +
          '<button type="button" class="hyperdoc-dom-connect-try">Try it</button>' +
          '<button type="button" class="hyperdoc-dom-connect-dismiss">Dismiss</button>' +
        '</span>' +
      '</div>' +
      '<div class="hyperdoc-dom-connect-help-panel" hidden>' +
        '<p>Connect visible elements in this page to create an association.</p>' +
        '<p>Choose source, then target. Esc cancels.</p>' +
      '</div>' +
      '<div class="hyperdoc-dom-connect-feedback" hidden></div>';
  }

  function bindSurface(state, surface) {
    state.surface = surface || null;
    state.root = null;
    state.overlay = null;
    state.line = null;
    state.sourceInput = null;
    state.targetInput = null;
    state.submit = null;
    if (!surface) {
      return false;
    }
    var controls = surface.querySelector(".hyperdoc-dom-connect-controls");
    var root = surface.querySelector(".hyperdoc-dom-connect-root");
    var overlay = surface.querySelector(".hyperdoc-dom-connect-overlay");
    var line = overlay && overlay.querySelector(".hyperdoc-dom-connect-line");
    if (!controls || !root || !overlay || !line) {
      return false;
    }
    var sourceInput = document.getElementById(controls.dataset.sourceInputId);
    var targetInput = document.getElementById(controls.dataset.targetInputId);
    var submit = controls.querySelector(".hyperdoc-dom-connect-submit");
    if (!sourceInput || !targetInput || !submit) {
      return false;
    }
    state.root = root;
    state.overlay = overlay;
    state.line = line;
    state.sourceInput = sourceInput;
    state.targetInput = targetInput;
    state.submit = submit;
    return true;
  }

  function syncPaneSurface(state) {
    var surface = activeSurfaceForPane(state.pane);
    var previousSurface = state.surface;
    var previousAvailable = state.available;
    var available = bindSurface(state, surface);
    state.available = available;
    state.slot.hidden = !available;
    if (!available) {
      clearFeedback(state);
      closeHelpPanel(state);
      setHoverElement(state, null);
      clearSource(state);
      state.enabled = false;
      state.toggle.dataset.mode = "inactive";
      setPhase(state, "dormant");
      return;
    }
    if (previousSurface && previousSurface !== surface) {
      setHoverElement(state, null);
      clearSource(state);
      if (state.enabled) {
        state.enabled = false;
        state.toggle.dataset.mode = "inactive";
      }
    }
    if (!previousAvailable || previousSurface !== surface) {
      clearFeedback(state);
      if (state.learned || state.introDismissed) {
        setPhase(state, "dormant");
      } else {
        setPhase(state, "coachmark");
      }
    }
  }

  function setPhase(state, phase) {
    state.phase = phase;
    state.slot.dataset.connectState = phase;
    if (state.surface) {
      state.surface.dataset.connectState = phase;
    }
    state.coachmark.hidden = phase !== "coachmark";
    state.status.hidden = !(phase === "select-source" ||
      phase === "select-target" ||
      phase === "submitting");
    state.cancel.hidden = !(phase === "select-source" || phase === "select-target");

    if (phase === "select-source") {
      setStatus(state, "Connect: choose source");
    } else if (phase === "select-target") {
      setStatus(state, "Connect: choose target");
    } else if (phase === "submitting") {
      setStatus(state, "Opening association...");
    }
  }

  function enterDormant(state) {
    clearResetTimer(state);
    state.enabled = false;
    if (state.surface) {
      state.surface.classList.remove("hyperdoc-dom-connect-active");
    }
    state.toggle.dataset.mode = "inactive";
    setHoverElement(state, null);
    clearSource(state);
    closeHelpPanel(state);
    if (!state.pendingRequest) {
      state.requestId = null;
    }
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
    if (state.overlay) {
      state.overlay.hidden = true;
    }
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
    if (!state.available || !state.surface) {
      return;
    }
    clearResetTimer(state);
    markIntroDismissed(state);
    state.enabled = true;
    state.surface.classList.add("hyperdoc-dom-connect-active");
    state.toggle.dataset.mode = "active";
    clearFeedback(state);
    closeHelpPanel(state);
    setPhase(state, "select-source");
  }

  function beginConnection(state, element, anchor) {
    setHoverElement(state, null);
    clearSource(state);
    state.source = anchor;
    state.sourceElement = element;
    state.requestId = makeRequestId();
    state.sourceElement.classList.add("hyperdoc-dom-connect-source");
    state.overlay.hidden = false;
    logStage(state.requestId, "source-selected", anchorLogData(anchor));
    setPhase(state, "select-target");
  }

  function updateLineFromMouse(state, clientX, clientY) {
    if (!state.enabled || !state.source || !state.sourceElement || !state.surface || !state.line) {
      return;
    }
    var fromPoint = elementCenter(state.surface, state.sourceElement);
    var toPoint = relativePoint(state.surface, clientX, clientY);
    setLine(state.line, fromPoint, toPoint);
  }

  function completeConnection(state, targetAnchor) {
    var requestId = state.requestId || makeRequestId();
    var payload = {
      requestId: requestId,
      contextObjectId: state.surface.dataset.contextObjectId || null,
      contextViewTitle: state.surface.dataset.contextViewTitle || null,
      source: state.source,
      target: targetAnchor
    };
    markLearned(state);
    clearResetTimer(state);
    logStage(requestId, "target-selected", anchorLogData(targetAnchor));
    logStage(requestId, "association-payload-assembled", payload);
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
      submitButton.setAttribute("data-dom-association-request-id", requestId);
      logStage(requestId, "request-sent-to-create-open-association", {
        contextObjectId: payload.contextObjectId,
        contextViewTitle: payload.contextViewTitle
      });
      registerPendingRequest(state, requestId);
      state.requestId = null;
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
      "Click inside the rendered page content, not the pane chrome, to create an association."
    );
  }

  function onRootClick(state, event) {
    if (!state.enabled) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    if (!state.root || event.currentTarget !== state.root) {
      return;
    }
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
        "Source selected - choose a different target element."
      );
      return;
    }
    completeConnection(state, anchor);
  }

  function ensurePaneState(surface) {
    var pane = surface && surface.closest(".inspector-pane");
    var slot = pane && pane.querySelector(".hyperdoc-dom-connect-pane-slot");
    if (!pane || !slot) {
      return null;
    }
    if (pane.hyperdocDomConnectState) {
      return pane.hyperdocDomConnectState;
    }
    ensurePaneControlMarkup(slot);
    var control = slot.querySelector(".hyperdoc-dom-connect-control");
    var coachmark = slot.querySelector(".hyperdoc-dom-connect-coachmark");
    var toggle = slot.querySelector(".hyperdoc-dom-connect-toggle");
    var helpToggle = slot.querySelector(".hyperdoc-dom-connect-help-toggle");
    var tryButton = slot.querySelector(".hyperdoc-dom-connect-try");
    var dismissButton = slot.querySelector(".hyperdoc-dom-connect-dismiss");
    var cancel = slot.querySelector(".hyperdoc-dom-connect-cancel");
    var feedback = slot.querySelector(".hyperdoc-dom-connect-feedback");
    var helpPanel = slot.querySelector(".hyperdoc-dom-connect-help-panel");
    var status = slot.querySelector(".hyperdoc-dom-connect-status");
    if (!control || !coachmark || !toggle || !helpToggle || !tryButton ||
        !dismissButton || !cancel || !feedback || !helpPanel || !status) {
      return null;
    }
    var state = {
      pane: pane,
      slot: slot,
      control: control,
      coachmark: coachmark,
      toggle: toggle,
      cancel: cancel,
      feedback: feedback,
      helpPanel: helpPanel,
      status: status,
      enabled: false,
      available: false,
      phase: "dormant",
      introDismissed: readPreference(STORAGE_KEYS.introDismissed),
      learned: readPreference(STORAGE_KEYS.learned),
      helpOpen: false,
      hoverElement: null,
      source: null,
      sourceElement: null,
      requestId: null,
      pendingRequest: null,
      resetTimer: null,
      surface: null,
      root: null,
      overlay: null,
      line: null,
      sourceInput: null,
      targetInput: null,
      submit: null
    };
    pane.hyperdocDomConnectState = state;
    slot.hidden = true;
    toggle.dataset.mode = "inactive";
    toggle.addEventListener("click", function () {
      if (!state.available) {
        return;
      }
      if (state.enabled) {
        deactivate(state, true);
      } else {
        activate(state);
      }
    });
    helpToggle.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleHelpPanel(state);
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
    document.addEventListener("click", function (event) {
      if (state.helpOpen && !state.slot.contains(event.target)) {
        closeHelpPanel(state);
      }
    }, true);
    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && state.enabled) {
        deactivate(state, true);
      }
    });
    window.addEventListener("hyperdoc-dom-connect-server-result", function (event) {
      handleServerResult(state, event.detail || {});
    });
    window.addEventListener("resize", function () {
      if (state.sourceElement && state.surface && state.line) {
        var center = elementCenter(state.surface, state.sourceElement);
        setLine(state.line, center, center);
      }
    });
    var observer = new MutationObserver(function () {
      syncPaneSurface(state);
    });
    observer.observe(pane, {
      subtree: true,
      attributes: true,
      attributeFilter: ["hidden", "class"]
    });
    return state;
  }

  function initSurface(surface) {
    if (!surface) {
      return;
    }
    var state = ensurePaneState(surface);
    if (!state) {
      return;
    }
    if (surface.dataset.hyperdocDomConnectInitialized !== "true") {
      var root = surface.querySelector(".hyperdoc-dom-connect-root");
      if (!root) {
        return;
      }
      surface.dataset.hyperdocDomConnectInitialized = "true";
      root.addEventListener("click", function (event) {
        onRootClick(state, event);
      }, true);
      root.addEventListener("mousemove", function (event) {
        if (state.enabled && state.root === root) {
          setHoverElement(state, anchorCandidate(state.root, event.target));
        }
        updateLineFromMouse(state, event.clientX, event.clientY);
      }, true);
      root.addEventListener("mouseleave", function () {
        if (state.root === root) {
          setHoverElement(state, null);
        }
      }, true);
    }
    syncPaneSurface(state);
  }

  window.hyperdocDomConnect = {
    initCurrentView: function () {
      if (!window.currentInspectorView) {
        return;
      }
      var surface = window.currentInspectorView.querySelector(".hyperdoc-dom-connect-surface");
      initSurface(surface);
    },
    notifyServerResult: function (detail) {
      window.dispatchEvent(
        new CustomEvent("hyperdoc-dom-connect-server-result", {
          detail: detail || {}
        })
      );
    }
  };
}());
