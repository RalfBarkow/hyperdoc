// Construct the full URL of a HyperDoc
//
// Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>
//
makeUrl = function(element) {
    var slugElements = element.getElementsByTagName('hyperdoc-slug');
    for(var i = 0; i < slugElements.length; ++ i) {
        var slug = slugElements[i];
        var url = window.location.origin + "/" + slug.textContent;
        var link = document.createElement('a');
        var linkText = document.createTextNode(url);
        link.appendChild(linkText);
        link.href = url;
        link.target = "_blank";
        slug.replaceWith(link);
        // slug.textContent = '';
        // slug.appendChild(link);
    }
}
