;;; catie-ui.el --- UI configuration -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------------
;; Theme
;; ---------------------------------------------------------------------------

(add-to-list
 'custom-theme-load-path
 (expand-file-name "themes" user-emacs-directory))

(load-theme 'strawberry-light t)

;; ---------------------------------------------------------------------------
;; Icons
;; ---------------------------------------------------------------------------

(use-package nerd-icons)

;; ---------------------------------------------------------------------------
;; Modeline
;; ---------------------------------------------------------------------------

(use-package doom-modeline
  :init
  (doom-modeline-mode 1)

  :custom
  (doom-modeline-icon t)
  (doom-modeline-buffer-file-name-style 'truncate-with-project)
  (doom-modeline-project-detection 'project)
  (doom-modeline-height 1))

;; ---------------------------------------------------------------------------
;; Which Key
;; ---------------------------------------------------------------------------

(use-package which-key
  :ensure nil

  :init
  (which-key-mode 1)

  :custom
  (which-key-idle-delay 0.35)
  (which-key-idle-secondary-delay 0.05))

;; ---------------------------------------------------------------------------
;; Line numbers
;; ---------------------------------------------------------------------------

(setq display-line-numbers-type 'relative)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)

(column-number-mode 1)

;; ---------------------------------------------------------------------------
;; Matching delimiters
;; ---------------------------------------------------------------------------

(show-paren-mode 1)

;; ---------------------------------------------------------------------------
;; File tree
;; ---------------------------------------------------------------------------

(use-package treemacs
  :commands
  (treemacs
   treemacs-select-window
   treemacs-display-current-project-exclusively)

  :custom
  ;; IDE-style project tree on the right.
  (treemacs-position 'right)
  (treemacs-width 34)

  :config
  ;; Keep the tree synced with the file we're editing.
  (treemacs-follow-mode 1)

  ;; Keep changes made outside Emacs reflected in the tree.
  (treemacs-filewatch-mode 1))

(provide 'catie-ui)
;;; catie-ui.el ends here
