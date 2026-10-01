# Shared dependency closure for development and the Catalog executable.
{ pkgs, sources, commonLispHyperSpec }:
{
  sbcl = pkgs.sbcl.withPackages (
    ps:
    with ps; [
      alexandria
      ps.arrow-macros
      babel
      bordeaux-threads
      cffi
      ps."cl-base32"
      ps."cl-base64"
      ps."cl-slug"
      ps."clack-handler-hunchentoot"
      ps."clog-ace"
      cl-who
      clog
      ps."closer-mop"
      dissect
      ps."damn-fast-stable-priority-queue"
      drakma
      ps."eclector-concrete-syntax-tree"
      flexi-streams
      fset
      ps."local-time"
      lquery
      iterate
      jzon
      plump
      puri
      ps."s-graphviz"
      serapeum
      sha1
      shasht
      str
      swank
      ps."trivial-clipboard"
      ps."trivial-cltl2"
      ps."trivial-package-local-nicknames"
      usocket
      ps._3bmd
      ps._3bmd-ext-code-blocks
    ]
  );
  sourceRegistry = "${sources.clog-moldable-inspector}//:${sources.html-inspector-views}//:${sources.plump-inspector-views}//:${sources.lwcells}//:${sources.named-closure}//:${sources.njson}//:${sources.shop3}/shop3//:${sources.shop3-pddl-tools}//:${sources.shop3-fiveam-asdf}//:${sources.shop3-random-state}//:${sources.shop3-documentation-utils}//:${sources.shop3-trivial-indent}//:${sources.shop3-trivial-garbage}//:${sources.shop3-iterate}//";
  hyperspecRoot = "${commonLispHyperSpec}/share/common-lisp-hyperspec/HyperSpec";
}
