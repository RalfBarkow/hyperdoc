# Core Chunk Classes

[…] the “core chunk classes” are where the whole model either becomes real or stays conceptual.

What you have now is *almost right*, but still **too abstract / incomplete to execute coherence**.

Let’s tighten it into a **minimal but correct kernel** you can actually run.

---

# 1. What’s missing in your current “core chunk classes”

From your screenshot, you currently have:

```lisp
(defclass hd-chunk ()
  ((id ...)
   (managed-p ...)
   (last-derived-at ...)))

(defgeneric chunk-basis (chunk))
(defgeneric chunk-update-basis (chunk))
(defgeneric derive-chunk (chunk))
(defgeneric derive-date (chunk))
(defgeneric chunk-up-to-date-p (chunk))
```

This defines **vocabulary**, but not yet **semantics**.

### Missing pieces:

1. ❌ No **default `chunk-up-to-date-p` logic**
2. ❌ No **coherence driver (`ensure-chunk`)**
3. ❌ No **date semantics (comparison vs basis)**
4. ❌ No **distinction between “unknown” vs “stale”**
5. ❌ No **recursion into basis**

Without these, your system cannot actually maintain coherence.

---

# 2. Minimal executable core (copy-paste)

Here is the **smallest complete kernel** that works.

## 2.1 Base class (keep yours, slight refinement)

```lisp
(defclass hd-chunk ()
  ((id :initarg :id :reader chunk-id)
   (managed-p :initarg :managed-p :initform t :accessor managed-p)
   (last-derived-at :initarg :last-derived-at :initform nil :accessor last-derived-at)))
```

---

## 2.2 Generics (same as yours)

```lisp
(defgeneric chunk-basis (chunk))
(defmethod chunk-basis ((chunk hd-chunk)) nil)

(defgeneric chunk-update-basis (chunk))
(defmethod chunk-update-basis ((chunk hd-chunk)) nil)

(defgeneric derive-chunk (chunk))

(defgeneric derive-date (chunk))
(defmethod derive-date ((chunk hd-chunk))
  (last-derived-at chunk))

(defgeneric chunk-up-to-date-p (chunk))
```

---

## 2.3 Define “unknown date” explicitly

McDermott requires a distinction:

* known date
* unchanged
* **no info**

```lisp
(defparameter +no-info-date+ -1)
```

---

## 2.4 Core logic: up-to-date check (THIS IS CRITICAL)

```lisp
(defmethod chunk-up-to-date-p ((chunk hd-chunk))
  (let ((my-date (derive-date chunk)))
    (cond
      ;; no information → must derive
      ((or (null my-date)
           (eql my-date +no-info-date+))
       nil)

      ;; otherwise compare with basis
      (t
       (every (lambda (basis)
                (let ((basis-date (derive-date basis)))
                  (and basis-date
                       (not (eql basis-date +no-info-date+))
                       (<= basis-date my-date))))
              (chunk-basis chunk))))))
```

👉 This is the **heart of coherence**.

---

## 2.5 Coherence driver: `ensure-chunk` (MISSING BEFORE)

```lisp
(defgeneric ensure-chunk (chunk))

(defmethod ensure-chunk ((chunk hd-chunk))
  (when (managed-p chunk)

    ;; 1. ensure basis first (conjunctive dependencies)
    (dolist (b (chunk-basis chunk))
      (ensure-chunk b))

    ;; 2. ensure update-basis (transient dependencies)
    (dolist (b (chunk-update-basis chunk))
      (ensure-chunk b))

    ;; 3. derive if needed
    (unless (chunk-up-to-date-p chunk)
      (let ((changed-at (derive-chunk chunk)))
        (when changed-at
          (setf (last-derived-at chunk) changed-at)))))

  chunk)
```

👉 This replaces your entire “repair function sequencing”.

---

# 3. Why this is now *actually declarative*

Before (your function):

```lisp
do A
do B
do C
reload
verify
```

Now:

```lisp
(make true: topic-image-registration)
```

And the system:

* figures out dependencies
* ensures them
* derives only what is stale

That is exactly McDermott:

> “assert relationships… and let the system restore coherence” 

---

# 4. Subtle but crucial correctness points

## 4.1 Derivers must obey contract

```lisp
derive-chunk → returns:
  NIL       = already up to date
  timestamp = changed
```

NOT:

* booleans
* arbitrary values

---

## 4.2 `derive-date` must be meaningful

If you leave everything as:

```lisp
(last-derived-at chunk)
```

you get **no real coherence**, only “was I derived”.

You will later override for:

* files → `file-write-date`
* topics.lisp → file date
* runtime registry → synthetic timestamp

---

## 4.3 Basis must be complete

If you forget a dependency:

→ system becomes incoherent silently

This is the hardest part (as McDermott warns).

---

# 5. Minimal sanity test (do this now)

Before adding HyperDoc complexity, test with a toy:

```lisp
(defclass test-chunk (hd-chunk)
  ((value :initarg :value :accessor value)))

(defmethod derive-chunk ((c test-chunk))
  (format t "Deriving ~A~%" (chunk-id c))
  (get-universal-time))
```

Then:

```lisp
(ensure-chunk (make-instance 'test-chunk :id :a))
```

You should see:

```
Deriving A
```

Run again:

→ nothing (already up-to-date)

---

# 6. What your screenshot now represents (important insight)

Left pane:
→ **static definition**

Right pane:
→ **live object system**

This is exactly the transition McDermott wants:

> from files → to inspectable runtime coherence graph

You are already there structurally.

---

# 7. Next step (do not skip)

Now that the kernel is correct:

👉 Implement ONE real chunk:

### `topic-page-chunk`

with:

* real `derive-date` (file-write-date)
* real `derive-chunk` (write file)

Then test:

```lisp
(ensure-chunk <topic-page-chunk>)
```

If that works, the architecture is validated.

---

# 8. Key takeaway

Your earlier version defined:

> a language for talking about coherence

This version defines:

> a system that enforces coherence

That is the exact boundary McDermott is concerned with.

---

If you want next:

* I wire this directly into your **page-lookup-issue objects**
* or we implement the **first real HyperDoc chunk end-to-end (topic page + topic definition + image registration)**
