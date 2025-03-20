# Writing HyperDoc text pages

<in-package>hyperdoc</in-package>

Pages can be written in HTML (extension `.html`) or Markdown
(extension `.md`). Markdown pages are converted to HTML and then
processed just like HTML pages. HyperDoc extends HTML using custom
tags and non-standard attributes for standard tags.

## Embedded code

Some of the HyperDoc extensions use Lisp expressions that are <a
expr="#'parse-and-eval">parsed and evaluated</a>. Expressions are
parsed in the context of the current package (special variable
`cl:*package*`), which can be set using the custom tag `<in-package>`
that has the same function as the special form `in-package` in Lisp
code. See <a page="Creating a HyperDoc" view="Source">the Markdown
file for this page</a> for an example.

## Links

Links are written using standard `<a>` tags, using non-standard
attributes for HyperDoc-specific links:

 - A `page` attribute contains the title of a page or source code file
   in the HyperDoc named by a `hyperdoc` attribute, or in the current
   HyperDoc if no `hyperdoc` attribute is given.

 - A `hyperdoc` attribute contains the title of a HyperDoc, which becomes
   the destination of the link, unless a `page` attribute is present as
   well (see above).

 - An `expr` attribute contains a Lisp expression whose value is the
   destination of the link. See <a expr="(asdf:find-system
   &quot;hyperdoc&quot;)">here</a> for an example.

 - A `view` attribute names a specific view to be selected in the
   panel for the link destination. See <a expr="(asdf:find-system
   &quot;hyperdoc&quot;)" view="Dependency graph">here</a> for an
   example.  The view attribute must be combined with one of `page`,
   `hyperdoc`, or `expr`.

The `expr` attribute has Lisp code as its value. Since HTML attributes
may not contain quotes, you have to write `&quot` instead if you have
string literals in your expression.

## Computed text

The custom tag `value-of` permits embedding the text representation (as defined by the function <a expr="#'html-inspector-views:text-representation">`text-representation`</a>) of a value computed from an expression. The expression is the text content of the tag. It is displayed when the mouse hovers over the rendered tag, whose text is underlined with a dotted line.

When using this tag in Markdown, watch out for parts of the Lisp code being interpreted as Markdown markup. In particular, the ear-muff convention for special variables is interpreted as italic. Asterisks therefore need to be written as `&#42;`.

## View transclusions

The custom tag `view-transclusion` has a Lisp expression as its text content. Its value must be an instance of <a expr="(find-class 'html-inspector-views:html-view)">`html-inspector-views:html-view`</a>. The HTML code corresponding to that view is inserted at the point of transclusion.

As an example, this is the <a expr="#'👀items">items view</a> of the vector <a expr="#(1 2)">`#(1 2)`</a>:

<view-transclusion>(👀items #(1 2))</view-transclusion>

When using this tag in Markdown, watch out for parts of the Lisp code being interpreted as Markdown markup. In particular, the ear-muff convention for special variables is interpreted as italic. Asterisks therefore need to be written as `&#42;`.

### Source code transclusions

There are two custom tags for facilitating a particularly frequent kind of transclusion: the insertion of Lisp source code into a page.

 - `source-of-function` inserts the source code of the function named by the
   tag's text content.

 - `source-of-class` inserts the source code of the class named by the
   tag's text content.

As an example, this is the source code of the <a expr="(find-class 'hyperdoc)">class <code>hyperdoc</code></a>:

<source-of-class>hyperdoc</source-of-class>
