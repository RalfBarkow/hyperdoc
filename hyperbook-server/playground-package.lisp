(in-package :clog-moldable-inspector)

(defmethod html-inspector-views/standard:playground-package :around ((obj t))
  (let ((pkg (when (next-method-p) (call-next-method))))
    (if (typep pkg 'package)
        pkg
        (find-package "CL-USER"))))
