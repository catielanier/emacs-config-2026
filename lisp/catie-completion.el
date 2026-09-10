;;; catie-completion.el --- Completion and navigation -*- lexical-binding: t; -*-

(use-package vertico
  :init
  (vertico-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles partial-completion)))))

(use-package marginalia
  :init
  (marginalia-mode 1))

(use-package consult
  :bind
  (("C-s" . consult-line)))

(use-package embark)

(use-package embark-consult
  :after (embark consult))

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.15)
  (corfu-auto-prefix 1)
  (corfu-cycle t)

  ;; Do NOT select/insert something merely because the popup appeared.
  (corfu-preselect 'prompt)
  (corfu-preview-current nil)
  (corfu-on-exact-match nil)

  :init
  (global-corfu-mode 1))

(use-package cape)

(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters
               #'nerd-icons-corfu-formatter))

(catie/leader
  "b"   '(:ignore t :which-key "buffer")
  "b b" '(consult-buffer :which-key "switch buffer")
  "b n" '(next-buffer :which-key "next buffer")
  "b p" '(previous-buffer :which-key "previous buffer")
  "b k" '(kill-current-buffer :which-key "kill buffer")

  "f"   '(:ignore t :which-key "file")
  "f f" '(find-file :which-key "find file")
  "f r" '(consult-recent-file :which-key "recent files")
  "f s" '(save-buffer :which-key "save file")

  "s"   '(:ignore t :which-key "search")
  "s s" '(consult-line :which-key "search buffer"))

(provide 'catie-completion)
;;; catie-completion.el ends here
