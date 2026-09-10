;;; init.el --- Catie's Emacs configuration -*- lexical-binding: t; -*-

(require 'package)

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))

(package-initialize)

(unless package-archive-contents
  (condition-case nil
      (package-read-all-archive-contents)
    (error nil)))

(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)

(setq use-package-always-ensure t
      use-package-expand-minimally t)

(add-to-list
 'load-path
 (expand-file-name
  "lisp"
  user-emacs-directory))


;; ---------------------------------------------------------------------------
;; Shared configuration
;; ---------------------------------------------------------------------------

(require 'catie-core)
(require 'catie-ui)
(require 'catie-evil)
(require 'catie-completion)

(require 'catie-languages)
(require 'catie-lsp)

(require 'catie-frameworks)
(require 'catie-backends)

(require 'catie-tailwind)
(require 'catie-linting)
(require 'catie-formatting)

(require 'catie-copilot)

(require 'catie-search)

(require 'catie-projects)
(require 'catie-testing)

(require 'catie-git)
(require 'catie-terminal)


;; ---------------------------------------------------------------------------
;; Platform-specific configuration
;; ---------------------------------------------------------------------------

(cond

 ((eq system-type 'darwin)
  (require 'catie-macos))

 ((eq system-type 'gnu/linux)
  (when
      (locate-library "catie-linux")

    (require 'catie-linux))))


;; ---------------------------------------------------------------------------
;; Custom
;; ---------------------------------------------------------------------------

(setq custom-file
      (expand-file-name
       "custom.el"
       user-emacs-directory))

(load custom-file 'noerror)


;;; init.el ends here
