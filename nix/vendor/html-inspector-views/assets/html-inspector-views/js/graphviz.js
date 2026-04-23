(function () {
  'use strict';

  var vizInstancePromise = null;

  function clearNode(node) {
    while (node.firstChild) {
      node.removeChild(node.firstChild);
    }
  }

  function isInspectorHtmlId(s) {
    var parts = s.split('-');
    if (parts.length !== 2) {
      return false;
    }
    if (!['inspect', 'action', 'eval'].includes(parts[0])) {
      return false;
    }
    if (isNaN(Number(parts[1]))) {
      return false;
    }
    return true;
  }

  function graphvizPlaceholders(root) {
    var scope = root && typeof root.querySelectorAll === 'function'
      ? root
      : document;
    return scope.querySelectorAll('[data-inspector-graphviz="true"]');
  }

  function graphvizDotSource(placeholder) {
    var attributeDot = placeholder.getAttribute('data-inspector-graphviz-dot');
    if (attributeDot !== null) {
      return attributeDot;
    }
    return "";
  }

  function graphvizOptions(placeholder) {
    var engine = placeholder.getAttribute('data-inspector-graphviz-engine');
    if (engine) {
      return { engine: engine };
    }
    return {};
  }

  function graphvizCanvas(placeholder) {
    var canvas = placeholder.querySelector('.inspector-graphviz-canvas');
    if (!canvas) {
      canvas = document.createElement('div');
      canvas.className = 'inspector-graphviz-canvas';
      placeholder.insertBefore(canvas, placeholder.firstChild);
    }
    return canvas;
  }

  function graphvizFallback(placeholder) {
    return placeholder.querySelector('.inspector-graphviz-dot-fallback');
  }

  function graphvizErrorBlock(placeholder) {
    return placeholder.querySelector('.inspector-graphviz-error');
  }

  function clearGraphvizError(placeholder) {
    var errorBlock = graphvizErrorBlock(placeholder);
    if (errorBlock && errorBlock.parentNode) {
      errorBlock.parentNode.removeChild(errorBlock);
    }
  }

  function showGraphvizError(placeholder, error) {
    var message = error && error.message ? error.message : String(error);
    var errorBlock = graphvizErrorBlock(placeholder);
    var fallback = graphvizFallback(placeholder);

    if (!errorBlock) {
      errorBlock = document.createElement('pre');
      errorBlock.className = 'inspector-graphviz-error';
      placeholder.insertBefore(errorBlock, placeholder.firstChild);
    }

    errorBlock.textContent =
      'Graphviz render error: ' + message + '\n\nRaw DOT remains available below.';
    if (fallback) {
      fallback.open = true;
    }
    placeholder.setAttribute('data-inspector-graphviz-state', 'error');
  }

  function vizInstance() {
    if (!window.Viz || typeof window.Viz.instance !== 'function') {
      return Promise.reject(new Error('Vendored Viz.js runtime is not available.'));
    }
    if (!vizInstancePromise) {
      vizInstancePromise = window.Viz.instance();
    }
    return vizInstancePromise;
  }

  function assignInspectorIds(svg) {
    var groups = svg.getElementsByTagName('g');
    var index;

    for (index = 0; index < groups.length; index += 1) {
      var group = groups[index];
      var titles = group.getElementsByTagName('title');
      if (titles.length !== 1) {
        continue;
      }
      var title = titles[0].textContent || "";
      if (isInspectorHtmlId(title)) {
        group.id = title;
      }
    }
  }

  async function renderDotIntoCanvas(dot, options, canvas) {
    var viz = await vizInstance();
    var svg = await viz.renderSVGElement(dot, options);

    assignInspectorIds(svg);
    svg.style.maxWidth = '100%';
    svg.style.height = 'auto';
    clearNode(canvas);
    canvas.appendChild(svg);
    return svg;
  }

  async function renderPlaceholder(placeholder) {
    var dot = graphvizDotSource(placeholder);
    var canvas = graphvizCanvas(placeholder);

    if (placeholder.getAttribute('data-inspector-graphviz-rendered') === 'true') {
      return;
    }

    if (!dot.trim()) {
      showGraphvizError(placeholder, new Error('DOT source is empty.'));
      return;
    }

    clearGraphvizError(placeholder);
    placeholder.setAttribute('data-inspector-graphviz-state', 'rendering');

    try {
      await renderDotIntoCanvas(dot, graphvizOptions(placeholder), canvas);
      placeholder.setAttribute('data-inspector-graphviz-rendered', 'true');
      placeholder.setAttribute('data-inspector-graphviz-state', 'rendered');
    } catch (error) {
      placeholder.removeAttribute('data-inspector-graphviz-rendered');
      showGraphvizError(placeholder, error);
    }
  }

  async function renderLegacyElement(node) {
    var dot = node.textContent || "";
    var options = Array.from(node.attributes)
      .map(function (attribute) { return [attribute.name, attribute.value]; })
      .reduce(function (accumulator, entry) {
        accumulator[entry[0]] = entry[1];
        return accumulator;
      }, {});

    if (!dot.trim()) {
      return;
    }

    await renderDotIntoCanvas(dot, options, node);
  }

  function processLegacyGraphvizElements(root) {
    var scope = root && typeof root.getElementsByTagName === 'function'
      ? root
      : document;
    var elements = scope.getElementsByTagName('graphviz-element');
    var index;

    for (index = 0; index < elements.length; index += 1) {
      renderLegacyElement(elements[index]);
    }
  }

  function initCurrentView(root) {
    var placeholders = graphvizPlaceholders(root);
    var index;

    for (index = 0; index < placeholders.length; index += 1) {
      renderPlaceholder(placeholders[index]);
    }
  }

  window.inspectorGraphviz = {
    initCurrentView: initCurrentView,
    processLegacyGraphvizElements: processLegacyGraphvizElements,
    renderPlaceholder: renderPlaceholder
  };
}());
