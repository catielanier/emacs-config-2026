;;; catie-languages.el --- Programming language modes -*- lexical-binding: t; -*-

(require 'treesit)


;; ---------------------------------------------------------------------------
;; Tree-sitter
;; ---------------------------------------------------------------------------

(unless (treesit-available-p)
  (error "This Emacs was built without tree-sitter support"))

;; Maximum syntax highlighting detail.
;;
;; Level 4 includes operators, delimiters, function calls, property access,
;; variables, and the other details that give Strawberry its full syntax
;; palette.
(setq treesit-font-lock-level 4)


;; ---------------------------------------------------------------------------
;; JavaScript / JSX
;; ---------------------------------------------------------------------------
;;
;; Emacs 31's built-in `js-ts-mode' understands JSX as part of the
;; JavaScript grammar, so we do not need a separate third-party JSX mode.

(add-to-list
 'auto-mode-alist
 '("\\.js\\'" . js-ts-mode))

(add-to-list
 'auto-mode-alist
 '("\\.mjs\\'" . js-ts-mode))

(add-to-list
 'auto-mode-alist
 '("\\.cjs\\'" . js-ts-mode))

(add-to-list
 'auto-mode-alist
 '("\\.jsx\\'" . js-ts-mode))


;; ---------------------------------------------------------------------------
;; TypeScript
;; ---------------------------------------------------------------------------

(add-to-list
 'auto-mode-alist
 '("\\.ts\\'" . typescript-ts-mode))


;; ---------------------------------------------------------------------------
;; TSX / React
;; ---------------------------------------------------------------------------

(add-to-list
 'auto-mode-alist
 '("\\.tsx\\'" . tsx-ts-mode))


;; ---------------------------------------------------------------------------
;; JSON / JSONC
;; ---------------------------------------------------------------------------

(add-to-list
 'auto-mode-alist
 '("\\.json\\'" . json-ts-mode))

(add-to-list
 'auto-mode-alist
 '("\\.jsonc\\'" . json-ts-mode))


;; ---------------------------------------------------------------------------
;; CSS
;; ---------------------------------------------------------------------------

(add-to-list
 'auto-mode-alist
 '("\\.css\\'" . css-ts-mode))


;; ---------------------------------------------------------------------------
;; HTML
;; ---------------------------------------------------------------------------

(add-to-list
 'auto-mode-alist
 '("\\.html?\\'" . html-ts-mode))


;; ---------------------------------------------------------------------------
;; YAML
;; ---------------------------------------------------------------------------

(add-to-list
 'auto-mode-alist
 '("\\.ya?ml\\'" . yaml-ts-mode))


;; ---------------------------------------------------------------------------
;; General programming behavior
;; ---------------------------------------------------------------------------

(defun catie/programming-language-setup ()
  "Common behavior for programming language buffers."

  ;; We already have smartparens handling pairs.
  ;;
  ;; Do not establish indentation widths here.  Formatter/language-specific
  ;; configuration will handle that later rather than imposing personal
  ;; formatting rules on work repositories.

  (setq-local truncate-lines t))


(add-hook
 'prog-mode-hook
 #'catie/programming-language-setup)


;; ---------------------------------------------------------------------------
;; Tree-sitter diagnostics
;; ---------------------------------------------------------------------------

(defun catie/treesit-info ()
  "Display tree-sitter information for the current buffer."

  (interactive)

  (message
   "Mode: %s | Tree-sitter parsers: %s"
   major-mode
   (if (treesit-parser-list)
       (mapcar
        #'treesit-parser-language
        (treesit-parser-list))
     "none")))


(provide 'catie-languages)

;;; catie-languages.el ends here
