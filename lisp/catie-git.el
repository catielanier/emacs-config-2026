;;; catie-git.el --- Git with one persistent LazyGit tab -*- lexical-binding: t; -*-

(require 'project)


;; ---------------------------------------------------------------------------
;; LazyGit tab state
;; ---------------------------------------------------------------------------

(defconst catie/lazygit-tab-name
  "LazyGit"
  "Name of the shared LazyGit tab.")


(defconst catie/lazygit-buffer-name
  "*lazygit*"
  "Name of the shared LazyGit vterm buffer.")


(defvar catie/lazygit-autostart-done nil
  "Non-nil once LazyGit autostart has been attempted this Emacs session.")


;; ---------------------------------------------------------------------------
;; Helpers
;; ---------------------------------------------------------------------------

(defun catie/lazygit-tab-exists-p ()
  "Return non-nil when the shared LazyGit tab exists."

  (member
   catie/lazygit-tab-name

   (mapcar
    (lambda (tab)
      (alist-get 'name tab))

    (tab-bar-tabs))))


(defun catie/current-tab-name ()
  "Return the name of the currently selected Emacs tab."

  (alist-get
   'name
   (tab-bar--current-tab)))


(defun catie/lazygit-project-root ()
  "Return the current project's root."

  (project-root
   (project-current t)))


;; ---------------------------------------------------------------------------
;; LazyGit buffer
;; ---------------------------------------------------------------------------

(defun catie/lazygit-create-buffer (root)
  "Create the shared LazyGit vterm buffer rooted initially at ROOT.

If the buffer already exists, return it unchanged."

  (require 'vterm)

  (let ((existing
         (get-buffer
          catie/lazygit-buffer-name)))

    (if existing

        existing

      (let ((buffer
             (get-buffer-create
              catie/lazygit-buffer-name)))

        (with-current-buffer buffer

          (setq default-directory
                (file-name-as-directory
                 (expand-file-name root)))

          ;; Initialize the terminal directly in this buffer.
          (vterm-mode)

          ;; Explicit Emacs-side controls from inside LazyGit/vterm.
          (local-set-key
           (kbd "C-c q")
           #'catie/lazygit-close-tab)

          (local-set-key
           (kbd "C-c g")
           #'catie/lazygit-run))

        buffer))))


(defun catie/lazygit-run ()
  "Run LazyGit in the shared LazyGit terminal."

  (interactive)

  (unless (derived-mode-p 'vterm-mode)
    (user-error
     "LazyGit terminal is not active"))

  (unless (executable-find "lazygit")
    (user-error
     "lazygit is not available on PATH"))

  (vterm-send-string
   "lazygit")

  (vterm-send-return))


;; ---------------------------------------------------------------------------
;; Create shared LazyGit tab
;; ---------------------------------------------------------------------------

(defun catie/lazygit-create-tab (root &optional background)
  "Create the shared LazyGit tab rooted initially at ROOT.

When BACKGROUND is non-nil, return to the tab that was selected
before LazyGit was created."

  (unless (executable-find "lazygit")
    (user-error
     "lazygit is not available on PATH"))

  (if (catie/lazygit-tab-exists-p)

      ;; Already exists.
      (unless background
        (tab-bar-switch-to-tab
         catie/lazygit-tab-name))

    ;; Need to create it.
    (let ((return-tab
           (catie/current-tab-name))

          ;; LazyGit is our permanent right-hand sentinel.
          (tab-bar-new-tab-to
           'rightmost)

          ;; If we're background-creating it, don't show the intermediate
          ;; switch on terminal Emacs.
          (inhibit-redisplay
           background))

      (tab-new)

      (tab-bar-rename-tab
       catie/lazygit-tab-name)

      (delete-other-windows)

      (let* ((existing-buffer
              (get-buffer
               catie/lazygit-buffer-name))

             (buffer
              (or
               existing-buffer
               (catie/lazygit-create-buffer root))))

        (switch-to-buffer
         buffer)

        ;; Only launch LazyGit automatically when this is a fresh buffer.
        ;;
        ;; If the buffer survived a closed tab, preserve whatever is already
        ;; running inside it.
        (unless existing-buffer
          (catie/lazygit-run)))

      ;; Background autostart means the user never leaves the project tab.
      (when background
        (tab-bar-switch-to-tab
         return-tab)))))


;; ---------------------------------------------------------------------------
;; First-project autostart
;; ---------------------------------------------------------------------------

(defun catie/lazygit-autostart-for-first-project (root)
  "Create LazyGit silently when the first project is opened.

This runs at most once per Emacs session.  If the user later closes
LazyGit, opening another project will not automatically recreate it."

  (unless catie/lazygit-autostart-done

    ;; Mark this before attempting startup so a failure doesn't cause every
    ;; subsequent project switch to keep retrying.
    (setq catie/lazygit-autostart-done
          t)

    (condition-case err

        (catie/lazygit-create-tab
         root
         t)

      (error

       (message
        "LazyGit autostart failed: %s"
        (error-message-string err))))))


;; ---------------------------------------------------------------------------
;; Interactive LazyGit
;; ---------------------------------------------------------------------------

(defun catie/lazygit ()
  "Switch to the shared LazyGit tab, creating it if necessary."

  (interactive)

  (if (catie/lazygit-tab-exists-p)

      (tab-bar-switch-to-tab
       catie/lazygit-tab-name)

    ;; Manual recreation is always allowed, even after first-project
    ;; autostart has already happened.
    (catie/lazygit-create-tab
     (catie/lazygit-project-root)
     nil)))


(defun catie/lazygit-close-tab ()
  "Close the shared LazyGit tab without killing its vterm buffer."

  (interactive)

  (if (equal
       (catie/current-tab-name)
       catie/lazygit-tab-name)

      (tab-close)

    (user-error
     "Current tab is not the LazyGit tab")))


;; ---------------------------------------------------------------------------
;; Leader bindings
;; ---------------------------------------------------------------------------

(catie/leader

  "g"
  '(:ignore t
    :which-key "git")

  "g g"
  '(catie/lazygit
    :which-key "LazyGit"))


(provide 'catie-git)

;;; catie-git.el ends here
