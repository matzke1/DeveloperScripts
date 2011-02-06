;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Expert User .emacs File.
;;; Copyright(C) 2002-2003 Robb Matzke.
;;; GNU General Public License

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Adjust the load path. I keep all my personal emacs stuff here...
(setq load-path (append load-path (list (expand-file-name "~/.xemacs"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Enable some expert features
(setq inhibit-startup-message t)        ;do not display startup message
(setq enable-recursive-minibuffers t)   ;allow minibuffer use in minibuffer
(put 'narrow-to-region 'disabled nil)   ;allow C-x n n
(put 'eval-expression 'disabled nil)    ;allow M-:
(put 'upcase-region 'disabled nil)      ;allow C-x C-u
(put 'downcase-region 'disabled nil)    ;allow C-x C-l
(put 'erase-buffer 'disabled nil)
(setq enable-local-variables 'query)    ;ask about LISP in files
(setq enable-local-eval 'query)         ;ask about `eval' in files
(setq version-control t)                ;use backup version numbers
(setq kept-old-versions 2)              ;keep first two original versions
(setq kept-new-versions 10)             ;keep 10 most recent versions
(setq trim-versions-without-asking t)   ;remove unneeded versions
(load "saveplace")                      ;remember point location in each file
(setq-default save-place t)             ;save places in all buffers
(load "complete")                       ;Dave's partial completions
(setq blink-matching-paren-distance 120000) ;increase default by 10x
(setq visible-bell t)                   ;be quiet -- flash instead of beep
(setq minibuffer-max-depth nil)         ;global max num minibuffers allowed
(setq efs-ftp-program-name "pftp")      ;tell ftp to be passive for firewall reasons
(setq minibuffer-confirm-incomplete t)  ;confirm incomplete entries
(setq complex-buffers-menu-p t)         ;buffers menu contains several subcommands
(setq next-line-add-newlines nil)       ;do not add lines at end of buffer
(setq buffers-menu-max-size nil)        ;max size of buffer menu (unlimited)
(font-lock-mode 1)                      ;turn on font lock mode, all buffers
(setq font-lock-maximum-size 1000000)	;max buffer size for fontifying
(setq line-number-mode t)		;turn on line numbers in mode line
(setq column-number-mode t)		;turn on column numbers in mode line
(display-time)				;display time and load average in mode line

;; background pixmaps
;(set-face-background-pixmap 'default "/path/to/image.xpm")
;(set-face-background-pixmap 'bold    "/path/to/another_image.xpm")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Functions that change the width of the frame (a.k.a., X11 window). You can also change the
;; size using the normal procedure for whatever window manager you use (e.g., dragging the resize
;; handles with the mouse) but sometimes just hitting some key combination is much faster. The
;; sizes here are arbitrary:
;;   80-columns:  HDF5 source code, man pages, etc.
;;   100-columns: most of Robb's own source code
;;   132-columns: SAF-related source code
;;   212-columns: Robbs almost full screen width
;; When editing C sources with Robb's C mode (rpmc-mode) with automatic filling enabled you'll
;; need to set the frame width before loading the source file. But if you forget, just save
;; any changes and do a find-alternate-file (C-x C-v) to reload the source file. See doc for
;; define-key for the keystroke format.
(global-set-key 'f4           (lambda () (interactive) (set-frame-width (selected-frame)  80)))
(global-set-key '(control f4) (lambda () (interactive) (set-frame-width (selected-frame) 100)))
(global-set-key '(meta f4)    (lambda () (interactive) (set-frame-width (selected-frame) 132)))
(global-set-key '(super f4)   (lambda () (interactive) (set-frame-width (selected-frame) 212)))

(set-frame-width (selected-frame) 132)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Additional key bindings. These can be whatever you want -- I use the function keys. Before
;; making the binding you might want to check what's attached to that key sequence by running
;; command-describe-key-briefly (C-h c) and pressing the key sequence in question.
(global-set-key 'f2 'vm)                ; VM is an e-mail program (MUA)
(global-set-key '(control f2) 'gnus)    ; gnus is a usenet newgroup reader
(global-set-key 'f3 'goto-line)         ; go to a specific line (1-origin)
(global-set-key '(control f3) 'goto-char) ; go to a specific character (1-origin)
(global-set-key 'f5 'compile)           ; run `make' or other compile command
(global-set-key '(control f5) 'grep)    ; grep like compile, use C-x ` to visit each match
(global-set-key 'f6 'rpmc-set-style)    ; set C coding style for current buffer
(global-set-key 'f7 'dictionary-lookup-definition)
(global-set-key 'button4 (lambda () (interactive) (scroll-down 5)))
(global-set-key 'button5 (lambda () (interactive) (scroll-up 5)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; filladapt -- better filling functions. "Filling" is the process of moving new-line characters
;; within a "paragraph" in order to make the lines all approximately the same length.
(require 'filladapt)
(setq-default filladapt-mode t)         ; enable filladapt for all buffers...
;(add-hook 'c-mode-hook 'turn-off-filladapt-mode) ; except C source code
(setq filladapt-mode-line-string nil)   ; and don't advertise the minor mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Insidious Big Brother Database (BBDB) -- keeps track of contact information for e-mail & news.
;(require 'bbdb)
;(bbdb-initialize 'vm 'message 'sc)
;(bbdb-insinuate-sc)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; supercite -- citations in e-mail.
;(add-hook 'mail-citation-hook 'sc-cite-original)
;(setq sc-citation-leader "")
;(setq sc-auto-fill-region-p nil)        ;I like to fill manually with M-q
;(setq sc-preferred-attribution-list
;      '("sc-lastchoice" "x-attribution" "sc-consult"
;        "initials" "firstname" "lastname" "emailname"))
;(setq sc-attrib-selection-list          ;This is BBDB stuff for supercite
;      '(("sc-from-address"
;         ((".*" (bbdb/sc-consult-attr (sc-mail-field "sc-from-address")))))))
;(setq sc-mail-glom-frame                ;This is BBDB stuff for supercite
;      '((begin				(setq sc-mail-headers-start (point)))
;        ("^x-attribution:[ 	]+.*$"  (sc-mail-fetch-field t) nil t)
;        ("^\\$ +:.*$"                   (sc-mail-fetch-field) nil t)
;        ("^$"                           (progn
;                                          (bbdb/sc-default)
;                                          (list 'abort '(step . 0))))
;        ("^[ 	]+"                     (sc-mail-append-field))
;        (sc-mail-warn-if-non-rfc822-p   (sc-mail-error-in-mail-field))
;        (end                            (setq sc-mail-headers-end (point)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Programming stuff follows...

;; etags is an indexing system for source code (C, C++, Fortran, Perl, Python, etc.)
;; Do "M-x manual-entry RET etags" for more info.
(setq tags-build-completion-table t)    ;always build, don't ask
(setq tags-auto-read-changed-tag-files t) ;automatically reread TAGS files

;; Changelogs -- a text file that has a specific format for recording changes to source code.
;; Every time you make a change to source code do "C-x 4 a" and enter your changes. You might
;; need to do "M-x add-change-log-entry" to create the initial Changelog file if you want only
;; a single Changelog at the root of your source tree. Robb uses Changelog files to facilitate
;; CVS checkin log messages.
(setq add-log-time-format 'current-time-string)

;; Compiling -- the `compile' command bound to `f5' above.  This will compile something (usually
;; with make(1) and capture the output in a separate window. You can visit each error/warning
;; with next-error (C-x `) or visit a specific error by middle-clicking (or C-c C-c) on that
;; error line.
(load "compile")
(setq remote-shell-program "ssh")
(setq compilation-window-height 8)
(setq remote-compile-prompt-for-host t)
(setq remote-compile-prompt-for-user t)
;(setq compilation-error-regexp-alist-alist ; run-time errors from SAF/SSlib
;      (append compilation-error-regexp-alist-alist
;	      '((sslib 
;		 ("    In [a-z_A-Z][a-z_A-Z0-9]*() at \\([a-zA-Z]?:?[^:( \t\n]+\\) line \\([0-9]+\\)$" 1 2)))))
(compilation-build-compilation-error-regexp-alist)
(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))

;; Perl programming
(setq perl-indent-level 4)

;; C programming
(defconst rpm-c-style
  `(
    (c-style-variables-are-local-p     . t)
    (c-tab-always-indent	       . nil)
    (c-basic-offset                    . 4)
    (c-echo-syntactic-information-p    . t)
    (c-indent-comments-syntactically-p . t)
    (c-hanging-comment-starter-p       . nil)
    (c-hanging-comment-ender-p         . nil)
    (c-backslash-column                . ,(- (frame-width) 5))
    (c-doc-comment-style               . javadoc)

    ;; Linefeeds before and/or after braces?
    (c-hanging-braces-alist     . (
				   (block-open before after)
				   (block-close . c-snug-do-while)
				   (brace-list-open)
				   (brace-list-close)
				   (brace-list-intro)
				   (brace-list-entry)
				   (class-open after)
				   (class-close before after)
				   (defun-open before after)
				   (defun-close before after)
				   (inline-open after)
				   (inline-close before after)
				   (substatement-open after)
				   (substatement-case-open after)
				   (extern-lang-open after)
				   (extern-lang-close before after)
				   ))

    ;; Linefeeds before and/or after colons?
    (c-hanging-colons-alist     . (
				   (access-label after)
				   (case-label after)
				   (inher-intro)
				   (label after)
				   (member-init-intro before)
				   ))

    ;; What happens for `#' signs?
    (c-electric-pound-behavior  . (alignleft))
       			   
    ;; Cleanup actions...
    (c-cleanup-list             . (brace-else-brace
				   brace-elseif-brace
				   brace-catch-brace
				   empty-defun-braces
				   defun-close-semi
				   list-close-comma
				   scope-operator
				   ))

    ;; Offsets
    (c-offsets-alist            . (
				   (access-label          . -)
				   (arglist-intro         . c-lineup-arglist-intro-after-paren)
				   (arglist-cont          . 0)
				   (arglist-cont-nonempty . c-lineup-arglist)
				   (arglist-close         . c-lineup-arglist)
				   (block-open            . 0)
				   (block-close           . 0)
				   (brace-list-open       . 0)
				   (brace-list-close      . 0)
				   (brace-list-intro      . +)
				   (brace-list-entry      . 0)
;				   (c                     . rpmc-c-no-indent)
				   (case-label            . +)
				   (class-open            . 0)
				   (comment-intro         . c-lineup-comment)
				   (cpp-macro             . -1000)
				   (defun-open            . 0)
				   (defun-close           . 0)
				   (defun-block-intro     . +)
				   (do-while-closure      . 0)
				   (else-clause           . 0)
				   (extern-lang-open      . 0)
				   (extern-lang-close     . 0)
				   (friend                . 0)
				   (func-decl-cont        . +)
				   (inclass               . +)
				   (inextern-lang         . 0)
				   (inher-intro           . +)
				   (inher-cont            . c-lineup-multi-inher)
				   (inline-open           . +)
				   (inline-close          . 0)
				   (knr-argdecl-intro     . 5)
				   (knr-argdecl           . 0)
				   (label                 . 0)
				   (member-init-intro     . +)
				   (member-init-cont      . 0)
				   (objc-method-intro     . -1000)
				   (objc-method-args-cont . c-lineup-ObjC-method-args)
				   (objc-method-call-cont . c-lineup-ObjC-method-call)
				   (statement             . 0)
				   (statement-case-intro  . +)
				   (statement-cont        . c-lineup-math)
				   (stream-op             . c-lineup-streamop)
				   (string                . -1000)
				   (substatement-open     . +)
				   (topmost-intro         . 0)
				   (topmost-intro-cont    . 0)
				   ))
    )
  "Robb Matzke C/C++ Programming Style")



(defun rpm-c-mode-hook ()
  ;; add my personal style and set it for the current buffer
  (c-add-style "rpm" rpm-c-style)
  (c-set-style "rpm")

  ;; other customizations
  (setq tab-width 8)			; The normal tab width
  (setq indent-tabs-mode nil)		; insert SPC rather than TAB characters

  (make-local-variable 'compile-command) ; set compile command on a per buffer basis
  (setq compile-command "make ")

  (make-local-variable 'fill-column)
  (setq fill-column (- (frame-width) 5))
  (setq c-backslash-column (- (frame-width) 5))
  (setq c-backslash-max-column c-backslash-column)

  (c-toggle-auto-hungry-state 1)	; Del and C-d eat white space aggressively
  (pilf-mode 1)				; Robb's program intra-line formatting mode (horizontal white space in a line)

  ;; Any word ending in `_t' is a type
  ;(append font-lock-keywords '("\\<[a-z_A-Z][a-z_A-Z0-9]*_t\\>" (0 font-lock-type-face)))

  ;; keybindings for all supported languages.  We can put these in
  ;; c-mode-map because c++-mode-map and java-mode-map inherit from it.
  (define-key c-mode-map "\C-m" 'newline-and-indent)
  (define-key c-mode-map "\C-j" 'newline)

  ;; Filling (automatic line wrapping) of comments and mult-line strings.
  (c-setup-filladapt)
  (filladapt-mode 1)
  (auto-fill-mode 1)
)


;(load "rpmc")				;Robb's C minor mode
(load "pilf")				;Robb's new C/C++ minor mode (2010)
(add-hook 'c-mode-hook 'rpm-c-mode-hook)
(add-hook 'c++-mode-hook 'rpm-c-mode-hook)

;; Function menu stuff (fume). This is for the `Functions' pulldown menu in the toolbar.
(require 'func-menu)
(define-key global-map 'f8 'function-menu)
(add-hook 'find-file-hooks 'fume-add-menubar-entry)
(define-key global-map "\C-cl" 'fume-list-functions)
(define-key global-map "\C-cg" 'fume-prompt-function-goto)
(define-key global-map '(shift button3) 'mouse-function-menu) ;note: conflicts with Hyperbole
(setq fume-max-items 50
      fume-fn-window-position 3
      fume-auto-position-popup t
      fume-display-in-modeline-p t
      fume-menubar-menu-location nil	;right-most left justified
      fume-buffer-name "*Function List*"
      fume-no-prompt-on-valid-default nil)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fixes for dired. Dired on debian has //DIRED garbage at end of buffer.
;; See http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=399483
;; This will no longer be necessary when it's fixed up stream.
;; Added by RPM 2010-02-08, XEmacs 21.4 (patch 21)
(add-hook 'dired-load-hook
  (lambda ()
    (set-variable 'dired-use-ls-dired
      (and (string-match "gnu" system-configuration)
           ;; Only supported for XEmacs >= 21.5 and GNU Emacs >= 21.4 (I think)
           (if (featurep 'xemacs)
               (and
		(fboundp 'emacs-version>=)
		(emacs-version>= 21 5))
             (and (boundp 'emacs-major-version)
                  (boundp 'emacs-minor-version)
                  (or (> emacs-major-version 21)
                      (and (= emacs-major-version 21)
                           (>= emacs-minor-version 4)))))))))
