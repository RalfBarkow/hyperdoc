# Associations

[…]

Below is a **direct mapping from AD4M concepts → concrete HyperDoc primitives**, followed by a **Codex-ready implementation slice** that fits your repo and constraints (inspectability, no premature execution, journaled operations).

---

# 1. Concept Mapping (AD4M → HyperDoc)

## 1.1 Perspective → Runtime graph slice

**AD4M**

* “perspective” = personal RDF graph

**HyperDoc (target)**

* a *bounded, inspectable graph slice* of the running image

### Concrete form

```lisp
(defclass hyperdoc-perspective ()
  ((root-object :initarg :root-object)
   (edges :initarg :edges)
   (provenance :initarg :provenance)))
```

👉 This is *not* a global graph — it is:

* derived
* inspectable
* replayable

→ aligns with McDermott’s “derived chunk” model 

---

## 1.2 Triple (RDF) → Association object

**AD4M**

```
(source, predicate, target)
```

**HyperDoc (already exists conceptually)**

* DOM association
* topic links
* inspector relations

### Make it explicit:

```lisp
(defclass hyperdoc-association ()
  ((source :initarg :source)
   (predicate :initarg :predicate)
   (target :initarg :target)
   (provenance :initarg :provenance)))
```

👉 This becomes your **first-class relation unit**

---

## 1.3 RDF-star metadata → Provenance slot

**AD4M**

* author
* timestamp
* signature

**HyperDoc (extend existing tracing)**

```lisp
(defclass hyperdoc-provenance ()
  ((request-id :initarg :request-id)
   (timestamp :initarg :timestamp)
   (actor :initarg :actor)
   (derivation :initarg :derivation)))
```

👉 You already *have* most of this in logs —
this moves it into **data**, not logs.

---

## 1.4 SHACL shapes → Topic factory contracts

**AD4M**

* schema = SHACL graph constraints

**HyperDoc**

* topic factories define structure

### Add explicit contract layer:

```lisp
(defclass hyperdoc-shape ()
  ((predicate :initarg :predicate)
   (required :initarg :required)
   (cardinality :initarg :cardinality)
   (target-type :initarg :target-type)))
```

Attach to topic:

```lisp
(defclass hyperdoc-topic-contract ()
  ((title :initarg :title)
   (shapes :initarg :shapes)))
```

👉 This gives you:

* validation
* inspectable expectations
* no static schema

---

## 1.5 OGM (lens) → Inspector view

**AD4M**

* subject class = lens over graph

**HyperDoc**

* inspector view = projection

### Make it explicit:

```lisp
(defclass hyperdoc-lens ()
  ((name :initarg :name)
   (predicate-filter :initarg :predicate-filter)
   (projection :initarg :projection)))
```

👉 This formalizes what your inspector already does implicitly

---

## 1.6 Link language → Transport seam

**AD4M**

* pluggable sync layer (DHT, IPFS, etc.)

**HyperDoc**

* FedWiki
* Zotero
* local runtime

### Formalize:

```lisp
(defclass hyperdoc-transport ()
  ((name :initarg :name)
   (send :initarg :send)
   (receive :initarg :receive)))
```

👉 This matches your:

* DMX import
* FedWiki materialization
* Zotero bridge

---

# 2. Critical Integration Point

The key move is:

> **Make associations the primary inspectable unit**

Right now:

* associations are implicit (DOM, topics, links)

Target:

* associations become **objects with identity + provenance**

---

# 3. Minimal Coherent Slice (Codex-ready)

This is a **single slice** you can commit without destabilizing anything.

## Codex prompt (copy-paste)

```
Goal:
Introduce first-class association objects with provenance into HyperDoc without breaking existing DOM connect behavior.

Scope:
- Add hyperdoc-association and hyperdoc-provenance classes
- Extend DOM connect submit path to construct association objects
- Preserve existing payload flow (button-payload-v1)
- Make associations inspectable in inspector

Steps:

1. Add new file: hyperdoc/associations.lisp

Content:

(in-package :hyperdoc)

(defclass hyperdoc-provenance ()
  ((request-id :initarg :request-id :accessor provenance-request-id)
   (timestamp :initarg :timestamp :accessor provenance-timestamp)
   (actor :initarg :actor :accessor provenance-actor)
   (derivation :initarg :derivation :accessor provenance-derivation)))

(defclass hyperdoc-association ()
  ((source :initarg :source :accessor association-source)
   (predicate :initarg :predicate :accessor association-predicate)
   (target :initarg :target :accessor association-target)
   (provenance :initarg :provenance :accessor association-provenance)))

(defun make-association-from-payload (payload)
  (let ((source (getf payload :source))
        (target (getf payload :target))
        (predicate (getf payload :predicate))
        (request-id (getf payload :request-id)))
    (make-instance 'hyperdoc-association
      :source source
      :predicate predicate
      :target target
      :provenance (make-instance 'hyperdoc-provenance
                    :request-id request-id
                    :timestamp (get-universal-time)
                    :actor :connect-gesture
                    :derivation :dom-connect))))

2. Modify:
hyperbook-server/inspector-dom-association.lisp

- At submit boundary:
  replace raw payload handling with call to make-association-from-payload
  ensure resulting object is passed to pane-open

3. Add inspector view:

(views:defview 👀association (obj hyperdoc-association)
  (views:html-view :title "Association" :priority 1
    (views:html
      (:div
        (:p (format nil "Source: ~A" (association-source obj)))
        (:p (format nil "Predicate: ~A" (association-predicate obj)))
        (:p (format nil "Target: ~A" (association-target obj)))))))

4. Ensure:
- existing DOM connect still works
- request-id preserved
- no change to frontend JS required

Commit message:
feat(hyperdoc): introduce first-class association objects with provenance
```

---

# 4. Why this slice is correct

It satisfies:

### (A) Your architectural direction

* everything inspectable
* no hidden execution
* explicit objects

### (B) McDermott coherence model

* associations become chunks
* derivable + trackable 

### (C) Semantic Web benefit (without RDF baggage)

* triples ✔
* provenance ✔
* no SPARQL ✘

---

# 5. What this unlocks next

Once this is in place, you can:

### 1. Add “association topics”

* association itself becomes a topic

### 2. Add validation (SHACL-like)

* enforce constraints on associations

### 3. Add replay / simulation

* inspect “what would happen if executed”

### 4. Add cross-transport sync

* associations as portable units

---

# 6. Bottom line

You don’t need AD4M.

You already have the stronger substrate:

> **a live, inspectable Lisp image**

This step simply:

> **makes relations first-class citizens inside it**

---

If you want, next step I’d recommend:

→ **“association as topic factory”** (so connections themselves become pages)
which directly matches your “everything connects to everything” goal.
