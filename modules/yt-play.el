;; YouTube playlist playback. Play youtube playlists songs by
;; song. All normal playback commands are available: play, pause, stop
;; and repeat. Requires internet and yt-dlp as external dependencies
;; to emacs

;;; VARIABLES 
(defvar lz/yt-process nil
  "The video currently in playback")

(defvar lz/yt-playlist nil
  "The links of the current playlist")

(defvar lz/yt-status nil
  "Status of the current playlist")

;;; CLASSES 
(defclass playlist-i ()
  ((links :initarg :links
	  :accessor links
	  :reader (setf links)
	  :type list)
   (current :initarg :current
	    :accessor current
	    :reader (setf current)
	    :type number)
   (loop :initarg :loop
	 :accessor loop
	 :reader (setf loop)
	 :type boolean)))

(cl-defmethod next-link ((iter playlist-i))
  (let* ((curr (slot-value iter 'current))
	 (cur (nth curr (slot-value iter 'links))))
    (set-slot-value iter 'current (1+ curr))
    cur))

;;; FUNCTIONS

;;;###autoload
(defun lz/get-links ()
  "Returns a list containing the links of the videos in the
playlist"
  (let* ((playlist-link (read-string "Playlist link: "))
	 (beg-command "yt-dlp --flat-playlist -i --print url ")
	 (command (concat beg-command "\"" playlist-link "\"")))
    (message "Retrieving all the links from the playlist (might take a while) ...")
    (split-string (shell-command-to-string command))))

;;;###autoload
(defun lz/yt-play (link)
  "Returns the raw process playing the given link"
  (let* ((sh "/bin/sh")
	 (args "-c")
	 (get-link (concat "yt-dlp -g " link))
	 (ffplay "ffplay -nodisp -hide_banner -loglevel error ")
	 (real-link (split-string (shell-command-to-string get-link)))
	 (audio (cadr real-link))
	 (video (car real-link))
	 (command (concat ffplay "\"" audio "\""))
	 (process-command (list sh args command)))
    (make-process
     :name "play-process"
     :buffer "*yt-playback*"
     :command process-command)))

;;;###autoload
(defun lz/yt-init ()
  "sets `lz/yt-playlist-iter` to an iterator over the list
generated by lz/get-links"
  (setq lz/yt-playlist 
	(playlist-i
	 :links (lz/get-links)
	 :current 0
	 :loop t)))

;;;###autoload
(defun lz/yt-handle-process-event (process event)
  "handles the process event `event`, the process itself is useless"
  (message event)
  (if (equal event "finished\n") (lz/yt-next)))

;;;###autoload
(defun lz/yt-start ()
  "Starts the playback of the current playlist"
  (message "Starting playback")
  (if lz/yt-process (kill-process lz/yt-process))
  (setq lz/yt-process (lz/yt-play (next-link lz/yt-playlist)))
  (set-process-sentinel lz/yt-process #'lz/yt-handle-process-event)
  (setq lz/yt-status 'playing))

;;;###autoload
(defun lz/yt-resume () 
  "Resumes an active playlist playback"
  (interactive)
  (message "Resuming playback")
  (if lz/yt-process
      (progn (continue-process lz/yt-process)
	     (setq lz/yt-status 'playing))))

;;;###autoload
(defun lz/yt-pause () 
  "Pauses an active playlist playback"
  (interactive)
  (message "Pausing playback")
  (if lz/yt-process
      (progn (signal-process lz/yt-process 'SIGSTOP)
	     (setq lz/yt-status 'paused))))

;;;###autoload
(defun lz/yt-stop () 
  "Pauses an active playlist playback"
  (interactive)
  (message "Stopping playback")
  (if lz/yt-process
      (progn (interrupt-process lz/yt-process)
	     (setq lz/yt-status 'stopped))))

;;;###autoload
(defun lz/yt-toggle ()
  "Toggles the status of the process between playing and pause"
  (interactive)
  (cond ((eq lz/yt-status 'playing) (lz/yt-pause))
	((eq lz/yt-status 'paused) (lz/yt-resume))
	((eq lz/yt-status 'stopped) (lz/yt-start))))

;;;###autoload
(defun lz/yt-next ()
  "Next song in the playlist"
  (interactive)
  (message "Bleah.. going to netx song in the playlist")
  (lz/yt-start))

;;;###autoload
(defun lz/yt-killall ()
  "Nukes everything"
  (kill-process lz/yt-process)
  (setf lz/yt-status nil lz/yt-playlist nil lz/yt-process nil))

;;;###autoload
(defun yt--key (key)
  (kbd (concat yt-keymap-prefix  " " key)))

;;; CUSTOMS 
(defcustom yt-keymap-prefix "C-c y"
  "The prefix for lofi-mode key bindings."
  :type 'string
  :group 'lofi)

;;; MINOR-MODE

;;;###autoload
(define-minor-mode yt-mode
  "Toggles global lofi mode"
  nil   ; Initial value, nil for disabled
  :global t
  :lighter " yt"
  :keymap
  (list (cons (yt--key "t") #'lz/yt-toggle)
	(cons (yt--key "s") #'lz/yt-stop)
	(cons (yt--key "p") #'lz/yt-pause)
	(cons (yt--key "r") #'lz/yt-resume)
	(cons (yt--key "n") #'lz/yt-next))

  (if yt-mode
      (progn (lz/yt-init) (lz/yt-start))
    (lz/yt-killall)))

(global-set-key (kbd (yt--key "i")) #'yt-mode)
(provide 'yt-play)
