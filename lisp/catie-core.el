;;; catie-core.el --- Core editor behaviour -*- lexical-binding: t; -*-

(setq make-backup-files nil
      auto-save-default nil
      auto-save-list-file-prefix nil
      history-length 500
      recentf-max-saved-items 200
      ring-bell-function #'ignore)

(savehist-mode 1)
(recentf-mode 1)
(delete-selection-mode 1)
(global-so-long-mode 1)

(defun catie/prog-buffer-defaults ()
  "Apply Catie's programming-buffer defaults."
  (setq-local show-trailing-whitespace t)
  (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

(add-hook 'prog-mode-hook #'catie/prog-buffer-defaults)

(use-package undo-fu-session
  :init
  (setq undo-fu-session-directory
        (expand-file-name "undo/" user-emacs-directory))
  :config
  (global-undo-fu-session-mode 1))

(use-package smartparens
  :hook ((prog-mode . smartparens-mode)
         (text-mode . smartparens-mode))
  :config
  (require 'smartparens-config))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(provide 'catie-core)
;;; catie-core.el ends here
