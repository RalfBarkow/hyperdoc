# DMX Projection Idempotency Confirmed

This page records the operational path from a broken Portacle/SLIME setup to a reproducible DMX projection workflow for one HyperDoc conceptual topic.

## Goal

Reach this terminal state without creating duplicate DMX topics:

```lisp
(:STATE :DMX-PROJECTION-IDEMPOTENCY-CONFIRMED
 :PROJECTION-TOPIC-ID 954435
 :URI "hyperdoc:topic/demokratische-praxis-als-infrastrukturfrage"
 :TOPIC-ACTION :UPDATE
 :TOPICMAP-ACTION :ALREADY-PRESENT
 :MUTATION-PERFORMED NIL
 :MUTATION-ALLOWED NIL)
```

The important property is not that the final run performs a mutation. It must not. The important property is that lookup-before-create resolves the existing projection by deterministic URI, chooses `:UPDATE` rather than `:CREATE`, observes that the topic is already present in the target topicmap, and then stops at the operator guard because mutation is disabled.

## Durable coordinates

```lisp
(defparameter *annotation-topic-id* 936040)
(defparameter *workspace-id* 919815)
(defparameter *topicmap-id* 919822)
(defparameter *expected-title*
  "Annotation: An active/alive pair is two agents connected by principal ports.")
```

The conceptual-topic projection created during this run has these coordinates:

```lisp
(defparameter *democratic-practice-topic-uri*
  "hyperdoc:topic/demokratische-praxis-als-infrastrukturfrage")

(defparameter *democratic-practice-projection-topic-id*
  954435)
```

## Narrative summary

Portacle was abandoned for this workflow. The supported control surface is the
Nix-managed HyperDoc SBCL image connected through SLY. The Portacle material below
is retained only as historical failure evidence.

First, Portacle's bundled SBCL and Quicklisp stack were not suitable for the current HyperDoc dependency graph. Updating Quicklisp brought in a current CFFI which failed in Portacle's old SBCL image while compiling `src/cffi-sbcl.lisp`, because `SB-ALIEN:DEFINE-ALIEN-CALLABLE` was not present in that image.

Second, connecting a mismatched SLIME client to a different SWANK server caused unstable behavior: hangs, process-filter errors, and version mismatch prompts. The solution was to stop using Portacle as the live Lisp image. Portacle or Spacemacs can be an editor, but the running Lisp image must be the Nix-managed HyperDoc SBCL image.

The flake/dev-shell path then established a matching client/server setup. The dev shell provides `hyperdoc-slime-connect` and `hyperdoc-sly-connect`; these are wrapper commands supplied by the flake, not random global commands. For this run, SLY was the smoother path:

```sh
LISP_IDE=sly ./dev.sh
```

The dev launcher printed a Slynk port, for example:

```text
Slynk: 127.0.0.1:58705
Emacs: M-x sly-connect  127.0.0.1  58705
```

The connected `*sly-mrepl for sbcl*` then confirmed the correct runtime:

```lisp
(list
 :implementation (lisp-implementation-type)
 :version (lisp-implementation-version)
 :directory (uiop:getcwd)
 :swank (asdf:component-pathname (asdf:find-system :swank)))
```

Observed shape:

```lisp
(:IMPLEMENTATION "SBCL"
 :VERSION "2.4.10"
 :DIRECTORY #P"/Users/rgb/workspace/hyperdoc/"
 :SWANK #P"/nix/store/...-sbcl-swank-2.29.1/")
```

The important runtime state was then reached:

```lisp
(progn
  (require :asdf)
  (asdf:load-system :hyperdoc/dmx-import)

  (defparameter *annotation-topic-id* 936040)
  (defparameter *workspace-id* 919815)
  (defparameter *topicmap-id* 919822)
  (defparameter *expected-title*
    "Annotation: An active/alive pair is two agents connected by principal ports.")

  (list
   :state :dmx-control-surface-ready
   :loaded :hyperdoc/dmx-import
   :annotation-topic-id *annotation-topic-id*
   :workspace-id *workspace-id*
   :topicmap-id *topicmap-id*
   :mutation-allowed nil))
```

Expected state:

```lisp
(:STATE :DMX-CONTROL-SURFACE-READY
 :LOADED :HYPERDOC/DMX-IMPORT
 :ANNOTATION-TOPIC-ID 936040
 :WORKSPACE-ID 919815
 :TOPICMAP-ID 919822
 :MUTATION-ALLOWED NIL)
```

## Authentication model

The DMX client must be constructed explicitly. Do not depend on implicit environment lookup while repairing a live projection.

DMX accepts an Authorization header using a custom scheme such as `DMX ...`. Therefore the client construction uses a header of the form:

```text
Authorization: DMX <base64(username:token-or-password)>
```

The token or password must be provided locally by the operator. Do not persist the secret in the HyperDoc page, shell history, or Git repository.

```lisp
(defun dmx-base64-credentials (username token-or-password)
  "Return base64(username:token-or-password)."
  (let* ((plain (format nil "~A:~A" username token-or-password))
         (octets (babel:string-to-octets plain :encoding :utf-8)))
    (cl-base64:usb8-array-to-base64-string octets)))

(defun make-explicit-dmx-authorization-header
    (&key (scheme "DMX") username token-or-password)
  (unless (and username token-or-password)
    (error "USERNAME and TOKEN-OR-PASSWORD are required."))
  (format nil "~A ~A"
          scheme
          (dmx-base64-credentials username token-or-password)))
```

Create the client explicitly:

```lisp
(defparameter *dmx-username* "mcp")
(defparameter *dmx-token-or-password* "PASTE_SECRET_HERE")

(defparameter *dmx-client*
  (make-instance 'hyperdoc::http-dmx-import-client
                 :base-url "https://dmx.ralfbarkow.ch"
                 :workspace-id 919815
                 :authorization-header
                 (make-explicit-dmx-authorization-header
                  :scheme "DMX"
                  :username *dmx-username*
                  :token-or-password *dmx-token-or-password*)))

(list
 :state :dmx-custom-auth-client-ready
 :loaded :hyperdoc/dmx-import
 :base-url (hyperdoc::dmx-import-base-url-of *dmx-client*)
 :workspace-id (hyperdoc::dmx-import-workspace-id-of *dmx-client*)
 :auth-scheme "DMX"
 :username *dmx-username*
 :token-present (and *dmx-token-or-password* t)
 :authorization-header-prefix "DMX "
 :has-auth-header
 (not (null (hyperdoc::dmx-import-authorization-header-of *dmx-client*)))
 :annotation-topic-id *annotation-topic-id*
 :topicmap-id *topicmap-id*
 :mutation-allowed nil)
```

Expected shape:

```lisp
(:STATE :DMX-CUSTOM-AUTH-CLIENT-READY
 :LOADED :HYPERDOC/DMX-IMPORT
 :BASE-URL "https://dmx.ralfbarkow.ch"
 :WORKSPACE-ID 919815
 :AUTH-SCHEME "DMX"
 :USERNAME "mcp"
 :TOKEN-PRESENT T
 :AUTHORIZATION-HEADER-PREFIX "DMX "
 :HAS-AUTH-HEADER T
 :ANNOTATION-TOPIC-ID 936040
 :TOPICMAP-ID 919822
 :MUTATION-ALLOWED NIL)
```

Confirm authenticated read access before attempting mutation:

```lisp
(let ((topic (hyperdoc::dmx-import-read-topic *dmx-client* *annotation-topic-id*)))
  (list
   :state :dmx-authenticated-read-ok
   :topic-id *annotation-topic-id*
   :topic-object-type (type-of topic)
   :mutation-allowed nil))
```

Expected shape:

```lisp
(:STATE :DMX-AUTHENTICATED-READ-OK
 :TOPIC-ID 936040
 :TOPIC-OBJECT-TYPE HASH-TABLE
 :MUTATION-ALLOWED NIL)
```

## Projection source chain

The source chain for the conceptual topic is:

```text
FedWiki story item paragraph id:
  8eb7143d5ca33d68

Conceptual topic:
  demokratische-praxis-als-infrastrukturfrage

Lisp factory symbol:
  DEMOKRATISCHE-PRAXIS-ALS-INFRASTRUKTURFRAGE-TOPIC

Factory call:
  (DEMOKRATISCHE-PRAXIS-ALS-INFRASTRUKTURFRAGE-TOPIC)

Produced object:
  a HyperDoc topic describing the democratic-practice-as-infrastructure concept

DMX projection URI:
  hyperdoc:topic/demokratische-praxis-als-infrastrukturfrage
```

The URI is deterministic. It is the lookup-before-create key.

```lisp
(defparameter *democratic-practice-projection-spec*
  '(:uri "hyperdoc:topic/demokratische-praxis-als-infrastrukturfrage"
    :conceptual-topic-id "demokratische-praxis-als-infrastrukturfrage"
    :title "Demokratische Praxis als Infrastrukturfrage"
    :summary "DMX projection of the HyperDoc topic demokratische-praxis-als-infrastrukturfrage."
    :fedwiki-paragraph-id "8eb7143d5ca33d68"
    :factory-symbol "DEMOKRATISCHE-PRAXIS-ALS-INFRASTRUKTURFRAGE-TOPIC"
    :factory-call "(DEMOKRATISCHE-PRAXIS-ALS-INFRASTRUKTURFRAGE-TOPIC)"
    :workspace-id 919815
    :topicmap-id 919822))
```

## Functions for reproducible lookup-before-create

The following functions implement the local operator surface used in the run. They plan first, block by default, and mutate only when `:mutation-allowed t` is explicitly supplied.

```lisp
(defun projection-spec-get (spec key)
  (getf spec key))

(defun projection-spec-uri (spec)
  (or (projection-spec-get spec :uri)
      (format nil "hyperdoc:topic/~A"
              (projection-spec-get spec :conceptual-topic-id))))

(defun make-hyperdoc-projection-text (spec)
  (format nil "HyperDoc → DMX projection~%~%
Conceptual topic: ~A~%
FedWiki story item paragraph id: ~A~%
Lisp factory symbol: ~A~%
Factory call: ~A~%
Produced object: a HyperDoc topic describing the democratic-practice-as-infrastructure concept~%~%
Summary: ~A~%"
          (projection-spec-get spec :conceptual-topic-id)
          (projection-spec-get spec :fedwiki-paragraph-id)
          (projection-spec-get spec :factory-symbol)
          (projection-spec-get spec :factory-call)
          (projection-spec-get spec :summary)))

(defun make-hyperdoc-projection-children (spec)
  (let ((children (make-hash-table :test #'equal)))
    (setf (gethash "dmx.notes.title" children)
          (projection-spec-get spec :title)
          (gethash "dmx.notes.text" children)
          (make-hyperdoc-projection-text spec))
    children))

(defun make-hyperdoc-projection-payload (spec)
  (let ((uri (projection-spec-uri spec)))
    (list :uri uri
          :external-key uri
          :type-uri "dmx.notes.note"
          :value (projection-spec-get spec :title)
          :children (make-hyperdoc-projection-children spec))))

(defun make-hyperdoc-projection-view-props
    (&key (x 1600) (y 1200) (visibility t) (pinned nil))
  (let ((view-props (make-hash-table :test #'equal)))
    (setf (gethash "dmx.topicmaps.x" view-props) x
          (gethash "dmx.topicmaps.y" view-props) y
          (gethash "dmx.topicmaps.visibility" view-props) visibility
          (gethash "dmx.topicmaps.pinned" view-props) pinned)
    view-props))

(defun dmx-object-id (object)
  (hyperdoc::dmx-import-object-id object))

(defun dmx-projection-write-plan (client spec)
  (let* ((uri (projection-spec-uri spec))
         (workspace-id (projection-spec-get spec :workspace-id))
         (topicmap-id (projection-spec-get spec :topicmap-id))
         (payload (make-hyperdoc-projection-payload spec))
         (existing-topic
           (hyperdoc::dmx-import-find-existing-topic client uri))
         (existing-topic-id (and existing-topic
                                 (dmx-object-id existing-topic)))
         (in-topicmap-p
           (and existing-topic-id
                (hyperdoc::dmx-import-topic-in-topicmap-p
                 client topicmap-id existing-topic-id))))
    (multiple-value-bind (normalized-view-props view-props-normalization)
        (hyperdoc::normalize-dmx-topicmap-view-props
         (make-hyperdoc-projection-view-props)
         :boundary 'dmx-projection-write-plan)
      (list
       :state :dmx-projection-write-plan-ready
       :uri uri
       :workspace-id workspace-id
       :topicmap-id topicmap-id
       :topic-action (if existing-topic :update :create)
       :topicmap-action (if in-topicmap-p :already-present :add)
       :existing-topic-id existing-topic-id
       :existing-topic-present-p (not (null existing-topic))
       :existing-topic existing-topic
       :payload payload
       :view-props normalized-view-props
       :view-props-normalization view-props-normalization
       :spec spec
       :mutation-allowed nil))))

(defun ensure-dmx-projection-for-hyperdoc-topic
    (client spec &key (mutation-allowed nil))
  (let* ((plan (dmx-projection-write-plan client spec))
         (topic-action (getf plan :topic-action))
         (topicmap-action (getf plan :topicmap-action))
         (topicmap-id (getf plan :topicmap-id))
         (payload (getf plan :payload))
         (existing-topic (getf plan :existing-topic))
         (view-props (getf plan :view-props)))
    (unless mutation-allowed
      (return-from ensure-dmx-projection-for-hyperdoc-topic
        (list
         :state :dmx-projection-write-blocked-by-operator-guard
         :reason "Plan is ready, but mutation-allowed is NIL."
         :plan plan
         :mutation-performed nil
         :mutation-allowed nil)))
    (let* ((topic
             (ecase topic-action
               (:create
                (hyperdoc::dmx-import-create-topic client payload))
               (:update
                (hyperdoc::dmx-import-update-topic client existing-topic payload))))
           (topic-id (dmx-object-id topic)))
      (unless topic-id
        (error "DMX projection write returned no topic id."))
      (ecase topicmap-action
        (:add
         (hyperdoc::dmx-import-add-topic-to-topicmap
          client topicmap-id topic-id view-props))
        (:already-present
         nil))
      (list
       :state :dmx-projection-ensure-complete
       :plan plan
       :result
       (list
        :state :dmx-projection-write-complete
        :mutation-performed t
        :topic-id topic-id
        :uri (getf plan :uri)
        :workspace-id (getf plan :workspace-id)
        :topicmap-id topicmap-id
        :topic-action topic-action
        :topicmap-action
        (if (eq topicmap-action :add) :present :already-present))
       :mutation-allowed t))))
```

## Human check before mutation

Always run the plan with mutation disabled before the first write:

```lisp
(defparameter *dmx-projection-plan-check*
  (ensure-dmx-projection-for-hyperdoc-topic
   *dmx-client*
   *democratic-practice-projection-spec*
   :mutation-allowed nil))

*dmx-projection-plan-check*
```

Before the topic existed, the plan was expected to say:

```lisp
:TOPIC-ACTION :CREATE
:TOPICMAP-ACTION :ADD
:EXISTING-TOPIC-ID NIL
:MUTATION-PERFORMED NIL
:MUTATION-ALLOWED NIL
```

The human-readable content was:

```lisp
(:STATE :DMX-PROJECTION-PLAN-HUMAN-CHECK
 :TOPIC-ACTION :CREATE
 :TOPICMAP-ACTION :ADD
 :PAYLOAD
 (:URI "hyperdoc:topic/demokratische-praxis-als-infrastrukturfrage"
  :EXTERNAL-KEY "hyperdoc:topic/demokratische-praxis-als-infrastrukturfrage"
  :TYPE-URI "dmx.notes.note"
  :VALUE "Demokratische Praxis als Infrastrukturfrage")
 :PAYLOAD-CHILDREN
 (("dmx.notes.title" . "Demokratische Praxis als Infrastrukturfrage")
  ("dmx.notes.text" . "HyperDoc → DMX projection ..."))
 :VIEW-PROPS
 (("dmx.topicmaps.x" . 1600)
  ("dmx.topicmaps.y" . 1200)
  ("dmx.topicmaps.visibility" . T)
  ("dmx.topicmaps.pinned")))
```

## One intentional mutation

After the plan was inspected, one explicit mutation was allowed:

```lisp
(defparameter *dmx-projection-write-result*
  (ensure-dmx-projection-for-hyperdoc-topic
   *dmx-client*
   *democratic-practice-projection-spec*
   :mutation-allowed t))

*dmx-projection-write-result*
```

Observed result:

```lisp
(:STATE :DMX-PROJECTION-ENSURE-COMPLETE
 :RESULT
 (:STATE :DMX-PROJECTION-WRITE-COMPLETE
  :MUTATION-PERFORMED T
  :TOPIC-ID 954435
  :URI "hyperdoc:topic/demokratische-praxis-als-infrastrukturfrage"
  :WORKSPACE-ID 919815
  :TOPICMAP-ID 919822
  :TOPIC-ACTION :CREATE
  :TOPICMAP-ACTION :PRESENT)
 :MUTATION-ALLOWED T)
```

This is the only run in the sequence that should use `:mutation-allowed t`.

## Idempotency readback

Immediately after the write, run again with mutation disabled:

```lisp
(defparameter *dmx-projection-readback-result*
  (ensure-dmx-projection-for-hyperdoc-topic
   *dmx-client*
   *democratic-practice-projection-spec*
   :mutation-allowed nil))

*dmx-projection-readback-result*
```

Observed result:

```lisp
(:STATE :DMX-PROJECTION-WRITE-BLOCKED-BY-OPERATOR-GUARD
 :REASON "Plan is ready, but mutation-allowed is NIL."
 :PLAN
 (:STATE :DMX-PROJECTION-WRITE-PLAN-READY
  :URI "hyperdoc:topic/demokratische-praxis-als-infrastrukturfrage"
  :WORKSPACE-ID 919815
  :TOPICMAP-ID 919822
  :TOPIC-ACTION :UPDATE
  :TOPICMAP-ACTION :ALREADY-PRESENT
  :EXISTING-TOPIC-ID 954435
  :EXISTING-TOPIC-PRESENT-P T)
 :MUTATION-PERFORMED NIL
 :MUTATION-ALLOWED NIL)
```

This blocked state is the success signal for idempotency. It means that lookup-before-create found the existing deterministic URI and therefore no duplicate topic would be created.

## Final proof expression

```lisp
(list
 :state :dmx-projection-idempotency-confirmed
 :projection-topic-id
 (getf (getf *dmx-projection-readback-result* :plan) :existing-topic-id)
 :uri
 (getf (getf *dmx-projection-readback-result* :plan) :uri)
 :topic-action
 (getf (getf *dmx-projection-readback-result* :plan) :topic-action)
 :topicmap-action
 (getf (getf *dmx-projection-readback-result* :plan) :topicmap-action)
 :mutation-performed
 (getf *dmx-projection-readback-result* :mutation-performed)
 :mutation-allowed
 (getf *dmx-projection-readback-result* :mutation-allowed))
```

Expected final state:

```lisp
(:STATE :DMX-PROJECTION-IDEMPOTENCY-CONFIRMED
 :PROJECTION-TOPIC-ID 954435
 :URI "hyperdoc:topic/demokratische-praxis-als-infrastrukturfrage"
 :TOPIC-ACTION :UPDATE
 :TOPICMAP-ACTION :ALREADY-PRESENT
 :MUTATION-PERFORMED NIL
 :MUTATION-ALLOWED NIL)
```

## SCXML-style state narration

```text
initial
  → portacle_swank_invalid
  → nix_managed_lisp_required
  → matching_sly_slynk_control_surface
  → dmx_control_surface_ready
  → dmx_custom_auth_client_ready
  → dmx_authenticated_read_ok
  → projection_spec_defined
  → deterministic_uri_lookup
  → first_plan_create_add_blocked_by_guard
  → operator_allows_single_mutation
  → dmx_projection_created_topic_954435
  → second_plan_update_already_present_blocked_by_guard
  → dmx_projection_idempotency_confirmed
```

The final invariant is:

```text
The URI hyperdoc:topic/demokratische-praxis-als-infrastrukturfrage resolves to DMX topic 954435, and the target topicmap 919822 already contains that topic. Future guarded runs must plan UPDATE / ALREADY-PRESENT, not CREATE / ADD.
```

## Operational rule

Use `:mutation-allowed nil` for all normal verification runs. Use `:mutation-allowed t` only after a human has inspected the plan and the intended operation is exactly one of:

```lisp
(:TOPIC-ACTION :CREATE :TOPICMAP-ACTION :ADD)
(:TOPIC-ACTION :UPDATE :TOPICMAP-ACTION :ALREADY-PRESENT)
```

For this specific run, the one creation has already happened. Therefore the safe steady-state check is now:

```lisp
(ensure-dmx-projection-for-hyperdoc-topic
 *dmx-client*
 *democratic-practice-projection-spec*
 :mutation-allowed nil)
```

and the expected plan is:

```lisp
:TOPIC-ACTION :UPDATE
:TOPICMAP-ACTION :ALREADY-PRESENT
:EXISTING-TOPIC-ID 954435
:MUTATION-PERFORMED NIL
```
