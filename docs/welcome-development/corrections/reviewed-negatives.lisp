(asdf:load-system "dreyeck/work/welcome-development")
(in-package #:dreyeck/work/welcome-development)
(defun baseline-observation (name records)
  (let ((state (development-state records)))
    (format t "~&REVIEWED-COMMIT ~A ACCEPTED (invalid record admitted): ~D facts~%" name (length state))))
(let* ((records (fixture-records :p1)) (properties (data (second records) :source-plan)))
  (setf (getf properties :digest) (fixture-sha #\0 64))
  (baseline-observation :b1-forged-digest records))
(baseline-observation :b2-wrong-s2-base
 (append (fixture-records :p4) (list (fixture-assignment :bad-base 's2 'codex (fixture-sha #\9)))))
(baseline-observation :b3-premature-s3
 (append (fixture-records :p0) (list (fixture-assignment :premature 's3 'codex +fixture-base+))))
(baseline-observation :b4-open-assignment
 (append (fixture-records :p1) (list (fixture-assignment :concurrent 's1 'claude-code +fixture-base+))))
(let* ((records (fixture-records :p3)) (a (second records)))
 (baseline-observation :b5-unclaimed-review
  (append records (list (fixture-review a (fixture-sha #\0))))))
