;;; catie-formatting.el --- Project-aware Prettier formatting -*- lexical-binding: t; -*-

(require 'json)
(require 'seq)
(require 'subr-x)


;; ---------------------------------------------------------------------------
;; Supported modes
;; ---------------------------------------------------------------------------

(defconst catie/prettier-modes
  '(js-ts-mode
    typescript-ts-mode
    tsx-ts-mode
    json-ts-mode
    css-ts-mode
    html-ts-mode
    yaml-ts-mode
    markdown-mode
    web-mode)
  "Major modes eligible for project-local Prettier.")


;; ---------------------------------------------------------------------------
;; Prettier project/config detection
;; ---------------------------------------------------------------------------

(defconst catie/prettier-config-files
  '(".prettierrc"
    ".prettierrc.json"
    ".prettierrc.json5"
    ".prettierrc.yaml"
    ".prettierrc.yml"
    ".prettierrc.js"
    ".prettierrc.mjs"
    ".prettierrc.cjs"
    ".prettierrc.ts"
    ".prettierrc.mts"
    ".prettierrc.cts"
    ".prettierrc.toml"
    "prettier.config.js"
    "prettier.config.mjs"
    "prettier.config.cjs"
    "prettier.config.ts"
    "prettier.config.mts"
    "prettier.config.cts")
  "Recognized Prettier configuration filenames.")


(defun catie/prettier-project-root ()
  "Return nearest directory containing a project-local Prettier."

  (when buffer-file-name
    (locate-dominating-file
     (file-name-directory buffer-file-name)

     (lambda (dir)
       (file-exists-p
        (expand-file-name
         "node_modules/prettier/package.json"
         dir))))))


(defun catie/package-json-has-prettier-config-p (directory)
  "Return non-nil if DIRECTORY/package.json contains a `prettier` key."

  (let ((package-json
         (expand-file-name
          "package.json"
          directory)))

    (when
        (file-readable-p package-json)

      (condition-case nil

          (let ((data
                 (json-parse-string
                  (with-temp-buffer
                    (insert-file-contents package-json)
                    (buffer-string))

                  :object-type 'alist
                  :array-type 'list
                  :null-object nil
                  :false-object nil)))

            (assoc "prettier" data))

        (error nil)))))


(defun catie/directory-has-prettier-config-p (directory)
  "Return non-nil if DIRECTORY contains Prettier configuration."

  (or
   (seq-some
    (lambda (name)
      (file-exists-p
       (expand-file-name name directory)))
    catie/prettier-config-files)

   (catie/package-json-has-prettier-config-p
    directory)))


(defun catie/prettier-configured-p ()
  "Return non-nil if this file has project-local Prettier configuration."

  (when-let* ((file buffer-file-name)
              (root (catie/prettier-project-root)))

    (let ((directory
           (file-name-as-directory
            (file-name-directory file)))

          (root
           (file-name-as-directory
            (expand-file-name root)))

          found
          done)

      (while
          (and directory
               (not found)
               (not done))

        (setq found
              (catie/directory-has-prettier-config-p
               directory))

        (if
            (equal directory root)

            (setq done t)

          (let ((parent
                 (file-name-directory
                  (directory-file-name directory))))

            (if
                (or
                 (null parent)
                 (equal parent directory))

                (setq done t)

              (setq directory parent)))))

      found)))


(defun catie/prettier-eligible-p ()
  "Return non-nil when this buffer should use Prettier."

  (and
   buffer-file-name

   (memq
    major-mode
    catie/prettier-modes)

   (catie/prettier-project-root)

   (catie/prettier-configured-p)))


;; ---------------------------------------------------------------------------
;; prettier.el
;; ---------------------------------------------------------------------------

(use-package prettier
  :ensure t

  :commands
  (prettier-mode
   prettier-prettify
   prettier-info
   prettier-restart)

  :custom

  (prettier-prettify-on-save-flag
   t)

  (prettier-pre-warm
   'full)

  ;; Let the repository's Prettier configuration remain authoritative.
  (prettier-mode-sync-config-flag
   t)

  ;; Explicitly do NOT use EditorConfig.
  (prettier-editorconfig-flag
   nil)

  ;; Infer Svelte/Vue/etc. from the actual filename.
  (prettier-infer-parser-flag
   t)

  (prettier-diff-timeout-seconds
   0)

  (prettier-mode-lighter
   nil))


;; ---------------------------------------------------------------------------
;; Enable only when the project opts into Prettier
;; ---------------------------------------------------------------------------

(defun catie/maybe-enable-prettier ()
  "Enable Prettier only for buffers whose project is configured for it."

  (when
      (catie/prettier-eligible-p)

    (prettier-mode 1)))


(dolist (mode catie/prettier-modes)

  (add-hook
   (intern
    (format "%s-hook" mode))

   #'catie/maybe-enable-prettier))


;; ---------------------------------------------------------------------------
;; Manual formatting
;; ---------------------------------------------------------------------------

(defun catie/format-buffer ()
  "Format the current buffer with project Prettier."

  (interactive)

  (unless
      (catie/prettier-eligible-p)

    (user-error
     "This file does not have project-local configured Prettier"))

  (prettier-prettify))


(defun catie/formatting-status ()
  "Show formatting status for the current buffer."

  (interactive)

  (message
   "Prettier: %s | local install: %s | project config: %s"

   (if
       (bound-and-true-p prettier-mode)

       "enabled"

     "disabled")

   (or
    (catie/prettier-project-root)
    "none")

   (if
       (catie/prettier-configured-p)

       "yes"

     "no")))


;; ---------------------------------------------------------------------------
;; Leader bindings
;; ---------------------------------------------------------------------------

(catie/leader

  "c f"
  '(catie/format-buffer
    :which-key "format buffer")

  "c F"
  '(catie/formatting-status
    :which-key "formatting status"))


(provide 'catie-formatting)

;;; catie-formatting.el ends here
