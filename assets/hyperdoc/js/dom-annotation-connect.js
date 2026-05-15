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

  function isHeadingTagName(tagName) {
    return ["h1", "h2", "h3", "h4", "h5", "h6"].indexOf(tagName) !== -1;
  }

  function slugifyText(value) {
    return collapseWhitespace(value || "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .replace(/-{2,}/g, "-")
      .slice(0, 96) || "anchor";
  }

  function domAnchorCandidate(root, target) {
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

  function contentAnchorCandidate(root, target) {
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
      if (tagName && (isHeadingTagName(tagName) || tagName === "li" || tagName === "p")) {
        return candidate;
      }
      candidate = candidate.parentElement;
    }
    return domAnchorCandidate(root, target);
  }

  function sourceAnchorCandidate(root, target) {
    if (!root || !target) {
      return null;
    }
    var candidate = target.closest("[data-hyperdoc-connect-source-anchor='true']");
    if (!candidate || !root.contains(candidate)) {
      return null;
    }
    return candidate;
  }

  function fedwikiStoryItemAnchorCandidate(root, target) {
    if (!root || !target) {
      return null;
    }
    var candidate = target.nodeType === 1 ? target : target.parentElement;
    if (!candidate) {
      return null;
    }
    candidate = candidate.closest("[data-hyperdoc-fedwiki-story-item-anchor='true']");
    if (!candidate || !root.contains(candidate)) {
      return null;
    }
    if (candidate.closest("[data-hyperdoc-connect-ignore='true']")) {
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
    if (strategy === "data-object-id") {
      return '[data-hyperdoc-object-id="' + cssEscape(value) + '"]';
    }
    if (strategy === "element-id") {
      return "#" + cssEscape(value);
    }
    return value;
  }

  function paneIdForElement(element) {
    var pane = element && element.closest(".inspector-pane");
    return pane && pane.dataset.hyperdocConnectPaneId || null;
  }

  function buildDomFallbackMetadata(element, root) {
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
      durabilityTier: (function () {
        if (strategy === "data-anchor") {
          return "strong";
        }
        if (strategy === "data-object-id" || strategy === "element-id") {
          return "medium";
        }
        return "weak";
      }()),
      durabilityNote: (function () {
        if (strategy === "data-anchor") {
          return "Authored anchor ids are the strongest DOM-backed anchors in this slice; durability depends on the id being preserved across page revisions.";
        }
        if (strategy === "data-object-id") {
          return "Object-id anchors remain stable while the rendered element continues to represent the same related object.";
        }
        if (strategy === "element-id") {
          return "Element-id anchors remain stable while the DOM id is preserved.";
        }
        return "Relative DOM-path anchors are fallback-level and can drift when the rendered tree shape changes.";
      }()),
      objectId: objectId || null
    };
  }

  function sectionPathForElement(root, element) {
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT);
    var current = walker.currentNode;
    var stack = [];
    while (current) {
      if (current === element) {
        break;
      }
      var tagName = current.tagName && current.tagName.toLowerCase();
      if (isHeadingTagName(tagName)) {
        var level = Number(tagName.slice(1));
        stack = stack.filter(function (entry) {
          return entry.level < level;
        });
        stack.push({
          level: level,
          label: collapseWhitespace(current.textContent || ""),
          slug: slugifyText(current.textContent || "")
        });
      }
      current = walker.nextNode();
    }
    if (element && isHeadingTagName(element.tagName && element.tagName.toLowerCase())) {
      var elementLevel = Number(element.tagName.toLowerCase().slice(1));
      stack = stack.filter(function (entry) {
        return entry.level < elementLevel;
      });
      stack.push({
        level: elementLevel,
        label: collapseWhitespace(element.textContent || ""),
        slug: slugifyText(element.textContent || "")
      });
    }
    return stack;
  }

  function scopeKeyForElement(root, element) {
    var path = sectionPathForElement(root, element);
    if (!path.length) {
      return "page-root";
    }
    return path.map(function (entry) {
      return "h" + entry.level + ":" + entry.slug;
    }).join("/");
  }

  function paragraphIndexInScope(root, element) {
    var scopeKey = scopeKeyForElement(root, element);
    var paragraphs = root.querySelectorAll("p");
    var index = 0;
    for (var i = 0; i < paragraphs.length; i += 1) {
      if (scopeKeyForElement(root, paragraphs[i]) !== scopeKey) {
        continue;
      }
      index += 1;
      if (paragraphs[i] === element) {
        return index;
      }
    }
    return 1;
  }

  function listContainerPath(list, root) {
    var segments = [];
    var current = list;
    while (current && current !== root) {
      var tagName = current.tagName && current.tagName.toLowerCase();
      if (tagName === "ul" || tagName === "ol" || tagName === "li") {
        var index = 1;
        var sibling = current.previousElementSibling;
        while (sibling) {
          if (sibling.tagName === current.tagName) {
            index += 1;
          }
          sibling = sibling.previousElementSibling;
        }
        segments.unshift(tagName + "[" + index + "]");
      }
      current = current.parentElement;
    }
    return segments;
  }

  function resolvedContentIdentity(element, root, fallback) {
    var tagName = element.tagName.toLowerCase();
    var sectionPath = sectionPathForElement(root, element);
    var scopeKey = scopeKeyForElement(root, element);
    var label = fallback.label;
    if (fallback.strategy === "data-anchor" ||
        fallback.strategy === "data-object-id" ||
        fallback.strategy === "element-id") {
      return {
        strategy: fallback.strategy,
        value: fallback.value,
        label: label,
        durabilityTier: fallback.durabilityTier,
        durabilityNote: fallback.durabilityNote,
        sectionPath: sectionPath
      };
    }
    if (isHeadingTagName(tagName)) {
      return {
        strategy: "heading-anchor",
        value: "heading:" + scopeKey,
        label: label,
        durabilityTier: "medium",
        durabilityNote: "Heading anchors resolve clicks to the semantic heading path inside the current HyperDoc content page. They are more durable than raw DOM paths, but can drift if headings are renamed or restructured.",
        sectionPath: sectionPath
      };
    }
    if (tagName === "li") {
      var list = element.parentElement;
      var itemIndex = 1;
      var sibling = element.previousElementSibling;
      while (sibling) {
        if (sibling.tagName === element.tagName) {
          itemIndex += 1;
        }
        sibling = sibling.previousElementSibling;
      }
      return {
        strategy: "list-item-anchor",
        value: "list-item:" + scopeKey + "/" +
          listContainerPath(list, root).join("/") +
          "/item[" + itemIndex + "]:" + slugifyText(label),
        label: label,
        durabilityTier: "medium",
        durabilityNote: "List-item anchors resolve clicks to the surrounding heading scope plus list and item position. They are more durable than raw DOM paths, but still depend on section and list structure remaining recognizable.",
        sectionPath: sectionPath
      };
    }
    if (tagName === "p") {
      return {
        strategy: "paragraph-anchor",
        value: "paragraph:" + scopeKey + "/p[" +
          paragraphIndexInScope(root, element) + "]:" + slugifyText(label),
        label: label,
        durabilityTier: "medium",
        durabilityNote: "Paragraph anchors resolve clicks to the surrounding heading scope plus paragraph index. They are more durable than raw DOM paths, but can drift if paragraphs are inserted, removed, or reordered.",
        sectionPath: sectionPath
      };
    }
    return {
      strategy: fallback.strategy,
      value: fallback.value,
      label: label,
      durabilityTier: fallback.durabilityTier,
      durabilityNote: fallback.durabilityNote,
      sectionPath: sectionPath
    };
  }

  function buildDomAnchor(element, root, surface) {
    var fallback = buildDomFallbackMetadata(element, root);
    var resolved = resolvedContentIdentity(element, root, fallback);
    return {
      providerKind: "dom-v1",
      viewKind: surface && surface.dataset.hyperdocConnectViewKind || "content",
      viewTitle: surface && surface.dataset.contextViewTitle || null,
      paneId: paneIdForElement(surface || element),
      contextObjectId: surface && surface.dataset.contextObjectId || null,
      strategy: resolved.strategy,
      value: resolved.value,
      label: resolved.label,
      selector: fallback.selector,
      tagName: element.tagName.toLowerCase(),
      textSnippet: fallback.textSnippet,
      durabilityTier: resolved.durabilityTier,
      durabilityNote: resolved.durabilityNote,
      sectionPath: resolved.sectionPath && resolved.sectionPath.map(function (entry) {
        return {
          level: entry.level,
          label: entry.label,
          slug: entry.slug
        };
      }),
      fallbackStrategy: fallback.strategy,
      fallbackValue: fallback.value,
      objectId: fallback.objectId || null
    };
  }

  function buildSourceAnchor(element, surface) {
    var path = element.dataset.hyperdocSourcePath || "";
    var startLine = Number(element.dataset.hyperdocSourceStartLine || 0) || null;
    var endLine = Number(element.dataset.hyperdocSourceEndLine || 0) || startLine;
    var startColumn = Number(element.dataset.hyperdocSourceStartColumn || 0) || 1;
    var endColumn = Number(element.dataset.hyperdocSourceEndColumn || 0) || startColumn;
    var value = element.dataset.hyperdocSourceValue || path;
    var label = collapseWhitespace(
      element.dataset.hyperdocSourceLabel ||
      element.innerText ||
      element.textContent ||
      value
    );
    return {
      providerKind: "source-v1",
      viewKind: surface && surface.dataset.hyperdocConnectViewKind || "source",
      viewTitle: surface && surface.dataset.contextViewTitle || null,
      paneId: paneIdForElement(surface || element),
      contextObjectId: surface && surface.dataset.contextObjectId || null,
      strategy: "source-line-range",
      value: value,
      label: limitText(label || value, 140),
      path: path,
      startLine: startLine,
      endLine: endLine,
      startColumn: startColumn,
      endColumn: endColumn,
      textSnippet: limitText(collapseWhitespace(element.textContent || ""), 220),
      durabilityTier: "medium",
      durabilityNote: "Source line anchors are durable for the same file path and line range, but line numbers can drift when the source file changes.",
      fallbackStrategy: null,
      fallbackValue: null,
      objectId: element.dataset.hyperdocSourceObjectId || null
    };
  }

  function buildAnnotationTargetAnchor(state) {
    var surface = state && state.surface;
    var annotationTopicId =
      surface && surface.dataset.hyperdocDockAnnotationTopicId || "dock-annotation";
    return {
      providerKind: "dock-v1",
      viewKind: "dock-target",
      viewTitle: surface && surface.dataset.contextViewTitle || null,
      paneId: state && state.paneId || paneIdForElement(surface),
      contextObjectId: surface && surface.dataset.contextObjectId || null,
      strategy: "annotation-topic",
      value: annotationTopicId,
      label: "Annotation",
      durabilityTier: "strong",
      durabilityNote:
        "The generic Annotation target is a synthetic authored anchor that classifies the relation as an annotation.",
      objectId: annotationTopicId
    };
  }

  function buildFedwikiAnchor(element, surface, root, target) {
    var clickedElement = domAnchorCandidate(root, target) || element;
    var fallback = buildDomFallbackMetadata(clickedElement, root);
    var siteDomain = element.dataset.hyperdocFedwikiSiteDomain ||
      surface && surface.dataset.hyperdocFedwikiSiteDomain ||
      null;
    var pageSlug = element.dataset.hyperdocFedwikiPageSlug ||
      surface && surface.dataset.hyperdocFedwikiPageSlug ||
      null;
    var pageTitle = element.dataset.hyperdocFedwikiPageTitle ||
      surface && surface.dataset.hyperdocFedwikiPageTitle ||
      null;
    var storyItemId = element.dataset.hyperdocFedwikiStoryItemId || null;
    var storyItemType = element.dataset.hyperdocFedwikiStoryItemType || null;
    var label = collapseWhitespace(
      element.dataset.hyperdocFedwikiStoryItemLabel ||
      fallback.label ||
      pageTitle ||
      storyItemId ||
      "FedWiki story item"
    );
    var value = "story-item:" +
      (siteDomain || "site") + "/" +
      (pageSlug || "page") + "#" +
      (storyItemId || "item");
    return {
      providerKind: "fedwiki-v1",
      viewKind: surface && surface.dataset.hyperdocConnectViewKind || "story",
      viewTitle: surface && surface.dataset.contextViewTitle || null,
      paneId: paneIdForElement(surface || element),
      contextObjectId: pageTitle ||
        surface && surface.dataset.contextObjectId ||
        null,
      pageTitle: pageTitle,
      siteDomain: siteDomain,
      pageSlug: pageSlug,
      storyItemId: storyItemId,
      storyItemType: storyItemType,
      strategy: "fedwiki-story-item",
      value: value,
      label: limitText(label || value, 140),
      selector: fallback.selector,
      tagName: clickedElement && clickedElement.tagName &&
        clickedElement.tagName.toLowerCase() || null,
      textSnippet: fallback.textSnippet,
      durabilityTier: "strong",
      durabilityNote: "FedWiki story-item anchors resolve clicks to site, slug, and story-item id. They remain durable while the page slug and story-item id are preserved by journal evolution; DOM location is fallback metadata only.",
      fallbackStrategy: fallback.strategy,
      fallbackValue: fallback.value,
      objectId: null
    };
  }

  function surfaceProviderKind(surface) {
    return surface && surface.dataset.hyperdocConnectProviderKind || "dom-v1";
  }

  function providerHelpSummary(surface) {
    return surface && surface.dataset.hyperdocConnectHelpSummary ||
      "Click a source anchor, then a target anchor.";
  }

  function providerHelpDetail(surface) {
    return surface && surface.dataset.hyperdocConnectHelpDetail ||
      "Connect keeps the resolved anchor and its presentation fallback separate. Esc cancels.";
  }

  function providerApiForKind(kind) {
    if (kind === "source-v1") {
      return {
        anchorCandidate: sourceAnchorCandidate,
        buildAnchor: function (element, surface) {
          return buildSourceAnchor(element, surface);
        }
      };
    }
    if (kind === "fedwiki-v1") {
      return {
        anchorCandidate: fedwikiStoryItemAnchorCandidate,
        buildAnchor: function (element, surface, root, target) {
          return buildFedwikiAnchor(element, surface, root, target);
        }
      };
    }
    return {
      anchorCandidate: contentAnchorCandidate,
      buildAnchor: function (element, surface, root) {
        return buildDomAnchor(element, root, surface);
      }
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

  function cloneData(value) {
    if (value === null || value === undefined) {
      return null;
    }
    try {
      return JSON.parse(JSON.stringify(value));
    } catch (error) {
      return {
        summary: String(value)
      };
    }
  }

  function stringValueLength(value) {
    return typeof value === "string" ? value.length : 0;
  }

  function stringValuePresent(value) {
    return stringValueLength(value) > 0;
  }

  function fieldDiagnostic(input) {
    return {
      found: !!input,
      id: input && input.id || null,
      name: input && input.name || null,
      present: !!(input && stringValuePresent(input.value)),
      length: input ? stringValueLength(input.value) : 0
    };
  }

  function surfaceDiagnostic(surface) {
    return {
      found: !!surface,
      id: surface && surface.id || null,
      paneId: paneIdForElement(surface),
      providerKind: surfaceProviderKind(surface),
      contextObjectId: surface && surface.dataset.contextObjectId || null,
      contextViewTitle: surface && surface.dataset.contextViewTitle || null
    };
  }

  function makeRequestId() {
    return "assoc-" + Date.now().toString(36) + "-" +
      Math.random().toString(36).slice(2, 8);
  }

  function anchorLogData(anchor) {
    return cloneData(anchor);
  }

  function logStage(requestId, stage, details) {
    var now = Date.now();
    window.hyperdocDomConnectEvents = window.hyperdocDomConnectEvents || [];
    window.hyperdocDomConnectEvents.push({
      requestId: requestId,
      stage: stage,
      timestamp: now,
      timestampLabel: new Date(now).toISOString(),
      details: details === undefined ? null : details
    });
    if (window.hyperdocDomConnectEvents.length > 400) {
      window.hyperdocDomConnectEvents.shift();
    }
    if (details !== undefined) {
      console.log("[DOM-ASSOC]", requestId, stage, details);
    } else {
      console.log("[DOM-ASSOC]", requestId, stage);
    }
  }

  function connectTestState() {
    if (!window.hyperdocDomConnectTestState) {
      window.hyperdocDomConnectTestState = {
        nextFailureMode: null,
        suppressedServerResults: {}
      };
    }
    return window.hyperdocDomConnectTestState;
  }

  function consumeNextFailureMode() {
    var state = connectTestState();
    var mode = state.nextFailureMode || null;
    state.nextFailureMode = null;
    return mode;
  }

  function suppressServerResult(requestId, reason) {
    if (!requestId) {
      return;
    }
    connectTestState().suppressedServerResults[requestId] = reason || true;
  }

  function suppressedServerResultReason(requestId) {
    if (!requestId) {
      return null;
    }
    return connectTestState().suppressedServerResults[requestId] || null;
  }

  function clearSuppressedServerResult(requestId) {
    if (!requestId) {
      return;
    }
    delete connectTestState().suppressedServerResults[requestId];
  }

  function escapeHtml(value) {
    return String(value === undefined || value === null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function makeIdleSession() {
    return {
      id: null,
      phase: "idle",
      originPaneId: null,
      sourcePaneId: null,
      sourceProviderKind: null,
      sourceAnchor: null,
      sourceState: null,
      targetPaneId: null,
      targetProviderKind: null,
      targetAnchor: null,
      targetState: null
    };
  }

  function connectManager() {
    if (!window.hyperdocDomConnectManager) {
      window.hyperdocDomConnectManager = {
        states: [],
        session: makeIdleSession()
      };
    }
    return window.hyperdocDomConnectManager;
  }

  function liveStates(manager) {
    manager.states = manager.states.filter(function (state) {
      return !!(state && state.pane && state.pane.isConnected);
    });
    return manager.states;
  }

  function registerState(manager, state) {
    if (liveStates(manager).indexOf(state) === -1) {
      manager.states.push(state);
    }
  }

  function sessionActive(manager) {
    return !!(manager.session && manager.session.id &&
      manager.session.phase !== "idle");
  }

  function sessionDiagnostic(session) {
    return {
      id: session && session.id || null,
      phase: session && session.phase || "idle",
      originPaneId: session && session.originPaneId || null,
      sourcePaneId: session && session.sourcePaneId || null,
      sourceProviderKind: session && session.sourceProviderKind || null,
      source: cloneData(session && session.sourceAnchor),
      targetPaneId: session && session.targetPaneId || null,
      targetProviderKind: session && session.targetProviderKind || null,
      target: cloneData(session && session.targetAnchor)
    };
  }

  var DOCK_PRESENTATION_SCOPE = "browser-session";
  var DOCK_CAPABILITY_CONNECT = "connect";
  var DOCK_CAPABILITY_SNIPPET = "snippet";
  var MOBILE_ROUTE_MEDIA_QUERY = "(max-width: 720px)";
  var MOBILE_ROUTE_SUCCESS_FEEDBACK_MS = 1600;
  var DOCK_INTRODUCTION_PRIORITY = [
    DOCK_CAPABILITY_SNIPPET,
    DOCK_CAPABILITY_CONNECT
  ];

  function mobileRouteViewport() {
    return !!(window.matchMedia &&
      window.matchMedia(MOBILE_ROUTE_MEDIA_QUERY).matches);
  }

  function createDockPresentationMemory() {
    return {
      scope: DOCK_PRESENTATION_SCOPE,
      introducedByCapability: {}
    };
  }

  function dockPresentationMemory() {
    if (!window.hyperdocDockPresentationMemory ||
        typeof window.hyperdocDockPresentationMemory !== "object") {
      window.hyperdocDockPresentationMemory = createDockPresentationMemory();
    }
    if (!window.hyperdocDockPresentationMemory.scope) {
      window.hyperdocDockPresentationMemory.scope = DOCK_PRESENTATION_SCOPE;
    }
    if (!window.hyperdocDockPresentationMemory.introducedByCapability ||
        typeof window.hyperdocDockPresentationMemory.introducedByCapability !== "object") {
      window.hyperdocDockPresentationMemory.introducedByCapability = {};
    }
    return window.hyperdocDockPresentationMemory;
  }

  function resetDockPresentationMemory() {
    window.hyperdocDockPresentationMemory = createDockPresentationMemory();
  }

  function capabilityScopedPresentationReason(capability, reason) {
    if (!reason) {
      return capability || null;
    }
    if (!capability) {
      return reason;
    }
    if (reason.indexOf(capability + ".") === 0) {
      return reason;
    }
    return capability + "." + reason;
  }

  function dockCapabilityIntroduced(memory, capability) {
    return !!(memory &&
      memory.introducedByCapability &&
      capability &&
      memory.introducedByCapability[capability]);
  }

  function markDockCapabilityIntroduced(memory, capability) {
    if (!memory || !capability) {
      return;
    }
    if (!memory.introducedByCapability) {
      memory.introducedByCapability = {};
    }
    memory.introducedByCapability[capability] = true;
  }

  function paneSnapshot(state) {
    var session = connectManager().session;
    return {
      paneId: state.paneId,
      activeTab: state.pane.querySelector(".inspector-tabs button.active") &&
        state.pane.querySelector(".inspector-tabs button.active").textContent.trim() || null,
      contextViewTitle: state.surface && state.surface.dataset.contextViewTitle || null,
      providerKind: state.providerKind,
      available: !!state.available,
      enabled: !!state.enabled,
      phase: state.phase,
      helpOpen: !!state.helpOpen,
      presentationState: state.presentationState || "latent",
      presentationReason: state.presentationReason || null,
      introducedCapability: state.introducedCapability || null,
      presentationScope: state.presentationScope || DOCK_PRESENTATION_SCOPE,
      coachmarkVisible: !!state.helpOpen,
      mobileRouteState: state.mobileRouteState || null,
      mobileRouteTitle: state.mobileRouteTitleNode &&
        state.mobileRouteTitleNode.textContent || null,
      selectedSourceLabel: anchorLabel(session && session.sourceAnchor, null),
      selectedSourcePane: !!(session && session.sourcePaneId &&
        session.sourcePaneId === state.paneId),
      pendingRequestId: state.pendingRequest && state.pendingRequest.id || null,
      compactCapabilities: state.compactCapabilities || [],
      coachmarkCapabilities: state.coachmarkCapabilities || [],
      providerHandoffs: state.providerHandoffs || []
    };
  }

  function transitionSnapshots() {
    return cloneData(window.hyperdocDomConnectEvents || []) || [];
  }

  function debugSnapshot() {
    var manager = connectManager();
    var now = Date.now();
    return {
      capturedAt: now,
      capturedAtLabel: new Date(now).toISOString(),
      session: sessionDiagnostic(manager.session),
      panes: liveStates(manager).map(function (state) {
        return paneSnapshot(state);
      }),
      transitions: transitionSnapshots()
    };
  }

  function anchorLabel(anchor, fallback) {
    var label = collapseWhitespace(anchor && (anchor.label || anchor.value || "") || "");
    if (!label && fallback) {
      label = fallback;
    }
    return label ? limitText(label, 64) : null;
  }

  function sessionCueText(session) {
    if (!session || !session.id) {
      return "Click Connect to start.";
    }
    if (session.phase === "choose-source") {
      return "Click a source anchor.";
    }
    if (session.phase === "choose-target") {
      return "Click a target anchor or tap Annotation.";
    }
    return "";
  }

  function mobileRouteStateForSession(state, session) {
    if (state &&
        state.completedRoute &&
        state.mobileRouteSuccessUntil &&
        Date.now() < state.mobileRouteSuccessUntil) {
      return "completed";
    }
    if (state && state.feedback &&
        !state.feedback.hidden &&
        state.feedback.dataset.kind === "success") {
      return "completed";
    }
    if (!session || !session.id || session.phase === "idle") {
      return "idle";
    }
    if (session.phase === "choose-source") {
      return "idle";
    }
    if (session.phase === "choose-target" && session.sourceAnchor) {
      return "source-latched";
    }
    if (session.phase === "submitting") {
      return "confirming";
    }
    return "idle";
  }

  function mobileRouteTitle(state, routeState, session) {
    var sourceLabel = anchorLabel(session && session.sourceAnchor, "source");
    var targetLabel = anchorLabel(session && session.targetAnchor, null);
    if (routeState === "source-latched") {
      return "From: " + (sourceLabel || "source");
    }
    if (routeState === "destination-candidate" && sourceLabel && targetLabel) {
      return sourceLabel + " \u2192 " + targetLabel;
    }
    if (routeState === "confirming") {
      if (sourceLabel && targetLabel) {
        return sourceLabel + " \u2192 " + targetLabel;
      }
      return "Opening route";
    }
    if (routeState === "completed") {
      return "Route saved";
    }
    return "Tap a station";
  }

  function mobileRouteDetail(routeState) {
    if (routeState === "source-latched") {
      return "Tap target or operation";
    }
    if (routeState === "confirming") {
      return "Opening route";
    }
    if (routeState === "completed") {
      return "";
    }
    return "";
  }

  function connectionSuccessText(session) {
    var sourceLabel = anchorLabel(session && session.sourceAnchor, null);
    var targetLabel = anchorLabel(session && session.targetAnchor, null);
    if (sourceLabel && targetLabel) {
      return 'Route saved: "' + sourceLabel + '" to "' + targetLabel + '".';
    }
    return "Route saved.";
  }

  function uniqueStates(states) {
    var result = [];
    states.forEach(function (state) {
      if (state && result.indexOf(state) === -1) {
        result.push(state);
      }
    });
    return result;
  }

  function setStatus(state, text) {
    state.status.textContent = text;
  }

  function setCue(state, text) {
    state.cue.textContent = text || "";
    state.cue.hidden = !text;
  }

  function setSourceSummary(state, anchor, visible) {
    var label = anchorLabel(anchor, "Selected source");
    state.sourceSummary.hidden = !(visible && label);
    state.sourceChip.textContent = label || "";
  }

  function dispatchHiddenDockButton(wrapper, clickOptions) {
    if (!wrapper) {
      return;
    }
    var button = wrapper.querySelector("button");
    if (!button) {
      return;
    }
    dispatchEvalButtonWhenReady(button, {
      click: function () {
        button.dispatchEvent(new MouseEvent("click", {
          bubbles: true,
          cancelable: true,
          shiftKey: !!(clickOptions && clickOptions.shiftKey)
        }));
      },
      dispatchDelayMs: clickOptions && clickOptions.dispatchDelayMs || 250
    });
  }

  function currentSessionSourceJson() {
    var session = connectManager().session;
    return session && session.sourceAnchor
      ? JSON.stringify(session.sourceAnchor)
      : "";
  }

  function currentSessionRequestId() {
    var session = connectManager().session;
    return session && session.id || "";
  }

  function writeCapabilityInspectionState(state) {
    if (!state) {
      return;
    }
    if (state.inspectInput) {
      dispatchValue(state.inspectInput, JSON.stringify(debugSnapshot()));
    }
    if (state.sourceInput) {
      dispatchValue(state.sourceInput, currentSessionSourceJson());
    }
    if (state.requestIdInput) {
      dispatchValue(state.requestIdInput, currentSessionRequestId());
    }
  }

  function inspectConnectCapability(state, event) {
    if (!state || !state.available) {
      return;
    }
    writeCapabilityInspectionState(state);
    dispatchHiddenDockButton(
      event.altKey ? state.connectEvidenceSubmit : state.connectRuntimeSubmit,
      {
        shiftKey: !!event.shiftKey,
        dispatchDelayMs: 250
      }
    );
  }

  function inspectAnnotationCapability(state, event) {
    if (!state || !state.available) {
      return;
    }
    writeCapabilityInspectionState(state);
    dispatchHiddenDockButton(
      event.altKey ? state.annotationEvidenceSubmit : state.annotationSemanticSubmit,
      {
        shiftKey: !!event.shiftKey,
        dispatchDelayMs: 250
      }
    );
  }

  function inspectGuideCapability(state, event) {
    if (!state || !state.available) {
      return;
    }
    writeCapabilityInspectionState(state);
    dispatchHiddenDockButton(
      event.altKey ? state.guideEvidenceSubmit : state.guideModelSubmit,
      {
        shiftKey: !!event.shiftKey,
        dispatchDelayMs: 250
      }
    );
  }

  function openSnippetPlayground(state, event) {
    if (!snippetDockAvailable(state)) {
      return;
    }
    markDockCapabilityUsed(
      state,
      DOCK_CAPABILITY_SNIPPET,
      "snippet-playground-opened"
    );
    refreshPaneStateFromSession(state);
    dispatchHiddenDockButton(state.snippetPlaygroundSubmit, {
      shiftKey: !!(event && event.shiftKey),
      dispatchDelayMs: 250
    });
  }

  function openCurrentAnnotation(state) {
    if (!state.available || !state.dockAnnotationSubmit) {
      return;
    }
    markDockCapabilityUsed(
      state,
      state.introducedCapability || DOCK_CAPABILITY_CONNECT,
      "annotation-opened"
    );
    refreshPaneStateFromSession(state);
    dispatchHiddenDockButton(state.dockAnnotationSubmit, {
      shiftKey: true,
      dispatchDelayMs: 250
    });
  }

  function completeAnnotationTarget(state) {
    var manager = state && state.manager || connectManager();
    var session = manager.session;
    if (!state || !state.available || !sessionActive(manager) ||
        session.phase !== "choose-target" || !session.sourceAnchor) {
      openCurrentAnnotation(state);
      return;
    }
    markDockCapabilityUsed(
      state,
      DOCK_CAPABILITY_CONNECT,
      "annotation-target-selected"
    );
    completeConnection(state, buildAnnotationTargetAnchor(state));
  }

  function clearMobileRouteSuccess(state) {
    if (!state) {
      return;
    }
    state.mobileRouteSuccessUntil = null;
    if (state.mobileRouteSuccessTimer) {
      window.clearTimeout(state.mobileRouteSuccessTimer);
      state.mobileRouteSuccessTimer = null;
    }
  }

  function showMobileRouteSuccess(state) {
    if (!state) {
      return;
    }
    clearMobileRouteSuccess(state);
    state.mobileRouteSuccessUntil =
      Date.now() + MOBILE_ROUTE_SUCCESS_FEEDBACK_MS;
    state.mobileRouteSuccessTimer = window.setTimeout(function () {
      state.mobileRouteSuccessTimer = null;
      state.mobileRouteSuccessUntil = null;
      refreshPaneStateFromSession(state);
    }, MOBILE_ROUTE_SUCCESS_FEEDBACK_MS);
  }

  function clearFeedback(state) {
    clearMobileRouteSuccess(state);
    state.feedback.hidden = true;
    state.feedback.textContent = "";
    state.feedback.innerHTML = "";
    delete state.feedback.dataset.kind;
  }

  function setFeedback(state, kind, text) {
    if (kind === "success" && mobileRouteViewport()) {
      state.feedback.hidden = true;
      state.feedback.textContent = "";
      state.feedback.innerHTML = "";
      delete state.feedback.dataset.kind;
      showMobileRouteSuccess(state);
      return;
    }
    clearMobileRouteSuccess(state);
    state.feedback.dataset.kind = kind;
    state.feedback.textContent = text;
    state.feedback.hidden = false;
  }

  function evidenceButtonAttributes(button) {
    [
      "data-dom-association-request-id",
      "data-dom-association-transport",
      "data-dom-association-context-object-id",
      "data-dom-association-context-view-title",
      "data-dom-connect-snapshot-field-id",
      "data-dom-connect-request-evidence-request-id",
      "data-dom-connect-browser-failure-kind",
      "data-dom-connect-browser-message",
      "data-dom-connect-browser-detail",
      "data-dom-connect-snapshot-json"
    ].forEach(function (attribute) {
      button.removeAttribute(attribute);
    });
  }

  function prepareEvidenceButton(state, requestId, failureKind, message, detail) {
    if (!state.evidenceSubmit) {
      return null;
    }
    var button = state.evidenceSubmit.querySelector("button");
    if (!button) {
      return null;
    }
    evidenceButtonAttributes(button);
    button.setAttribute(
      "data-dom-association-request-id",
      requestId || ("connect-evidence-" + Date.now().toString(36) + "-" +
        Math.random().toString(36).slice(2, 8))
    );
    button.setAttribute("data-dom-association-transport", "connect-request-evidence-v1");
    button.setAttribute(
      "data-dom-association-context-object-id",
      state.surface && state.surface.dataset.contextObjectId || ""
    );
    button.setAttribute(
      "data-dom-association-context-view-title",
      state.surface && state.surface.dataset.contextViewTitle || ""
    );
    if (state.inspectInput) {
      button.setAttribute(
        "data-dom-connect-snapshot-field-id",
        state.inspectInput.id || ""
      );
    }
    button.setAttribute(
      "data-dom-connect-request-evidence-request-id",
      requestId || ""
    );
    button.setAttribute(
      "data-dom-connect-browser-failure-kind",
      failureKind || ""
    );
    button.setAttribute(
      "data-dom-connect-browser-message",
      message || ""
    );
    button.setAttribute(
      "data-dom-connect-browser-detail",
      detail || ""
    );
    button.setAttribute(
      "data-dom-connect-snapshot-json",
      JSON.stringify(debugSnapshot())
    );
    if (state.inspectInput) {
      dispatchValue(state.inspectInput, JSON.stringify(debugSnapshot()));
    }
    if (state.requestIdInput) {
      dispatchValue(state.requestIdInput, requestId || "");
    }
    if (state.browserFailureKindInput) {
      dispatchValue(state.browserFailureKindInput, failureKind || "");
    }
    if (state.browserMessageInput) {
      dispatchValue(state.browserMessageInput, message || "");
    }
    if (state.browserDetailInput) {
      dispatchValue(state.browserDetailInput, detail || "");
    }
    return button;
  }

  function setFailureFeedback(state, message, requestId, failureKind, detail) {
    var button = prepareEvidenceButton(state, requestId, failureKind, message, detail);
    var html =
      '<span class="hyperdoc-dom-connect-feedback-message">' +
      escapeHtml(message) +
      "</span>";
    if (button && requestId) {
      html +=
        ' <button type="button" class="hyperdoc-dom-connect-feedback-open-evidence"' +
        ' data-request-id="' + escapeHtml(requestId) + '"' +
        ' data-failure-kind="' + escapeHtml(failureKind || "") + '"' +
        ' data-message="' + escapeHtml(message || "") + '"' +
        ' data-detail="' + escapeHtml(detail || "") + '">' +
        "Inspect request evidence" +
        "</button>";
    }
    if (requestId) {
      html +=
        ' <span class="hyperdoc-dom-connect-feedback-request-id">' +
        "Request id " + escapeHtml(requestId) + "." +
        "</span>";
    }
    state.feedback.dataset.kind = "error";
    state.feedback.innerHTML = html;
    state.feedback.hidden = false;
  }

  function openRequestEvidence(state, requestId, failureKind, message, detail) {
    var button = prepareEvidenceButton(state, requestId, failureKind, message, detail);
    if (!button) {
      return;
    }
    dispatchEvalButtonWhenReady(button, {
      click: function () {
        button.dispatchEvent(new MouseEvent("click", {
          bubbles: true,
          cancelable: true,
          shiftKey: true
        }));
      },
      dispatchDelayMs: 250
    });
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
    clearSuppressedServerResult(state.pendingRequest.id);
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

  function failPendingRequest(state, failureKind, message, detail) {
    if (!state.pendingRequest) {
      return;
    }
    var requestId = state.pendingRequest.id;
    var manager = state.manager || connectManager();
    logStage(requestId, "request-failed", {
      failureKind: failureKind || null,
      message: message,
      detail: detail || null
    });
    clearPendingRequest(state);
    resetConnectSession(manager);
    setFailureFeedback(state, message, requestId, failureKind, detail);
  }

  function registerPendingRequest(state, requestId) {
    clearPendingRequest(state);
    var forcedFailureMode = consumeNextFailureMode();
    if (forcedFailureMode) {
      suppressServerResult(requestId, forcedFailureMode);
    }
    state.pendingRequest = {
      id: requestId,
      forcedFailureMode: forcedFailureMode,
      timeoutId: window.setTimeout(function () {
        if (!state.pendingRequest || state.pendingRequest.id !== requestId) {
          return;
        }
        if (state.pendingRequest.forcedFailureMode ===
            "websocket-disconnect-before-acknowledgement") {
          failPendingRequest(
            state,
            "websocket-disconnect-before-acknowledgement",
            "Connection closed before the association pane opened.",
            "WebSocket closed before any server acknowledgement for this request."
          );
        } else if (connectionClosed()) {
          failPendingRequest(
            state,
            "websocket-disconnect-before-acknowledgement",
            "Connection closed before the association pane opened.",
            "WebSocket closed before any server acknowledgement for this request."
          );
        } else {
          failPendingRequest(
            state,
            "pane-open-timeout",
            "Association could not be opened.",
            "No server acknowledgement arrived before the request timed out."
          );
        }
      }, forcedFailureMode ? 250 : 5000),
      connectionWatchId: window.setInterval(function () {
        if (!state.pendingRequest || state.pendingRequest.id !== requestId) {
          return;
        }
        if (state.pendingRequest.forcedFailureMode ===
            "websocket-disconnect-before-acknowledgement" ||
            connectionClosed()) {
          failPendingRequest(
            state,
            "websocket-disconnect-before-acknowledgement",
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
    if (suppressedServerResultReason(detail.requestId)) {
      return;
    }
    var manager = state.manager || connectManager();
    var session = manager.session;
    var feedbackText = connectionSuccessText(session);
    var completedRoute = sessionDiagnostic(session);
    var feedbackStates = uniqueStates([
      session && session.sourceState,
      session && session.targetState,
      state
    ]);
    if (detail.status === "pane-open-succeeded") {
      logStage(detail.requestId, "pane-open-succeeded", detail);
      clearPendingRequest(state);
      resetConnectSession(manager);
      feedbackStates.forEach(function (feedbackState) {
        recordCompletedRoute(feedbackState, completedRoute);
        setFeedback(feedbackState, "success", feedbackText);
        refreshPaneStateFromSession(feedbackState);
      });
      return;
    }
    failPendingRequest(
      state,
      "server-failed",
      detail.message || "Association could not be opened.",
      detail.detail || null
    );
  }

  function closeHelpPanel(state) {
    if (!state) {
      return;
    }
    state.rediscoveryRequested = false;
    state.presentationEvent = {
      type: "guide-close",
      capability: state.introducedCapability || null,
      reason: "guide-closed"
    };
    state.presentationReason = capabilityScopedPresentationReason(
      state.introducedCapability,
      "guide-closed"
    );
    refreshPaneStateFromSession(state);
  }

  function dismissCoachmark(state, reason) {
    if (!state) {
      return;
    }
    state.rediscoveryRequested = false;
    state.presentationEvent = {
      type: "dismiss",
      capability: state.introducedCapability || null,
      reason: reason || "dismissed"
    };
    state.presentationReason = capabilityScopedPresentationReason(
      state.introducedCapability,
      reason || "dismissed"
    );
    refreshPaneStateFromSession(state);
  }

  function toggleHelpPanel(state) {
    if (!state || !state.available) {
      return;
    }
    if (state.presentationState === "rediscovery") {
      closeHelpPanel(state);
      return;
    }
    state.rediscoveryRequested = true;
    state.presentationReason = capabilityScopedPresentationReason(
      state.introducedCapability,
      "guide-opened"
    );
    refreshPaneStateFromSession(state);
  }

  function updateProviderCopy(state) {
    var helpSummary = providerHelpSummary(state.surface);
    state.providerHelpSummary = helpSummary;
    state.providerHelpDetail = providerHelpDetail(state.surface);
    state.helpToggle.title = "Rediscover Dock guidance";
    state.helpToggle.setAttribute("aria-label", "Rediscover Dock guidance");
    state.toggle.title = helpSummary;
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
      var surface = view.querySelector(
        ".hyperdoc-connect-provider-surface, .hyperdoc-dom-connect-surface"
      );
      if (surface) {
        return surface;
      }
    }
    return null;
  }

  function tabButtonByExactText(pane, label) {
    if (!pane) {
      return null;
    }
    var tabs = pane.querySelectorAll(".inspector-tabs button");
    for (var i = 0; i < tabs.length; i += 1) {
      var text = tabs[i].textContent && tabs[i].textContent.replace(/\s+/g, " ").trim();
      if (text === label) {
        return tabs[i];
      }
    }
    return null;
  }

  function externalTabButton(pane) {
    return tabButtonByExactText(pane, "External");
  }

  function paneTitleText(pane) {
    if (!pane) {
      return "";
    }
    var node = pane.querySelector(".inspector-title-bar-object") ||
      pane.querySelector(".inspector-title-bar-class");
    return collapseWhitespace(node && node.textContent || "");
  }

  function dmxDockAvailable(state) {
    return !!(
      state &&
      /^DMX topic\b/i.test(paneTitleText(state.pane)) &&
      externalTabButton(state.pane)
    );
  }

  function snippetDockAvailable(state) {
    return !!(
      state &&
      state.available &&
      (state.providerKind === "source-v1" ||
       state.providerKind === "fedwiki-v1") &&
      state.snippetPlaygroundSubmit
    );
  }

  function dockCapabilityActionable(state, capability) {
    if (capability === DOCK_CAPABILITY_CONNECT) {
      return !!(state && state.available);
    }
    if (capability === DOCK_CAPABILITY_SNIPPET) {
      return snippetDockAvailable(state);
    }
    return false;
  }

  function dockCapabilityTeachable(state, capability) {
    if (capability === DOCK_CAPABILITY_CONNECT) {
      return dockCapabilityActionable(state, capability) &&
        !!collapseWhitespace(state && state.providerHelpSummary || "");
    }
    if (capability === DOCK_CAPABILITY_SNIPPET) {
      return snippetDockAvailable(state);
    }
    return false;
  }

  function relevantDockCapabilities(state) {
    var capabilities = [];
    if (dockCapabilityActionable(state, DOCK_CAPABILITY_CONNECT)) {
      capabilities.push(DOCK_CAPABILITY_CONNECT);
    }
    if (dockCapabilityActionable(state, DOCK_CAPABILITY_SNIPPET)) {
      capabilities.push(DOCK_CAPABILITY_SNIPPET);
    }
    return capabilities;
  }

  function newlyRelevantDockCapabilities(state, capabilities) {
    var previous = state && state.relevantDockCapabilities || [];
    var next = capabilities ? capabilities.slice() : [];
    var newlyRelevant = [];
    next.forEach(function (capability) {
      if (previous.indexOf(capability) === -1) {
        newlyRelevant.push(capability);
      }
    });
    if (state) {
      state.relevantDockCapabilities = next;
    }
    return newlyRelevant;
  }

  function preferredDockCapability(state, memory, capabilities) {
    var options = capabilities || [];
    if (!options.length) {
      return null;
    }
    if (state && state.introducedCapability &&
        options.indexOf(state.introducedCapability) !== -1) {
      return state.introducedCapability;
    }
    for (var i = 0; i < DOCK_INTRODUCTION_PRIORITY.length; i += 1) {
      var candidate = DOCK_INTRODUCTION_PRIORITY[i];
      if (options.indexOf(candidate) !== -1 &&
          dockCapabilityIntroduced(memory, candidate)) {
        return candidate;
      }
    }
    return options[0];
  }

  function nextDockIntroductionCapability(state, memory, newlyRelevantCapabilities) {
    for (var i = 0; i < DOCK_INTRODUCTION_PRIORITY.length; i += 1) {
      var capability = DOCK_INTRODUCTION_PRIORITY[i];
      if (newlyRelevantCapabilities.indexOf(capability) === -1) {
        continue;
      }
      if (!dockCapabilityActionable(state, capability)) {
        continue;
      }
      if (!dockCapabilityTeachable(state, capability)) {
        continue;
      }
      if (dockCapabilityIntroduced(memory, capability)) {
        continue;
      }
      return capability;
    }
    return null;
  }

  function syncDockCapabilities(state) {
    if (!state || !state.dmx || !state.snippetPlayground) {
      return;
    }
    var showDmx = dmxDockAvailable(state);
    var showSnippetPlayground = snippetDockAvailable(state);
    state.dmx.hidden = !showDmx;
    state.snippetPlayground.hidden = !showSnippetPlayground;
    state.providerHandoff.hidden = !showDmx;
    state.providerHandoffs = [];
    if (showDmx) {
      state.providerHandoffs.push("DMX");
    }
  }

  function openDmxDockCapability(state) {
    var tab = externalTabButton(state && state.pane);
    if (!tab || !dmxDockAvailable(state)) {
      return;
    }
    markDockCapabilityUsed(
      state,
      state.introducedCapability || DOCK_CAPABILITY_CONNECT,
      "dmx-opened"
    );
    refreshPaneStateFromSession(state);
    tab.click();
  }

  function ensurePaneControlMarkup(slot) {
    if (!slot || slot.dataset.hyperdocDomConnectControl === "true") {
      return;
    }
    slot.dataset.hyperdocDomConnectControl = "true";
    slot.innerHTML =
      '<div class="hyperdoc-dom-connect-control hyperdoc-dock-control" data-hyperdoc-connect-ignore="true">' +
        '<div class="hyperdoc-dock-compact">' +
          '<div class="hyperdoc-mobile-route-copy" aria-live="polite">' +
            '<span class="hyperdoc-mobile-route-title">Tap a station</span>' +
            '<span class="hyperdoc-mobile-route-detail" hidden></span>' +
          '</div>' +
          '<span class="hyperdoc-dock-label">Capabilities</span>' +
          '<div class="hyperdoc-dock-actions">' +
            '<button type="button" class="hyperdoc-dom-connect-toggle hyperdoc-dock-action" ' +
                    'title="Click a source anchor, then a target anchor.">Connect</button>' +
            '<button type="button" class="hyperdoc-dock-annotation hyperdoc-dock-action" ' +
                    'title="Tap to complete Connect to the generic Annotation target, or reopen the current-object annotation when Connect is idle.">Annotation</button>' +
            '<button type="button" class="hyperdoc-dock-snippet-playground hyperdoc-dock-action" ' +
                    'title="Open a snippet playground crosswalk for the current source surface." ' +
                    'data-hyperdoc-snippet-playground-submit="true" hidden>Snippet</button>' +
            '<button type="button" class="hyperdoc-mobile-route-open hyperdoc-dock-action" ' +
                    'title="Open the saved route again." hidden>Open route</button>' +
            '<button type="button" class="hyperdoc-mobile-route-evidence hyperdoc-dock-action" ' +
                    'title="Open evidence for the current route request when available." hidden>Evidence</button>' +
          '</div>' +
          '<button type="button" class="hyperdoc-dom-connect-help-toggle hyperdoc-dock-guide" ' +
                  'title="Rediscover Dock guidance" aria-label="Rediscover Dock guidance" aria-expanded="false">Guide</button>' +
        '</div>' +
        '<div class="hyperdoc-dom-connect-help-panel hyperdoc-dock-coachmark" aria-hidden="true">' +
          '<div class="hyperdoc-dock-coachmark-header">' +
            '<span class="hyperdoc-dock-state-badge">Introduction</span>' +
            '<span class="hyperdoc-dock-coachmark-title">Connect</span>' +
          '</div>' +
          '<p class="hyperdoc-dock-coachmark-summary"></p>' +
          '<p class="hyperdoc-dock-coachmark-detail"></p>' +
          '<div class="hyperdoc-dock-provider-handoff" hidden>' +
            '<span class="hyperdoc-dock-provider-handoff-label">Open richer workflow</span>' +
            '<div class="hyperdoc-dock-provider-actions">' +
              '<button type="button" class="hyperdoc-dock-dmx" ' +
                      'title="Open the External DMX handoff view for this pane." hidden>DMX</button>' +
            '</div>' +
          '</div>' +
          '<div class="hyperdoc-dock-session-state">' +
            '<span class="hyperdoc-dom-connect-status" hidden>Pick source</span>' +
            '<span class="hyperdoc-dom-connect-source-summary" hidden>' +
              '<span class="hyperdoc-dom-connect-source-summary-label">Source:</span>' +
              '<span class="hyperdoc-dom-connect-source-chip"></span>' +
            '</span>' +
            '<span class="hyperdoc-dom-connect-cue" hidden></span>' +
          '</div>' +
          '<div class="hyperdoc-dock-coachmark-actions">' +
            '<button type="button" class="hyperdoc-dom-connect-clear" hidden>Clear</button>' +
            '<button type="button" class="hyperdoc-dom-connect-cancel" hidden>Cancel</button>' +
            '<button type="button" class="hyperdoc-dock-dismiss">Dismiss</button>' +
          '</div>' +
        '</div>' +
      '</div>' +
      '<div class="hyperdoc-dom-connect-feedback" hidden></div>';
  }

  function writeSubmitPayload(submitButton, payload, state, sourceJson, targetJson) {
    submitButton.setAttribute("data-dom-association-request-id", payload.requestId);
    submitButton.setAttribute("data-dom-association-transport", "button-payload-v2");
    submitButton.setAttribute(
      "data-dom-association-context-object-id",
      payload.contextObjectId || ""
    );
    submitButton.setAttribute(
      "data-dom-association-context-view-title",
      payload.contextViewTitle || ""
    );
    submitButton.setAttribute("data-dom-association-source-json", sourceJson);
    submitButton.setAttribute("data-dom-association-target-json", targetJson);
    submitButton.setAttribute(
      "data-dom-association-source-field-id",
      state.sourceInput && state.sourceInput.id || ""
    );
    submitButton.setAttribute(
      "data-dom-association-target-field-id",
      state.targetInput && state.targetInput.id || ""
    );
    submitButton.setAttribute(
      "data-dom-association-source-pane-id",
      payload.sourcePaneId || ""
    );
    submitButton.setAttribute(
      "data-dom-association-target-pane-id",
      payload.targetPaneId || ""
    );
    submitButton.setAttribute(
      "data-dom-association-source-provider-kind",
      payload.sourceProviderKind || ""
    );
    submitButton.setAttribute(
      "data-dom-association-target-provider-kind",
      payload.targetProviderKind || ""
    );
  }

  function evalButtonBound(button) {
    return !!(button &&
      button.getAttribute("data-hyperdoc-eval-bound") === "true");
  }

  function dispatchEvalButtonWhenReady(button, options) {
    var click = options && options.click;
    var onTimeout = options && options.onTimeout;
    var dispatchDelayMs = options && options.dispatchDelayMs || 0;
    var attemptsRemaining = options && options.maxAttempts || 60;

    function tryDispatch() {
      if (!button || !button.isConnected) {
        if (onTimeout) {
          onTimeout("Submit bridge disappeared before the request could be dispatched.");
        }
        return;
      }
      if (evalButtonBound(button)) {
        window.setTimeout(click, dispatchDelayMs);
        return;
      }
      attemptsRemaining -= 1;
      if (attemptsRemaining <= 0) {
        if (onTimeout) {
          onTimeout("Submit bridge did not become ready before dispatch.");
        }
        return;
      }
      window.setTimeout(tryDispatch, 50);
    }

    window.setTimeout(tryDispatch, 0);
  }

  function bindSurface(state, surface) {
    var provider = providerApiForKind(surfaceProviderKind(surface));
    state.surface = surface || null;
    state.root = null;
    state.overlay = null;
    state.line = null;
    state.sourceInput = null;
    state.targetInput = null;
    state.inspectInput = null;
    state.requestIdInput = null;
    state.browserFailureKindInput = null;
    state.browserMessageInput = null;
    state.browserDetailInput = null;
    state.submit = null;
    state.evidenceSubmit = null;
    state.dockAnnotationSubmit = null;
    state.connectRuntimeSubmit = null;
    state.connectEvidenceSubmit = null;
    state.annotationSemanticSubmit = null;
    state.annotationEvidenceSubmit = null;
    state.guideModelSubmit = null;
    state.guideEvidenceSubmit = null;
    state.snippetPlaygroundSubmit = null;
    state.provider = provider;
    state.providerKind = surfaceProviderKind(surface);
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
    var inspectInput = document.getElementById(controls.dataset.snapshotInputId);
    var requestIdInput = document.getElementById(controls.dataset.requestIdInputId);
    var browserFailureKindInput = document.getElementById(
      controls.dataset.browserFailureKindInputId
    );
    var browserMessageInput = document.getElementById(
      controls.dataset.browserMessageInputId
    );
    var browserDetailInput = document.getElementById(
      controls.dataset.browserDetailInputId
    );
    var submit = controls.querySelector(".hyperdoc-dom-connect-submit");
    var evidenceSubmit = controls.querySelector(".hyperdoc-dom-connect-evidence-submit");
    var dockAnnotationSubmit = controls.querySelector(".hyperdoc-dock-annotation-submit");
    var connectRuntimeSubmit = controls.querySelector(".hyperdoc-dock-connect-runtime-submit");
    var connectEvidenceSubmit = controls.querySelector(".hyperdoc-dock-connect-evidence-submit");
    var annotationSemanticSubmit = controls.querySelector(".hyperdoc-dock-annotation-semantic-submit");
    var annotationEvidenceSubmit = controls.querySelector(".hyperdoc-dock-annotation-evidence-submit");
    var guideModelSubmit = controls.querySelector(".hyperdoc-dock-guide-model-submit");
    var guideEvidenceSubmit = controls.querySelector(".hyperdoc-dock-guide-evidence-submit");
    var snippetPlaygroundSubmit = controls.querySelector(".hyperdoc-dock-snippet-playground-submit");
    if (!sourceInput || !targetInput || !inspectInput ||
        !requestIdInput || !browserFailureKindInput ||
        !browserMessageInput || !browserDetailInput ||
        !submit || !evidenceSubmit || !dockAnnotationSubmit ||
        !connectRuntimeSubmit || !connectEvidenceSubmit ||
        !annotationSemanticSubmit || !annotationEvidenceSubmit ||
        !guideModelSubmit || !guideEvidenceSubmit ||
        !snippetPlaygroundSubmit) {
      return false;
    }
    state.root = root;
    state.overlay = overlay;
    state.line = line;
    state.sourceInput = sourceInput;
    state.targetInput = targetInput;
    state.inspectInput = inspectInput;
    state.requestIdInput = requestIdInput;
    state.browserFailureKindInput = browserFailureKindInput;
    state.browserMessageInput = browserMessageInput;
    state.browserDetailInput = browserDetailInput;
    state.submit = submit;
    state.evidenceSubmit = evidenceSubmit;
    state.dockAnnotationSubmit = dockAnnotationSubmit;
    state.connectRuntimeSubmit = connectRuntimeSubmit;
    state.connectEvidenceSubmit = connectEvidenceSubmit;
    state.annotationSemanticSubmit = annotationSemanticSubmit;
    state.annotationEvidenceSubmit = annotationEvidenceSubmit;
    state.guideModelSubmit = guideModelSubmit;
    state.guideEvidenceSubmit = guideEvidenceSubmit;
    state.snippetPlaygroundSubmit = snippetPlaygroundSubmit;
    updateProviderCopy(state);
    syncDockCapabilities(state);
    return true;
  }

  function dockPresentationLabel(presentationState) {
    if (presentationState === "introduction") {
      return "Introduction";
    }
    if (presentationState === "active") {
      return "Active";
    }
    if (presentationState === "degraded") {
      return "Degraded";
    }
    if (presentationState === "rediscovery") {
      return "Rediscovery";
    }
    return "Latent";
  }

  function markDockCapabilityUsed(state, capability, reason) {
    var memory = dockPresentationMemory();
    markDockCapabilityIntroduced(memory, capability);
    state.rediscoveryRequested = false;
    state.presentationEvent = {
      type: "capability-used",
      capability: capability || null,
      reason: reason || "capability-used"
    };
    state.presentationReason = capabilityScopedPresentationReason(
      capability,
      reason || "capability-used"
    );
  }

  function dockPresentationForState(state, session, sessionVisible) {
    var memory = dockPresentationMemory();
    var relevantCapabilities = relevantDockCapabilities(state);
    var newlyRelevantCapabilities = newlyRelevantDockCapabilities(
      state,
      relevantCapabilities
    );
    var preferredCapability = preferredDockCapability(
      state,
      memory,
      relevantCapabilities
    );
    var event = state.presentationEvent;
    if (!state.available) {
      return {
        state: "hidden",
        introducedCapability: null,
        presentationScope: memory.scope,
        reason: "provider-unavailable",
        consumeEvent: true
      };
    }
    if (sessionVisible) {
      return {
        state: "active",
        introducedCapability: DOCK_CAPABILITY_CONNECT,
        presentationScope: memory.scope,
        reason: capabilityScopedPresentationReason(
          DOCK_CAPABILITY_CONNECT,
          session && session.phase || "session-active"
        ),
        consumeEvent: true
      };
    }
    if (state.rediscoveryRequested) {
      return {
        state: "rediscovery",
        introducedCapability: preferredCapability,
        presentationScope: memory.scope,
        reason: capabilityScopedPresentationReason(
          preferredCapability,
          "guide-opened"
        ),
        consumeEvent: true
      };
    }
    if (state.presentationState === "introduction" &&
        state.introducedCapability &&
        !event &&
        dockCapabilityActionable(state, state.introducedCapability) &&
        dockCapabilityTeachable(state, state.introducedCapability)) {
      return {
        state: "introduction",
        introducedCapability: state.introducedCapability,
        presentationScope: memory.scope,
        reason: state.presentationReason ||
          capabilityScopedPresentationReason(
            state.introducedCapability,
            "newly-relevant"
          ),
        consumeEvent: false
      };
    }
    var introductionCapability = nextDockIntroductionCapability(
      state,
      memory,
      newlyRelevantCapabilities
    );
    if (introductionCapability) {
      markDockCapabilityIntroduced(memory, introductionCapability);
      return {
        state: "introduction",
        introducedCapability: introductionCapability,
        presentationScope: memory.scope,
        reason: capabilityScopedPresentationReason(
          introductionCapability,
          "newly-relevant"
        ),
        consumeEvent: true
      };
    }
    if (event && (event.type === "dismiss" ||
        event.type === "guide-close" ||
        event.type === "capability-used")) {
      return {
        state: "degraded",
        introducedCapability: event.capability || preferredCapability,
        presentationScope: memory.scope,
        reason: capabilityScopedPresentationReason(
          event.capability || preferredCapability,
          event.reason || "compact-available"
        ),
        consumeEvent: true
      };
    }
    if ((state.presentationState === "active" ||
         state.presentationState === "degraded" ||
         state.presentationState === "rediscovery") &&
        preferredCapability) {
      return {
        state: "degraded",
        introducedCapability: preferredCapability,
        presentationScope: memory.scope,
        reason: state.presentationReason ||
          capabilityScopedPresentationReason(
            preferredCapability,
            "compact-available"
          ),
        consumeEvent: true
      };
    }
    return {
      state: "latent",
      introducedCapability: null,
      presentationScope: memory.scope,
      reason: "compact-capabilities-remain-available",
      consumeEvent: true
    };
  }

  function dockCoachmarkCopy(state, presentationState, introducedCapability) {
    if (introducedCapability === DOCK_CAPABILITY_SNIPPET) {
      return {
        title: "Snippet",
        summary: "Open a snippet workflow for the current source surface.",
        detail:
          presentationState === "rediscovery"
            ? "Guide reopened Snippet guidance for this pane. The richer snippet workflow lives in the pane body, and the compact Snippet action remains available after this guidance recedes."
            : "The Dock is temporarily expanded because Snippet became newly relevant here. The richer snippet workflow lives in the pane body, and the compact Snippet action remains available after this introduction recedes."
      };
    }
    if (presentationState === "active") {
      return {
        title: "Connect",
        summary: "Connect is active in this pane.",
        detail:
          "Task state stays in the coachmark while the richer route or traversal workflow remains in the pane body. Annotation is also a valid target while Connect is waiting for one."
      };
    }
    if (presentationState === "rediscovery") {
      return {
        title: "Connect",
        summary: state.providerHelpSummary,
        detail:
          "The Dock can expand again for rediscovery, but the same capability stays available from the compact row."
      };
    }
    if (presentationState === "introduction") {
      return {
        title: "Connect",
        summary: state.providerHelpSummary,
        detail:
          "The Dock is temporarily expanded because Connect became newly relevant here. Annotation remains available after this introduction recedes and can complete an active Connect gesture as a generic target, while inspection stays in the inspector tabs."
      };
    }
    return {
      title: "Connect",
      summary: "",
      detail: ""
    };
  }

  function applyDockPresentation(state, presentation) {
    var coachmark = presentation.state === "introduction" ||
      presentation.state === "active" ||
      presentation.state === "rediscovery";
    if (mobileRouteViewport()) {
      coachmark = false;
    }
    var introducedCapability = presentation.introducedCapability || null;
    var copy = dockCoachmarkCopy(
      state,
      presentation.state,
      introducedCapability
    );
    state.presentationState = presentation.state;
    state.introducedCapability = introducedCapability;
    state.presentationScope = presentation.presentationScope || DOCK_PRESENTATION_SCOPE;
    state.presentationReason = presentation.reason || null;
    if (presentation.consumeEvent) {
      state.presentationEvent = null;
    }
    state.helpOpen = coachmark;
    state.slot.dataset.helpOpen = coachmark ? "true" : "false";
    state.slot.dataset.dockPresentation = presentation.state;
    state.slot.dataset.dockIntroducedCapability = introducedCapability || "";
    state.slot.dataset.dockPresentationReason = state.presentationReason || "";
    state.control.dataset.dockPresentation = presentation.state;
    state.control.dataset.dockIntroducedCapability = introducedCapability || "";
    state.control.dataset.dockPresentationReason = state.presentationReason || "";
    state.helpToggle.textContent = coachmark && presentation.state === "rediscovery"
      ? "Hide guide"
      : "Guide";
    state.helpToggle.setAttribute("aria-expanded", coachmark ? "true" : "false");
    state.helpPanel.setAttribute("aria-hidden", coachmark ? "false" : "true");
    state.stateBadge.textContent = dockPresentationLabel(presentation.state);
    state.coachmarkTitle.textContent = copy.title;
    state.coachmarkSummary.textContent = copy.summary;
    state.coachmarkDetail.textContent = copy.detail;
    state.providerHandoffLabel.textContent =
      "Richer workflow lives in the pane body";
    state.dismiss.hidden = presentation.state === "active" || !coachmark;
    state.compactCapabilities = ["Connect", "Annotation"];
    if (!state.snippetPlayground.hidden) {
      state.compactCapabilities.push("Snippet");
    }
    state.compactCapabilities.push("Guide");
    state.coachmarkCapabilities = coachmark
      ? (state.providerHandoffs || []).slice()
      : [];
    if (state.surface) {
      state.surface.dataset.hyperdocDockPresentation = presentation.state;
    }
  }

  function recordCompletedRoute(state, route) {
    if (!state || !route) {
      return;
    }
    state.completedRoute = cloneData(route);
  }

  function openCompletedRoute(state) {
    var route = state && state.completedRoute;
    if (!route || !route.source || !route.target) {
      return;
    }
    var manager = state.manager || connectManager();
    clearFeedback(state);
    manager.session = {
      id: makeRequestId(),
      phase: "choose-target",
      originPaneId: route.originPaneId || state.paneId,
      sourcePaneId: route.sourcePaneId || state.paneId,
      sourceProviderKind: route.sourceProviderKind || route.source.providerKind || null,
      sourceAnchor: route.source,
      sourceState: state,
      targetPaneId: null,
      targetProviderKind: null,
      targetAnchor: null,
      targetState: null
    };
    completeConnection(state, route.target);
  }

  function applyMobileRouteStrip(state) {
    if (!state || !state.slot || !state.mobileRouteTitleNode) {
      return;
    }
    var manager = state.manager || connectManager();
    var session = manager.session;
    var mobile = mobileRouteViewport();
    var routeState = mobile
      ? mobileRouteStateForSession(state, session)
      : "";
    var routeTitle = mobile ? mobileRouteTitle(state, routeState, session) : "";
    var routeDetail = mobile ? mobileRouteDetail(routeState) : "";
    state.mobileRouteState = routeState || null;
    state.slot.dataset.mobileRoute = mobile ? "true" : "false";
    state.slot.dataset.mobileRouteState = routeState;
    state.control.dataset.mobileRoute = mobile ? "true" : "false";
    state.control.dataset.mobileRouteState = routeState;
    state.mobileRouteTitleNode.textContent = routeTitle || "Tap a station";
    state.mobileRouteDetailNode.textContent = routeDetail;
    state.mobileRouteDetailNode.hidden = !routeDetail;

    state.toggle.hidden = mobile;
    state.annotation.hidden = mobile && routeState !== "source-latched";
    state.helpToggle.hidden = mobile;
    state.snippetPlayground.hidden = mobile || state.snippetPlayground.hidden;
    state.dmx.hidden = mobile || state.dmx.hidden;

    if (mobile) {
      state.clear.hidden = true;
      state.cancel.hidden = !(routeState === "source-latched" ||
        routeState === "confirming");
    }
    state.mobileRouteOpen.hidden = !(mobile &&
      routeState === "completed" &&
      state.completedRoute);
    state.mobileRouteEvidence.hidden = !(mobile &&
      routeState === "completed" &&
      state.completedRoute &&
      state.completedRoute.requestId);

    if (mobile) {
      state.compactCapabilities = ["Lay route"];
      if (!state.annotation.hidden) {
        state.compactCapabilities.push("Annotation");
      }
      if (!state.mobileRouteOpen.hidden) {
        state.compactCapabilities.push("Open route");
      }
      if (!state.mobileRouteEvidence.hidden) {
        state.compactCapabilities.push("Evidence");
      }
    }
  }

  function refreshPaneStateFromSession(state) {
    var manager = state.manager || connectManager();
    var session = manager.session;
    var available = !!state.available;
    state.slot.hidden = !available;
    if (!available) {
      state.enabled = false;
      state.toggle.dataset.mode = "inactive";
      state.presentationState = "hidden";
      state.introducedCapability = null;
      state.presentationReason = "provider-unavailable";
      state.helpOpen = false;
      state.slot.dataset.helpOpen = "false";
      state.slot.dataset.dockPresentation = "hidden";
      state.slot.dataset.dockIntroducedCapability = "";
      state.slot.dataset.dockPresentationReason = state.presentationReason;
      state.control.dataset.dockPresentation = "hidden";
      state.control.dataset.dockIntroducedCapability = "";
      state.control.dataset.dockPresentationReason = state.presentationReason;
      if (!state.pendingRequest) {
        setPhase(state, "dormant");
      }
      return;
    }
    syncDockCapabilities(state);

    var activeForSource = session.phase === "choose-source" &&
      session.originPaneId === state.paneId;
    var activeForTarget = session.phase === "choose-target";
    var activeForSubmitting = session.phase === "submitting" &&
      session.id !== null;
    var sessionVisible = activeForSource || activeForTarget || activeForSubmitting;
    var presentation;

    state.enabled = activeForSource || activeForTarget;
    state.toggle.dataset.mode = sessionVisible ? "active" : "inactive";
    if (state.surface) {
      state.surface.classList.toggle("hyperdoc-dom-connect-active", !!state.enabled);
    }
    if (!sessionVisible) {
      if (!state.pendingRequest) {
        setPhase(state, "dormant");
      }
    } else if (session.phase === "choose-source") {
      setPhase(state, activeForSource ? "select-source" : "dormant");
    } else if (session.phase === "choose-target") {
      setPhase(state, "select-target");
    } else if (session.phase === "submitting") {
      setPhase(state, "submitting");
    }
    presentation = dockPresentationForState(state, session, sessionVisible);
    applyDockPresentation(state, presentation);
    applyMobileRouteStrip(state);
  }

  function refreshAllPaneStates(manager) {
    liveStates(manager).forEach(function (state) {
      refreshPaneStateFromSession(state);
    });
  }

  function resetConnectSession(manager, options) {
    var preservePendingState = options && options.preservePendingState;
    liveStates(manager).forEach(function (state) {
      if (state !== preservePendingState) {
        clearPendingRequest(state);
      }
      enterDormant(state);
    });
    manager.session = makeIdleSession();
    refreshAllPaneStates(manager);
  }

  function startConnectSession(state) {
    var manager = state.manager;
    markDockCapabilityUsed(
      state,
      DOCK_CAPABILITY_CONNECT,
      "connect-started"
    );
    if (sessionActive(manager)) {
      resetConnectSession(manager);
    }
    liveStates(manager).forEach(function (otherState) {
      clearFeedback(otherState);
      otherState.completedRoute = null;
      otherState.rediscoveryRequested = false;
      setHoverElement(otherState, null);
    });
    manager.session = {
      id: makeRequestId(),
      phase: "choose-source",
      originPaneId: state.paneId,
      sourcePaneId: null,
      sourceProviderKind: null,
      sourceAnchor: null,
      sourceState: null,
      targetPaneId: null,
      targetProviderKind: null,
      targetAnchor: null,
      targetState: null
    };
    logStage(manager.session.id, "session-started", sessionDiagnostic(manager.session));
    refreshAllPaneStates(manager);
  }

  function cancelConnectSession(state) {
    var manager = state.manager;
    var requestId = manager.session && manager.session.id;
    resetConnectSession(manager);
    if (requestId) {
      logStage(requestId, "session-cancelled", {
        paneId: state.paneId
      });
    }
  }

  function syncPaneSurface(state) {
    if (state.syncingPaneSurface) {
      return;
    }
    state.syncingPaneSurface = true;
    try {
      var surface = activeSurfaceForPane(state.pane);
      var previousSurface = state.surface;
      var previousAvailable = state.available;
      var available = bindSurface(state, surface);
      state.available = available;
      if (!available) {
        clearFeedback(state);
        state.rediscoveryRequested = false;
        state.helpOpen = false;
        setHoverElement(state, null);
        clearSource(state);
        refreshPaneStateFromSession(state);
        return;
      }
      if (previousSurface && previousSurface !== surface) {
        previousSurface.classList.remove("hyperdoc-dom-connect-active");
        setHoverElement(state, null);
        clearSource(state);
      }
      if (!previousAvailable || previousSurface !== surface) {
        clearFeedback(state);
        updateProviderCopy(state);
      }
      refreshPaneStateFromSession(state);
    } finally {
      state.syncingPaneSurface = false;
    }
  }

  function schedulePaneSurfaceSync(state) {
    if (!state || state.syncPaneSurfaceScheduled) {
      return;
    }
    state.syncPaneSurfaceScheduled = true;
    var schedule = window.requestAnimationFrame || function (callback) {
      return window.setTimeout(callback, 0);
    };
    schedule(function () {
      state.syncPaneSurfaceScheduled = false;
      syncPaneSurface(state);
    });
  }

  function setPhase(state, phase) {
    var session = state.manager && state.manager.session;
    var showSourceSummary = !!(session && session.sourceAnchor &&
      (phase === "select-target" || phase === "submitting"));
    var cueText = sessionCueText(phase === "dormant" ? null : session);
    state.phase = phase;
    state.slot.dataset.connectState = phase;
    state.control.dataset.connectState = phase;
    if (state.surface) {
      state.surface.dataset.connectState = phase;
    }
    state.status.hidden = !(phase === "select-source" ||
      phase === "select-target" ||
      phase === "submitting");
    setSourceSummary(state, session && session.sourceAnchor, showSourceSummary);
    setCue(state, phase === "submitting" ? "" : cueText);
    state.clear.hidden = !(phase === "select-target" && showSourceSummary);
    state.cancel.hidden = !(phase === "select-source" || phase === "select-target");

    if (phase === "select-source") {
      setStatus(state, "Pick source");
    } else if (phase === "select-target") {
      setStatus(state, "Pick target");
    } else if (phase === "submitting") {
      setStatus(state, "Opening association...");
    } else {
      setStatus(state, "");
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
    state.rediscoveryRequested = false;
    state.helpOpen = false;
    if (!state.pendingRequest) {
      state.requestId = null;
    }
    setPhase(state, "dormant");
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
    cancelConnectSession(state);
  }

  function activate(state) {
    if (!state.available || !state.surface) {
      return;
    }
    clearResetTimer(state);
    startConnectSession(state);
  }

  function clearSelectedSource(state) {
    var manager = state.manager;
    var session = manager.session;
    if (!sessionActive(manager) || session.phase !== "choose-target") {
      return;
    }
    liveStates(manager).forEach(function (otherState) {
      clearFeedback(otherState);
      otherState.completedRoute = null;
      otherState.rediscoveryRequested = false;
      setHoverElement(otherState, null);
    });
    if (session.sourceState) {
      clearSource(session.sourceState);
    }
    session.phase = "choose-source";
    session.sourcePaneId = null;
    session.sourceProviderKind = null;
    session.sourceAnchor = null;
    session.sourceState = null;
    session.targetPaneId = null;
    session.targetProviderKind = null;
    session.targetAnchor = null;
    session.targetState = null;
    logStage(session.id, "source-cleared", {
      paneId: state.paneId
    });
    refreshAllPaneStates(manager);
  }

  function beginConnection(state, element, anchor) {
    var manager = state.manager;
    var session = manager.session;
    setHoverElement(state, null);
    clearSource(state);
    state.source = anchor;
    state.sourceElement = element;
    state.requestId = session.id;
    state.sourceElement.classList.add("hyperdoc-dom-connect-source");
    state.overlay.hidden = false;
    session.phase = "choose-target";
    session.sourcePaneId = state.paneId;
    session.sourceProviderKind = anchor.providerKind;
    session.sourceAnchor = anchor;
    session.sourceState = state;
    logStage(session.id, "source-selected", {
      paneId: state.paneId,
      providerKind: anchor.providerKind,
      anchor: anchorLogData(anchor),
      session: sessionDiagnostic(session)
    });
    refreshAllPaneStates(manager);
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
    var manager = state.manager;
    var session = manager.session;
    var sourceState = session.sourceState;
    var sourceAnchor = session.sourceAnchor;
    var requestId = session.id || makeRequestId();
    var pendingState = sourceState || state;
    if (!sourceAnchor) {
      setFeedback(
        state,
        "error",
        "Association could not be opened. No source anchor is active in the current Connect session."
      );
      resetConnectSession(manager);
      return;
    }
    var previousSurface = state.surface;
    var activeSurface = activeSurfaceForPane(state.pane);
    var submitSurface = activeSurface || previousSurface;
    var submitReady = bindSurface(state, submitSurface);
    var sourceJson = JSON.stringify(sourceAnchor);
    var targetJson = JSON.stringify(targetAnchor);
    var payload = {
      requestId: requestId,
      sourcePaneId: session.sourcePaneId,
      targetPaneId: state.paneId,
      sourceProviderKind: sourceAnchor.providerKind,
      targetProviderKind: targetAnchor.providerKind,
      contextObjectId: submitSurface && submitSurface.dataset.contextObjectId || null,
      contextViewTitle: submitSurface && submitSurface.dataset.contextViewTitle || null,
      source: sourceAnchor,
      target: targetAnchor
    };
    var submitButton = submitReady &&
      state.submit &&
      state.submit.querySelector("button");
    session.phase = "submitting";
    session.targetPaneId = state.paneId;
    session.targetProviderKind = targetAnchor.providerKind;
    session.targetAnchor = targetAnchor;
    session.targetState = state;
    clearResetTimer(state);
    logStage(requestId, "target-selected", {
      paneId: state.paneId,
      providerKind: targetAnchor.providerKind,
      anchor: anchorLogData(targetAnchor),
      session: sessionDiagnostic(session)
    });
    logStage(requestId, "association-payload-assembled", payload);
    logStage(requestId, "submit-boundary-resolved", {
      sourceSurface: surfaceDiagnostic(sourceState && sourceState.surface),
      activeSurface: surfaceDiagnostic(activeSurface),
      previousSurface: surfaceDiagnostic(previousSurface),
      submitSurface: surfaceDiagnostic(submitSurface),
      activeSurfaceMatchesPrevious: activeSurface === previousSurface,
      sourceField: fieldDiagnostic(state.sourceInput),
      targetField: fieldDiagnostic(state.targetInput),
      sourceJsonPresent: stringValuePresent(sourceJson),
      sourceJsonLength: stringValueLength(sourceJson),
      targetJsonPresent: stringValuePresent(targetJson),
      targetJsonLength: stringValueLength(targetJson)
    });
    if (!submitReady || !state.sourceInput || !state.targetInput || !submitButton) {
      logStage(requestId, "submit-bridge-missing", {
        submitReady: submitReady,
        sourceField: fieldDiagnostic(state.sourceInput),
        targetField: fieldDiagnostic(state.targetInput),
        submitButtonFound: !!submitButton
      });
      resetConnectSession(manager);
      setFeedback(
        state,
        "error",
        "Association could not be opened. Submit bridge could not resolve its active surface."
      );
      return;
    }
    // Mirror into the legacy hidden inputs for diagnostics only. The clicked
    // submit button now carries the authoritative request payload.
    dispatchValue(state.sourceInput, sourceJson);
    dispatchValue(state.targetInput, targetJson);
    if (state.inspectInput) {
      dispatchValue(state.inspectInput, JSON.stringify(debugSnapshot()));
    }
    if (state.requestIdInput) {
      dispatchValue(state.requestIdInput, requestId);
    }
    if (state.browserFailureKindInput) {
      dispatchValue(state.browserFailureKindInput, "");
    }
    if (state.browserMessageInput) {
      dispatchValue(state.browserMessageInput, "");
    }
    if (state.browserDetailInput) {
      dispatchValue(state.browserDetailInput, "");
    }
    logStage(requestId, "hidden-field-mirror-written", {
      sourceField: fieldDiagnostic(state.sourceInput),
      targetField: fieldDiagnostic(state.targetInput),
      snapshotField: fieldDiagnostic(state.inspectInput),
      requestIdField: fieldDiagnostic(state.requestIdInput)
    });
    writeSubmitPayload(submitButton, payload, state, sourceJson, targetJson);
    logStage(requestId, "request-payload-written", {
      transport: "button-payload-v2",
      sourcePaneId: payload.sourcePaneId,
      targetPaneId: payload.targetPaneId,
      sourceProviderKind: payload.sourceProviderKind,
      targetProviderKind: payload.targetProviderKind,
      submitButtonId: submitButton.id || null,
      sourceFieldId: state.sourceInput.id || null,
      targetFieldId: state.targetInput.id || null,
      sourceJsonPresent: stringValuePresent(sourceJson),
      sourceJsonLength: stringValueLength(sourceJson),
      targetJsonPresent: stringValuePresent(targetJson),
      targetJsonLength: stringValueLength(targetJson)
    });
    liveStates(manager).forEach(function (otherState) {
      setHoverElement(otherState, null);
      clearSource(otherState);
      otherState.rediscoveryRequested = false;
    });
    refreshAllPaneStates(manager);
    logStage(requestId, "request-sent-to-create-open-association", {
      contextObjectId: payload.contextObjectId,
      contextViewTitle: payload.contextViewTitle,
      sourcePaneId: payload.sourcePaneId,
      targetPaneId: payload.targetPaneId,
      sourceProviderKind: payload.sourceProviderKind,
      targetProviderKind: payload.targetProviderKind,
      transport: "button-payload-v2"
    });
    registerPendingRequest(pendingState, requestId);
    state.requestId = null;
    dispatchEvalButtonWhenReady(submitButton, {
      click: function () {
        submitButton.click();
      },
      onTimeout: function (detail) {
        failPendingRequest(
          pendingState,
          "Association could not be opened.",
          detail
        );
      },
      dispatchDelayMs: 250
    });
    pendingState.resetTimer = window.setTimeout(function () {
      if (manager.session.phase === "submitting") {
        resetConnectSession(manager, {
          preservePendingState: pendingState
        });
      }
    }, 900);
  }

  function invalidClick(state) {
    setStatus(
      state,
      mobileRouteViewport()
        ? "Tap a station in the active view."
        : "Click a source or target in the active view, not in the Connect controls."
    );
  }

  function onRootClick(state, event) {
    var manager = state.manager;
    var session = manager.session;
    var mobileIdleRoute = mobileRouteViewport() &&
      state.available &&
      !sessionActive(manager);
    if ((!state.enabled || !sessionActive(manager)) && !mobileIdleRoute) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    if (!state.root || event.currentTarget !== state.root) {
      return;
    }
    var element = state.provider &&
      state.provider.anchorCandidate &&
      state.provider.anchorCandidate(state.root, event.target);
    if (!element) {
      invalidClick(state);
      return;
    }
    var anchor = state.provider.buildAnchor(element, state.surface, state.root, event.target);
    if (mobileIdleRoute) {
      startConnectSession(state);
      beginConnection(state, element, anchor);
      updateLineFromMouse(state, event.clientX, event.clientY);
      return;
    }
    if (session.phase === "choose-source") {
      beginConnection(state, element, anchor);
      updateLineFromMouse(state, event.clientX, event.clientY);
      return;
    }
    if (session.phase !== "choose-target") {
      return;
    }
    if (session.sourceAnchor && anchorKey(anchor) === anchorKey(session.sourceAnchor) &&
        state.paneId === session.sourcePaneId) {
      setStatus(
        state,
        "Source selected - choose a different target anchor."
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
    if (!pane.dataset.hyperdocConnectPaneId) {
      pane.dataset.hyperdocConnectPaneId = "pane-" +
        Math.random().toString(36).slice(2, 10);
    }
    if (pane.hyperdocDomConnectState) {
      return pane.hyperdocDomConnectState;
    }
    ensurePaneControlMarkup(slot);
    var manager = connectManager();
    var control = slot.querySelector(".hyperdoc-dom-connect-control");
    var toggle = slot.querySelector(".hyperdoc-dom-connect-toggle");
    var annotation = slot.querySelector(".hyperdoc-dock-annotation");
    var snippetPlayground = slot.querySelector(".hyperdoc-dock-snippet-playground");
    var mobileRouteTitleNode = slot.querySelector(".hyperdoc-mobile-route-title");
    var mobileRouteDetailNode = slot.querySelector(".hyperdoc-mobile-route-detail");
    var mobileRouteOpen = slot.querySelector(".hyperdoc-mobile-route-open");
    var mobileRouteEvidence = slot.querySelector(".hyperdoc-mobile-route-evidence");
    var dmx = slot.querySelector(".hyperdoc-dock-dmx");
    var cue = slot.querySelector(".hyperdoc-dom-connect-cue");
    var sourceSummary = slot.querySelector(".hyperdoc-dom-connect-source-summary");
    var sourceChip = slot.querySelector(".hyperdoc-dom-connect-source-chip");
    var clear = slot.querySelector(".hyperdoc-dom-connect-clear");
    var helpToggle = slot.querySelector(".hyperdoc-dom-connect-help-toggle");
    var cancel = slot.querySelector(".hyperdoc-dom-connect-cancel");
    var feedback = slot.querySelector(".hyperdoc-dom-connect-feedback");
    var helpPanel = slot.querySelector(".hyperdoc-dom-connect-help-panel");
    var status = slot.querySelector(".hyperdoc-dom-connect-status");
    var stateBadge = slot.querySelector(".hyperdoc-dock-state-badge");
    var coachmarkTitle = slot.querySelector(".hyperdoc-dock-coachmark-title");
    var coachmarkSummary = slot.querySelector(".hyperdoc-dock-coachmark-summary");
    var coachmarkDetail = slot.querySelector(".hyperdoc-dock-coachmark-detail");
    var providerHandoff = slot.querySelector(".hyperdoc-dock-provider-handoff");
    var providerHandoffLabel = slot.querySelector(".hyperdoc-dock-provider-handoff-label");
    var dismiss = slot.querySelector(".hyperdoc-dock-dismiss");
    if (!control || !toggle || !annotation || !snippetPlayground ||
        !mobileRouteTitleNode || !mobileRouteDetailNode ||
        !mobileRouteOpen || !mobileRouteEvidence ||
        !dmx ||
        !cue || !sourceSummary || !sourceChip || !clear ||
        !stateBadge || !coachmarkTitle || !coachmarkSummary ||
        !coachmarkDetail || !providerHandoff || !providerHandoffLabel || !dismiss ||
        !helpToggle || !cancel || !feedback || !helpPanel || !status) {
      return null;
    }
    var state = {
      pane: pane,
      paneId: pane.dataset.hyperdocConnectPaneId,
      manager: manager,
      slot: slot,
      control: control,
      toggle: toggle,
      annotation: annotation,
      snippetPlayground: snippetPlayground,
      mobileRouteTitleNode: mobileRouteTitleNode,
      mobileRouteDetailNode: mobileRouteDetailNode,
      mobileRouteOpen: mobileRouteOpen,
      mobileRouteEvidence: mobileRouteEvidence,
      dmx: dmx,
      cue: cue,
      sourceSummary: sourceSummary,
      sourceChip: sourceChip,
      clear: clear,
      cancel: cancel,
      feedback: feedback,
      helpToggle: helpToggle,
      helpPanel: helpPanel,
      status: status,
      stateBadge: stateBadge,
      coachmarkTitle: coachmarkTitle,
      coachmarkSummary: coachmarkSummary,
      coachmarkDetail: coachmarkDetail,
      providerHandoff: providerHandoff,
      providerHandoffLabel: providerHandoffLabel,
      dismiss: dismiss,
      enabled: false,
      available: false,
      phase: "dormant",
      helpOpen: false,
      presentationState: "latent",
      presentationReason: null,
      introducedCapability: null,
      presentationScope: DOCK_PRESENTATION_SCOPE,
      presentationEvent: null,
      relevantDockCapabilities: [],
      rediscoveryRequested: false,
      hoverElement: null,
      source: null,
      sourceElement: null,
      requestId: null,
      pendingRequest: null,
      resetTimer: null,
      syncingPaneSurface: false,
      syncPaneSurfaceScheduled: false,
      mobileRouteSuccessTimer: null,
      mobileRouteSuccessUntil: null,
      provider: providerApiForKind("dom-v1"),
      providerKind: "dom-v1",
      surface: null,
      root: null,
      overlay: null,
      line: null,
      sourceInput: null,
      targetInput: null,
      inspectInput: null,
      requestIdInput: null,
      browserFailureKindInput: null,
      browserMessageInput: null,
      browserDetailInput: null,
      submit: null,
      evidenceSubmit: null,
      dockAnnotationSubmit: null,
      connectRuntimeSubmit: null,
      connectEvidenceSubmit: null,
      annotationSemanticSubmit: null,
      annotationEvidenceSubmit: null,
      guideModelSubmit: null,
      guideEvidenceSubmit: null,
      snippetPlaygroundSubmit: null,
      compactCapabilities: [],
      coachmarkCapabilities: [],
      providerHandoffs: [],
      providerHelpSummary: "",
      providerHelpDetail: "",
      completedRoute: null
    };
    pane.hyperdocDomConnectState = state;
    registerState(manager, state);
    slot.hidden = true;
    slot.dataset.helpOpen = "false";
    slot.dataset.dockPresentation = "latent";
    slot.dataset.dockIntroducedCapability = "";
    slot.dataset.dockPresentationReason = "";
    toggle.dataset.mode = "inactive";
    control.dataset.connectState = "dormant";
    control.dataset.dockPresentation = "latent";
    control.dataset.dockIntroducedCapability = "";
    control.dataset.dockPresentationReason = "";
    if (!helpPanel.id) {
      helpPanel.id = (slot.id || "hyperdoc-dom-connect-pane-slot") + "-help-panel";
    }
    helpToggle.setAttribute("aria-controls", helpPanel.id);
    helpToggle.setAttribute("aria-expanded", "false");
    helpPanel.setAttribute("aria-hidden", "true");
    toggle.addEventListener("click", function (event) {
      if (!state.available) {
        return;
      }
      if (event.shiftKey || event.altKey) {
        event.preventDefault();
        event.stopPropagation();
        inspectConnectCapability(state, event);
        return;
      }
      if (sessionActive(state.manager)) {
        deactivate(state, true);
      } else {
        activate(state);
      }
    });
    annotation.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      if (event.shiftKey || event.altKey) {
        inspectAnnotationCapability(state, event);
        return;
      }
      completeAnnotationTarget(state);
    });
    snippetPlayground.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      openSnippetPlayground(state, event);
    });
    mobileRouteOpen.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      openCompletedRoute(state);
    });
    mobileRouteEvidence.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      openRequestEvidence(
        state,
        state.completedRoute && state.completedRoute.requestId || null,
        "",
        "Route evidence",
        ""
      );
    });
    dmx.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      openDmxDockCapability(state);
    });
    helpToggle.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      if (event.shiftKey || event.altKey) {
        inspectGuideCapability(state, event);
        return;
      }
      toggleHelpPanel(state);
    });
    clear.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      clearSelectedSource(state);
    });
    feedback.addEventListener("click", function (event) {
      var button = event.target.closest(".hyperdoc-dom-connect-feedback-open-evidence");
      if (!button) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      openRequestEvidence(
        state,
        button.dataset.requestId || null,
        button.dataset.failureKind || null,
        button.dataset.message || null,
        button.dataset.detail || null
      );
    });
    cancel.addEventListener("click", function () {
      deactivate(state, true);
    });
    dismiss.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      dismissCoachmark(state, "dismissed");
    });
    document.addEventListener("click", function (event) {
      if (state.helpOpen && !state.slot.contains(event.target)) {
        if (state.presentationState === "rediscovery") {
          closeHelpPanel(state);
        } else if (state.presentationState === "introduction") {
          dismissCoachmark(state, "dismissed-outside");
        }
      }
    }, true);
    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && sessionActive(state.manager)) {
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
      refreshPaneStateFromSession(state);
    });
    var observer = new MutationObserver(function () {
      schedulePaneSurfaceSync(state);
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
          setHoverElement(
            state,
            state.provider &&
              state.provider.anchorCandidate &&
              state.provider.anchorCandidate(state.root, event.target)
          );
        }
        updateLineFromMouse(state, event.clientX, event.clientY);
      }, true);
      root.addEventListener("mouseleave", function () {
        if (state.root === root) {
          setHoverElement(state, null);
        }
      }, true);
    }
    schedulePaneSurfaceSync(state);
    if (surface.dataset.hyperdocSourceFocusApplied !== "true") {
      surface.dataset.hyperdocSourceFocusApplied = "true";
      var focusLine = surface.querySelector(
        ".hyperdoc-source-connect-line[data-hyperdoc-source-focus='true']"
      );
      if (focusLine && typeof focusLine.scrollIntoView === "function") {
        window.setTimeout(function () {
          focusLine.scrollIntoView({ block: "center", inline: "nearest" });
        }, 0);
      }
    }
  }

  window.hyperdocDomConnect = {
    initCurrentView: function () {
      if (!window.currentInspectorView) {
        return;
      }
      var surface = window.currentInspectorView.querySelector(
        ".hyperdoc-connect-provider-surface, .hyperdoc-dom-connect-surface"
      );
      initSurface(surface);
    },
    notifyServerResult: function (detail) {
      window.dispatchEvent(
        new CustomEvent("hyperdoc-dom-connect-server-result", {
          detail: detail || {}
        })
      );
    },
    readSessionState: function () {
      return sessionDiagnostic(connectManager().session);
    },
    readPaneStates: function () {
      return liveStates(connectManager()).map(function (state) {
        return paneSnapshot(state);
      });
    },
    readDebugSnapshot: function () {
      return debugSnapshot();
    },
    __test: {
      forceNextFailureMode: function (kind) {
        connectTestState().nextFailureMode = kind || null;
      },
      clearFailureModes: function () {
        connectTestState().nextFailureMode = null;
        connectTestState().suppressedServerResults = {};
      },
      resetDockPresentation: function () {
        resetDockPresentationMemory();
        liveStates(connectManager()).forEach(function (state) {
          state.rediscoveryRequested = false;
          state.presentationReason = null;
          state.introducedCapability = null;
          state.presentationScope = DOCK_PRESENTATION_SCOPE;
          state.presentationEvent = null;
          state.relevantDockCapabilities = [];
          refreshPaneStateFromSession(state);
        });
      }
    }
  };
}());
