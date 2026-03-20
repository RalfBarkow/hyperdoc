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
    var direct = target.closest(
      "[data-hyperdoc-anchor-id], [id], li, p, h1, h2, h3, h4, h5, h6, pre, blockquote, a, code, tt"
    );
    var candidate = direct || (target.nodeType === 1 ? target : target.parentElement);
    if (!candidate || !root.contains(candidate)) {
      return null;
    }
    if (candidate.closest(".hyperdoc-dom-connect-toolbar") ||
        candidate.closest(".hyperdoc-dom-connect-controls")) {
      return null;
    }
    if (candidate === root) {
      return null;
    }
    return candidate;
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
    if (strategy === "element-id") {
      return "#" + cssEscape(value);
    }
    return value;
  }

  function buildAnchor(element, root) {
    var anchorId = element.dataset.hyperdocAnchorId;
    var elementId = element.id;
    var strategy = "dom-path";
    var value = domPath(element, root);
    if (anchorId) {
      strategy = "data-anchor";
      value = anchorId;
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
      objectId: element.dataset.hyperdocObjectId || null
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

  function setStatus(state, text) {
    state.status.textContent = text;
  }

  function clearSource(state) {
    if (state.sourceElement) {
      state.sourceElement.classList.remove("hyperdoc-dom-connect-source");
    }
    state.source = null;
    state.sourceElement = null;
    state.overlay.hidden = true;
  }

  function deactivate(state, resetStatus) {
    state.enabled = false;
    state.toggle.dataset.mode = "inactive";
    state.cancel.hidden = true;
    clearSource(state);
    if (resetStatus) {
      setStatus(state, "Direction matters: click source first, then target.");
    }
  }

  function activate(state) {
    state.enabled = true;
    state.toggle.dataset.mode = "active";
    state.cancel.hidden = false;
    setStatus(state, "Connect mode active. Click the source element.");
  }

  function beginConnection(state, element, anchor) {
    clearSource(state);
    state.source = anchor;
    state.sourceElement = element;
    state.sourceElement.classList.add("hyperdoc-dom-connect-source");
    state.overlay.hidden = false;
    setStatus(state, 'Source selected: "' + anchor.label + '". Click the target element.');
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
    dispatchValue(state.sourceInput, JSON.stringify(state.source));
    dispatchValue(state.targetInput, JSON.stringify(targetAnchor));
    deactivate(state, false);
    setStatus(state, 'Opening relation annotation for "' +
      sourceAnchor.label + '" -> "' + targetAnchor.label + '".');
    var submitButton = state.submit.querySelector("button");
    if (submitButton) {
      submitButton.click();
    }
  }

  function onRootClick(state, event) {
    if (!state.enabled) {
      return;
    }
    var element = anchorCandidate(state.root, event.target);
    if (!element) {
      return;
    }
    var anchor = buildAnchor(element, state.root);
    event.preventDefault();
    event.stopPropagation();
    if (!state.source) {
      beginConnection(state, element, anchor);
      updateLineFromMouse(state, event.clientX, event.clientY);
      return;
    }
    if (anchorKey(anchor) === anchorKey(state.source)) {
      setStatus(state, "Pick a different target element.");
      return;
    }
    completeConnection(state, anchor);
  }

  function initSurface(surface) {
    if (!surface || surface.dataset.hyperdocDomConnectInitialized === "true") {
      return;
    }
    var controls = surface.querySelector(".hyperdoc-dom-connect-controls");
    var root = surface.querySelector(".hyperdoc-dom-connect-root");
    var toggle = surface.querySelector(".hyperdoc-dom-connect-toggle");
    var cancel = surface.querySelector(".hyperdoc-dom-connect-cancel");
    var status = surface.querySelector(".hyperdoc-dom-connect-status");
    var overlay = surface.querySelector(".hyperdoc-dom-connect-overlay");
    var line = overlay && overlay.querySelector(".hyperdoc-dom-connect-line");
    if (!controls || !root || !toggle || !cancel || !status || !overlay || !line) {
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
      root: root,
      toggle: toggle,
      cancel: cancel,
      status: status,
      overlay: overlay,
      line: line,
      sourceInput: sourceInput,
      targetInput: targetInput,
      submit: submit,
      enabled: false,
      source: null,
      sourceElement: null
    };
    surface.dataset.hyperdocDomConnectInitialized = "true";
    toggle.dataset.mode = "inactive";
    toggle.addEventListener("click", function () {
      if (state.enabled) {
        deactivate(state, true);
      } else {
        activate(state);
      }
    });
    cancel.addEventListener("click", function () {
      deactivate(state, true);
    });
    root.addEventListener("click", function (event) {
      onRootClick(state, event);
    }, true);
    root.addEventListener("mousemove", function (event) {
      updateLineFromMouse(state, event.clientX, event.clientY);
    }, true);
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
