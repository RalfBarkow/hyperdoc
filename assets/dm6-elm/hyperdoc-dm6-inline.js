(function (global) {
  'use strict';

  function setStatus(root, value) {
    var status = root.querySelector('.dm6-status');
    if (status) status.textContent = value;
  }

  function appendEvidence(root, label, value) {
    var pre = root.querySelector('.dm6-evidence');
    if (!pre) return;
    var text = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
    pre.textContent += '[' + label + '] ' + text + '\n';
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

  function subscribeOptionalPorts(root, app) {
    if (!app || !app.ports) return;

    ['store', 'log', 'evidence'].forEach(function (name) {
      if (app.ports[name] && app.ports[name].subscribe) {
        app.ports[name].subscribe(function (event) {
          appendEvidence(root, name, event);
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

    setStatus(root, 'loading ' + bundle);

    loadScriptOnce(bundle).then(function () {
      if (!global.Elm || !global.Elm.AppEmbed || typeof global.Elm.AppEmbed.init !== 'function') {
        setStatus(root, 'Elm.AppEmbed not found after loading bundle');
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
      appendEvidence(root, 'init', { slug: slug, storedBytes: stored.length });
      subscribeOptionalPorts(root, app);
    }).catch(function (error) {
      setStatus(root, error.message || String(error));
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
    mountAll: mountAll
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { mountAll(document); });
  } else {
    mountAll(document);
  }
}(window));
