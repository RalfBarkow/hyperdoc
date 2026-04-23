# Writing text pages

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

## Page lifecycle and communication

In this project, many pages are created first as communication artifacts
between collaborators. Their first purpose is to capture proposals,
feedback, and decisions in a form that can be linked, reviewed, and
revised.

When a page stabilizes, extract its durable parts into:

 - developer-facing architecture or workflow documentation in HyperDoc,
 - operational guidance for assistants (for example in `AGENTS.md`).

This means pages like "Where This Functionality Belongs" are valid and
useful even when they are narrow in scope: they support active
collaboration first, and can later be consolidated into broader
reference material.

There is also a second relation to FedWiki working pages: topics can be
mirrored or linked to localhost FedWiki pages in
`/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages` when journaling and rapid
collaborative editing are needed. See
<a page="Communication Surfaces Policy">Communication Surfaces Policy</a>.

### Connected communication surfaces

HyperDoc pages and localhost FedWiki pages are two surfaces for the same
collaboration, with different strengths:

 - HyperDoc is the stable, inspectable reference surface for concepts,
   architecture, and implementation context.
 - localhost FedWiki is the fast, journaled working surface for
   day-to-day iteration, notes, and collaborative edits.

The connection is topic-based. For important topics, keep both surfaces
reachable by links or counterparts, so readers can move between durable
reference and active working history.

Use this practical rule:

 - if the content is still moving quickly, start or continue in FedWiki;
 - if the content has stabilized enough to guide implementation, ensure a
   HyperDoc page exists;
 - when both exist, keep titles and links aligned, but do not force
   identical markup or identical structure.

## Page genres: reference vs walkthrough example

Classify page intent before drafting:

- `Reference/contract page` for definitions, contracts, inventories,
  architecture summaries, and browseable inspectable-object indexes.
- `Walkthrough example page` for story-driven demonstrations, click-through
  learning, and before/after operational workflows.

If a task asks for an `example page`, default to a walkthrough example page.
Do not answer with a reference/index page that only lists object links.

### Walkthrough example page pattern

Use this compact structure:

- `Goal`
- `Starting situation`
- `Step 1`, `Step 2`, ...
- `Expected result` and/or `Why this matters`
- `Boundary`

Each step should include:

- `Click:` what to open or run
- `Observe:` what to notice
- `Why this matters:` what that observation proves

Narrative arc:

- start state
- inspect cause
- inspect derivation
- act / mutate / run
- observe changed result
- explain significance

For mutation/rewrite/debug walkthroughs, make `before -> cause -> action ->
after` explicit.

HyperDoc-specific rule:
- clickable `expr` links alone do not make a good example page; examples must
  be staged as actions with observations and consequences.

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
   &quot;hyperdoc&quot;)">here</a> for an example. If the `<a>` element
   has no children (e.g. `<a expr="nil"/>`), the link text is the
   text representation of the object being linked to.

For consistency, prefer this default text-representation behavior over
custom display overrides. Policy: remove the `:display` argument and rely
on the object's text representation.

 - A `view` attribute names a specific view to be selected in the
   panel for the link destination. See <a expr="(asdf:find-system
   &quot;hyperdoc&quot;)" view="Dependency graph">here</a> for an
   example.  The view attribute must be combined with one of `page`,
   `hyperdoc`, or `expr`.

The `expr` attribute has Lisp code as its value. Since HTML attributes
may not contain raw double quotes, encode Lisp string quotes as
`&quot;` inside the attribute value.

Do not use backslash-escaped quotes (`\"`) inside HTML `expr`
attributes. Use:

`expr="(hyperdoc::trim-whitespace-string &quot;string-arg&quot;)"`

## Computed text

The custom tag `value-of` permits embedding the text representation (as defined by the function <a expr="#'html-inspector-views:text-representation">`text-representation`</a>) of a value computed from an expression. The expression is the text content of the tag. It is displayed when the mouse hovers over the rendered tag, whose text is underlined with a dotted line.

When using this tag in Markdown, watch out for parts of the Lisp code being interpreted as Markdown markup. In particular, the ear-muff convention for special variables is interpreted as italic. Asterisks therefore need to be written as `&#42;`.

## Computed HTML code

The custom tag `html-expr` permits inserting HTML code that is computed. The text content of the tag is evaluated and the result replaces the `html-expr` element.

## View transclusions

The custom tag `view-transclusion` has a Lisp expression as its text content. Its value must be an instance of <a expr="(find-class 'html-inspector-views:html-view)">`html-inspector-views:html-view`</a>. The HTML code corresponding to that view is inserted at the point of transclusion.

As an example, this is the <a expr="#'html-inspector-views:👀items">items view</a> of the vector <a expr="#(:a :b)"/>:

<view-transclusion>(html-inspector-views:👀items #(:a :b))</view-transclusion>

When using this tag in Markdown, watch out for parts of the Lisp code being interpreted as Markdown markup. In particular, the ear-muff convention for special variables is interpreted as italic. Asterisks therefore need to be written as `&#42;`.

### Source code transclusions

There are two custom tags for facilitating a particularly frequent kind of transclusion: the insertion of Lisp source code into a page.

 - `source-of-function` inserts the source code of the function named by the
   tag's text content.

 - `source-of-class` inserts the source code of the class named by the
   tag's text content.

As an example, this is the source code of the <a expr="(find-class 'hyperdoc)">class <code>hyperdoc</code></a>:

<source-of-class>hyperdoc</source-of-class>

### Lisp code

Source code transclusions can be used only for functions and classes that have already been added to the image. An element with tag `<lisp-code>` inserts arbitrary Lisp code with syntax highlighting, but without loading it. An optional attribute `package` specifies the name of the package in which the code should be parsed, the default is the package set by the last preceding `<in-package>` element.

## Lisp code generating HTML code

An element with tag `html-generator` is rendered by evaluating its text
as Lisp code. See <a page="Forms" hyperdoc="moldable-inspector">this page</a>
for examples. The Lisp code should follow the principles outlined in
<a page="Defining custom views" hyperdoc="moldable-inspector">the inspector tutorial</a>,
which implies calling functions from the libraries <a expr="(asdf:find-system :html-inspector-views)"><tt>html-inspector-views</tt></a> and <a expr="(asdf:find-system :cl-who)"><tt>cl-who</tt></a>.
