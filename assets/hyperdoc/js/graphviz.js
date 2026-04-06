(function () {
  'use strict';

  var vizInstancePromise = null;

  function clearNode(node) {
    while (node.firstChild) {
      node.removeChild(node.firstChild);
    }
  }

  function graphvizPlaceholders(root) {
    var scope = root && typeof root.querySelectorAll === 'function'
      ? root
      : document;
    return scope.querySelectorAll('[data-hyperdoc-graphviz="true"]');
  }

  function graphvizDotSource(placeholder) {
    var attributeDot = placeholder.getAttribute('data-hyperdoc-graphviz-dot');
    var sourceNode = placeholder.querySelector(
      'script.hyperdoc-graphviz-dot[type="text/plain"]'
    );
    if (attributeDot !== null) {
      return attributeDot;
    }
    if (sourceNode) {
      return sourceNode.textContent || '';
    }
    return '';
  }

  function graphvizCanvas(placeholder) {
    var canvas = placeholder.querySelector('.hyperdoc-graphviz-canvas');
    if (!canvas) {
      canvas = document.createElement('div');
      canvas.className = 'hyperdoc-graphviz-canvas';
      placeholder.insertBefore(canvas, placeholder.firstChild);
    }
    return canvas;
  }

  function graphvizFallback(placeholder) {
    return placeholder.querySelector('.hyperdoc-graphviz-dot-fallback');
  }

  function graphvizErrorBlock(placeholder) {
    return placeholder.querySelector('.hyperdoc-graphviz-error');
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
      errorBlock.className = 'hyperdoc-graphviz-error';
      placeholder.insertBefore(errorBlock, placeholder.firstChild);
    }

    errorBlock.textContent =
      'Graphviz render error: ' + message + '\n\nRaw DOT remains available below.';
    if (fallback) {
      fallback.open = true;
    }
    placeholder.setAttribute('data-hyperdoc-graphviz-state', 'error');
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

  async function renderPlaceholder(placeholder) {
    var dot = graphvizDotSource(placeholder);
    var canvas = graphvizCanvas(placeholder);
    var svg;
    var viz;

    if (placeholder.getAttribute('data-hyperdoc-graphviz-rendered') === 'true') {
      return;
    }

    if (!dot.trim()) {
      showGraphvizError(placeholder, new Error('DOT source is empty.'));
      return;
    }

    clearGraphvizError(placeholder);
    placeholder.setAttribute('data-hyperdoc-graphviz-state', 'rendering');

    try {
      viz = await vizInstance();
      svg = viz.renderSVGElement(dot);
      svg.style.maxWidth = '100%';
      svg.style.height = 'auto';
      clearNode(canvas);
      canvas.appendChild(svg);
      placeholder.setAttribute('data-hyperdoc-graphviz-rendered', 'true');
      placeholder.setAttribute('data-hyperdoc-graphviz-state', 'rendered');
    } catch (error) {
      placeholder.removeAttribute('data-hyperdoc-graphviz-rendered');
      showGraphvizError(placeholder, error);
    }
  }

  function initCurrentView(root) {
    var placeholders = graphvizPlaceholders(root);
    var index;

    for (index = 0; index < placeholders.length; index += 1) {
      renderPlaceholder(placeholders[index]);
    }
  }

  window.hyperdocGraphviz = {
    initCurrentView: initCurrentView,
    renderPlaceholder: renderPlaceholder
  };
}());
