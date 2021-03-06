;; Time-stamp: <2015-02-23 11:42:32 kmodi>

;; Number
;; https://github.com/chrisdone/number

(use-package number
  :config
  (progn
    (defhydra hydra-math (:color blue)
      "math-operation"
      ("+" number/add      "Add")
      ("-" number/sub      "Sub")
      ("*" number/multiply "Mul")
      ("/" number/divide   "Div")
      ("0" number/pad      "Pad 0s")
      ("=" number/eval     "Eval")
      ("q" nil             "cancel" :color blue))
    (bind-key "C-c m" #'hydra-math/body modi-mode-map)))


(provide 'setup-number)
