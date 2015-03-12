;; Robb's emacs startup file                                                                           -*- lisp -*-

(add-to-list 'load-path (expand-file-name "~/.emacs.d"))
(add-to-list 'load-path (expand-file-name "~/.emacs.d/cc-mode"))
(add-to-list 'load-path (expand-file-name "~/.emacs.d/gnus/lisp"))
(require 'gnus-load)

(setq inhibit-startup-message t)        ;do not display startup message
(setq enable-recursive-minibuffers t)   ;allow minibuffer use in minibuffer
(put 'narrow-to-region 'disabled nil)   ;allow C-x n n
(put 'eval-expression 'disabled nil)    ;allow M-:
(put 'upcase-region 'disabled nil)      ;allow C-x C-u
(put 'downcase-region 'disabled nil)    ;allow C-x C-l
(setq enable-local-variables 'query)    ;ask about LISP in files
(setq enable-local-eval 'query)         ;ask about `eval' in files
(setq version-control t)                ;use backup version numbers
(setq kept-old-versions 2)              ;keep first two original versions
(setq kept-new-versions 10)             ;keep 10 most recent versions
(setq visible-bell t)                   ;be quiet -- flash instead of beep
(setq next-line-add-newlines nil)       ;do not add lines at end of buffer
(setq line-number-mode t)		;turn on line numbers in mode line
(setq column-number-mode t)		;turn on column numbers in mode line
(tool-bar-mode 0)			;turn off the tool bar since it just wastes screen real estate
(setq read-quoted-char-radix 16)	;enter quoted chars in hexadecimal instead of octal

;(require 'icicles)
;(icy-mode)
;(require 'egg)

;; Frame width
(global-set-key (kbd "<M-S-f4>") (lambda () (interactive) (set-frame-width (selected-frame) 133)))
(global-set-key (kbd "<f4>")     (lambda () (interactive) (set-frame-width (selected-frame) 80)))
(set-frame-width (selected-frame) 133)

;; Additional key bindings
(global-set-key (kbd "<f3>") 'goto-line)
(global-set-key (kbd "<C-f3>") 'goto-char)
(global-set-key (kbd "<f5>") 'compile)
(global-set-key (kbd "<C-f5>") 'grep)
(global-set-key [?\C-c ?, ?i] 'semantic-analyze-proto-impl-toggle)

;; Bindings to make Emacs more like XEmacs
(global-set-key [?\C-x ?/] 'point-to-register)
(global-set-key [?\C-x ?j] 'jump-to-register)

;; Make mouse wheel to scroll a constant amount each click
(global-set-key [mouse-4] (lambda () (interactive) (scroll-down 5)))
(global-set-key [mouse-5] (lambda () (interactive) (scroll-up 5)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto-complete-el (Debian package)
(add-to-list 'load-path "~/.emacs.d")
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
(ac-config-default)
(setq ac-use-quick-help t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CEDET
;; Do not install Debian "ede" package. Use:
;; bzr checkout bzr://cedet.bzr.sourceforge.net/bzrroot/cedet/code/trunk cedet
;; See http://cedet.sourceforge.net/bzr-repo.shtml

(load-file "~/cedet/cedet-devel-load.el")
(load-file "~/cedet/contrib/semantic-tag-folding.el")
(setq semantic-default-submodes '(; enables global support for Semanticdb
				  global-semanticdb-minor-mode
				  ; automatic bookmarking of tags that you edited, so you can return to them later with the
				  ; semantic-mrub-switch-tags command.
				  global-semantic-mru-bookmark-mode
				  ; activates CEDET's context menu that is bound to right mouse button
				  global-cedet-m3-minor-mode
				  ; activates highlighting of first line for current tag (function, class, etc)
				  global-semantic-highlight-func-mode
				  ; activates mode when name of current tag will be shown in top line of buffer
				  global-semantic-stickyfunc-mode
				  ; activates use of separate styles for tags decoration (depending on tag's class). These styles
				  ; are defined in the semantic-decoration-styles list.
				  ;global-semantic-decoration-mode
				  ; activates highlighting of local names that are the same as name of tag under cursor
				  global-semantic-idle-local-symbol-highlight-mode
				  ; activates automatic parsing of source code in the idle time
				  global-semantic-idle-scheduler-mode
				  ; activates displaying of possible name completions in the idle time. Requires that
				  ; global-semantic-idle-schedule-mode was enabled.
				  ;       global-semantic-idle-completions-mode
				  ; ?
				  global-semantic-tag-folding-mode
				  global-semantic-minor-mode))

;(semantic-mode 1)                      ; COMMENTED OUT BECAUSE IT CAUSES "Wrong type argument: stringp, 1" when loading C++ files
(require 'semantic/ia)			; advanced features
(require 'semantic/bovine/gcc)		; system header file locations for GCC
(require 'semantic/mru-bookmark)	; automatic bookmark tracking
(require 'semantic-tag-folding)		; see cedet/contrib/semantic-tag-folding.el
;(semantic-add-system-include "~/boost/boost_1_47_0/include" 'c++-mode)
(semantic-load-enable-code-helpers)

;; Integrate cedet with imenu: creates a menu item that lists things in the buffer
(setq imenu-sort-function 'imenu--sort-by-name)
(setq imenu-max-items 100)		;maximum number of elements in a mouse menu
;(setq imenu-after-jump-hook (lambda () (recenter 3)))
(defun robb-semantic-hook ()
  (imenu-add-to-menubar "TAGS"))
(add-hook 'semantic-init-hooks 'robb-semantic-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; filladapt -- better filling functions. "Filling" is the process of moving new-line characters
;; within a "paragraph" in order to make the lines all approximately the same length.
(require 'filladapt)
(setq-default filladapt-mode t)         ; enable filladapt for all buffers...
;(add-hook 'c-mode-hook 'turn-off-filladapt-mode) ; except C source code
;(setq filladapt-mode-line-string nil)   ; and don't advertise the minor mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Programming stuff follows...

;; Compiling -- the `compile' command bound to `f5' above.  This will compile something (usually
;; with make(1) and capture the output in a separate window. You can visit each error/warning
;; with next-error (C-x `) or visit a specific error by middle-clicking (or C-c C-c) on that
;; error line.
;(load "compile")
(setq compilation-window-height 8)
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
				   (class-close before)
				   (defun-open after)
				   (defun-close before after)
				   (inline-open after)
				   (inline-close before after)
				   (substatement-open after)
				   (substatement-case-open after)
				   (extern-lang-open after)
				   (extern-lang-close before after)
				   (namespace-open after)
				   (namespace-close before after)
				   (statement-case-open after)
				   (statement-case-close before after)
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
				   (innamespace           . 0)
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
				   (namespace-open        . -)
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
  (setq fill-column (- 132 5))		; use 132 instead of (frame-width)
  (setq c-backslash-column (- 132 5))	; ditto
  (setq c-backslash-max-column c-backslash-column)

  (c-toggle-auto-hungry-state 1)	; Del and C-d eat white space aggressively
  (pilf-mode 1)				; Robb's program intra-line formatting mode (horizontal white space in a line)
  (setq comment-column (or (pilf-get-config 'trailing-comment-column) 64))

  (hide-ifdef-mode 1)

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

  ;; Show completions when "." or ">" (as in "->") is pressed (not applicable when using auto-complete)
;  (local-set-key "." 'semantic-complete-self-insert) 
;  (local-set-key ">" 'semantic-complete-self-insert)

  ;; Use auto-complete for Semantic name completion
;  (add-to-list 'ac-sources 'ac-source-gtags)
;  (add-to-list 'ac-sources 'ac-source-semantic)
  (imenu-add-to-menubar "TAGS")
)


;(load "rpmc")				;Robb's C minor mode
(load "pilf")				;Robb's new C/C++ minor mode (2010)
(add-hook 'c-mode-hook 'rpm-c-mode-hook)
(add-hook 'c++-mode-hook 'rpm-c-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Selectively hides C/C++ 'if' and 'ifdef' regions.
(setq hide-ifdef-mode-hook
      (lambda ()
	(if (not hide-ifdef-define-alist)
	    (setq hide-ifdef-define-alist
		  '((rose ROSE_ENABLE_SIMULATOR)
		    (list2 ONE TWO THREE))))
	(hide-ifdef-use-define-alist 'rose) ; use this list by default
	))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org Mode
(setq org-hide-leading-stars t)
(setq org-odd-levels-only t)
(setq org-log-done 'time)
(setq org-agenda-files '("~/Notes"))
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(blink-matching-paren t)
 '(column-number-mode t)
 '(compilation-context-lines 0)
 '(compilation-scroll-output t)
 '(compilation-skip-threshold 0)
 '(delete-old-versions t)
 '(display-time-mode t)
 '(ecb-auto-activate t)
 '(ecb-options-version "2.32")
 '(ecb-source-path (quote ("/home/matzke/GS-CAD/ROSE/sources/edg4x/src")))
 '(ede-project-directories (quote ("/home/matzke/rose" "/home/matzke/rose/src")))
 '(global-linum-mode t)
 '(hide-ifdef-initially t)
 '(hide-ifdef-shadow t)
 '(next-error-highlight t)
 '(save-place t nil (saveplace))
 '(scroll-bar-mode (quote right))
 '(show-paren-mode t)
 '(show-paren-style (quote mixed))
 '(text-mode-hook (quote (turn-on-auto-fill text-mode-hook-identify)))
 '(transient-mark-mode nil)
 '(vc-handled-backends (quote (RCS CVS SVN SCCS Bzr Hg Mtn Arch)))
 '(which-function-mode t))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :stipple nil :background "white" :foreground "black" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 92 :width normal :foundry "unknown" :family "DejaVu Sans Mono"))))
 '(font-lock-doc-face ((t (:inherit font-lock-string-face :background "#ffffdd" :foreground "black" :slant oblique))))
 '(hide-ifdef-shadow ((t (:inherit shadow :foreground "#ccc")))))
