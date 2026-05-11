(function (global) {
  'use strict';

  function nowIso() { return new Date().toISOString(); }

  function ensureEvidenceStore(root) {
    if (!root.dm6Evidence) root.dm6Evidence = [];
    return root.dm6Evidence;
  }

  function setStatus(root, value) {
    var status = root.querySelector('.dm6-status');
    if (status) status.textContent = value;
  }

  function appendEvidence(root, record) {
    var pre = root.querySelector('.dm6-evidence');
    if (!pre) return;
    pre.textContent += '[' + record.kind + '] ' + JSON.stringify(record, null, 2) + '\n';
  }

  function renderEvidenceSummary(root) {
    var target = root.querySelector('.dm6-evidence-summary');
    if (!target) return;
    var records = ensureEvidenceStore(root);
    var kinds = {};
    records.forEach(function (record) {
      kinds[record.kind] = (kinds[record.kind] || 0) + 1;
    });
    target.textContent = JSON.stringify({ total: records.length, kinds: kinds }, null, 2);
  }

  function evidenceRecord(root, kind, payload) {
    var record = {
      source: 'dm6-appembed',
      kind: kind,
      receivedAt: nowIso(),
      slug: root.getAttribute('data-dm6-slug') || null,
      payload: payload || {}
    };
    ensureEvidenceStore(root).push(record);
    appendEvidence(root, record);
    renderEvidenceSummary(root);
    try {
      root.dispatchEvent(new CustomEvent('hyperdoc:dm6-evidence', {
        bubbles: true,
        detail: record
      }));
    } catch (_) {}
    return record;
  }

  function stageSnapshot(root) {
    var stage = root.querySelector('.dm6-stage');
    if (!stage) return { present: false };
    var rect = stage.getBoundingClientRect();
    return {
      present: true,
      childElementCount: stage.childElementCount,
      textLength: (stage.textContent || '').trim().length,
      firstChildTag: stage.firstElementChild ? stage.firstElementChild.tagName : null,
      innerHtmlPrefix: (stage.innerHTML || '').slice(0, 300),
      width: rect.width,
      height: rect.height,
      svgCount: stage.querySelectorAll ? stage.querySelectorAll('svg').length : 0,
      canvasCount: stage.querySelectorAll ? stage.querySelectorAll('canvas').length : 0
    };
  }

  function recordStageLater(root, label, delay) {
    window.setTimeout(function () {
      evidenceRecord(root, label, stageSnapshot(root));
    }, delay);
  }

  function loadScriptOnce(src) {
    if (global.Elm && global.Elm.AppEmbed) return Promise.resolve();
    return new Promise(function (resolve, reject) {
      var existing = document.querySelector('script[data-dm6-inline-bundle="' + src + '"]');
      if (existing) {
        existing.addEventListener('load', resolve, { once: true });
        existing.addEventListener('error', reject, { once: true });
        return;
      }
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

  function availablePorts(app) {
    if (!app || !app.ports) return [];
    return Object.keys(app.ports).sort();
  }

  function subscribeOptionalPorts(root, app) {
    var ports = availablePorts(app);
    evidenceRecord(root, 'ports-available', {
      ports: ports,
      expected: ['storeModel', 'evidence', 'setHash', 'importJSON', 'exportJSON', 'imageFilePicker'],
      present: {
        storeModel: ports.indexOf('storeModel') >= 0,
        log: ports.indexOf('log') >= 0,
        evidence: ports.indexOf('evidence') >= 0
      }
    });

    ['storeModel', 'evidence', 'setHash', 'importJSON', 'exportJSON', 'imageFilePicker'].forEach(function (name) {
      if (app && app.ports && app.ports[name] && app.ports[name].subscribe) {
        app.ports[name].subscribe(function (event) {
          evidenceRecord(root, 'port:' + name, {
            port: name,
            event: event
          });
        });
      }
    });
  }

  function mount(root) {
    if (!root || root.dataset.dm6Mounted === 'true') return;
    root.dataset.dm6Mounted = 'true';

    var stage = root.querySelector('.dm6-stage');
    if (!stage) return;

    var bundle = root.getAttribute('data-dm6-bundle') || '/assets/dm6-elm/app.js';
    var title = (document.querySelector('h1') || {}).textContent || 'empty';
    var slug = root.getAttribute('data-dm6-slug') || slugify(title);
    var stored = storedFromRoot(root);

    root.setAttribute('data-dm6-slug', slug);

    setStatus(root, 'loading ' + bundle);
    evidenceRecord(root, 'mount-requested', {
      bundle: bundle,
      slug: slug,
      storedBytes: stored.length
    });
    evidenceRecord(root, 'stage-before-init', stageSnapshot(root));

    loadScriptOnce(bundle).then(function () {
      evidenceRecord(root, 'bundle-loaded', {
        bundle: bundle,
        hasElm: !!global.Elm,
        hasAppEmbed: !!(global.Elm && global.Elm.AppEmbed),
        hasInit: !!(global.Elm && global.Elm.AppEmbed &&
                    typeof global.Elm.AppEmbed.init === 'function')
      });

      if (!global.Elm || !global.Elm.AppEmbed ||
          typeof global.Elm.AppEmbed.init !== 'function') {
        setStatus(root, 'Elm.AppEmbed not found after loading bundle');
        evidenceRecord(root, 'mount-failed', { reason: 'Elm.AppEmbed.init missing' });
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
      setStatus(root, 'mounted slug=' + slug);

      evidenceRecord(root, 'init', {
        slug: slug,
        storedBytes: stored.length,
        flagsShape: { slug: 'String', stored: 'String' }
      });

      subscribeOptionalPorts(root, app);

      recordStageLater(root, 'stage-after-init-100ms', 100);
      recordStageLater(root, 'stage-after-init-1000ms', 1000);
    }).catch(function (error) {
      setStatus(root, error.message || String(error));
      evidenceRecord(root, 'mount-error', { message: error.message || String(error) });
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
    snapshotAll: function (scope) {
      var root = scope || document;
      var nodes = root.querySelectorAll ? root.querySelectorAll('.dm6-hyperdoc-map') : [];
      var result = [];
      for (var i = 0; i < nodes.length; i += 1) {
        result.push({
          slug: nodes[i].getAttribute('data-dm6-slug'),
          mounted: nodes[i].dataset.dm6Mounted === 'true',
          status: (nodes[i].querySelector('.dm6-status') || {}).textContent || null,
          stage: stageSnapshot(nodes[i]),
          evidence: ensureEvidenceStore(nodes[i])
        });
      }
      return result;
    }
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { mountAll(document); });
  } else {
    mountAll(document);
  }
}(window));
