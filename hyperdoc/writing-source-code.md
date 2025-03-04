# Writing HyperDoc source code files

<in-package>hyperdoc</in-package>

Source code files are standard Lisp files, which however need to respect a few conventions to be correctly integrated into a HyperDoc:

 - The first line of the file must be a comment. Its text, after stripping away
   leading semi-colons and whitespace, becomes the title displayed in the
   <a hyperdoc="HyperDoc" view="Code">source code file list</a>, which is also
   what you can use in the `page` attribute of a link (see above).

 - Each source code file must start with an `in-package` form, to ensure that the
   HyperDoc parser correctly inteprets symbol.

 - Use of non-standard reader macros should be avoided, because the HyperDoc parser
   is not aware of them.

## Links in code

Links can be inserted anywhere at the toplevel of a code file, using the macro <a expr="(macro-function 'see)">`see`</a>. This macro has no effect
on the loaded code. It is detected by the HyperDoc parser in a source code view,
which renderes the macro's argument with a link to the value of the argument.

For links to pages or HyperDocs, use functions <a
expr="#'page">`page`</a> and <a
expr="#'hyperdoc">`hyperdoc`</a> in the argument to <a
expr="(macro-function 'see)">`see`</a>.

## Examples

Code examples can be written using <a expr="(macro-function
'defexample)">`defexample`</a>, which is equivalent to `defun` except
that is takes no argument list, because examples don't take arguments.

Examples are rendered with a play button before the `defexample`
form. Clicking on that button runs the example and opens its result in
a new pane.

See <a expr="#'the-answer">this example</a> as an example.
