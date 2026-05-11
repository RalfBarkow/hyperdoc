(function (global) {
  'use strict';

  var suppressedOverlays = [];

  function nowIso() {
    return new Date().toISOString();
  }

  function byClass(root, name) {
    return root.querySelector('.' + name);
  }

  function setText(root, className, value) {
    var node = byClass(root, className);
    if (node) node.textContent = value;
  }

  function parseMaybeJson(value) {
    if (typeof value !== 'string') return value;
    try {
      return JSON.parse(value);
    } catch (_) {
      return value;
    }
  }

  function evidenceState(root) {
    if (!root._dm6EvidenceState) {
      root._dm6EvidenceState = {
        events: [],
        lastSemanticKind: null
      };
    }
    return root._dm6EvidenceState;
  }

  function semanticKindFromRecord(record) {
    var payload = record.payload || {};
    var event = payload.event;
    if (event && typeof event === 'object' && event.kind) return event.kind;
    if (record.kind && record.kind.indexOf('port:') === 0) return record.kind;
    return record.kind || 'event';
  }

  function renderEvidence(root) {
    var state = evidenceState(root);
    var kinds = {};
    state.events.forEach(function (event) {
      var key = event.kind || 'event';
      kinds[key] = (kinds[key] || 0) + 1;
    });

    var last = state.events.length ? state.events[state.events.length - 1] : null;
    if (last) state.lastSemanticKind = semanticKindFromRecord(last);

    var summary = {
      total: state.events.length,
      last: state.lastSemanticKind || null,
      kinds: kinds
    };

    var summaryNode = byClass(root, 'dm6-evidence-summary');
    if (summaryNode) {
      summaryNode.textContent = JSON.stringify(summary, null, 2);
    }

    var pre = byClass(root, 'dm6-evidence');
    if (pre) {
      pre.textContent = state.events.map(function (event) {
        return '[' + event.kind + '] ' + JSON.stringify(event, null, 2);
      }).join('\n');
    }

    setText(root, 'dm6-evidence-count', String(state.events.length));
    setText(root, 'dm6-evidence-last', state.lastSemanticKind || 'none');
  }

  function appendEvidence(root, kind, payload) {
    var state = evidenceState(root);
    var slug = root.getAttribute('data-dm6-slug') || 'empty';
    var parsedPayload = payload;

    if (kind.indexOf('port:') === 0) {
      parsedPayload = {
        port: kind.slice(5),
        event: parseMaybeJson(payload)
      };
    }

    var record = {
      source: 'dm6-appembed',
      kind: kind,
      receivedAt: nowIso(),
      slug: slug,
      payload: parsedPayload
    };

    state.events.push(record);
    renderEvidence(root);
    return record;
  }

  function loadScriptOnce(src) {
    if (global.Elm && global.Elm.AppEmbed) return Promise.resolve();

    var existing = document.querySelector('script[data-dm6-inline-bundle="' + src + '"]');
    if (existing) {
      return new Promise(function (resolve, reject) {
        existing.addEventListener('load', resolve, { once: true });
        existing.addEventListener('error', reject, { once: true });
      });
    }

    return new Promise(function (resolve, reject) {
      var script = document.createElement('script');
      script.src = src;
      script.dataset.dm6InlineBundle = src;
      script.onload = resolve;
      script.onerror = function () { reject(new Error('Could not load ' + src)); };
      document.head.appendChild(script);
    });
  }

  function slugify(value) {
    return String(value || 'empty')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '') || 'empty';
  }

  function storedFromRoot(root) {
    var attr = root.getAttribute('data-dm6-stored');
    if (attr && attr.trim()) return attr.trim();

    var node = root.querySelector('script.dm6-stored');
    if (node && node.textContent.trim()) return node.textContent.trim();

    return '{}';
  }

  function stageSnapshot(root) {
    var canvas = byClass(root, 'dm6-canvas');
    var stage = byClass(root, 'dm6-stage') || canvas;
    if (!stage) return { present: false };

    var rect = stage.getBoundingClientRect();
    return {
      present: true,
      childElementCount: stage.childElementCount,
      textLength: (stage.textContent || '').length,
      firstChildTag: stage.firstElementChild ? stage.firstElementChild.tagName : null,
      innerHtmlPrefix: (stage.innerHTML || '').slice(0, 120),
      width: rect.width,
      height: rect.height,
      svgCount: stage.querySelectorAll ? stage.querySelectorAll('svg').length : 0,
      canvasCount: stage.querySelectorAll ? stage.querySelectorAll('canvas').length : 0
    };
  }

  function subscribeOptionalPorts(root, app) {
    if (!app || !app.ports) {
      appendEvidence(root, 'ports-available', {
        ports: [],
        expected: ['storeModel', 'store', 'log', 'evidence'],
        present: {}
      });
      return;
    }

    var ports = Object.keys(app.ports).sort();
    var expected = ['storeModel', 'store', 'log', 'evidence', 'setHash', 'importJSON', 'exportJSON', 'imageFilePicker'];
    var present = {};
    expected.forEach(function (name) {
      present[name] = ports.indexOf(name) >= 0;
    });

    appendEvidence(root, 'ports-available', {
      ports: ports,
      expected: expected,
      present: present
    });

    ports.forEach(function (name) {
      var port = app.ports[name];
      if (port && typeof port.subscribe === 'function') {
        try {
          port.subscribe(function (event) {
            appendEvidence(root, 'port:' + name, event);
          });
        } catch (error) {
          appendEvidence(root, 'port-subscribe-error', {
            port: name,
            message: error.message || String(error)
          });
        }
      }
    });
  }

  function intersects(a, b) {
    return !(a.right < b.left || a.left > b.right || a.bottom < b.top || a.top > b.bottom);
  }

  function restoreSuppressedOverlays() {
    suppressedOverlays.forEach(function (entry) {
      entry.el.style.pointerEvents = entry.pointerEvents;
      entry.el.style.opacity = entry.opacity;
      entry.el.style.filter = entry.filter;
    });
    suppressedOverlays = [];
  }

  function suppressIntersectingOverlays(root) {
    restoreSuppressedOverlays();

    var canvas = byClass(root, 'dm6-canvas') || root;
    var canvasRect = canvas.getBoundingClientRect();

    Array.prototype.forEach.call(document.body.children, function (el) {
      if (!el || el === root || root.contains(el)) return;
      if (el.closest && el.closest('.dm6-hyperdoc-map')) return;

      var style = global.getComputedStyle(el);
      var position = style.position;
      var zIndex = parseInt(style.zIndex, 10);

      if (isNaN(zIndex)) zIndex = 0;

      var overlayLike =
        (position === 'fixed' || position === 'absolute' || position === 'sticky') &&
        zIndex >= 10;

      if (!overlayLike) return;

      var rect = el.getBoundingClientRect();
      if (!rect.width || !rect.height) return;

      var tooGlobal =
        rect.width > global.innerWidth * 0.96 &&
        rect.height > global.innerHeight * 0.96;

      if (tooGlobal) return;

      if (intersects(canvasRect, rect)) {
        suppressedOverlays.push({
          el: el,
          pointerEvents: el.style.pointerEvents,
          opacity: el.style.opacity,
          filter: el.style.filter
        });
        el.style.pointerEvents = 'none';
        el.style.opacity = '0.08';
        el.style.filter = 'grayscale(1)';
      }
    });
  }

  function enterEmbeddedAppFocus(root) {
    document.body.classList.add('hyperdoc-embedded-app-focus');
    suppressIntersectingOverlays(root);
    setText(root, 'dm6-input-owner', 'dm6 topic map');
    setText(root, 'dm6-hyperdoc-state', 'HyperDoc overlays paused inside embedded app');
  }

  function leaveEmbeddedAppFocus(root) {
    document.body.classList.remove('hyperdoc-embedded-app-focus');
    restoreSuppressedOverlays();
    setText(root, 'dm6-input-owner', 'page');
    setText(root, 'dm6-hyperdoc-state', 'HyperDoc overlays active outside embedded app');
  }

  function setupIslandFocus(root) {
    root.addEventListener('pointerenter', function () {
      enterEmbeddedAppFocus(root);
    });

    root.addEventListener('pointerleave', function () {
      leaveEmbeddedAppFocus(root);
    });

    root.addEventListener('focusin', function () {
      enterEmbeddedAppFocus(root);
    });

    root.addEventListener('focusout', function () {
      setTimeout(function () {
        if (!root.contains(document.activeElement)) {
          leaveEmbeddedAppFocus(root);
        }
      }, 0);
    });
  }

  function setupToolbar(root) {
    var toolbar = byClass(root, 'dm6-toolbar');
    if (!toolbar) return;

    toolbar.addEventListener('click', function (event) {
      var button = event.target.closest('button[data-dm6-action]');
      if (!button) return;

      var action = button.getAttribute('data-dm6-action');
      var canvas = byClass(root, 'dm6-canvas');
      var drawer = byClass(root, 'dm6-evidence-drawer');

      if (action === 'select') {
        setText(root, 'dm6-mode', 'select');
        appendEvidence(root, 'ui-mode', { mode: 'select' });
      } else if (action === 'move') {
        setText(root, 'dm6-mode', 'move / drag');
        appendEvidence(root, 'ui-mode', { mode: 'move' });
      } else if (action === 'cross') {
        setText(root, 'dm6-mode', 'cross boundary');
        appendEvidence(root, 'ui-mode', { mode: 'cross-boundary' });
      } else if (action === 'fit') {
        if (canvas) {
          canvas.scrollLeft = 0;
          canvas.scrollTop = 0;
        }
        appendEvidence(root, 'ui-fit-requested', stageSnapshot(root));
      } else if (action === 'reset') {
        setText(root, 'dm6-mode', 'select');
        if (canvas) {
          canvas.scrollLeft = 0;
          canvas.scrollTop = 0;
        }
        appendEvidence(root, 'ui-reset-view', stageSnapshot(root));
      } else if (action === 'evidence') {
        if (drawer) drawer.open = !drawer.open;
      }
    });

    var copy = root.querySelector('[data-dm6-evidence-copy]');
    if (copy) {
      copy.addEventListener('click', function () {
        var text = JSON.stringify(evidenceState(root).events, null, 2);
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text);
        }
      });
    }

    var clear = root.querySelector('[data-dm6-evidence-clear]');
    if (clear) {
      clear.addEventListener('click', function () {
        root._dm6EvidenceState = { events: [], lastSemanticKind: null };
        renderEvidence(root);
      });
    }

    var download = root.querySelector('[data-dm6-evidence-download]');
    if (download) {
      download.addEventListener('click', function () {
        var blob = new Blob([JSON.stringify(evidenceState(root).events, null, 2)], {
          type: 'application/json'
        });
        var a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = 'dm6-evidence-' + Date.now() + '.json';
        document.body.appendChild(a);
        a.click();
        setTimeout(function () {
          URL.revokeObjectURL(a.href);
          a.remove();
        }, 0);
      });
    }
  }

  function mount(root) {
    if (!root || root.dataset.dm6Mounted === 'true') return;
    root.dataset.dm6Mounted = 'true';

    setupIslandFocus(root);
    setupToolbar(root);

    var stage = byClass(root, 'dm6-stage');
    if (!stage) return;

    var bundle = root.getAttribute('data-dm6-bundle') || '/assets/dm6-elm/app.js';
    var title = (document.querySelector('h1') || {}).textContent || 'empty';
    var slug = root.getAttribute('data-dm6-slug') || slugify(title);
    var stored = storedFromRoot(root);

    root.setAttribute('data-dm6-slug', slug);

    setText(root, 'dm6-status', 'loading ' + bundle);
    setText(root, 'dm6-mode', 'select');
    setText(root, 'dm6-input-owner', 'page');
    setText(root, 'dm6-hyperdoc-state', 'HyperDoc overlays active outside embedded app');

    appendEvidence(root, 'mount-requested', {
      bundle: bundle,
      slug: slug,
      storedBytes: stored.length
    });

    appendEvidence(root, 'stage-before-init', stageSnapshot(root));

    loadScriptOnce(bundle).then(function () {
      appendEvidence(root, 'bundle-loaded', {
        bundle: bundle,
        hasElm: !!global.Elm,
        hasAppEmbed: !!(global.Elm && global.Elm.AppEmbed),
        hasInit: !!(global.Elm && global.Elm.AppEmbed && global.Elm.AppEmbed.init)
      });

      if (!global.Elm || !global.Elm.AppEmbed || typeof global.Elm.AppEmbed.init !== 'function') {
        setText(root, 'dm6-status', 'Elm.AppEmbed not found after loading bundle');
        return;
      }

      var app = global.Elm.AppEmbed.init({
        node: stage,
        flags: {
          slug: String(slug),
          stored: String(stored || '{}')
        }
      });

      root.dm6App = app;

      setText(root, 'dm6-status', 'mounted slug=' + slug);
      setText(root, 'dm6-mount-summary', 'dm6 mounted · evidence connected · try clicking or dragging a topic');

      appendEvidence(root, 'init', {
        slug: slug,
        storedBytes: stored.length,
        flagsShape: {
          slug: 'String',
          stored: 'String'
        }
      });

      subscribeOptionalPorts(root, app);

      setTimeout(function () {
        appendEvidence(root, 'stage-after-init-100ms', stageSnapshot(root));
      }, 100);

      setTimeout(function () {
        appendEvidence(root, 'stage-after-init-1000ms', stageSnapshot(root));
      }, 1000);
    }).catch(function (error) {
      setText(root, 'dm6-status', error.message || String(error));
      appendEvidence(root, 'error', error.message || String(error));
    });
  }

  function mountAll(scope) {
    var root = scope || document;
    var nodes = root.querySelectorAll ? root.querySelectorAll('.dm6-hyperdoc-map') : [];
    for (var i = 0; i < nodes.length; i += 1) mount(nodes[i]);
  }

  global.hyperdocDm6Inline = {
    mount: mount,
    mountAll: mountAll,
    evidenceState: evidenceState
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { mountAll(document); });
  } else {
    mountAll(document);
  }
}(window));
