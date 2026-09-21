;; ASDF source text as data.
;;
;; Nothing here knows about ASDF, about Git, or about where the text
;; came from. It takes a string that is meant to be an ASDF definition
;; and says what is syntactically in it. Anything further — whether
;; ASDF accepts it, what it defines once evaluated, whether a system
;; can be built — belongs to a runtime that is allowed to ask.
;;
;; It lived in DREYECK/GIT, because that is where it was first needed,
;; for definitions read out of Git blobs. Its input was always just a
;; string.

(in-package #:dreyeck/asdf-source)

(defstruct asdf-source-node
  kind
  raw
  value
  children
  start
  end)

(defun asdf-source-delimiter-p (character)
  (or (null character)
      (find character "()\";'`," :test #'char=)
      (find character '(#\Space #\Tab #\Newline #\Return #\Page)
            :test #'char=)))

(defun scan-asdf-source (source)
  "Parse SOURCE into a package-free structural tree without invoking READ.

Character by character, so that reading a definition is not a step
towards running it. CL:READ would consult the current readtable, honour
reader macros, intern symbols and resolve #. — all of which can run
code or depend on the image. This scans instead, and answers only about
the text.

It does not apply #+ and #- either, so the tree is the same whatever
image reads it. That is honest but worth knowing: what ASDF would see
can differ from what is written here."
  (let ((position 0)
        (length (length source))
        (issues nil))
    (labels
        ((prefix-at-p (prefix)
           (and (<= (+ position (length prefix)) length)
                (string= prefix source
                         :start2 position
                         :end2 (+ position (length prefix)))))
         (skip-line-comment ()
           (loop while (and (< position length)
                            (not (find (char source position)
                                       '(#\Newline #\Return))))
                 do (incf position)))
         (skip-block-comment ()
           (let ((start position)
                 (depth 0))
             (loop while (< position length)
                   do (cond
                        ((prefix-at-p "#|")
                         (incf depth)
                         (incf position 2))
                        ((prefix-at-p "|#")
                         (decf depth)
                         (incf position 2)
                         (when (zerop depth) (return)))
                        (t (incf position))))
             (unless (zerop depth)
               (push (list start "Unterminated #| ... |# comment.")
                     issues))))
         (skip-ignored ()
           (loop
             (loop while (and (< position length)
                              (find (char source position)
                                    '(#\Space #\Tab #\Newline #\Return #\Page)))
                   do (incf position))
             (cond
               ((and (< position length)
                     (char= (char source position) #\;))
                (skip-line-comment))
               ((prefix-at-p "#|")
                (skip-block-comment))
               (t (return)))))
         (parse-string-node ()
           (let ((start position))
             (incf position)
             (let ((value
                     (with-output-to-string (stream)
                       (loop while (< position length)
                             for character = (char source position)
                             do (incf position)
                                (cond
                                  ((char= character #\\)
                                   (if (< position length)
                                       (progn
                                         (write-char (char source position)
                                                     stream)
                                         (incf position))
                                       (push
                                        (list start
                                              "Trailing escape in string.")
                                        issues)))
                                  ((char= character #\")
                                   (return))
                                  (t (write-char character stream)))
                             finally
                                (push (list start "Unterminated string.")
                                      issues)))))
               (make-asdf-source-node
                :kind :string
                :raw (subseq source start position)
                :value value
                :start start
                :end position))))
         (parse-character-node ()
           (let ((start position))
             (incf position 2)
             (when (< position length)
               (if (asdf-source-delimiter-p (char source position))
                   (incf position)
                   (loop while (and (< position length)
                                    (not
                                     (asdf-source-delimiter-p
                                      (char source position))))
                         do (incf position))))
             (make-asdf-source-node
              :kind :token
              :raw (subseq source start position)
              :value (subseq source start position)
              :start start
              :end position)))
         (parse-token-node ()
           (let ((start position))
             (loop while (and (< position length)
                              (not
                               (asdf-source-delimiter-p
                                (char source position))))
                   do (incf position))
             (when (= start position)
               (incf position))
             (make-asdf-source-node
              :kind :token
              :raw (subseq source start position)
              :value (subseq source start position)
              :start start
              :end position)))
         (parse-reader-eval-node ()
           (let ((start position))
             (incf position 2)
             (skip-ignored)
             (let ((child (and (< position length) (parse-form))))
               (push
                (list start
                      "Reader-evaluation form #. was retained as unsupported and was not evaluated.")
                issues)
               (make-asdf-source-node
                :kind :reader-eval
                :raw (subseq source start position)
                :children (and child (list child))
                :start start
                :end position))))
         (parse-list-node ()
           (let ((start position)
                 (children nil)
                 (closed-p nil))
             (incf position)
             (loop
               (skip-ignored)
               (cond
                 ((>= position length) (return))
                 ((char= (char source position) #\))
                  (incf position)
                  (setf closed-p t)
                  (return))
                 (t (push (parse-form) children))))
             (unless closed-p
               (push (list start "Unterminated list.") issues))
             (make-asdf-source-node
              :kind :list
              :raw (subseq source start position)
              :children (nreverse children)
              :start start
              :end position)))
         (parse-form ()
           (skip-ignored)
           (cond
             ((>= position length) nil)
             ((prefix-at-p "#.") (parse-reader-eval-node))
             ((prefix-at-p "#\\") (parse-character-node))
             ((char= (char source position) #\() (parse-list-node))
             ((char= (char source position) #\") (parse-string-node))
             ((char= (char source position) #\))
              (let ((start position))
                (incf position)
                (push (list start "Unexpected closing parenthesis.") issues)
                (make-asdf-source-node
                 :kind :error
                 :raw ")"
                 :start start
                 :end position)))
             (t (parse-token-node)))))
      (let ((nodes nil))
        (loop
          (skip-ignored)
          (when (>= position length) (return))
          (push (parse-form) nodes))
        (values (nreverse nodes) (nreverse issues))))))

(defun simple-asdf-designator-name (node)
  (case (asdf-source-node-kind node)
    (:string (string-downcase (asdf-source-node-value node)))
    (:token
     (let ((raw (asdf-source-node-raw node)))
       (unless (or (zerop (length raw))
                   (and (char= (char raw 0) #\#)
                        (not (uiop:string-prefix-p "#:" raw)))
                   (find #\| raw))
         (let* ((without-uninterned
                  (if (uiop:string-prefix-p "#:" raw)
                      (subseq raw 2)
                      raw))
                (last-colon (position #\: without-uninterned :from-end t))
                (name (if last-colon
                          (subseq without-uninterned (1+ last-colon))
                          without-uninterned)))
           (unless (zerop (length name))
             (string-downcase name))))))
    (otherwise nil)))

(defun asdf-defsystem-form-p (node)
  (and (eq :list (asdf-source-node-kind node))
       (let ((head (first (asdf-source-node-children node))))
         (and head
              (string= "defsystem"
                       (or (simple-asdf-designator-name head) ""))))))

(defun depends-on-node (defsystem-node)
  (let ((children (asdf-source-node-children defsystem-node)))
    (loop for tail on (cddr children)
          for key = (first tail)
          when (and key
                    (eq :token (asdf-source-node-kind key))
                    (string-equal ":depends-on"
                                  (asdf-source-node-raw key)))
            return (second tail))))
