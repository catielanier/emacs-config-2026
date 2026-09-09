;;; catie-projects.el --- Projects and workspaces -*- lexical-binding: t; -*-

(require 'project)


;; ---------------------------------------------------------------------------
;; Project home buffer
;; ---------------------------------------------------------------------------

(define-derived-mode catie-project-home-mode special-mode "Project"
  "Major mode for Catie's project home buffers.")

(with-eval-after-load 'evil
  ;; The dashboard is part of our editing environment, so it should support
  ;; the SPC leader even though it derives from special-mode.
  (evil-set-initial-state 'catie-project-home-mode 'normal))


;; ---------------------------------------------------------------------------
;; Project discovery
;; ---------------------------------------------------------------------------

(defconst catie/projects-root
  (expand-file-name "~/projects/")
  "Root directory containing Catie's projects.")

(defun catie/refresh-projects ()
  "Discover projects directly beneath `catie/projects-root'."
  (interactive)

  (when (file-directory-p catie/projects-root)
    ;; Non-recursive intentionally.
    ;;
    ;; ~/projects/foo
    ;; ~/projects/bar
    ;;
    ;; We do not want to crawl through node_modules or nested repositories.
    (project-remember-projects-under
     catie/projects-root
     nil)))

(add-hook 'emacs-startup-hook #'catie/refresh-projects)


;; ---------------------------------------------------------------------------
;; Project naming
;; ---------------------------------------------------------------------------

(defun catie/project-name-from-root (root)
  "Return a clean project name for ROOT."
  (file-name-nondirectory
   (directory-file-name
    (expand-file-name root))))

(defun catie/current-tab-names ()
  "Return the names of all current Emacs tabs."
  (mapcar
   (lambda (tab)
     (alist-get 'name tab))
   (tab-bar-tabs)))


;; ---------------------------------------------------------------------------
;; Project dashboard
;; ---------------------------------------------------------------------------

(defun catie/project-home-buffer (root)
  "Return the project home buffer for ROOT."

  (let* ((root
          (file-name-as-directory
           (expand-file-name root)))

         (name
          (catie/project-name-from-root root))

         (buffer
          (get-buffer-create
           (format "*project:%s*" name))))

    (with-current-buffer buffer

      ;; This is important: project.el, Treemacs, Magit, Eat, etc. can all
      ;; derive the current project from this directory.
      (setq default-directory root)

      (unless (derived-mode-p 'catie-project-home-mode)
        (catie-project-home-mode))

      (let ((inhibit-read-only t))

        (erase-buffer)

        (insert
         (propertize
          name
          'face
          '(:weight bold :height 1.4)))

        (insert "\n")
        (insert root)
        (insert "\n\n")

        (insert "SPC p f    find file\n")
        (insert "SPC p g    search project\n")
        (insert "SPC t t    terminal split\n")
        (insert "SPC t T    terminal tab\n")
        (insert "SPC g g    Magit\n")))

    buffer))


;; ---------------------------------------------------------------------------
;; IDE layout
;; ---------------------------------------------------------------------------

(defun catie/project-layout (root)
  "Create Catie's standard IDE layout for project ROOT."

  (let* ((root
          (file-name-as-directory
           (expand-file-name root)))

         (home-buffer
          (catie/project-home-buffer root)))

    ;; Put the dashboard in the main editor window.
    (switch-to-buffer home-buffer)

    ;; Ensure project-sensitive commands resolve against this project.
    (setq default-directory root)

    ;; New project workspace starts clean.
    (delete-other-windows)

    ;; Keep track of the editor window because Treemacs may focus itself
    ;; while being created.
    (let ((editor-window
           (selected-window)))

      (require 'treemacs)

      ;; Show only this project's tree.
      (treemacs-display-current-project-exclusively)

      ;; Return focus to the editor.
      (when (window-live-p editor-window)
        (select-window editor-window)))))


;; ---------------------------------------------------------------------------
;; Tabspaces
;; ---------------------------------------------------------------------------

(use-package tabspaces
  :after project

  :custom

  ;; Each tab/workspace gets its own buffer collection.
  (tabspaces-use-filtered-buffers-as-default t)

  (tabspaces-default-tab "Home")

  (tabspaces-remove-to-default t)

  (tabspaces-include-buffers
   '("*scratch*"))

  ;; Never create anything inside a project repository.
  (tabspaces-initialize-project-with-todo nil)

  ;; No workspace/session files.
  (tabspaces-session nil)
  (tabspaces-session-auto-restore nil)

  ;; We provide our own leader bindings.
  (tabspaces-keymap-prefix nil)

  (tabspaces-fully-resolve-paths t)

  (tab-bar-new-tab-choice "*scratch*")

  :config

  (setq tab-bar-show 1
        tab-bar-close-button-show nil
        tab-bar-new-button-show nil
        tab-bar-tab-hints t)

  (tabspaces-mode 1)
  (tab-bar-mode 1)

  (tab-bar-rename-tab "Home"))


;; ---------------------------------------------------------------------------
;; Open project
;; ---------------------------------------------------------------------------

(defun catie/open-project-workspace ()
  "Open an existing known project in its own workspace.

Unlike `tabspaces-open-or-create-project-and-workspace', this does not
invoke `project-switch-project' and therefore does not open Emacs'
project command dispatcher."

  (interactive)

  (let ((projects
         (project-known-project-roots)))

    (unless projects
      (user-error
       "No projects known; run M-x catie/refresh-projects"))

    (let* ((selected-root
            (completing-read
             "Project: "
             projects
             nil
             t))

           (root
            (file-name-as-directory
             (expand-file-name selected-root)))

           (workspace-name
            (catie/project-name-from-root root))

           (already-open
            (member
             workspace-name
             (catie/current-tab-names))))

      ;; IMPORTANT:
      ;;
      ;; Do NOT use:
      ;;
      ;;   tabspaces-open-or-create-project-and-workspace
      ;;
      ;; That function invokes project-switch-project, which is where the
      ;; "Command in ~/projects/...: f Find file..." menu came from.
      ;;
      ;; This function only switches/creates the tab.
      (tabspaces-switch-or-create-workspace
       workspace-name)

      ;; If we're creating this workspace for the first time, build the
      ;; standard IDE layout.
      ;;
      ;; If the workspace already exists, preserve its buffers, splits,
      ;; terminals, etc.
      (unless already-open

        ;; The scratch buffer inherited by a newly-created tab doesn't know
        ;; which project we're in yet.
        (setq default-directory root)

        (catie/project-layout root)))))


;; ---------------------------------------------------------------------------
;; Project file/search commands
;; ---------------------------------------------------------------------------

(defun catie/project-find-file ()
  "Find a file in the current project."
  (interactive)

  (let ((project
         (project-current t)))

    (project-find-file project)))


(defun catie/consult-ripgrep-project ()
  "Ripgrep through the current project."

  (interactive)

  (require 'consult)

  (let ((project
         (project-current t)))

    (consult-ripgrep
     (project-root project))))


;; ---------------------------------------------------------------------------
;; Consult workspace buffers
;; ---------------------------------------------------------------------------

(with-eval-after-load 'consult

  (with-eval-after-load 'tabspaces

    ;; Keep global buffers available, but don't make them the default.
    (plist-put consult-source-buffer :hidden t)
    (plist-put consult-source-buffer :default nil)

    (defvar consult--source-workspace
      (list
       :name "Workspace Buffers"
       :narrow ?w
       :history 'buffer-name-history
       :category 'buffer
       :state #'consult--buffer-state
       :default t

       :items
       (lambda ()
         (consult--buffer-query
          :predicate #'tabspaces--local-buffer-p
          :sort 'visibility
          :as #'buffer-name)))

      "Workspace-local buffer source for Consult.")

    (add-to-list
     'consult-buffer-sources
     'consult--source-workspace)))


;; ---------------------------------------------------------------------------
;; Leader bindings
;; ---------------------------------------------------------------------------

(catie/leader

  ;; -------------------------------------------------------------------------
  ;; Workspaces
  ;; -------------------------------------------------------------------------

  "TAB"
  '(:ignore t :which-key "workspace")

  "TAB TAB"
  '(tabspaces-switch-or-create-workspace
    :which-key "switch/create")

  "TAB n"
  '(tab-new
    :which-key "new")

  "TAB c"
  '(tabspaces-close-workspace
    :which-key "close")

  "TAB k"
  '(tabspaces-kill-buffers-close-workspace
    :which-key "close + kill buffers")

  "TAB s"
  '(tab-switch
    :which-key "switch by name")


  ;; -------------------------------------------------------------------------
  ;; Projects
  ;; -------------------------------------------------------------------------

  "p"
  '(:ignore t :which-key "project")

  "p p"
  '(catie/open-project-workspace
    :which-key "switch project")

  "p f"
  '(catie/project-find-file
    :which-key "find file")

  "p b"
  '(project-switch-to-buffer
    :which-key "project buffer")

  "p g"
  '(catie/consult-ripgrep-project
    :which-key "ripgrep")

  "p d"
  '(project-dired
    :which-key "project directory")

  "p r"
  '(catie/refresh-projects
    :which-key "refresh projects")


  ;; -------------------------------------------------------------------------
  ;; UI
  ;; -------------------------------------------------------------------------

  "o"
  '(:ignore t :which-key "open")

  "o t"
  '(treemacs-select-window
    :which-key "file tree"))


(provide 'catie-projects)

;;; catie-projects.el ends here
