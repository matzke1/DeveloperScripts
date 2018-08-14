;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Maildir utilities (mu) for Emacs (mu4e)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'mu4e)

;;--------------------
;; Getting mail
;;--------------------

;; Use the "offlinesmtp" tool (configured elsewhere) to synchronize ~/HoosierFocus-Maildir with
;; mail.hoosierfocus.com and create an index, then use mu4e to read the local maildir with the index.
(setq
 mu4e-maildir       "~/HoosierFocus-Maildir" ; must not be a symlink
 mu4e-sent-folder   "/Sent"		     ; these are relative to mu4e-maildir
 mu4e-drafts-folder "/Drafts"
 mu4e-trash-folder  "/Trash"
 mu4e-refile-folder "/Archives"
 mu4e-get-mail-command "true"		     ; offlinesmtp is running separatately, outside emacs
 mu4e-update-interval 330)		     ; automatic update database in seconds

;;--------------------
;; Sending mail.
;;--------------------

;; Use Emacs smtpmail and the external gnutls-bin package (sudo aptitude install gnutls-bin).
(require 'starttls)
(setq
  message-send-mail-function 'smtpmail-send-it
  smtpmail-smtp-server       "mail.hoosierfocus.com"
  smtpmail-smtp-user         "matzke"
  ;smtpmail-smtp-service      25              ; standard port
  smtpmail-smtp-service      2525             ; to bypass Comcast consumer firewall
  smtpmail-stream-type       'starttls
)

;;--------------------
;; Mu4e start window
;;--------------------

;; bookmarks: search specification, title, invocation character
(setq mu4e-bookmarks
      '(("maildir:/INBOX (prio:high OR flag:flagged)"
	 "important" ?*)

	("maildir:/INBOX OR maildir:/Sent"
	 "INBOX" ?i)

	("flag:unread AND NOT flag:trashed AND NOT maildir:/Junk"
	 "Unread messages" ?u)

	("date:today..now"
	 "Today (all messages)" ?T)

	("date:today..now AND NOT flag:trashed AND (maildir:/INBOX OR maildir:/Sent)"
	 "Today (inbox)" ?t)

	("date:7d..now"
	 "Week (all messages)" ?W)

	("date:7d..now AND NOT flag:trashed AND (maildir:/INBOX OR maildir:/Sent)"
	 "Week (inbox)" ?w)

	("date:31d..now"
	 "Month (all messages)" ?M)

	("date:31d..now AND NOT flag:trashed AND (maildir:/INBOX OR maildir:/Sent)"
	 "Month (inbox)" ?m)))

;;--------------------
;; Message summary
;;--------------------

;; Columns are almost like the defaults except wider fields and no subject for threads
(setq mu4e-headers-fields
      '((:human-date   	 . 12)		; or :date
	(:flags        	 . 6)
	(:maildir 	 . 16)
	(:from         	 . 22)
	(:thread-subject . nil)))	; or :subject

;;--------------------
;; Message view
;;--------------------

;; External command to convert HTML to text. Also try w3m
(setq mu4e-html2text-command "html2text")

;;--------------------
;; Message attachments
;;--------------------

(setq mu4e-attachment-dir "~/Downloads") ; where to save attachments

;;--------------------
;; Writing email
;;--------------------

(setq user-mail-address "matzke@hoosierfocus.com"
      user-full-name "Robb Matzke")

;; No signature
(setq mu4e-compose-signature-auto-include nil)

;; Flowed format: mu4e sets up visual-line-mode and also fill (M-q) to do the right thing. Each paragraph is a single
;; long line. When sending, emacs will add the special line continuation characters
(setq mu4e-compose-format-flowed t)

;; Every new email gets a new window (emacs frame). This works better in tiling window managers.
(setq mu4e-compose-in-new-frame t)	; added in mu4e 0.9.18

;; Don't keep message buffers around after sending
(setq message-kill-buffer-on-exit t)

;;--------------------
;; To-do lists
;;--------------------

(require 'org-mu4e)

;; store link-to-message if in header view rather than storing link-to-header-query
(setq org-mu4e-link-query-in-heades-mode nil)

(setq org-capture-templates
      '(("t" "todo" entry (file-headline "~/todo.org" "Tasks")
	 "* TODO [#A] %?\nSCHEDULED: %(org-insert-time-stamp (org-read-date nil t \"+0d\"))\n%a\n")))

