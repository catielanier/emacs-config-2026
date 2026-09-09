;;; catie-macos.el --- macOS-specific behaviour -*- lexical-binding: t; -*-

(defun catie/macos-copy (text &optional _push)
  "Copy TEXT to the macOS system clipboard."
  (with-temp-buffer
    (insert text)
    (call-process-region
     (point-min)
     (point-max)
     "pbcopy")))

(defun catie/macos-paste ()
  "Return text currently on the macOS system clipboard."
  (shell-command-to-string "pbpaste"))

(setq interprogram-cut-function #'catie/macos-copy
      interprogram-paste-function #'catie/macos-paste)

(require 'browse-url)

(setq browse-url-browser-function
      #'browse-url-default-macosx-browser)

(provide 'catie-macos)
;;; catie-macos.el ends here
