# Creating a HyperDoc

<in-package>hyperdoc</in-package>

A HyperDoc is defined by

 - A directory containing <a page="Writing text pages">text
   pages</a> and <a page="Writing source code pages">source
   code pages</a>
 - A title
 - Optionally: the title of a page to be displayed as the entry page

A HyperDoc is part of system defined via ASDF, its directory resides
next to the .asd file in the file system. In the current implementation,
a HyperDoc unit is realized as a real ASDF system in a version-controlled
repository. The directory contains both the text pages (in HTML or Markdown
format) and the source code files, which must be loaded as a module in the
system component list. In other words, a HyperDoc is not outside the ASDF
model: it lives inside a real ASDF system, under a real module, with real
file ordering and loading rules. HyperDoc is therefore a standard Common Lisp
software package with added conventions for organizing non-code media.

See for example the <a expr="(asdf:system-relative-pathname
&quot;hyperdoc&quot; &quot;hyperdoc/&quot;)">directory for the
HyperDoc you are looking at</a>, and the <a
expr="(asdf:system-source-file &quot;hyperdoc&quot;)">system
definition file</a> that lists the module "hyperdoc" among its
components.

For the conceptual model behind that arrangement, see
<a page="Understanding ASDF Systems in HyperDoc">Understanding ASDF Systems in HyperDoc</a>.

The source code files in the ASDF module should be loaded serially, in
order to ensure that the order in which the source code files are
listed in the <a expr="*hyperdoc*" view="Code">Code view</a>
corresponds to the order in which they have been loaded by ASDF.

The title of the HyperDoc is defined in the call to <a
expr="#'make-hyperdoc">`make-hyperdoc`</a>. See the definition of <a
expr="(html-inspector-views/standard:var-definition '*hyperdoc*)">`*hyperdoc*`</a> for an example.

An ASDF system can contain any number of HyperDocs, but in most cases
a single one is sufficient.

The repository [hyperdoc-template](https://codeberg.org/khinsen/hyperdoc-template) is a convenient starting point for creating a HyperDoc.
