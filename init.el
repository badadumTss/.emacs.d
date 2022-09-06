; me
(setq user-email-address "lucazanny@gmail.com")

;; use-package init
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "https" "http")))
  (when no-ssl (warn "No ssl! MITM possibili!"))
  (add-to-list 'package-archives
               (cons 
                "melpa" (concat proto "://melpa.org/packages/")) 
               t))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Behaviour
(global-set-key (kbd "C-x C-b") 'ibuffer)
(defalias 'yes-or-no-p 'y-or-n-p)

(ido-mode 1)

(if (daemonp)
    (global-set-key (kbd "C-x C-c") 'delete-frame)
  (global-set-key (kbd "C-x C-c") 'save-buffers-kill-emacs))

(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)
(global-set-key (kbd "<f5>") 'revert-buffer)

;; Themes and visual components
(global-hl-line-mode 1)

(if (not (version< emacs-version "26.0"))
    (progn
      (global-display-line-numbers-mode t)
      (setq display-line-numbers-type 'relative))
  (global-linum-mode t))

(tool-bar-mode -1)
(toggle-scroll-bar -1)
(menu-bar-mode -1)

(setq lz/frame-settings
      '((width . 100)
	(height . 30)
	(vertical-scroll-bars . nil)
	(horizontal-scroll-bars . nil)
	(font . "Monospace 14")))

(setq initial-frame-alist lz/frame-settings)
(setq default-frame-alist lz/frame-settings)

(show-paren-mode 1)
(setq show-paren-style 'mixed)
(setq display-time-day-and-date t)
(display-time-mode 1)

;; Temi condizionali in base all'avvio
(cond
 ((member "-nano" command-line-args)
  (progn
    (add-to-list 'load-path (concat user-emacs-directory "nano-emacs/"))
    (require 'nano)))
 (t
  (use-package ef-themes
    :ensure
    :config
    (setq ef-themes-to-toggle '(ef-spring ef-winter))
    
    ;; Make customisations that affect Emacs faces BEFORE loading a theme
    ;; (any change needs a theme re-load to take effect).
    
    (setq ef-themes-headings ; read the manual's entry or the doc string
	  '((0 . (variable-pitch light 1.9))
            (1 . (variable-pitch light 1.8))
            (2 . (variable-pitch regular 1.7))
            (3 . (variable-pitch regular 1.6))
            (4 . (variable-pitch regular 1.5))
            (5 . (variable-pitch 1.4)) ; absence of weight means `bold'
            (6 . (variable-pitch 1.3))
            (7 . (variable-pitch 1.2))
            (t . (variable-pitch 1.1))))
    
    ;; They are nil by default...
    ;; (setq ef-themes-mixed-fonts t
    ;; 	    ef-themes-variable-pitch-ui t)
    
    ;; Disable all other themes to avoid awkward blending:
    (mapc #'disable-theme custom-enabled-themes)
    
    ;; Load the theme of choice:
    (load-theme 'ef-spring :no-confirm)
    
    ;; OR use this to load the theme which also calls `ef-themes-post-load-hook':
    (ef-themes-select 'ef-spring))))

;; Packs
(use-package magit :ensure)
(use-package rust-mode :ensure)
(use-package evil
  :ensure
  :config
  (evil-mode 1)
  (define-key evil-normal-state-map (kbd "TAB") 'indent-for-tab-command))
(use-package go-mode :ensure)

;; Set custom file
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

;; Functions
(defun lz/open-configs ()
  "Funzione per aprire il file di configurazione"
  (interactive)
  (find-file 
   (expand-file-name 
    (concat user-emacs-directory "init.el")))) 

(defun lz/next-buffer-other-window (&optional arg interactive)
  "In other window switch to ARGth next buffer.
Call `switch-to-next-buffer' unless the selected window is the
minibuffer window or is dedicated to its buffer."
  (interactive "p\np")
  (let ((other (other-window-for-scrolling))
        (current (selected-window)))
    (select-window other)
    (next-buffer arg interactive)
    (select-window current)))

(defun lz/previous-buffer-other-window (&optional arg interactive)
  "In other window switch to ARGth previous buffer.
Call `switch-to-prev-buffer' unless the selected window is the
minibuffer window or is dedicated to its buffer."
  (interactive "p\np")
  (let ((other (other-window-for-scrolling))
        (current (selected-window)))
    (select-window other)
    (previous-buffer arg interactive)
    (select-window current)))

(defun lz/ff-other-window ()
  "Find file in other window."
      (interactive)
  (cond
   ((one-window-p t)
    (call-interactively #'find-file-other-window))
   (t
    (let ((other (other-window-for-scrolling))
          (current (selected-window)))
      (select-window other)
      (call-interactively #'find-file)
      (select-window current)))))

(defun lz/kill-buffer-other-window ()
  "Kills buffer in other window."
  (interactive)
  (let ((other (other-window-for-scrolling))
        (current (selected-window)))
    (select-window other)
    (kill-buffer)
    (select-window current)))

(defun lz/shell-vertically-split (&optional shell-type)
  "Opens a shell in a vertically split window, if given 'eshell
as argument starts a new eshell, 'term starts a new term and
'ansi-term a new ansi-term"
  (interactive)
  (let ((other (split-window-below))
	(current (selected-window))
	(term-here (lambda ()
		     (let* ((current (selected-window))
			    (shell-buffer (shell)))
		       (delete-window (get-buffer-window shell-buffer))
		       (select-window current)
		       (switch-to-buffer shell-buffer)))))
    (select-window other)
    (if (boundp shell-type)
	(cond ((= shell-type 'eshell) (eshell))
	      ((= shell-type 'term) (term))
	      ((= shell-type 'ansi-term) (ansi-term))
	      (t (funcall term-here)))
      (funcall term-here))
    (select-window current)))

(defun lz/koans-setup ()
  "Starts the setup for the next koan to do"
  (interactive)
  (let*
      ((dir "/home/luca/gitgets/lisp-koans/")
       (out (shell-command-to-string
	     "cd /home/luca/gitgets/lisp-koans/; clisp -q -norc -ansi contemplate.lisp | grep \"File\""))
       (file-raw (cadr (split-string out)))
       (filename (concat dir (cadr (split-string file-raw "\""))))
       (command (concat "cd " dir " && sh meditate-linux.sh clisp"))
       (current (selected-window))
       (other (get-buffer-window (shell))))
    (select-window current)
    (find-file filename)
    (select-window other)
    (insert command)
    (comint-send-input)
    (select-window current)))

(add-to-list 'load-path (concat user-emacs-directory "modules/"))
(require 'lofi)