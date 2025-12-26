// Construct the full URL of a HyperDoc
//
// Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>
//
makeUrl = function(element) {
    var slugElements = element.getElementsByTagName('hyperbook-slug');
    while (slugElements.length > 0) {
        var slug = slugElements[0];
        var url = window.location.origin + '/' + slug.textContent;
        var link = document.createElement('a');
        var linkText = document.createTextNode(url);
        link.appendChild(linkText);
        link.href = url;
        link.target = '_blank';
        slug.replaceWith(link);
    }
}
