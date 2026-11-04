;;;; Properties of the Catalog's membership, derived from what the product declares. No list of ids, no count.
;;;;
;;;; Where membership is declared. The default Catalog is what loading DREYECK/CATALOG registers. DREYECK/CATALOG's :DEPENDS-ON
;;;; (dreyeck.asd) names the systems; each system that carries a HyperBook defines it with DEFHYPERDOC, whose :ID and
;;;; :ASDF-SYSTEM-NAME are in that system's own source, and loading the system registers it (HYPERBOOK:REGISTER, which keeps the
;;;; first book of an id). Adding or withdrawing a book is therefore one edit: a :DEPENDS-ON entry (and the system's own DEFHYPERDOC).
;;;; Nothing here has to be edited with it.
;;;;
;;;; What is derived, independently of the running Catalog:
;;;;  * the closure of DREYECK/CATALOG's ASDF dependencies (DECLARED-SYSTEMS);
;;;;  * the HyperDocs those systems of this repository declare, read as text from their component source files (SOURCE-HYPERDOCS).
;;;; MEMBERSHIP-REPORT compares that with the Catalog that was actually materialized. A report compared with a set that was itself
;;;; taken from the same Catalog would prove nothing; this one is taken from source and from ASDF.
(defpackage #:dreyeck/catalog/membership
  (:use #:cl)
  (:export #:declared-systems #:repository-systems #:system-source-files #:scan-hyperdocs-in-text #:source-hyperdocs
           #:catalog-ids #:membership-report #:report-problems #:assert-membership #:assert-hyperbook-present
           #:assert-additive #:assert-idempotent #:assert-registration-keeps-first #:load-systems))
(in-package #:dreyeck/catalog/membership)

;;; ASDF: the declaration

(defun %dependency-name (designator)
  "The system name of a :DEPENDS-ON entry, or NIL for an entry that is not a plain system name (feature, version forms)."
  (cond ((stringp designator) designator)
        ((and designator (symbolp designator)) (string-downcase (symbol-name designator)))
        (t nil)))

(defun declared-systems (&optional (root "dreyeck/catalog"))
  "The names of ROOT and of every system it depends on, directly or not, as ASDF declares them."
  (let ((seen '()) (queue (list root)))
    (loop while queue
          do (let ((name (pop queue)))
               (unless (member name seen :test #'string=)
                 (push name seen)
                 (let ((system (asdf:find-system name nil)))
                   (when system
                     (dolist (dependency (asdf:system-depends-on system))
                       (let ((dependency-name (%dependency-name dependency)))
                         (when dependency-name (push dependency-name queue)))))))))
    (nreverse seen)))

(defun %repository-root () (truename (asdf:system-source-directory "dreyeck")))

(defun repository-systems (names)
  "Those of the system NAMES whose source lives in this repository's tree."
  (let ((root (%repository-root)))
    (remove-if-not (lambda (name)
                     (let* ((system (asdf:find-system name nil))
                            (directory (and system (asdf:system-source-directory system))))
                       (and directory (let ((directory (truename directory)))
                                        (or (equal directory root) (uiop:subpathp directory root))))))
                   names)))

(defun system-source-files (name)
  "The Lisp source files of the components of system NAME."
  (let ((files '()))
    (labels ((walk (component)
               (when (typep component 'asdf:cl-source-file)
                 (let ((path (ignore-errors (asdf:component-pathname component))))
                   (when (and path (probe-file path)) (push (truename path) files))))
               (when (typep component 'asdf:parent-component)
                 (mapc #'walk (asdf:component-children component)))))
      (let ((system (asdf:find-system name nil)))
        (when system (walk system))))
    (nreverse files)))

;;; Source: the HyperDocs a system declares

(defun %strip-comments (text)
  "TEXT with ; comments removed, leaving strings and #\\ characters alone."
  (with-output-to-string (out)
    (let ((in-string nil) (i 0) (n (length text)))
      (loop while (< i n)
            do (let ((c (char text i)))
                 (cond (in-string
                        (write-char c out)
                        (cond ((char= c #\\) (when (< (1+ i) n) (incf i) (write-char (char text i) out)))
                              ((char= c #\") (setf in-string nil))))
                       ((char= c #\") (setf in-string t) (write-char c out))
                       ((and (char= c #\#) (< (1+ i) n) (char= (char text (1+ i)) #\\))
                        (write-string (subseq text i (min n (+ i 3))) out) (incf i 2))
                       ((char= c #\;) (loop while (and (< i n) (char/= (char text i) #\Newline)) do (incf i)) (decf i))
                       (t (write-char c out))))
               (incf i)))))

(defun %string-mask (text)
  "A bit vector over TEXT: 1 for a character inside a string literal (the quotes themselves count as outside)."
  (let ((mask (make-array (length text) :element-type 'bit :initial-element 0)) (in-string nil) (n (length text)) (i 0))
    (loop while (< i n)
          do (let ((c (char text i)))
               (cond (in-string (cond ((char= c #\\) (setf (sbit mask i) 1) (when (< (1+ i) n) (incf i) (setf (sbit mask i) 1)))
                                      ((char= c #\") (setf in-string nil))
                                      (t (setf (sbit mask i) 1))))
                     ((char= c #\") (setf in-string t))
                     ((and (char= c #\#) (< (1+ i) n) (char= (char text (1+ i)) #\\)) (incf i 2))))
             (incf i))
    mask))

(defun %form-end (text start)
  "The index after the list that opens at START, or NIL when it does not close."
  (let ((depth 0) (in-string nil) (n (length text)) (i start))
    (loop while (< i n)
          do (let ((c (char text i)))
               (cond (in-string (cond ((char= c #\\) (incf i)) ((char= c #\") (setf in-string nil))))
                     ((char= c #\") (setf in-string t))
                     ((and (char= c #\#) (< (1+ i) n) (char= (char text (1+ i)) #\\)) (incf i 2))
                     ((char= c #\() (incf depth))
                     ((char= c #\)) (decf depth) (when (zerop depth) (return-from %form-end (1+ i))))))
             (incf i))
    nil))

(defun %keyword-string (form keyword)
  "The string that follows KEYWORD (without its colon, any case) in the text FORM, or NIL."
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings (format nil "(?i):~A\\s+\"([^\"]*)\"" keyword) form)
    (and match (aref groups 0))))

(defun scan-hyperdocs-in-text (text)
  "The DEFHYPERDOC forms in TEXT, as plists (:id :system :main-page). Comments are ignored. A form's :id and :asdf-system-name
must be string literals; a form whose :id is not is reported with :id NIL, so that it cannot go unnoticed."
  (let* ((text (%strip-comments text)) (mask (%string-mask text)) (found '()) (start 0))
    (loop
      (let ((at (cl-ppcre:scan "(?i)\\(\\s*(?:[a-z0-9/\\-]+:{1,2})?defhyperdoc[\\s)]" text :start start)))
        (unless at (return))
        (if (= 1 (sbit mask at))
            (setf start (1+ at))              ; inside a string: not a form
            (let ((end (%form-end text at)))
              (unless end (return))
              (let ((form (subseq text at end)))
                (push (list :id (%keyword-string form "id") :system (%keyword-string form "asdf-system-name")
                            :main-page (%keyword-string form "main-page-id"))
                      found))
              (setf start end)))))
    (nreverse found)))

(defun source-hyperdocs (&optional (systems (repository-systems (declared-systems))))
  "The HyperDocs declared in the component source files of SYSTEMS, each as (:id :system :main-page :file)."
  (let ((result '()))
    (dolist (system systems)
      (dolist (file (system-source-files system))
        (let ((text (ignore-errors (uiop:read-file-string file))))
          (when (and text (search "defhyperdoc" text :test #'char-equal))
            (dolist (entry (scan-hyperdocs-in-text text))
              (push (append entry (list :file file)) result))))))
    (nreverse result)))

;;; The Catalog, compared with the declaration

(defun catalog-ids (&optional (catalog hyperbook:*catalog*))
  (mapcar #'hyperbook:id-of (hyperbook:hyperbooks-of catalog)))

(defun %hyperdoc-p (book) (typep book 'hyperdoc:hyperdoc))
(defun %system-of (book) (and (%hyperdoc-p book) (slot-boundp book 'hyperdoc::asdf-system-name) (hyperdoc::asdf-system-name-of book)))

(defun %literal-ids (systems)
  "Every string that follows :ID in the component source files of SYSTEMS: the ids that the sources themselves give to books."
  (let ((ids (make-hash-table :test #'equal)))
    (dolist (system systems ids)
      (dolist (file (system-source-files system))
        (let ((text (ignore-errors (uiop:read-file-string file))))
          (when text
            (cl-ppcre:do-register-groups (id) ("(?i):id\\s+\"([^\"]+)\"" (%strip-comments text))
              (setf (gethash id ids) t))))))))

(defun membership-report (&key (catalog hyperbook:*catalog*)
                            (systems (declared-systems))
                            (declared (source-hyperdocs (repository-systems systems)))
                            (check-pages nil))
  "What differs between CATALOG and the declaration (SYSTEMS: the ASDF closure; DECLARED: the HyperDocs read from their source).
A plist; every problem list is NIL for a Catalog that is what the product declares.
 :MISSING          declared ids that the Catalog does not have
 :DUPLICATED       ids that occur more than once
 :WRONG-SYSTEM     declared ids whose book names another ASDF system than its declaration
 :UNSCANNED        declared HyperDocs whose :id or :asdf-system-name is not a string literal in the source
 :UNDECLARED       HyperDocs in the Catalog whose system is not in the ASDF closure, or whose id no source declares
 :UNATTRIBUTED     books that are not HyperDocs and whose id no source of this repository's systems in the closure gives as an :ID
 :MAIN-PAGE        declared main pages that do not open (only with CHECK-PAGES)"
  (let* ((books (hyperbook:hyperbooks-of catalog))
         (ids (mapcar #'hyperbook:id-of books))
         (declared-ids (remove nil (mapcar (lambda (entry) (getf entry :id)) declared)))
         (literal-ids (%literal-ids (repository-systems systems)))
         (report (list :missing '() :duplicated '() :wrong-system '() :unscanned '() :undeclared '() :unattributed '() :main-page '())))
    (flet ((add (key value) (push value (getf report key))))
      (dolist (entry declared)
        (unless (and (getf entry :id) (getf entry :system)) (add :unscanned (getf entry :file))))
      (dolist (id declared-ids)
        (unless (member id ids :test #'string=) (add :missing id)))
      (dolist (id (remove-duplicates ids :test #'string=))
        (when (> (count id ids :test #'string=) 1) (add :duplicated id)))
      (dolist (entry declared)
        (let ((book (and (getf entry :id) (find (getf entry :id) books :key #'hyperbook:id-of :test #'string=))))
          (when (and book (getf entry :system) (not (equal (%system-of book) (getf entry :system))))
            (add :wrong-system (getf entry :id)))))
      (dolist (book books)
        (cond ((%hyperdoc-p book)
               (unless (and (member (%system-of book) systems :test #'equal)
                            (member (hyperbook:id-of book) declared-ids :test #'string=))
                 (add :undeclared (hyperbook:id-of book))))
              (t (unless (gethash (hyperbook:id-of book) literal-ids) (add :unattributed (hyperbook:id-of book))))))
      (when check-pages
        (dolist (entry declared)
          (let ((book (and (getf entry :id) (find (getf entry :id) books :key #'hyperbook:id-of :test #'string=)))
                (main (getf entry :main-page)))
            (when (and book main)
              (unless (ignore-errors
                       (hyperdoc::ensure-pages-loaded book)
                       (and (equal main (hyperbook:main-page-id-of book))
                            (hyperbook:find-page book main :signal-error? t)))
                (add :main-page (getf entry :id))))))))
    (loop for (key value) on report by #'cddr collect key collect (nreverse value))))

(defun report-problems (report)
  "The problem entries of REPORT that are not empty, as a plist."
  (loop for (key value) on report by #'cddr when value append (list key value)))

(defun assert-membership (&rest arguments &key &allow-other-keys)
  "Signal an error naming every difference between the Catalog and the product's declaration. Returns the report."
  (let* ((report (apply #'membership-report arguments)) (problems (report-problems report)))
    (when problems (error "The Catalog is not what the product declares: ~S" problems))
    report))

(defun assert-hyperbook-present (id &key (catalog hyperbook:*catalog*) (declared-in-source t) (check-main-page t))
  "The HyperBook ID is in CATALOG exactly once and, as a HyperDoc declared in source, opens its declared main page."
  (let* ((ids (catalog-ids catalog)) (count (count id ids :test #'string=)))
    (unless (= 1 count) (error "~S occurs ~D times in the Catalog." id count))
    (when declared-in-source
      (let ((entry (find id (source-hyperdocs) :key (lambda (e) (getf e :id)) :test #'equal)))
        (unless entry (error "No source of the ASDF closure of dreyeck/catalog declares ~S." id))
        (when (and check-main-page (getf entry :main-page))
          (let ((book (find id (hyperbook:hyperbooks-of catalog) :key #'hyperbook:id-of :test #'string=)))
            (hyperdoc::ensure-pages-loaded book)
            (unless (equal (getf entry :main-page) (hyperbook:main-page-id-of book))
              (error "~S declares main page ~S but its book has ~S." id (getf entry :main-page) (hyperbook:main-page-id-of book)))
            (hyperbook:find-page book (getf entry :main-page) :signal-error? t)))))
    t))

;;; Loading more, loading again, registering twice

(defun load-systems (names &key reload-sources)
  "Load the systems NAMES. With RELOAD-SOURCES, also evaluate their source files again, so that their DEFHYPERDOC forms run a second
time (ASDF's :FORCE cannot be used inside another ASDF operation, such as a test-op)."
  (dolist (name names)
    (asdf:load-system name)
    (when reload-sources
      (let ((*error-output* (make-broadcast-stream)))
        (handler-bind ((warning #'muffle-warning))
          (dolist (file (system-source-files name)) (load file)))))))

(defun %snapshot (catalog) (mapcar (lambda (book) (cons (hyperbook:id-of book) book)) (hyperbook:hyperbooks-of catalog)))

(defun assert-additive (&key (catalog hyperbook:*catalog*) (loader (lambda ()) ))
  "Run LOADER, which loads further systems. Every HyperBook that was in CATALOG before is still there, once, and is the same object;
nothing was removed and nothing replaced. Returns the ids that were added."
  (let ((before (%snapshot catalog)))
    (funcall loader)
    (let ((after (%snapshot catalog)))
      (dolist (entry before)
        (let ((same (remove (car entry) after :key #'car :test-not #'string=)))
          (unless (= 1 (length same)) (error "~S occurs ~D times after loading." (car entry) (length same)))
          (unless (eq (cdr entry) (cdr (first same))) (error "~S was replaced by another object after loading." (car entry)))))
      (set-difference (mapcar #'car after) (mapcar #'car before) :test #'string=))))

(defun assert-idempotent (&key (catalog hyperbook:*catalog*) (loader (lambda ())))
  "Run LOADER, which loads systems that are already loaded. The Catalog is afterwards the same list of the same objects, in the same order."
  (let ((before (copy-list (hyperbook:hyperbooks-of catalog))))
    (funcall loader)
    (unless (equal before (hyperbook:hyperbooks-of catalog))
      (error "Loading again changed the Catalog: ~S -> ~S" (mapcar #'hyperbook:id-of before) (catalog-ids catalog)))
    t))

(defun assert-registration-keeps-first (&key (catalog hyperbook:*catalog*) (register #'hyperbook:register))
  "REGISTER a different HyperBook under every id the Catalog has. The Catalog must keep the first book of each id, once. The Catalog
is restored afterwards whatever happens."
  (let ((saved (copy-list (hyperbook:hyperbooks-of catalog))))
    (unwind-protect
         (progn
           (dolist (id (remove-duplicates (mapcar #'hyperbook:id-of saved) :test #'string=))
             (funcall register (make-instance 'hyperbook:hyperbook :id id)))
           (unless (equal saved (hyperbook:hyperbooks-of catalog))
             (error "Registering a second book under an existing id changed the Catalog.")))
      (setf (hyperbook:hyperbooks-of catalog) saved))
    t))
