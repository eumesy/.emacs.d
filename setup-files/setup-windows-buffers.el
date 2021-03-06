;; Time-stamp: <2015-05-11 14:38:39 kmodi>

;; Functions to manipulate windows and buffers

;; http://www.emacswiki.org/emacs/WinnerMode
;; Winner Mode is a global minor mode. When activated, it allows to “undo”
;; (and “redo”) changes in the window configuration with the key commands
;; ‘C-c left’ and ‘C-c right’
(use-package winner
  :config
  (progn
    (winner-mode 1)))

;; Uniquify
;; The library uniquify overrides Emacs’ default mechanism for making buffer
;; names unique (using suffixes like <2>, <3> etc.) with a more sensible
;; behaviour which use parts of the file names to make the buffer names
;; distinguishable.
(use-package uniquify
  :config
  (progn
    (setq uniquify-buffer-name-style 'post-forward)))

;; http://www.emacswiki.org/emacs/RecentFiles
(use-package recentf
  :config
  (progn
    (recentf-mode 1)
    (setq recentf-max-menu-items 2000)))

(use-package windmove
  :config
  (progn
    (setq windmove-wrap-around t) ; default = nil
    (windmove-default-keybindings) ; Bind windmove nav to S-left/right/up/down

    (key-chord-define-global "p[" #'windmove-left)
    (key-chord-define-global "[]" #'windmove-right)))

;; Reopen Killed File
;; http://emacs.stackexchange.com/a/3334/115
(defvar killed-file-list nil
  "List of recently killed files.")

(defun add-file-to-killed-file-list ()
  "If buffer is associated with a file name, add that file to the
`killed-file-list' when killing the buffer."
  (when buffer-file-name
    (push buffer-file-name killed-file-list)))

(add-hook 'kill-buffer-hook #'add-file-to-killed-file-list)

(defun reopen-killed-file ()
  "Reopen the most recently killed file, if one exists."
  (interactive)
  (if killed-file-list
      (find-file (pop killed-file-list))
    (message "No recently killed file found to reopen.")))

;; Transpose Frame
;; Converts between horz-split <-> vert-split. In addition it also rotates
;; the windows around in the frame when you have 3 or more windows.
(use-package transpose-frame
  :load-path "elisp/transpose-frame/")

;; http://www.whattheemacsd.com/
(defun rotate-windows ()
  "Rotate your windows"
  (interactive)
  (cond ((not (> (count-windows)1))
         (message "You can't rotate a single window!"))
        (t
         (setq i 1)
         (setq numWindows (count-windows))
         (while  (< i numWindows)
           (let* (
                  (w1 (elt (window-list) i))
                  (w2 (elt (window-list) (+ (% i numWindows) 1)))

                  (b1 (window-buffer w1))
                  (b2 (window-buffer w2))

                  (s1 (window-start w1))
                  (s2 (window-start w2))
                  )
             (set-window-buffer w1  b2)
             (set-window-buffer w2 b1)
             (set-window-start w1 s2)
             (set-window-start w2 s1)
             (setq i (1+ i)))))))

;; http://www.whattheemacsd.com/
(defun delete-current-buffer-file ()
  "Deletes file connected to current buffer and kills buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
        (ido-kill-buffer)
      (when (yes-or-no-p "Are you sure you want to delete this file? ")
        (delete-file filename)
        (kill-buffer buffer)
        (message "File '%s' successfully deleted." filename)))))

;; http://www.whattheemacsd.com/
(defun rename-current-buffer-file ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil)
          (message "File '%s' successfully renamed to '%s'."
                   name (file-name-nondirectory new-name)))))))

;; Display the file path of the file in current buffer and also copy it to
;; the kill-ring
;; http://camdez.com/blog/2013/11/14/emacs-show-buffer-file-name/
(defun show-copy-buffer-file-name (arg)
  "Show the full path to the current file in the minibuffer and also copy it.

    C-u COMMAND -> Copy only the file name (not the full path).
C-u C-u COMMAND -> Copy the full path without env var replacement."
  (interactive "p")
  (let* ((file-name-full (buffer-file-name))
         file-name)
    (if file-name-full
        (progn
          (cl-case arg
            (4 (setq file-name (concat (file-name-base file-name-full) ; C-u
                                       (file-name-extension file-name-full :period))))
            (16 (setq file-name file-name-full)) ; C-u C-u
            (t (setq file-name (replace-regexp-in-string ; no prefix
                                (concat "_" (getenv "USER")) "_${USER}"
                                file-name-full))))
          (kill-new file-name)
          (message file-name))
      (error "Buffer not visiting a file"))))

;; http://www.emacswiki.org/emacs-en/download/misc-cmds.el
(defun revert-buffer-no-confirm ()
  "Revert buffer without confirmation."
  (interactive)
  (revert-buffer t t))

;; Revert All Buffers
(defun revert-all-buffers ()
  "Refreshes all open buffers from their respective files"
  (interactive)
  (let* ((list (buffer-list))
         (buffer (car list)))
    (while buffer
      ;; (message "test: %s %s %s %s"
      ;;          buffer
      ;;          (buffer-file-name buffer)
      ;;          (buffer-modified-p buffer)
      ;;          (file-exists-p (format "%s" (buffer-file-name buffer))))

      ;; Revert only buffers containing files which are not modified
      ;; Don't try to revert buffers like *Messages*
      (when (and (buffer-file-name buffer) (not (buffer-modified-p buffer)))
        (if (file-exists-p (format "%s" (buffer-file-name  buffer)))
            ;; if the file exists, revert the buffer
            (progn
              (set-buffer buffer)
              (revert-buffer t t t))
          ;; if the file doesn't exist, kill the buffer
          (let (kill-buffer-query-functions) ; no query done when killing buffer
            (kill-buffer buffer)
            (message "Killed buffer of non-existing file: %s" (buffer-file-name buffer)))))
      (setq list (cdr list))
      (setq buffer (car list)))
    (message "Refreshing open files")))

;; Set the frame fill the center screen
(defun full-screen-center ()
  (interactive)
  (let ((frame-resize-pixelwise t))
    (set-frame-position nil 1910 0) ; pixels x y from upper left
    (set-frame-size     nil 1894 1096 :pixelwise))) ; width, height

;; http://emacs.stackexchange.com/a/81/115
(defun modi/switch-to-scratch-and-back (arg)
  "Toggle between *scratch-MODE* buffer and the current buffer.
If a scratch buffer does not exist, create it with the major mode set to that
of the buffer from where this function is called.

    C-u COMMAND -> Open/switch to a scratch buffer in `org-mode'
C-u C-u COMMAND -> Open/switch to a scratch buffer in `emacs-elisp-mode'"
  (interactive "P")
  (if (and (null arg)
           (string-match "\*scratch" (buffer-name)))
      (switch-to-buffer (other-buffer))
    (let (mode-str)
      (cl-case (car arg)
        (4  (setq mode-str "org-mode"))
        (16 (setq mode-str "emacs-lisp-mode"))
        (t  (setq mode-str (format "%s" major-mode))))
      (switch-to-buffer (get-buffer-create
                         (concat "*scratch-" mode-str "*")))
      (modi-mode) ; Set my minor mode to activate my key bindings
      (funcall (intern mode-str))))) ; http://stackoverflow.com/a/7539787/1219634

;; Perform the "C-g" action automatically when focus moves away from the minibuffer
;; This is to avoid the irritating occassions where repeated `C-g` pressing doesn't
;; edit the mini-buffer as cursor focus has moved out of it.
;; http://stackoverflow.com/a/3024055/1219634
(defun stop-using-minibuffer ()
  "kill the minibuffer"
  (when (and (>= (recursion-depth) 1) (active-minibuffer-window))
    (abort-recursive-edit)))
(add-hook 'mouse-leave-buffer-hook #'stop-using-minibuffer)

;; http://www.emacswiki.org/emacs/SwitchingBuffers
(defun toggle-between-buffers ()
  "Toggle between 2 buffers"
  (interactive)
  (switch-to-buffer (other-buffer)))
;; (other-buffer &optional BUFFER VISIBLE-OK FRAME)
;; - Return most recently selected buffer other than BUFFER. Ignore the argument
;;   BUFFER unless it denotes a live buffer.
;; - If VISIBLE-OK==1, a buffer is returned even when it is visible in a split
;;   window.Buffers not visible in windows are preferred to visible buffers,
;;   unless optional second argument VISIBLE-OK is non-nil.
;; - If the optional third argument FRAME is non-nil, use that frame's buffer
;;   list instead of the selected frame's buffer list.

;; Scroll without moving the point/cursor
(defun scroll-up-dont-move-point ()
  "Scroll up by 1 line without moving the point."
  (interactive) (scroll-up 1))

(defun scroll-down-dont-move-point ()
  "Scroll down by 1 line without moving the point."
  (interactive) (scroll-down 1))

(defun scroll-other-window-up-dont-move-point ()
  "Scroll other window up by 1 line without moving the point."
  (interactive) (scroll-other-window 1))

(defun scroll-other-window-down-dont-move-point ()
  "Scroll other window down by 1 line without moving the point."
  (interactive) (scroll-other-window -1))

;; Below bindings are made in global map and not in my minor mode as I want
;; other modes to override those bindings.
(bind-keys
 ("<M-up>"    . scroll-down-dont-move-point)
 ("<M-down>"  . scroll-up-dont-move-point)
 ;; Change the default `M-left` key binding from `left-word'
 ;; The same function anyways is also bound to `C-left`
 ("<M-left>"  . scroll-other-window-down-dont-move-point)
 ("<S-prior>" . scroll-other-window-down-dont-move-point) ; S-PgUp
 ;; Change the default `M-right` key binding from `right-word'
 ;; The same function anyways is also bound to `C-right`
 ("<M-right>" . scroll-other-window-up-dont-move-point)
 ("<S-next>"  . scroll-other-window-up-dont-move-point)) ; S-PgDown

(bind-keys
 :map modi-mode-map
  ;; Make Alt+mousewheel scroll the other buffer
  ("<M-mouse-4>" . scroll-other-window-down-dont-move-point) ; M + wheel up
  ("<M-mouse-5>" . scroll-other-window-up-dont-move-point)) ; M + wheel down

;; Commented out this piece of code as it is giving the below error:
;; byte-code: Wrong number of arguments: (lambda (arg)
;; (mwheel-scroll-all-function-all (quote scroll-up) arg)), 0
;; ;; Allow scrolling of all buffers using mouse-wheel in scroll-all-mode
;; ;; (by default scroll-all-mode doesn't do that)
;; ;; http://www.emacswiki.org/emacs/ScrollAllMode
;; (defun mwheel-scroll-all-function-all (func arg)
;;   (if scroll-all-mode
;;       (save-selected-window
;;         (walk-windows
;;          (lambda (win)
;;            (select-window win)
;;            (condition-case nil
;;                (funcall func arg)
;;              (error nil)))))
;;     (funcall func arg)))

;; (defun mwheel-scroll-all-scroll-up-all (arg)
;;   (mwheel-scroll-all-function-all 'scroll-up arg))

;; (defun mwheel-scroll-all-scroll-down-all (arg)
;;   (mwheel-scroll-all-function-all 'scroll-down arg))

;; (setq mwheel-scroll-up-function   'mwheel-scroll-all-scroll-up-all)
;; (setq mwheel-scroll-down-function 'mwheel-scroll-all-scroll-down-all)

(setq mwheel-scroll-up-function   'scroll-up)
(setq mwheel-scroll-down-function 'scroll-down)

;; Move window splitters / Resize windows
;; https://github.com/abo-abo/hydra/blob/master/hydra-examples.el

(defun hydra-move-splitter-left ()
  "Move window splitter left."
  (interactive)
  (let ((windmove-wrap-around nil))
    (if (windmove-find-other-window 'right)
        (shrink-window-horizontally 1)
      (enlarge-window-horizontally 1))))

(defun hydra-move-splitter-right ()
  "Move window splitter right."
  (interactive)
  (let ((windmove-wrap-around nil))
    (if (windmove-find-other-window 'right)
        (enlarge-window-horizontally 1)
      (shrink-window-horizontally 1))))

(defun hydra-move-splitter-up ()
  "Move window splitter up."
  (interactive)
  (let ((windmove-wrap-around nil))
    (if (windmove-find-other-window 'up)
        (enlarge-window 1)
      (shrink-window 1))))

(defun hydra-move-splitter-down ()
  "Move window splitter down."
  (interactive)
  (let ((windmove-wrap-around nil))
    (if (windmove-find-other-window 'up)
        (shrink-window 1)
      (enlarge-window 1))))

(defhydra hydra-win-resize (:color red)
  "win-resize"
  ("]"        hydra-move-splitter-right "→")
  ("["        hydra-move-splitter-left  "←")
  ("p"        hydra-move-splitter-up    "↑") ; mnemonic: `p' for `up'
  ("{"        hydra-move-splitter-up    "↑")
  ("\\"       hydra-move-splitter-down  "↓")
  ("}"        hydra-move-splitter-down  "↓")
  ("="        balance-windows           "Balance")
  ("q"        nil                       "cancel" :color blue)
  ("<return>" nil                       "cancel" :color blue))
(bind-key "C-c ]" #'hydra-win-resize/body modi-mode-map)
(bind-key "C-c [" #'hydra-win-resize/body modi-mode-map)

;; Ediff
(use-package ediff
  :commands (ediff-files ediff-buffers modi/ediff-dwim)
  :config
  (progn
    ;; No separate frame for ediff control buffer
    (setq ediff-window-setup-function #'ediff-setup-windows-plain)

    ;; Split windows horizontally in ediff (instead of vertically)
    (setq ediff-split-window-function #'split-window-horizontally)

    (defun modi/ediff-dwim ()
      "Do ediff as I mean.

- If a region is active, call `ediff-regions-wordwise'.
- Else if the frame has 2 windows with identical major modes,
  - Do `ediff-files' if the buffers are associated to files and the buffers
    have not been modified.
  - Do `ediff-buffers' otherwise.
- Else if the current is a file buffer with a VC backend, call `vc-ediff'
- Else call `ediff-buffers'."
      (interactive)
      (let* ((num-win (safe-length (window-list)))
             (bufa (get-buffer (buffer-name)))
             (filea (buffer-file-name bufa))
             (modea (with-current-buffer bufa major-mode))
             bufb fileb modeb)
        (save-excursion
          (other-window 1)
          (setq bufb (get-buffer (buffer-name)))
          (setq fileb (buffer-file-name bufb))
          (setq modeb (with-current-buffer bufb major-mode)))
        (cond
         ;; If a region is selected
         ((region-active-p)
          (call-interactively 'ediff-regions-wordwise))
         ;; Else If 2 windows with same major modes
         ((and (= 2 num-win)
               (eq modea modeb))
          (if (or
               ;; if either of the buffers is not associated to a file
               (null filea) (null fileb)
               ;; if either of the buffers is modified
               (buffer-modified-p bufa) (buffer-modified-p bufb))
              (progn
                (message "Running (ediff-buffers \"%s\" \"%s\") .." bufa bufb)
                (ediff-buffers bufa bufb))
            (progn
              (message "Running (ediff-files \"%s\" \"%s\") .." filea fileb)
              (ediff-files filea fileb))))
         ;; Else If file in current buffer has a vc backend
         ((and (buffer-file-name)
               (vc-registered (buffer-file-name)))
          (call-interactively 'vc-ediff))
         ;; Else call `ediff-buffers'
         (t (call-interactively 'ediff-buffers)))))))

(defun modi/set-file-permissions (perm)
  "Change permissions of the file in current buffer.
Example: M-644 M-x modi/set-file-permissions."
  (interactive "p")
  (when (<= perm 1)
    (setq perm 644))
  (let ((cmd (concat "chmod "
                     (format "%s " perm)
                     (buffer-file-name))))
    (message "%s" cmd)
    (shell-command cmd "*Shell Temp*")
    (kill-buffer "*Shell Temp*")))

(defvar modi/toggle-one-window--buffer-name nil
  "Variable to store the name of the buffer for which the `modi/toggle-one-window'
function is called.")
(defvar modi/toggle-one-window--window-configuration nil
  "Variable to store the window configuration before `modi/toggle-one-window'
function was called.")
(defun modi/toggle-one-window (&optional force-one-window)
  "Toggles the frame state between deleting all windows other than
the current window and the windows state prior to that.

`winner' is required for this function."
  (interactive "P")
  (if (or (null (one-window-p))
          force-one-window)
      (progn
        (setq modi/toggle-one-window--buffer-name (buffer-name))
        (setq modi/toggle-one-window--window-configuration (current-window-configuration))
        (delete-other-windows))
    (progn
      (when modi/toggle-one-window--buffer-name
        (set-window-configuration modi/toggle-one-window--window-configuration)
        (switch-to-buffer modi/toggle-one-window--buffer-name)))))

;; https://tsdh.wordpress.com/2015/03/03/swapping-emacs-windows-using-dragndrop/
(defun th/swap-window-buffers-by-dnd (drag-event)
  "Swaps the buffers displayed in the DRAG-EVENT's start and end window."
  (interactive "e")
  (let ((start-win (cl-caadr drag-event))
        (end-win   (cl-caaddr drag-event)))
    (when (and (windowp start-win)
               (windowp end-win)
               (not (eq start-win end-win))
               (not (memq (minibuffer-window)
                          (list start-win end-win))))
      (let ((bs (window-buffer start-win))
            (be (window-buffer end-win)))
        (unless (eq bs be)
          (set-window-buffer start-win be)
          (set-window-buffer end-win bs))))))
(bind-key "<C-S-drag-mouse-1>" #'th/swap-window-buffers-by-dnd modi-mode-map)

(bind-keys
 :map modi-mode-map
  ("C-x 1"        . modi/toggle-one-window) ; default binding to `delete-other-windows'
  ;; overriding `C-x C-p' originally bound to `mark-page' command
  ("C-x C-p"      . show-copy-buffer-file-name)
  ;; overriding `C-x <delete>' originally bound to `backward-kill-sentence' command
  ("C-x <delete>" . delete-current-buffer-file)
  ("C-x C-r"      . rename-current-buffer-file)
  ("C-S-t"        . reopen-killed-file) ; mimicking reopen-closed-tab binding used in browsers
  ("C-c )"        . rotate-windows)) ; rotate windows clockwise. This will do the act of swapping windows if the frame is split into only 2 windows

;; Bind a function to execute when middle clicking a buffer name in mode line
;; http://stackoverflow.com/a/26629984/1219634
(bind-key "<mode-line> <mouse-2>"   #'show-copy-buffer-file-name       mode-line-buffer-identification-keymap)
(bind-key "<mode-line> <S-mouse-2>" (λ (show-copy-buffer-file-name 4)) mode-line-buffer-identification-keymap)

;; Below bindings are made in global map and not in my minor mode as I want
;; other modes to override those bindings.
(bind-keys
 ("<f5>"   . revert-buffer)
 ("<S-f5>" . revert-all-buffers)
 ("<S-f9>" . eshell))

(bind-to-modi-map "b" modi/switch-to-scratch-and-back)
(bind-to-modi-map "f" full-screen-center)
(bind-to-modi-map "y" bury-buffer)

(key-chord-define-global "XX" (λ (kill-buffer (current-buffer))))
(key-chord-define-global "ZZ" #'toggle-between-buffers)
(key-chord-define-global "5t" #'revert-buffer) ; alternative to F5


(provide 'setup-windows-buffers)

;; TIPS

;; (1) `C-l'
;; C-l calls the `recenter-top-bottom' command. But typing C-l twice in a row
;; (C-l C-l) scrolls the window so that point is on the topmost screen line.
;; Typing a third C-l scrolls the window so that point is on the bottom-most
;; screen line. Each successive C-l cycles through these three positions.
