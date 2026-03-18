# Make the **issue repair function disappear as the primary abstraction**

The primary abstraction should be:

* **chunks**
* **dependencies**
* **derivers**
* **managed vs dormant state**
* **verification as chunk freshness**, not ad-hoc post-check

That is the declarative shift McDermott argues for: the system should know **what must be true**, **what depends on what**, and **how each chunk is rederived**. 

Below is the shape I would use for HyperDoc.

---

# 1. Replace “repair function” with chunk types

Your current function mixes four different concerns:

* issue interpretation
* topic ontology construction
* page materialization
* reload / verification

Those should become distinct chunk classes.

## Core chunk classes

```lisp
(defclass hd-chunk ()
  ((id :initarg :id :reader chunk-id)
   (managed-p :initarg :managed-p :initform t :accessor managed-p)
   (last-derived-at :initarg :last-derived-at :initform nil :accessor last-derived-at)))

(defgeneric chunk-basis (chunk)
  (:method ((chunk hd-chunk)) nil))

(defgeneric chunk-update-basis (chunk)
  (:method ((chunk hd-chunk)) nil))

(defgeneric derive-chunk (chunk)
  (:documentation "Bring CHUNK up to date. Return NIL if unchanged,
or a positive timestamp if changed."))

(defgeneric derive-date (chunk)
  (:documentation "Return known derivation date, NIL if unchanged/unknown,
or a distinguished no-info marker if derivation is required.")
  (:method ((chunk hd-chunk))
    (last-derived-at chunk)))

(defgeneric chunk-up-to-date-p (chunk))
```

This gives you the McDermott vocabulary directly:

* **basis** = conjunctive dependency set
* **update basis** = transient dependencies needed during rederivation
* **derive-chunk** = deriver

---

# 2. Model the HyperDoc domain as chunks

For your missing-topic case, I would use at least these chunk types:

## Topic-definition chunk

Represents:

> “The topic handle exists in the topic registry.”

```lisp
(defclass topic-definition-chunk (hd-chunk)
  ((title :initarg :title :reader topic-title)
   (handle :initarg :handle :reader topic-handle)))
```

## Topic-page chunk

Represents:

> “The HyperDoc page file for this topic exists with canonical structure.”

```lisp
(defclass topic-page-chunk (hd-chunk)
  ((title :initarg :title :reader topic-title)
   (pathname :initarg :pathname :reader topic-page-pathname)))
```

## FedWiki-twin chunk

Represents:

> “The FedWiki counterpart for this topic exists.”

```lisp
(defclass fedwiki-topic-twin-chunk (hd-chunk)
  ((title :initarg :title :reader topic-title)
   (slug :initarg :slug :reader fedwiki-slug)))
```

## Running-image-registration chunk

Represents:

> “The running Lisp image knows about the topic.”

```lisp
(defclass topic-image-registration-chunk (hd-chunk)
  ((title :initarg :title :reader topic-title)
   (handle :initarg :handle :reader topic-handle)))
```

---

# 3. Encode dependencies declaratively

Now the important part: express dependencies as methods, not scripts.

## Topic page depends on topic definition

```lisp
(defmethod chunk-basis ((chunk topic-page-chunk))
  (list (make-instance 'topic-definition-chunk
                       :id (list :topic-definition (topic-title chunk))
                       :title (topic-title chunk)
                       :handle (topic-handle-from-title (topic-title chunk)))))
```

## Running image registration depends on both topic definition and page

```lisp
(defmethod chunk-basis ((chunk topic-image-registration-chunk))
  (let* ((title (topic-title chunk))
         (handle (topic-handle chunk)))
    (list (make-instance 'topic-definition-chunk
                         :id (list :topic-definition title)
                         :title title
                         :handle handle)
          (make-instance 'topic-page-chunk
                         :id (list :topic-page title)
                         :title title
                         :pathname (topic-page-pathname-from-title title)))))
```

## FedWiki twin depends on topic page

```lisp
(defmethod chunk-basis ((chunk fedwiki-topic-twin-chunk))
  (list (make-instance 'topic-page-chunk
                       :id (list :topic-page (topic-title chunk))
                       :title (topic-title chunk)
                       :pathname (topic-page-pathname-from-title
                                  (topic-title chunk)))))
```

That is the real declarative move: the system no longer says “run these steps”; it says “this chunk depends on those chunks”.

---

# 4. Derivers become local and narrow

Each chunk knows only how to make **its own proposition** true.

## Topic definition deriver

```lisp
(defmethod derive-chunk ((chunk topic-definition-chunk))
  (if (topic-definition-present-p (topic-handle chunk))
      nil
      (progn
        (append-topic-definition-to-topics-file
         :title (topic-title chunk)
         :handle (topic-handle chunk))
        (get-universal-time))))
```

## Topic page deriver

```lisp
(defmethod derive-chunk ((chunk topic-page-chunk))
  (if (probe-file (topic-page-pathname chunk))
      nil
      (progn
        (write-canonical-topic-page
         :title (topic-title chunk)
         :pathname (topic-page-pathname chunk))
        (get-universal-time))))
```

## Running image registration deriver

This is where reload belongs. Not globally.

```lisp
(defmethod derive-chunk ((chunk topic-image-registration-chunk))
  (if (topic-registered-in-image-p (topic-handle chunk))
      nil
      (progn
        (reload-topic-registry)
        (get-universal-time))))
```

Now reload is not a generic cleanup step. It is the deriver for a specific chunk proposition:

> “the image registration is current”

That is much cleaner.

---

# 5. Use a generic coherence driver

You need one orchestrator that recursively derives bases first.

```lisp
(defgeneric ensure-chunk (chunk))

(defmethod ensure-chunk ((chunk hd-chunk))
  (when (managed-p chunk)
    (dolist (basis (chunk-basis chunk))
      (ensure-chunk basis))
    (dolist (basis (chunk-update-basis chunk))
      (ensure-chunk basis))
    (let ((changed-at (derive-chunk chunk)))
      (when changed-at
        (setf (last-derived-at chunk) changed-at))))
  chunk)
```

This is the McDermott engine in miniature.

---

# 6. Make issues point to chunks, not repairs

A page-lookup issue should not primarily say “suggested repair: scaffold topic”.

It should say:

* this issue witnesses failure of chunk `X`
* chunk `X` is not up to date
* here is the basis tree

Example:

```lisp
(defclass page-lookup-issue ()
  ((source-page :initarg :source-page :reader issue-source-page)
   (link-text :initarg :link-text :reader issue-link-text)
   (expected-page-id :initarg :expected-page-id :reader issue-expected-page-id)
   (target-chunk :initarg :target-chunk :reader issue-target-chunk)))
```

Then:

```lisp
(defun issue-target-topic-page-chunk (issue)
  (let ((title (or (issue-expected-page-id issue)
                   (issue-link-text issue))))
    (make-instance 'topic-page-chunk
                   :id (list :topic-page title)
                   :title title
                   :pathname (topic-page-pathname-from-title title))))
```

And repair becomes:

```lisp
(defun repair-issue (issue)
  (ensure-chunk (issue-target-chunk issue)))
```

That is declarative enough.

---

# 7. Keep “Needs topic” and “Needs materialization” as derived diagnoses

These should not be manually assigned first. They should be inferred from chunk state.

## Diagnosis functions

```lisp
(defun issue-needs-topic-p (issue)
  (let* ((title (or (issue-expected-page-id issue)
                    (issue-link-text issue)))
         (chunk (make-instance 'topic-definition-chunk
                               :id (list :topic-definition title)
                               :title title
                               :handle (topic-handle-from-title title))))
    (not (topic-definition-present-p (topic-handle chunk)))))

(defun issue-needs-materialization-p (issue)
  (let ((chunk (issue-target-topic-page-chunk issue)))
    (not (probe-file (topic-page-pathname chunk)))))
```

Now the UI tabs:

* **Needs topic**
* **Needs materialization**
* **Fixed**

become **views over chunk state**, not hand-maintained flags.

---

# 8. Add timestamps and freshness honestly

McDermott is specific that derivation is about freshness, not just existence. 

So don’t stop at `probe-file`.

Track dates for:

* `topics.lisp`
* topic page file
* loaded registry state in image
* FedWiki twin journal/page

Example:

```lisp
(defmethod derive-date ((chunk topic-page-chunk))
  (when-let ((file (probe-file (topic-page-pathname chunk))))
    (file-write-date file)))

(defmethod derive-date ((chunk topic-definition-chunk))
  (when-let ((file (probe-file #P"hyperdoc/topics.lisp")))
    (file-write-date file)))
```

Then `chunk-up-to-date-p` can compare basis dates to derived dates.

```lisp
(defmethod chunk-up-to-date-p ((chunk hd-chunk))
  (let ((my-date (derive-date chunk)))
    (and my-date
         (every (lambda (basis)
                  (let ((basis-date (derive-date basis)))
                    (and basis-date
                         (<= basis-date my-date))))
                (chunk-basis chunk)))))
```

That gives you actual coherence semantics instead of existence checks.

---

# 9. Minimal concrete slice for your case

For the specific missing topic page issue, the target chunk should probably be:

```lisp
(make-instance 'topic-image-registration-chunk
               :id (list :topic-image-registration "Running image coherence")
               :title "Running image coherence"
               :handle "running-image-coherence")
```

Why this one and not just page chunk?

Because your user-visible success condition is not merely:

* file exists

but:

* lookup in the running image resolves

So the top-level repair target should be the **running-image registration chunk**. Its basis naturally pulls in:

* topic definition
* topic page
* reload

That matches the actual operational truth.

---

# 10. What to delete from the current script-like version

Delete these as top-level orchestration concerns:

* `had-constructor`
* `had-page`
* manual sequencing
* generic `reload-hyperdoc`
* final ad-hoc `verify-repair`

Those all become consequences of:

* `chunk-basis`
* `derive-chunk`
* `derive-date`
* `ensure-chunk`

---

# 11. Resulting public API

Keep the API tiny:

```lisp
(defun issue->target-chunk (issue) ...)
(defun diagnose-issue (issue) ...)
(defun repair-issue (issue)
  (ensure-chunk (issue->target-chunk issue)))
```

And for the UI:

```lisp
(defun issue-status (issue)
  (if (chunk-up-to-date-p (issue->target-chunk issue))
      :fixed
      :open))
```

That is the properly declarative / chunk-based form.

---

# 12. Practical rule

A function is still too script-like if it says:

> first do A, then B, then C

It becomes chunk-based when it says:

> make proposition P true; P depends on Q and R; Q has its own deriver; R has its own deriver

That is the transformation you want.

If you want, I’ll turn this into a copy-pasteable Common Lisp file with:

* `defclass` forms,
* `ensure-chunk`,
* `topic-definition-chunk`,
* `topic-page-chunk`,
* `topic-image-registration-chunk`,
* and `repair-issue` wired to your lookup issue model.
