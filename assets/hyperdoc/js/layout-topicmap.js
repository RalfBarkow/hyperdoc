(function () {
  "use strict";

  var initialized = new WeakSet();
  var activePreview = null;

  function toArray(nodes) {
    return Array.prototype.slice.call(nodes || []);
  }

  function first(selector, root) {
    return (root || document).querySelector(selector);
  }

  function topic(surface, id) {
    return surface.querySelector('[data-layout-topic-id="' + id + '"]');
  }

  function trimText(value) {
    return String(value || "").replace(/\s+/g, " ").trim();
  }

  function rectObject(element) {
    if (!element) {
      return null;
    }
    var rect = element.getBoundingClientRect();
    return {
      x: Math.round(rect.x),
      y: Math.round(rect.y),
      width: Math.round(rect.width),
      height: Math.round(rect.height),
      top: Math.round(rect.top),
      right: Math.round(rect.right),
      bottom: Math.round(rect.bottom),
      left: Math.round(rect.left)
    };
  }

  function scrollContext(element) {
    if (!element) {
      return null;
    }
    var styles = window.getComputedStyle(element);
    return {
      overflowX: styles.overflowX,
      overflowY: styles.overflowY,
      scrollLeft: element.scrollLeft || 0,
      scrollTop: element.scrollTop || 0,
      scrollWidth: element.scrollWidth || 0,
      scrollHeight: element.scrollHeight || 0,
      clientWidth: element.clientWidth || 0,
      clientHeight: element.clientHeight || 0
    };
  }

  function evidenceForTopic(card) {
    var selector = card.getAttribute("data-layout-selector");
    var element = selector ? first(selector) : null;
    return {
      topicId: card.getAttribute("data-layout-topic-id"),
      selector: selector,
      found: !!element,
      elementId: element ? element.id || null : null,
      classList: element ? toArray(element.classList) : [],
      boundingBox: rectObject(element),
      scrollContext: scrollContext(element),
      role: element ? element.getAttribute("role") : null
    };
  }

  function captureRuntimeEvidence(surface) {
    var evidence = {};
    toArray(surface.querySelectorAll("[data-layout-topic-id]")).forEach(function (card) {
      var item = evidenceForTopic(card);
      evidence[item.topicId] = item;
      card.setAttribute("data-layout-runtime-found", item.found ? "true" : "false");
      if (item.boundingBox) {
        card.setAttribute("data-layout-bounding-box", JSON.stringify(item.boundingBox));
      }
      var measurement = card.querySelector(".hyperdoc-layout-topic__measurement");
      if (measurement) {
        measurement.textContent = item.boundingBox
          ? "Bounding box: " + item.boundingBox.width + " x " + item.boundingBox.height +
            " at " + item.boundingBox.left + ", " + item.boundingBox.top
          : "Bounding box: selector not present in the live DOM";
      }
    });
    surface.__hyperdocLayoutEvidence = evidence;
    return evidence;
  }

  function setStatus(surface, message) {
    var patch = surface.querySelector(".hyperdoc-layout-patch");
    if (patch) {
      patch.setAttribute("aria-label", message);
    }
  }

  function revealPatch(surface) {
    var patch = surface.querySelector(".hyperdoc-layout-patch");
    if (!patch) {
      return null;
    }
    patch.hidden = false;
    patch.setAttribute("data-layout-patch-status", "created");
    setStatus(surface, "move-topic-into-box-patch created");
    patch.scrollIntoView({ block: "nearest", inline: "nearest" });
    var preview = patch.querySelector(".hyperdoc-layout-preview");
    if (preview) {
      preview.focus();
    }
    return patch;
  }

  function clearDropReady(surface) {
    toArray(surface.querySelectorAll(".is-drop-ready")).forEach(function (card) {
      card.classList.remove("is-drop-ready");
    });
  }

  function dragData(event) {
    var data = "";
    if (event.dataTransfer) {
      data = event.dataTransfer.getData("text/plain") || "";
    }
    return data;
  }

  function acceptedDrop(event, card) {
    var source = dragData(event);
    return source === "hyperdoc-reel__buttons" &&
      card.getAttribute("data-layout-topic-id") === "inspector-pane";
  }

  function topicCardAt(surface, x, y) {
    var element = document.elementFromPoint(x, y);
    var card = element && element.closest
      ? element.closest("[data-layout-topic-id]")
      : null;
    return card && surface.contains(card) ? card : null;
  }

  function acceptedPointerDrop(drag, card) {
    return !!drag &&
      drag.source === "hyperdoc-reel__buttons" &&
      !!card &&
      card.getAttribute("data-layout-topic-id") === "inspector-pane";
  }

  function clearPointerDrag(surface) {
    var drag = surface.__hyperdocLayoutPointerDrag;
    if (drag && drag.sourceCard) {
      drag.sourceCard.classList.remove("is-dragging");
    }
    surface.__hyperdocLayoutPointerDrag = null;
    clearDropReady(surface);
  }

  function wireDragDrop(surface) {
    toArray(surface.querySelectorAll("[data-layout-topic-id]")).forEach(function (card) {
      card.addEventListener("dragstart", function (event) {
        if (card.getAttribute("data-layout-topic-id") !== "hyperdoc-reel__buttons") {
          event.preventDefault();
          return;
        }
        card.classList.add("is-dragging");
        if (event.dataTransfer) {
          event.dataTransfer.effectAllowed = "move";
          event.dataTransfer.setData("text/plain", "hyperdoc-reel__buttons");
        }
      });

      card.addEventListener("dragend", function () {
        card.classList.remove("is-dragging");
        clearDropReady(surface);
      });

      card.addEventListener("dragover", function (event) {
        if (acceptedDrop(event, card)) {
          event.preventDefault();
          card.classList.add("is-drop-ready");
          if (event.dataTransfer) {
            event.dataTransfer.dropEffect = "move";
          }
        }
      });

      card.addEventListener("dragleave", function () {
        card.classList.remove("is-drop-ready");
      });

      card.addEventListener("drop", function (event) {
        if (!acceptedDrop(event, card)) {
          clearDropReady(surface);
          return;
        }
        event.preventDefault();
        clearDropReady(surface);
        revealPatch(surface);
      });

      card.addEventListener("pointerdown", function (event) {
        if (event.button !== 0 ||
            card.getAttribute("data-layout-topic-id") !== "hyperdoc-reel__buttons") {
          return;
        }
        surface.__hyperdocLayoutPointerDrag = {
          pointerId: event.pointerId,
          source: "hyperdoc-reel__buttons",
          sourceCard: card,
          startX: event.clientX,
          startY: event.clientY
        };
        card.classList.add("is-dragging");
        if (card.setPointerCapture) {
          card.setPointerCapture(event.pointerId);
        }
      });

      card.addEventListener("pointermove", function (event) {
        var drag = surface.__hyperdocLayoutPointerDrag;
        if (!drag || drag.pointerId !== event.pointerId) {
          return;
        }
        var target = topicCardAt(surface, event.clientX, event.clientY);
        clearDropReady(surface);
        if (acceptedPointerDrop(drag, target)) {
          target.classList.add("is-drop-ready");
        }
      });

      card.addEventListener("pointerup", function (event) {
        var drag = surface.__hyperdocLayoutPointerDrag;
        if (!drag || drag.pointerId !== event.pointerId) {
          return;
        }
        var target = topicCardAt(surface, event.clientX, event.clientY);
        if (drag.sourceCard && drag.sourceCard.releasePointerCapture) {
          try {
            drag.sourceCard.releasePointerCapture(event.pointerId);
          } catch (error) {
            /* Pointer capture may already be released by the browser. */
          }
        }
        if (acceptedPointerDrop(drag, target)) {
          clearPointerDrag(surface);
          revealPatch(surface);
          return;
        }
        clearPointerDrag(surface);
      });

      card.addEventListener("pointercancel", function (event) {
        var drag = surface.__hyperdocLayoutPointerDrag;
        if (!drag || drag.pointerId !== event.pointerId) {
          return;
        }
        clearPointerDrag(surface);
      });
    });
  }

  function previewTargetPane(surface) {
    return surface.closest(".inspector-pane") ||
      first(".inspector-pane.hyperdoc-reel__item") ||
      first(".inspector-pane");
  }

  function previewButtons() {
    return first(".hyperdoc-reel__buttons");
  }

  function previewReel() {
    return first(".hyperdoc-reel");
  }

  function previewScrollable() {
    return first(".hyperdoc-reel__scrollable");
  }

  function previewPaneBody(pane) {
    return pane
      ? pane.querySelector(".inspector-body") || pane
      : null;
  }

  function rendererEffects(patch, phase) {
    if (!patch) {
      return [];
    }
    return toArray(
      patch.querySelectorAll(
        '.hyperdoc-layout-renderer-effect[data-layout-effect-phase="' + phase + '"]'
      )
    );
  }

  function effectKind(effect) {
    return effect ? effect.getAttribute("data-layout-effect-kind") || "" : "";
  }

  function effectId(effect) {
    return effect ? effect.getAttribute("data-layout-effect-id") || "" : "";
  }

  function storeOriginalStyle(buttons) {
    if (!buttons.hasAttribute("data-layout-original-style")) {
      buttons.setAttribute("data-layout-original-style", buttons.getAttribute("style") || "");
    }
  }

  function storeOriginalInlineProperty(element, property) {
    var dataName = "data-layout-original-" + property.replace(/[A-Z]/g, function (match) {
      return "-" + match.toLowerCase();
    });
    if (element && !element.hasAttribute(dataName)) {
      element.setAttribute(dataName, element.style[property] || "");
    }
  }

  function positionPreviewRail() {
    if (!activePreview) {
      return;
    }
    var buttons = activePreview.buttons;
    var pane = activePreview.pane;
    if (!buttons || !pane || !pane.isConnected) {
      return;
    }
    var rect = pane.getBoundingClientRect();
    var visibleRight = Math.min(window.innerWidth, rect.right);
    var visibleBottom = Math.min(window.innerHeight, rect.bottom);
    var right = Math.max(8, window.innerWidth - visibleRight + 12);
    var bottom = Math.max(8, window.innerHeight - visibleBottom + 12);
    buttons.style.position = "fixed";
    buttons.style.insetBlockEnd = "auto";
    buttons.style.insetInlineEnd = "auto";
    buttons.style.right = right + "px";
    buttons.style.bottom = bottom + "px";
    buttons.style.top = "auto";
    buttons.style.left = "auto";
    buttons.style.zIndex = "1000";
  }

  function applyPreviewEffect(surface, patch, effect) {
    var pane = activePreview && activePreview.pane;
    var buttons = activePreview && activePreview.buttons;
    var reel = activePreview && activePreview.reel;
    var kind = effectKind(effect);
    if (kind === "set-style") {
      var target = effect.getAttribute("data-layout-effect-target");
      var property = effect.getAttribute("data-layout-effect-style-property");
      var value = effect.getAttribute("data-layout-effect-style-value");
      var body = target === "active-pane-body" ? previewPaneBody(pane) : null;
      if (!body || !property || !value) {
        return false;
      }
      storeOriginalInlineProperty(body, property);
      body.style[property] = value;
      body.setAttribute("data-layout-preview-clearance", "reserved");
      body.setAttribute("data-layout-preview-clearance-effect", effectId(effect));
      return true;
    }
    if (kind === "position-control-rail") {
      if (!pane || !buttons || !reel) {
        return false;
      }
      reel.setAttribute("data-layout-preview", "buttons-in-pane");
      buttons.setAttribute("data-layout-preview", "buttons-in-pane");
      buttons.setAttribute("data-layout-preview-effect", effectId(effect));
      buttons.setAttribute(
        "data-layout-preview-parent",
        buttons.parentElement ? trimText(buttons.parentElement.className) : ""
      );
      pane.setAttribute("data-layout-preview-target", "buttons-in-pane");
      pane.setAttribute("data-layout-preview-effect", effectId(effect));
      positionPreviewRail();
      return true;
    }
    return false;
  }

  function activatePreview(surface, patch) {
    var pane = previewTargetPane(surface);
    var buttons = previewButtons();
    var reel = previewReel();
    var scrollable = previewScrollable();
    var effects = rendererEffects(patch, "preview");
    if (!pane || !buttons || !reel || !scrollable || effects.length === 0 ||
        patch.getAttribute("data-layout-repair-plan-status") === "blocked") {
      if (patch) {
        patch.setAttribute("data-preview-state", "failed");
        patch.setAttribute("data-preview-source", "renderer-effects");
        patch.setAttribute("data-preview-effect-count", String(effects.length));
      }
      return;
    }
    storeOriginalStyle(buttons);
    activePreview = {
      surface: surface,
      pane: pane,
      buttons: buttons,
      reel: reel,
      scrollable: scrollable
    };
    var consumed = effects.reduce(function (count, effect) {
      return count + (applyPreviewEffect(surface, patch, effect) ? 1 : 0);
    }, 0);
    if (patch) {
      patch.setAttribute("data-preview-source", "renderer-effects");
      patch.setAttribute("data-preview-effect-count", String(consumed));
      patch.setAttribute(
        "data-preview-state",
        consumed === effects.length ? "previewed" : "failed"
      );
    }
    captureRuntimeEvidence(surface);
  }

  function applyDurableEffects(patch, status) {
    var effect = rendererEffects(patch, "apply").find(function (candidate) {
      return effectKind(candidate) === "durable-override";
    });
    if (!effect || patch.getAttribute("data-layout-repair-plan-status") === "blocked") {
      patch.setAttribute("data-layout-apply-state", "failed");
      patch.setAttribute("data-layout-apply-source", "renderer-effects");
      if (status) {
        status.textContent =
          "Apply failed because the repair plan has no durable override effect.";
      }
      return;
    }
    patch.setAttribute("data-layout-apply-state", "durable-override-created");
    patch.setAttribute("data-layout-apply-source", "renderer-effects");
    patch.setAttribute("data-layout-apply-effect", effectId(effect));
    patch.setAttribute(
      "data-layout-durable-override",
      effect.getAttribute("data-layout-effect-replay") || effectId(effect)
    );
    if (status) {
      status.textContent =
        "Durable override evidence created from the apply-phase renderer effect.";
    }
  }

  function wirePatchActions(surface) {
    var patch = surface.querySelector(".hyperdoc-layout-patch");
    if (!patch) {
      return;
    }
    var preview = patch.querySelector(".hyperdoc-layout-preview");
    var apply = patch.querySelector(".hyperdoc-layout-apply");
    var status = patch.querySelector(".hyperdoc-layout-apply-status");
    if (preview) {
      preview.addEventListener("click", function () {
        activatePreview(surface, patch);
      });
    }
    if (apply) {
      apply.addEventListener("click", function () {
        applyDurableEffects(patch, status);
      });
    }
  }

  function initSurface(surface) {
    if (initialized.has(surface)) {
      captureRuntimeEvidence(surface);
      return;
    }
    initialized.add(surface);
    captureRuntimeEvidence(surface);
    wireDragDrop(surface);
    wirePatchActions(surface);
  }

  function init(root) {
    var scope = root || document;
    toArray(scope.querySelectorAll(".hyperdoc-layout-topicmap")).forEach(initSurface);
  }

  window.addEventListener("resize", positionPreviewRail, { passive: true });
  document.addEventListener("scroll", positionPreviewRail, true);

  window.hyperdocLayoutTopicmap = {
    init: init,
    readSnapshot: function (root) {
      var surface = root && root.matches && root.matches(".hyperdoc-layout-topicmap")
        ? root
        : first(".hyperdoc-layout-topicmap", root || document);
      return surface ? captureRuntimeEvidence(surface) : null;
    },
    repositionPreviews: positionPreviewRail
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      init(document);
    }, { once: true });
  } else {
    init(document);
  }
}());
