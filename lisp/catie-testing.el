;;; catie-testing.el --- Tests, verification and project tasks -*- lexical-binding: t; -*-

(require 'project)
(require 'json)
(require 'seq)
(require 'subr-x)
(require 'compile)


;; ---------------------------------------------------------------------------
;; Generic task runner
;; ---------------------------------------------------------------------------

(defvar catie/last-task-command nil
  "Last command launched by Catie's task runner.")

(defvar catie/last-task-directory nil
  "Working directory of the last task.")

(defvar catie/last-task-name nil
  "Name of the last task.")


(defun catie/task-project-root ()
  "Return the current project root."

  (file-name-as-directory
   (expand-file-name
    (project-root
     (project-current t)))))


(defun catie/task-relative-file ()
  "Return the current file relative to the project."

  (unless buffer-file-name
    (user-error "Current buffer is not visiting a file"))

  (file-relative-name
   buffer-file-name
   (catie/task-project-root)))


(defun catie/run-task (command &optional directory name)
  "Run COMMAND in a compilation buffer."

  (let* ((directory
          (file-name-as-directory
           (expand-file-name
            (or directory
                (catie/task-project-root)))))

         (name
          (or name "task"))

         (default-directory
          directory))

    (setq catie/last-task-command
          command)

    (setq catie/last-task-directory
          directory)

    (setq catie/last-task-name
          name)

    (compilation-start
     command
     'compilation-mode
     (lambda (_)
       (format
        "*%s:%s*"
        name
        (file-name-nondirectory
         (directory-file-name directory)))))))


(defun catie/rerun-last-task ()
  "Rerun the most recently launched task."

  (interactive)

  (unless catie/last-task-command
    (user-error "No task has been run yet"))

  (catie/run-task
   catie/last-task-command
   catie/last-task-directory
   catie/last-task-name))


;; ---------------------------------------------------------------------------
;; JSON / package metadata
;; ---------------------------------------------------------------------------

(defun catie/read-json (file)
  "Return FILE parsed as an alist, or nil."

  (when (file-readable-p file)

    (condition-case nil

        (with-temp-buffer

          (insert-file-contents file)

          (json-parse-buffer
           :object-type 'alist
           :array-type 'list
           :null-object nil
           :false-object nil))

      (error nil))))


(defun catie/package-json ()
  "Return the current project's package.json."

  (catie/read-json
   (expand-file-name
    "package.json"
    (catie/task-project-root))))


(defun catie/package-scripts ()
  "Return scripts from the current package.json."

  (alist-get
   "scripts"
   (catie/package-json)
   nil
   nil
   #'string=))


(defun catie/package-script-p (name)
  "Return non-nil when package.json defines NAME."

  (assoc-string
   name
   (catie/package-scripts)
   t))


(defun catie/first-package-script (names)
  "Return the first package script present from NAMES."

  (seq-find
   #'catie/package-script-p
   names))


;; ---------------------------------------------------------------------------
;; Node package manager
;; ---------------------------------------------------------------------------

(defun catie/node-package-manager ()
  "Return the package manager used by the current project."

  (let ((root
         (catie/task-project-root)))

    (cond

     ((file-exists-p
       (expand-file-name
        "pnpm-lock.yaml"
        root))
      "pnpm")

     ((file-exists-p
       (expand-file-name
        "yarn.lock"
        root))
      "yarn")

     ((or
       (file-exists-p
        (expand-file-name
         "bun.lock"
         root))

       (file-exists-p
        (expand-file-name
         "bun.lockb"
         root)))
      "bun")

     (t
      "npm"))))


(defun catie/node-script-command (script)
  "Return the command used to run SCRIPT."

  (format
   "%s run %s"
   (shell-quote-argument
    (catie/node-package-manager))

   (shell-quote-argument
    script)))


(defun catie/project-node-bin (name)
  "Return project-local Node executable NAME, or nil."

  (let ((path
         (expand-file-name
          (format
           "node_modules/.bin/%s"
           name)

          (catie/task-project-root))))

    (when
        (file-executable-p path)

      path)))


;; ---------------------------------------------------------------------------
;; Jest / Playwright detection
;; ---------------------------------------------------------------------------

(defun catie/playwright-file-p ()
  "Return non-nil when the current file looks like a Playwright test."

  (let ((file
         (downcase
          (catie/task-relative-file))))

    (or
     (string-match-p
      "\\(?:^\\|/\\)e2e/"
      file)

     (string-match-p
      "\\(?:^\\|/\\)playwright/"
      file))))


(defun catie/node-test-framework ()
  "Return the most appropriate Node test framework."

  (cond

   ((and
     (catie/project-node-bin "playwright")
     (catie/playwright-file-p))
    'playwright)

   ((catie/project-node-bin "jest")
    'jest)

   ((catie/project-node-bin "playwright")
    'playwright)

   (t
    nil)))


;; ---------------------------------------------------------------------------
;; Current test names
;; ---------------------------------------------------------------------------

(defun catie/current-go-test ()
  "Return the nearest Go test function."

  (save-excursion

    (when
        (re-search-backward
         "^func[ \t]+\\(Test[[:alnum:]_]+\\)[ \t]*("
         nil
         t)

      (match-string-no-properties 1))))


(defun catie/current-js-test ()
  "Return the nearest Jest/Playwright test name."

  (save-excursion

    (when
        (re-search-backward
         "\\_<\\(?:it\\|test\\)\\s-*([[:space:]\n]*['\"`]\\([^'\"`]+\\)['\"`]"
         nil
         t)

      (match-string-no-properties 1))))


(defun catie/current-php-test ()
  "Return the nearest PHPUnit test method."

  (save-excursion

    (when
        (re-search-backward
         "function[ \t\n]+\\(test[[:alnum:]_]+\\)[ \t\n]*("
         nil
         t)

      (match-string-no-properties 1))))


;; ---------------------------------------------------------------------------
;; Test current item
;; ---------------------------------------------------------------------------

(defun catie/test-current ()
  "Run the test nearest point."

  (interactive)

  (cond

   ;; Go
   ((derived-mode-p 'go-ts-mode)

    (if-let ((name
              (catie/current-go-test)))

        (catie/run-task
         (format
          "go test -run %s ."
          (shell-quote-argument
           (format "^%s$" name)))

         (file-name-directory
          buffer-file-name)

         "test")

      (catie/test-file)))


   ;; PHPUnit
   ((derived-mode-p 'php-ts-mode)

    (let* ((phpunit
            (expand-file-name
             "vendor/bin/phpunit"
             (catie/task-project-root)))

           (name
            (catie/current-php-test)))

      (unless (file-executable-p phpunit)
        (user-error
         "No project-local PHPUnit found"))

      (if name

          (catie/run-task
           (format
            "%s --filter %s %s"

            (shell-quote-argument phpunit)

            (shell-quote-argument name)

            (shell-quote-argument
             (catie/task-relative-file)))

           nil
           "test")

        (catie/test-file))))


   ;; JS / TS / TSX / Vue / Svelte
   ((memq
     major-mode
     '(js-ts-mode
       typescript-ts-mode
       tsx-ts-mode
       web-mode))

    (let ((framework
           (catie/node-test-framework))

          (test-name
           (catie/current-js-test))

          (file
           (catie/task-relative-file)))

      (unless framework
        (user-error
         "No project-local Jest or Playwright found"))

      (unless test-name
        (catie/test-file))

      (when test-name

        (pcase framework

          ('jest

           (catie/run-task
            (format
             "%s %s -t %s"

             (shell-quote-argument
              (catie/project-node-bin "jest"))

             (shell-quote-argument file)

             (shell-quote-argument test-name))

            nil
            "test"))


          ('playwright

           (catie/run-task
            (format
             "%s test %s -g %s"

             (shell-quote-argument
              (catie/project-node-bin "playwright"))

             (shell-quote-argument file)

             (shell-quote-argument test-name))

            nil
            "test"))))))


   (t

    (user-error
     "Current-test runner not configured for %s"
     major-mode))))


;; ---------------------------------------------------------------------------
;; Test current file
;; ---------------------------------------------------------------------------

(defun catie/test-file ()
  "Run tests for the current file."

  (interactive)

  (unless buffer-file-name
    (user-error
     "Current buffer is not visiting a file"))

  (cond

   ;; Go tests are package-level.
   ((derived-mode-p 'go-ts-mode)

    (catie/run-task
     "go test ."

     (file-name-directory
      buffer-file-name)

     "test"))


   ;; PHPUnit
   ((derived-mode-p 'php-ts-mode)

    (let ((phpunit
           (expand-file-name
            "vendor/bin/phpunit"
            (catie/task-project-root))))

      (unless (file-executable-p phpunit)
        (user-error
         "No project-local PHPUnit found"))

      (catie/run-task
       (format
        "%s %s"

        (shell-quote-argument phpunit)

        (shell-quote-argument
         (catie/task-relative-file)))

       nil
       "test")))


   ;; Python
   ((derived-mode-p 'python-ts-mode)

    (catie/run-task
     (format
      "python -m pytest %s"

      (shell-quote-argument
       (catie/task-relative-file)))

     nil
     "test"))


   ;; Node
   ((memq
     major-mode
     '(js-ts-mode
       typescript-ts-mode
       tsx-ts-mode
       web-mode))

    (let ((framework
           (catie/node-test-framework))

          (file
           (catie/task-relative-file)))

      (pcase framework

        ('jest

         (catie/run-task
          (format
           "%s %s"

           (shell-quote-argument
            (catie/project-node-bin "jest"))

           (shell-quote-argument file))

          nil
          "test"))


        ('playwright

         (catie/run-task
          (format
           "%s test %s"

           (shell-quote-argument
            (catie/project-node-bin "playwright"))

           (shell-quote-argument file))

          nil
          "test"))


        (_

         (user-error
          "No project-local Jest or Playwright found")))))


   (t

    (user-error
     "File-test runner not configured for %s"
     major-mode))))


;; ---------------------------------------------------------------------------
;; Project test
;; ---------------------------------------------------------------------------

(defun catie/test-project ()
  "Run the project's normal test suite."

  (interactive)

  (let ((root
         (catie/task-project-root)))

    (cond

     ;; Node project script is authoritative.
     ((and
       (file-exists-p
        (expand-file-name "package.json" root))

       (catie/package-script-p "test"))

      (catie/run-task
       (catie/node-script-command "test")
       root
       "test"))


     ;; Go
     ((file-exists-p
       (expand-file-name "go.mod" root))

      (catie/run-task
       "go test ./..."
       root
       "test"))


     ;; PHP
     ((file-executable-p
       (expand-file-name
        "vendor/bin/phpunit"
        root))

      (catie/run-task
       "./vendor/bin/phpunit"
       root
       "test"))


     ;; .NET
     ((directory-files
       root
       nil
       "\\.\\(?:sln\\|csproj\\)\\'"
       t)

      (catie/run-task
       "dotnet test"
       root
       "test"))


     ;; Gradle / Kotlin
     ((file-executable-p
       (expand-file-name
        "gradlew"
        root))

      (catie/run-task
       "./gradlew test"
       root
       "test"))


     ;; Python
     ((or
       (file-exists-p
        (expand-file-name "pyproject.toml" root))

       (file-exists-p
        (expand-file-name "pytest.ini" root)))

      (catie/run-task
       "python -m pytest"
       root
       "test"))


     (t

      (user-error
       "Couldn't determine this project's test command")))))


;; ---------------------------------------------------------------------------
;; Project verification
;; ---------------------------------------------------------------------------

(defun catie/node-verification-command ()
  "Build verification command from scripts the repository actually defines."

  ;; An explicit umbrella command wins.
  (if-let ((umbrella
            (catie/first-package-script
             '("verify" "validate"))))

      (catie/node-script-command
       umbrella)

    (let* ((groups
            '(("lint:check" "lint")
              ("format:check"
               "check:format"
               "prettier:check")
              ("typecheck"
               "type-check"
               "check:types"
               "types:check")
              ("test:ci" "test")))

           (scripts
            (delq
             nil
             (mapcar
              #'catie/first-package-script
              groups))))

      ;; Some repos deliberately expose one `check' command.
      (when
          (and
           (null scripts)
           (catie/package-script-p "check"))

        (setq scripts
              '("check")))

      (when scripts

        (mapconcat
         #'catie/node-script-command
         scripts
         " && ")))))


(defun catie/project-verify ()
  "Run authoritative project verification.

For Node projects, use only scripts declared by package.json.
Other ecosystems use their normal project verification commands."

  (interactive)

  (let* ((root
          (catie/task-project-root))

         command)

    (cond

     ;; Node
     ((file-exists-p
       (expand-file-name
        "package.json"
        root))

      (setq command
            (catie/node-verification-command))

      (unless command
        (user-error
         "No verification scripts found in package.json")))


     ;; Go
     ((file-exists-p
       (expand-file-name
        "go.mod"
        root))

      (setq command
            "go vet ./... && go test ./..."))


     ;; PHP: trust Composer's project script when present.
     ((file-exists-p
       (expand-file-name
        "composer.json"
        root))

      (let* ((composer
              (catie/read-json
               (expand-file-name
                "composer.json"
                root)))

             (scripts
              (alist-get
               "scripts"
               composer
               nil
               nil
               #'string=))

             (script
              (seq-find
               (lambda (name)
                 (assoc-string
                  name
                  scripts
                  t))
               '("verify"
                 "validate"
                 "check"
                 "test"))))

        (unless script
          (user-error
           "No verification script found in composer.json"))

        (setq command
              (format
               "composer run-script %s"
               (shell-quote-argument script)))))


     ;; Gradle's `check' is its normal verification lifecycle.
     ((file-executable-p
       (expand-file-name
        "gradlew"
        root))

      (setq command
            "./gradlew check"))


     ;; .NET
     ((directory-files
       root
       nil
       "\\.\\(?:sln\\|csproj\\)\\'"
       t)

      (setq command
            "dotnet test"))


     (t

      (user-error
       "No project verification strategy detected")))

    (catie/run-task
     command
     root
     "verify")))


;; ---------------------------------------------------------------------------
;; AWS CDK
;; ---------------------------------------------------------------------------

(defun catie/cdk-executable ()
  "Return the project's CDK executable."

  (or
   (catie/project-node-bin "cdk")
   (executable-find "cdk")))


(defun catie/run-cdk (command)
  "Run CDK COMMAND."

  (let ((cdk
         (catie/cdk-executable)))

    (unless cdk
      (user-error
       "No project-local or PATH cdk found"))

    (catie/run-task
     (format
      "%s %s"
      (shell-quote-argument cdk)
      command)

     nil
     "cdk")))


(defun catie/cdk-synth ()
  "Run CDK synth."

  (interactive)

  (catie/run-cdk
   "synth"))


(defun catie/cdk-diff ()
  "Run CDK diff."

  (interactive)

  (catie/run-cdk
   "diff"))


;; ---------------------------------------------------------------------------
;; Keys
;; ---------------------------------------------------------------------------

(catie/leader

  "r"
  '(:ignore t
    :which-key "run")

  "r t"
  '(catie/test-current
    :which-key "test current")

  "r f"
  '(catie/test-file
    :which-key "test file")

  "r p"
  '(catie/test-project
    :which-key "test project")

  "r r"
  '(catie/rerun-last-task
    :which-key "rerun")

  "r s"
  '(catie/cdk-synth
    :which-key "CDK synth")

  "r d"
  '(catie/cdk-diff
    :which-key "CDK diff")

  "p v"
  '(catie/project-verify
    :which-key "verify project"))


(provide 'catie-testing)

;;; catie-testing.el ends here
