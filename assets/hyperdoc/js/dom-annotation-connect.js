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
      selectedSourceLabel: anchorLabel(session && session.sourceAnchor, null),
      selectedSourcePane: !!(session && session.sourcePaneId &&
        session.sourcePaneId === state.paneId),
      pendingRequestId: state.pendingRequest && state.pendingRequest.id || null
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
      return "Use Dock actions or click Connect to start.";
    }
    if (session.phase === "choose-source") {
      return "Click a source anchor.";
    }
    if (session.phase === "choose-target") {
      return "Click a target anchor.";
    }
    return "";
  }

  function connectionSuccessText(session) {
    var sourceLabel = anchorLabel(session && session.sourceAnchor, "source");
    var targetLabel = anchorLabel(session && session.targetAnchor, "target");
    if (sourceLabel && targetLabel) {
      return 'Connected "' + sourceLabel + '" to "' + targetLabel + '".';
    }
    return "Connected.";
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

  function inspectConnectState(state) {
    if (!state.available || !state.inspectSubmit) {
      return;
    }
    var requestId = "connect-inspect-" + Date.now().toString(36) + "-" +
      Math.random().toString(36).slice(2, 8);
    var snapshotJson = JSON.stringify(debugSnapshot());
    var button = state.inspectSubmit.querySelector("button");
    if (button) {
      [
        "data-dom-association-request-id",
        "data-dom-association-transport",
        "data-dom-association-context-object-id",
        "data-dom-association-context-view-title",
        "data-dom-association-source-json",
        "data-dom-association-target-json",
        "data-dom-association-source-field-id",
        "data-dom-association-target-field-id",
        "data-dom-association-source-pane-id",
        "data-dom-association-target-pane-id",
        "data-dom-association-source-provider-kind",
        "data-dom-association-target-provider-kind",
        "data-dom-connect-inspection-pane-id",
        "data-dom-connect-snapshot-field-id",
        "data-dom-connect-snapshot-json"
      ].forEach(function (attribute) {
        button.removeAttribute(attribute);
      });
      button.setAttribute("data-dom-association-request-id", requestId);
      button.setAttribute("data-dom-association-transport", "connect-snapshot-v1");
      button.setAttribute(
        "data-dom-association-context-object-id",
        state.surface && state.surface.dataset.contextObjectId || ""
      );
      button.setAttribute(
        "data-dom-association-context-view-title",
        state.surface && state.surface.dataset.contextViewTitle || ""
      );
      button.setAttribute(
        "data-dom-connect-inspection-pane-id",
        state.paneId || ""
      );
      if (state.inspectInput) {
        button.setAttribute(
          "data-dom-connect-snapshot-field-id",
          state.inspectInput.id || ""
        );
      }
      button.setAttribute("data-dom-connect-snapshot-json", snapshotJson);
      if (state.inspectInput) {
        dispatchValue(state.inspectInput, snapshotJson);
      }
      if (state.requestIdInput) {
        dispatchValue(state.requestIdInput, requestId);
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
          shiftKey: true
        }));
      },
      dispatchDelayMs: clickOptions && clickOptions.dispatchDelayMs || 250
    });
  }

  function inspectCurrentObject(state) {
    if (!state.available || !state.dockInspectSubmit) {
      return;
    }
    dispatchHiddenDockButton(state.dockInspectSubmit, {
      dispatchDelayMs: 250
    });
  }

  function openCurrentAnnotation(state) {
    if (!state.available || !state.dockAnnotationSubmit) {
      return;
    }
    dispatchHiddenDockButton(state.dockAnnotationSubmit, {
      dispatchDelayMs: 250
    });
  }

  function clearFeedback(state) {
    state.feedback.hidden = true;
    state.feedback.textContent = "";
    state.feedback.innerHTML = "";
    delete state.feedback.dataset.kind;
  }

  function setFeedback(state, kind, text) {
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
        setFeedback(feedbackState, "success", feedbackText);
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
    state.helpOpen = false;
    state.slot.dataset.helpOpen = "false";
    state.helpToggle.setAttribute("aria-expanded", "false");
    state.helpPanel.setAttribute("aria-hidden", "true");
  }

  function toggleHelpPanel(state) {
    state.helpOpen = !state.helpOpen;
    state.slot.dataset.helpOpen = state.helpOpen ? "true" : "false";
    state.helpToggle.setAttribute("aria-expanded", state.helpOpen ? "true" : "false");
    state.helpPanel.setAttribute("aria-hidden", state.helpOpen ? "false" : "true");
  }

  function updateProviderCopy(state) {
    var helpSummary = providerHelpSummary(state.surface);
    var helpDetail = providerHelpDetail(state.surface);
    state.helpToggle.title = helpSummary;
    state.helpToggle.setAttribute("aria-label", helpSummary);
    state.toggle.title = helpSummary;
    state.helpPanel.innerHTML =
      "<p>" + helpSummary + "</p>" +
      "<p>" + helpDetail + "</p>" +
      "<p>Dock also keeps Inspect and Annotation beside Connect for the current pane object.</p>";
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

  function touchFahrplanTabButton(pane) {
    if (!pane) {
      return null;
    }
    var tabs = pane.querySelectorAll(".inspector-tabs button");
    for (var i = 0; i < tabs.length; i += 1) {
      var text = tabs[i].textContent && tabs[i].textContent.replace(/\s+/g, " ").trim();
      if (text === "Touch-Fahrplan") {
        return tabs[i];
      }
    }
    return null;
  }

  function zoteroDockAvailable(state) {
    return !!(
      state &&
      state.surface &&
      state.surface.dataset.hyperdocDockZoteroAvailable === "true" &&
      touchFahrplanTabButton(state.pane)
    );
  }

  function syncDockCapabilities(state) {
    if (!state || !state.zotero) {
      return;
    }
    var shouldHideZotero = !zoteroDockAvailable(state);
    if (!!state.zotero.hidden !== shouldHideZotero) {
      state.zotero.hidden = shouldHideZotero;
    }
  }

  function openZoteroDockCapability(state) {
    var tab = touchFahrplanTabButton(state && state.pane);
    if (!tab || !zoteroDockAvailable(state)) {
      return;
    }
    tab.click();
  }

  function ensurePaneControlMarkup(slot) {
    if (!slot || slot.dataset.hyperdocDomConnectControl === "true") {
      return;
    }
    slot.dataset.hyperdocDomConnectControl = "true";
    slot.innerHTML =
      '<div class="hyperdoc-dom-connect-control hyperdoc-dock-control" data-hyperdoc-connect-ignore="true">' +
        '<span class="hyperdoc-dock-label">Dock</span>' +
        '<div class="hyperdoc-dock-actions">' +
          '<button type="button" class="hyperdoc-dom-connect-toggle hyperdoc-dock-action" ' +
                  'title="Click a source anchor, then a target anchor.">Connect</button>' +
          '<button type="button" class="hyperdoc-dock-inspect hyperdoc-dock-action" ' +
                  'title="Inspect the current pane object.">Inspect</button>' +
          '<button type="button" class="hyperdoc-dock-annotation hyperdoc-dock-action" ' +
                  'title="Open or reopen the generic Annotation object for the current pane object.">Annotation</button>' +
          '<button type="button" class="hyperdoc-dock-zotero hyperdoc-dock-action" ' +
                  'title="Open the Touch-Fahrplan provider view for this pane." hidden>Zotero</button>' +
        '</div>' +
        '<span class="hyperdoc-dom-connect-status" hidden>Pick source</span>' +
        '<span class="hyperdoc-dom-connect-source-summary" hidden>' +
          '<span class="hyperdoc-dom-connect-source-summary-label">Source:</span>' +
          '<span class="hyperdoc-dom-connect-source-chip"></span>' +
        '</span>' +
        '<span class="hyperdoc-dom-connect-cue">Use Dock actions or click Connect to start.</span>' +
        '<button type="button" class="hyperdoc-dom-connect-clear" hidden>Clear</button>' +
        '<button type="button" class="hyperdoc-dom-connect-inspect" ' +
                'title="Inspect the current Connect session and pane states.">Connect state</button>' +
        '<button type="button" class="hyperdoc-dom-connect-help-toggle" ' +
                'title="How Connect works in this view" aria-label="How Connect works in this view" aria-expanded="false">?</button>' +
        '<button type="button" class="hyperdoc-dom-connect-cancel" hidden>Cancel</button>' +
      '</div>' +
      '<div class="hyperdoc-dom-connect-help-panel" aria-hidden="true">' +
        '<p>Click a source anchor, then a target anchor.</p>' +
        '<p>Connect keeps the resolved anchor and its presentation fallback separate. Esc cancels.</p>' +
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
    state.inspectSubmit = null;
    state.evidenceSubmit = null;
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
    var inspectSubmit = controls.querySelector(".hyperdoc-dom-connect-inspect-submit");
    var evidenceSubmit = controls.querySelector(".hyperdoc-dom-connect-evidence-submit");
    var dockInspectSubmit = controls.querySelector(".hyperdoc-dock-inspect-submit");
    var dockAnnotationSubmit = controls.querySelector(".hyperdoc-dock-annotation-submit");
    if (!sourceInput || !targetInput || !inspectInput ||
        !requestIdInput || !browserFailureKindInput ||
        !browserMessageInput || !browserDetailInput ||
        !submit || !inspectSubmit || !evidenceSubmit ||
        !dockInspectSubmit || !dockAnnotationSubmit) {
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
    state.inspectSubmit = inspectSubmit;
    state.evidenceSubmit = evidenceSubmit;
    state.dockInspectSubmit = dockInspectSubmit;
    state.dockAnnotationSubmit = dockAnnotationSubmit;
    updateProviderCopy(state);
    syncDockCapabilities(state);
    return true;
  }

  function refreshPaneStateFromSession(state) {
    var manager = state.manager || connectManager();
    var session = manager.session;
    var available = !!state.available;
    state.slot.hidden = !available;
    if (!available) {
      state.enabled = false;
      state.toggle.dataset.mode = "inactive";
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

    state.enabled = activeForSource || activeForTarget;
    state.toggle.dataset.mode = sessionVisible ? "active" : "inactive";
    if (state.surface) {
      state.surface.classList.toggle("hyperdoc-dom-connect-active", !!state.enabled);
    }
    if (!sessionVisible) {
      if (!state.pendingRequest) {
        setPhase(state, "dormant");
      }
      return;
    }
    if (session.phase === "choose-source") {
      setPhase(state, activeForSource ? "select-source" : "dormant");
    } else if (session.phase === "choose-target") {
      setPhase(state, "select-target");
    } else if (session.phase === "submitting") {
      setPhase(state, "submitting");
    }
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
  }

  function startConnectSession(state) {
    var manager = state.manager;
    if (sessionActive(manager)) {
      resetConnectSession(manager);
    }
    liveStates(manager).forEach(function (otherState) {
      clearFeedback(otherState);
      closeHelpPanel(otherState);
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
        closeHelpPanel(state);
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
    closeHelpPanel(state);
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
      closeHelpPanel(otherState);
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
      closeHelpPanel(otherState);
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
      "Click a source or target in the active view, not in the Connect controls."
    );
  }

  function onRootClick(state, event) {
    var manager = state.manager;
    var session = manager.session;
    if (!state.enabled || !sessionActive(manager)) {
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
    var dockInspect = slot.querySelector(".hyperdoc-dock-inspect");
    var annotation = slot.querySelector(".hyperdoc-dock-annotation");
    var zotero = slot.querySelector(".hyperdoc-dock-zotero");
    var cue = slot.querySelector(".hyperdoc-dom-connect-cue");
    var sourceSummary = slot.querySelector(".hyperdoc-dom-connect-source-summary");
    var sourceChip = slot.querySelector(".hyperdoc-dom-connect-source-chip");
    var clear = slot.querySelector(".hyperdoc-dom-connect-clear");
    var inspect = slot.querySelector(".hyperdoc-dom-connect-inspect");
    var helpToggle = slot.querySelector(".hyperdoc-dom-connect-help-toggle");
    var cancel = slot.querySelector(".hyperdoc-dom-connect-cancel");
    var feedback = slot.querySelector(".hyperdoc-dom-connect-feedback");
    var helpPanel = slot.querySelector(".hyperdoc-dom-connect-help-panel");
    var status = slot.querySelector(".hyperdoc-dom-connect-status");
    if (!control || !toggle || !dockInspect || !annotation || !zotero ||
        !cue || !sourceSummary || !sourceChip || !clear ||
        !inspect ||
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
      dockInspect: dockInspect,
      annotation: annotation,
      zotero: zotero,
      cue: cue,
      sourceSummary: sourceSummary,
      sourceChip: sourceChip,
      clear: clear,
      inspect: inspect,
      cancel: cancel,
      feedback: feedback,
      helpToggle: helpToggle,
      helpPanel: helpPanel,
      status: status,
      enabled: false,
      available: false,
      phase: "dormant",
      helpOpen: false,
      hoverElement: null,
      source: null,
      sourceElement: null,
      requestId: null,
      pendingRequest: null,
      resetTimer: null,
      syncingPaneSurface: false,
      syncPaneSurfaceScheduled: false,
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
      inspectSubmit: null,
      evidenceSubmit: null,
      dockInspectSubmit: null,
      dockAnnotationSubmit: null
    };
    pane.hyperdocDomConnectState = state;
    registerState(manager, state);
    slot.hidden = true;
    slot.dataset.helpOpen = "false";
    toggle.dataset.mode = "inactive";
    control.dataset.connectState = "dormant";
    if (!helpPanel.id) {
      helpPanel.id = (slot.id || "hyperdoc-dom-connect-pane-slot") + "-help-panel";
    }
    helpToggle.setAttribute("aria-controls", helpPanel.id);
    helpToggle.setAttribute("aria-expanded", "false");
    helpPanel.setAttribute("aria-hidden", "true");
    toggle.addEventListener("click", function () {
      if (!state.available) {
        return;
      }
      if (sessionActive(state.manager)) {
        deactivate(state, true);
      } else {
        activate(state);
      }
    });
    dockInspect.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      inspectCurrentObject(state);
    });
    annotation.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      openCurrentAnnotation(state);
    });
    zotero.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      openZoteroDockCapability(state);
    });
    helpToggle.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      toggleHelpPanel(state);
    });
    clear.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      clearSelectedSource(state);
    });
    inspect.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      inspectConnectState(state);
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
    document.addEventListener("click", function (event) {
      if (state.helpOpen && !state.slot.contains(event.target)) {
        closeHelpPanel(state);
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
      }
    }
  };
}());
