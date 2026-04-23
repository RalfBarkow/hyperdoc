// Process <graphviz-element> elements in a view
//
// Copyright (c) 2024-2026 Konrad Hinsen <konrad.hinsen@fastmail.net>
//
function processGraphvizElements(element) {
    if (window.inspectorGraphviz &&
        typeof window.inspectorGraphviz.processLegacyGraphvizElements === 'function') {
        window.inspectorGraphviz.processLegacyGraphvizElements(element);
    }
};
