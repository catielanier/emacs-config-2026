;;; catie-git.el --- Git with LazyGit -*- lexical-binding: t; -*-

(require 'project)
(require 'seq)


(defun catie/git-project-root ()
  "Return the current project's root."
  (project-root
   (project-current t)))


(defun catie/git-project-name (root)
  "Return a display name for project ROOT."
  (file-name-nondirectory
   (directory-file-name root)))


(defun catie/git-tab-name (root)
  "Return the Git tab name for ROOT."
  (format
   "%s:git"
   (catie/git-project-name root)))


(defun catie/lazygit-buffer-name (root)
  "Return the LazyGit vterm buffer name for ROOT."
  (format
   "*lazygit:%s*"
   (catie/git-project-name root)))


(defun catie/tab-exists-p (name)
  "Return non-nil if an Emacs tab named NAME exists."
  (seq-some
   (lambda (tab)
     (equal
      (alist-get 'name tab)
      name))
   (tab-bar-tabs)))


(defun catie/lazygit-close-tab ()
  "Close the current Git tab."
  (interactive)
  (tab-close))


(defun catie/lazygit-run ()
  "Run LazyGit inside the current vterm."
  (interactive)

  (unless (derived-mode-p 'vterm-mode)
    (user-error "Not inside vterm"))

  (vterm-send-string "lazygit")
  (vterm-send-return))


(defun catie/lazygit ()
  "Open LazyGit for the current project in its own Emacs tab."
  (interactive)

  (unless (executable-find "lazygit")
    (user-error "lazygit is not available on PATH"))

  (require 'vterm)

  (let* ((root
          (catie/git-project-root))

         (tab-name
          (catie/git-tab-name root))

         (buffer-name
          (catie/lazygit-buffer-name root)))

    ;; Existing Git workspace.
    (if (catie/tab-exists-p tab-name)

        (tab-bar-switch-to-tab
         tab-name)

      ;; New Git workspace.
      (tab-new)

      (tab-bar-rename-tab
       tab-name)

      (delete-other-windows)

      (let ((buffer
             (get-buffer-create
              buffer-name)))

        (switch-to-buffer
         buffer)

        (setq default-directory root)

        (unless (derived-mode-p 'vterm-mode)
          (vterm-mode))

        ;; Explicit Emacs controls from the LazyGit terminal.
        (local-set-key
         (kbd "C-c q")
         #'catie/lazygit-close-tab)

        (local-set-key
         (kbd "C-c g")
         #'catie/lazygit-run)

        (catie/lazygit-run)))))


(catie/leader

  "g"
  '(:ignore t :which-key "git")

  "g g"
  '(catie/lazygit
    :which-key "LazyGit"))


(provide 'catie-git)

;;; catie-git.el ends here
