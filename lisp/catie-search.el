;;; catie-search.el --- Editable project-wide search -*- lexical-binding: t; -*-

(require 'project)
(require 'compile)


;; ---------------------------------------------------------------------------
;; wgrep
;; ---------------------------------------------------------------------------

(use-package wgrep
  :ensure t
  :after grep

  :custom

  ;; Applying the wgrep transaction should also save the files it changed.
  (wgrep-auto-save-buffer t)

  ;; Don't silently override genuinely read-only files.
  (wgrep-change-readonly-file nil))


;; ---------------------------------------------------------------------------
;; Helpers
;; ---------------------------------------------------------------------------

(defun catie/search-project-root ()
  "Return the current project root."

  (file-name-as-directory
   (expand-file-name
    (project-root
     (project-current t)))))


(defun catie/editable-ripgrep-ready (buffer _status)
  "Turn completed grep BUFFER into an editable wgrep buffer."

  (when (buffer-live-p buffer)

    (with-current-buffer buffer

      (remove-hook
       'compilation-finish-functions
       #'catie/editable-ripgrep-ready
       t)

      (when (derived-mode-p 'grep-mode)

        (condition-case nil

            (progn

              (wgrep-change-to-wgrep-mode)

              ;; We actually want to edit this buffer with Vim motions.
              (when
                  (fboundp 'evil-normal-state)

                (evil-normal-state))

              (message
               "Editable results ready — edit, C-c C-e applies, C-c C-k aborts"))

          (error nil))))))


;; ---------------------------------------------------------------------------
;; Editable ripgrep
;; ---------------------------------------------------------------------------

(defun catie/project-replace ()
  "Ripgrep the project and open the results as an editable transaction."

  (interactive)

  (unless (executable-find "rg")
    (user-error
     "ripgrep is not available"))

  (let* ((root
          (catie/search-project-root))

         (initial
          (thing-at-point
           'symbol
           t))

         (pattern
          (read-string
           "Project replace search: "
           initial))

         (default-directory
          root)

         (project-name
          (file-name-nondirectory
           (directory-file-name root)))

         (command
          (format
           "rg --line-number --no-heading --with-filename --color=never --smart-case -- %s ."

           (shell-quote-argument
            pattern)))

         (buffer
          (compilation-start
           command
           'grep-mode

           (lambda (_)
             (format
              "*replace:%s*"
              project-name)))))

    (with-current-buffer buffer

      (add-hook
       'compilation-finish-functions
       #'catie/editable-ripgrep-ready
       nil
       t))

    (pop-to-buffer
     buffer)))


;; ---------------------------------------------------------------------------
;; Keys
;; ---------------------------------------------------------------------------

(catie/leader

  "s R"
  '(catie/project-replace
    :which-key "editable project replace"))


(provide 'catie-search)

;;; catie-search.el ends here
