// Construct canonical HyperBook URLs from server-provided path data.
//
// Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>
//
(function(global) {
    function isAbsoluteUrl(value) {
        return /^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(value || '');
    }

    function normalizePath(pathOrSlug) {
        if (!pathOrSlug) return null;
        if (isAbsoluteUrl(pathOrSlug)) return pathOrSlug;
        return pathOrSlug[0] === '/' ? pathOrSlug : '/' + pathOrSlug;
    }

    function canonicalUrl(pathOrUrl) {
        var normalized = normalizePath(pathOrUrl);
        if (!normalized) return null;
        if (isAbsoluteUrl(normalized)) return normalized;
        try {
            return new URL(normalized, global.location.origin).toString();
        } catch (error) {
            return normalized;
        }
    }

    function pathFromElement(element, slugElement) {
        var dataPath = element && element.getAttribute
            ? element.getAttribute('data-hyperdoc-url-path')
            : null;
        if (dataPath) return dataPath;
        if (!slugElement || !slugElement.textContent) return null;
        return slugElement.textContent.trim();
    }

    global.makeUrl = function(element) {
        if (!element || !element.getElementsByTagName) return;
        var slugElements = element.getElementsByTagName('hyperbook-slug');
        while (slugElements.length > 0) {
            var slugElement = slugElements[0];
            var resolved = canonicalUrl(pathFromElement(element, slugElement));
            var link = document.createElement('a');
            link.appendChild(document.createTextNode(resolved || ''));
            link.href = resolved || '#';
            link.target = '_blank';
            slugElement.replaceWith(link);
        }
    };
})(window);
