;; Robb's emacs startup file                                                                           -*- lisp -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Search paths
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(add-to-list 'load-path (expand-file-name "~/.emacs.d/lisp"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Enable MELPA package repository
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; You'll have to run: M-x package-refresh-contents or M-x package-list-contents to ensure that Emacs has fetched the
;;; MELPA package list before you can install packages with M-x package-install or similar.
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl (warn "\
Your version of Emacs does not support SSL connections,
which is unsafe because it allows man-in-the-middle attacks.
There are two things you can do about this warning:
1. Install an Emacs version that does support SSL and be safe.
2. Remove this warning from your init file so you won't see it again."))
  (add-to-list 'package-archives (cons "melpa"        (concat proto "://melpa.org/packages/"       )) t)
  (add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t))

(package-initialize)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Basic global settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq inhibit-startup-message t)        ; do not display startup message
(setq enable-recursive-minibuffers t)   ; allow minibuffer use in minibuffer
(put 'narrow-to-region 'disabled nil)   ; allow C-x n n
(put 'eval-expression 'disabled nil)    ; allow M-:
(put 'upcase-region 'disabled nil)      ; allow C-x C-u
(put 'downcase-region 'disabled nil)    ; allow C-x C-l
(setq enable-local-variables 'query)    ; ask about LISP in files
(setq enable-local-eval 'query)         ; ask about `eval' in files
(setq version-control t)                ; use backup version numbers
(setq kept-old-versions 2)              ; keep first two original versions
(setq kept-new-versions 10)             ; keep 10 most recent versions
(setq visible-bell t)                   ; be quiet, but flash since sound is muted by default on Robb's machines
(setq next-line-add-newlines nil)       ; do not add lines at end of buffer
(setq line-number-mode t)		; turn on line numbers in mode line
(setq column-number-mode t)		; turn on column numbers in mode line
(tool-bar-mode 0)			; turn off the tool bar since it just wastes screen real estate
(setq read-quoted-char-radix 16)	; enter quoted chars in hexadecimal instead of octal
(set-cursor-color "green")              ; to be visible even with reverse video
(setq gc-cons-threshold 100000000)      ; allow larger expressions on modern machines
(setq read-process-output-max (* 1024 1024)) ; allow more input on larger machines

;; The split-window-sensibly is insensible. Splitting windows so they're side-by-side rather than one on top of the
;; other doesn't work well when the user has adjusted the frame size to be suitable for editing. If the code is up to
;; 132 columns wide and the user has disabled truncate-lines then splitting in half side by side only makes sense if the
;; window is at least 2 * 132 + n characters wide (where "n" accounts for however much additional space would be lost
;; due to scroll bars, gutters, etc.
(setq split-width-threshold nil)
(setq split-height-threshold nil)

;; Additional key bindings
(global-set-key (kbd "<f3>") 'goto-line)
(global-set-key (kbd "<C-f3>") 'goto-char)
(global-set-key (kbd "<f4>") 'magit-status)
(global-set-key (kbd "<C-f4>") 'magit-dispatch-popup)
(global-set-key (kbd "<f5>") 'compile)
(global-set-key (kbd "<C-f5>") 'grep)

(global-set-key [?\C-x ?/] 'point-to-register)  ; quicker than the default binding
(global-set-key [?\C-x ?j] 'jump-to-register)   ; quicker than the default binding

;; Make mouse wheel to scroll a constant amount each click. This is less confusing than the stupid variable amount
;; of scrolling (which is faster, but becomes impossible to track quickly with my eyes).
(global-set-key [mouse-4] (lambda () (interactive) (scroll-down 5)))
(global-set-key [mouse-5] (lambda () (interactive) (scroll-up 5)))

;; Control-Z to suspend emacs is stupid when running from a window manager. It has the same effect as exiting from emacs
;; (since there's no terminal from which you can resume it) but it doesn't offer to save any files. With i3 emacs enters
;; some kind of weird state where teh window flashes if you press C-g but doesn't respond to anything else.  This is
;; made even worse by the fact that C-z is right next to C-x on Qwerty and Colemak keyboards.
(global-unset-key (kbd "C-z"))

;; Extra bindings for programmable keyboards
(global-set-key (kbd "C-M-s-b") 'ido-switch-buffer)
(global-set-key (kbd "C-M-s-c") 'compile)
(global-set-key (kbd "C-M-s-e") 'next-error)
(global-set-key (kbd "C-M-s-g") 'grep)
(global-set-key (kbd "C-M-s-l") 'goto-line)
(global-set-key (kbd "C-M-s-s") 'delete-other-windows)
(global-set-key (kbd "C-M-s-o") 'other-window)
(global-set-key (kbd "C-M-s-z") 'undo)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Helm -- completion mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'helm)
(require 'helm-config)

;; The default "C-x c" is quite close to "C-x C-c" which quits Emacs. Therefore, change the helm prefix to "C-c h". Note
;; that we must set the key globally because we cannot change helm-command-prefix-key once helm-config is loaded.
(global-set-key (kbd "C-c h") 'helm-command-prefix)
(global-unset-key (kbd "C-x c"))

(global-set-key (kbd "C-x C-f") 'helm-find-files)
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "M-y") 'helm-show-kill-ring)
(global-set-key (kbd "C-x b") 'helm-mini)
(global-set-key (kbd "C-c h o") 'helm-occur)
(global-set-key (kbd "C-h a") 'helm-apropos)
(global-set-key (kbd "C-h SPC") 'helm-all-mark-rings)

(define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action) ; rebind tab to run persistent action
(define-key helm-map (kbd "C-i") 'helm-execute-persistent-action)   ; make TAB work in terminal
(define-key helm-map (kbd "C-z") 'helm-select-action)		    ; list actions using C-z

(when (executable-find "curl")
  (setq helm-google-suggest-use-curl-p t))

(setq
 ;helm-full-frame 1
 helm-buffers-fuzzy-matching t
 helm-recent-fuzzy-match t
 helm-M-x-fuzzy-match t
 helm-split-window-inside-p t	      ; open helm buffer inside current window, not occupy whole other window
 ;helm-move-to-line-cycle-in-source t     ; move to end or beginning of source when reaching top or bottom of source
 ;helm-ff-search-library-in-sexp t	      ; search for library in 'require and 'declare-function sexp
 ;helm-scroll-amount 8		      ; scroll this many lines other window using M-<next> and M-<prior>
 helm-ff-file-name-history-use-recentf t
 helm-echo-input-in-header-line t)

(defun robb/helm-hide-minibuffer-maybe ()
  "Hide minibuffer in Helm session if we use the header line as input field."
  (when (with-helm-buffer helm-echo-input-in-header-line)
    (let ((ov (make-overlay (point-min) (point-max) nil nil t)))
      (overlay-put ov 'window (selected-window))
      (overlay-put ov 'face
                   (let ((bg-color (face-background 'default nil)))
                     `(:background ,bg-color :foreground ,bg-color)))
      (setq-local cursor-type nil))))

(add-hook 'helm-minibuffer-set-up-hook 'robb/helm-hide-minibuffer-maybe)

;; Limit the size of the helm buffer so that the first line, which is echoing what we're typing, is not jumping around
;; vertically on the screen as the number of matches changes.
(setq helm-autoresize-max-height 0
      helm-autoresize-min-height 40)

;; So that we can use helm to search for Unix man pages.
(add-to-list 'helm-sources-using-default-as-input 'helm-source-man-pages)

(helm-autoresize-mode 1)
(helm-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Ivy -- completion mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; (use-package ivy
;;;   :demand
;;;   :config (ivy-mode 1)
;;;   :custom (ivy-use-virtual-buffers t)
;;;   :bind (
;;; 	 ("C-s" . swiper)
;;; 	 ("C-r" . swiper-backward)
;;; 	 ("C-c C-r" . ivy-resume)
;;; 	 ("M-x" . counsel-M-x)
;;; 	 ("C-x C-f" . counsel-find-file)
;;; 	 ("C-h f" . counsel-describe-function)
;;; 	 ("C-h v" . counsel-describe-variable)
;;; 	 ("C-h o" . counsel-describe-symbol)
;;; 	 ("C-c g" . counsel-git)	; needs testing
;;; 	 ("C-c j" . counsel-git-grep)	; needs testing
;;; 	 ("C-c k" . counsel-ag)		; needs testing
;;; 	 ("C-c l" . counsel-locate)	; needs testing
;;; 	 ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Company mode -- complete anything
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; (use-package company
;;;   :hook (after-init . global-company-mode)
;;;   :custom
;;;   (company-minimum-prefix-length 1)
;;;   (company-idle-delay 0.1)
;;;   (company-show-numbers t)
;;;   ;;(company-selection-wrap-around t)
;;;   ;;(company-global-modes '(not help-mode helpful-mode))
;;;   (company-clang-executable "/usr/bin/clang-10")
;;;   )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IDO -- completion mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; (setq ido-enable-flex-matching t)
;;; (setq ido-everywhere t)
;;; (ido-mode 1)
;;; 
;;; (require 'ido-vertical-mode)
;;; (ido-vertical-mode t)
;;; (setq ido-vertical-define-keys 'C-n-and-C-p-up-down-left-right)
;;; 
;;; (global-set-key (kbd "M-x") 'smex)
;;; (global-set-key (kbd "M-X") 'smex-major-mode-commands)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Key mode -- interactively shows bindings for prefix keys
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package which-key
  :config (which-key-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Flycheck -- syntax checking for over 40 different programming languages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; ;;(use-package flycheck
;;; ;;  :ensure t
;;; ;;  :init (global-flycheck-mode))
;;; ;;(add-hook 'after-init-hook #'global-flycheck-mode)
;;; (require 'flycheck)
;;; (add-hook 'after-init-hook #'global-flycheck-mode)
;;; 
;;; ;;; flycheck apparently doesn't have any mechanism for adjusting the include search path or other compiler switches that
;;; ;;; might be necessary on a per source file basis.  But we can define a new checker that uses ede-compdb functions to do
;;; ;;; some of this.
;;; (use-package ede-compdb
;;; 	     :ensure t)
;;; (require 'ede-compdb)
;;; 
;;; ;;; When visiting a source file, we need to tell flycheck how to invoke the compiler. It needs to have the correct
;;; ;;; compiler, the correct include directory search path, the correct preprocessor defines and undefines, the correct
;;; ;;; multi-threading switches, the correct directory from which the compile command is invoked (since include search path
;;; ;;; might have relative path names, etc.  Most of this information can be obtained from an LLVM compilation database
;;; ;;; usually named "compile_commands.json". However, there are some problems we need to overcome:
;;; ;;;
;;; ;;; Problem 1: The compilation database lives in the build tree, not the source tree. Placing a symlink in the source
;;; ;;; tree problematic because then it gets monitored by the version control system.
;;; ;;;
;;; ;;; Problem 2: The compilation database is created as an artifact of the build system, and is therefore not always
;;; ;;; available when editing in the source tree.
;;; ;;;
;;; ;;; Problem 3: There might be more than one build tree for a given source tree when mutliple configurations of the
;;; ;;; project are built. Therefore we need to be able to choose which build tree's compilation database should be used.
;;; ;;;
;;; ;;; Problem 4: When the build system is Tup, the source tree and build tree are union mounted and therefore the build
;;; ;;; commands will reference the source files using names inside the build tree. After the build, these names of the
;;; ;;; source files no longer exist. Therefore we need to be able to convert the incorrect source file names that appear in
;;; ;;; the compilation database to their correct names in the real filesystem.
;;; ;;;
;;; ;;; Problem 5: For a large project, the compilation database can be many megabytes of JSON even without extraneous white
;;; ;;; space. Parsing this and doing the transformations and filesystem checks necessary to find and construct the syntax
;;; ;;; checking command takes too long in Lisp.
;;; ;;;
;;; ;;; We attempt solve these problems by invoking a separate compiled binary that does most of the work and returns a
;;; ;;; command-line (list of strings) that can be used by flycheck.  The following function is invoked in a source buffer.
;;; (defun robb/flycheck-compdb-setup ()
;;;   "Set up flycheck variables from compilation database for the current buffer."
;;;   (let ((output-buffer (get-buffer-create (generate-new-buffer-name "compile-database-parser")))
;;; 	(source-file-name (buffer-file-name))
;;; 	compile-command)
;;;     (unwind-protect
;;; 	(unless (null source-file-name)
;;; 	  (message "ROBB: running flycheck-compdb-setup for %s" source-file-name)
;;; 	  (with-current-buffer output-buffer (insert "(setq compile-command "))
;;; 
;;; 	  (if nil
;;; 	      (call-process "compile-database-parser" nil output-buffer nil (buffer-file-name))
;;; 	    ;; Debugging
;;; 	    (with-current-buffer output-buffer
;;; 	      (insert "(list \"/home/matzke/.spock/var/installed/wisconsin/641a39c9/gnu++14/bin/c++\" \"-I/home/matzke/.spock/var/installed/wisconsin/c3e0c349/capstone/include\" \"-DROSE_HAVE_DLIB\" \"-I/home/matzke/.spock/var/installed/wisconsin/023230f6/dlib/include\" \"-I/home/matzke/.spock/var/installed/wisconsin/2d8c4b36/libgcrypt/include\" \"-I/home/matzke/.spock/var/installed/wisconsin/92ccd7a6/libgpg-error/include\" \"-I/home/matzke/.spock/var/installed/wisconsin/bd33cb38/libpqxx/include\" \"-I/home/matzke/.spock/var/installed/wisconsin/32995dbf/sqlite/include\" \"-I/home/matzke/.spock/var/installed/wisconsin/2e9813bb/yamlcpp/include\" \"-I/home/matzke/.spock/var/installed/wisconsin/5195aec5/z3/include\" \"-I/home/matzke/.spock/var/installed/wisconsin/910bd440/boost-nopy/include\" \"-DBOOST_SYSTEM_NO_DEPRECATED=1\" \"-I/home/matzke/.spock/var/installed/wisconsin/a55e17c1/zlib/include\" \"-I../../..\" \"-I../../../src\" \"-I../../../src/3rdPartyLibraries/libharu-2.1.0/include\" \"-I../../../src/frontend/SageIII\" \"-I../../../src/frontend/SageIII/sageInterface\" \"-I../../../src/midend/binaryAnalyses\" \"-I../../../src/roseSupport\" \"-I../../../src/util\" \"-I../../../src/util/commandlineProcessing\" \"-I../../../src/util/stringSupport\" \"-g\" \"-DNDEBUG\" \"-pthread\" \"-D_FORTIFY_SOURCE=2\" \"-c\" \"/home/matzke/rose-wip/rose/src/util/Sawyer/CommandLine.C\")")))
;;; 
;;; 	  (message "ROBB: call-process completed")
;;; 	  (with-current-buffer output-buffer (insert ")"))
;;; 	  (eval-buffer output-buffer); always returns nil, which is why we added the (setq compile-command XXX) wrapper around the output buffer
;;; 	  (message "ROBB: compile-command = %s" compile-command)
;;; 	  (setq flycheck-clang-args (cdr compile-command)))
;;;       (if (null compile-command)
;;; 	  (message "ROBB: no compile command output"))
;;;       (message "ROBB: killing output buffer")
;;;       ;(kill-buffer output-buffer)
;;;       )))
;;; 
;;; ;;; FIXME: perhaps we should only run this on C and C++ files
;;; (add-hook 'flycheck-mode-hook #'robb/flycheck-compdb-setup)
;;; 
;;; 
;;; 
;;; 
;;; 
;;; ;;      ;; Configure flycheck clang checker.
;;; ;;      ;; TODO: configure gcc checker also
;;; ;;      (when (string-match " -std=\\([^ ]+\\)" cmd)
;;; ;;        (setq-local flycheck-clang-language-standard (match-string 1 cmd)))
;;; ;;      (when (string-match " -stdlib=\\([^ ]+\\)" cmd)
;;; ;;        (setq-local flycheck-clang-standard-library (match-string 1 cmd)))
;;; ;;      (when (string-match " -fms-extensions " cmd)
;;; ;;        (setq-local flycheck-clang-ms-extensions t))
;;; ;;      (when (string-match " -fno-exceptions " cmd)
;;; ;;        (setq-local flycheck-clang-no-exceptions t))
;;; ;;      (when (string-match " -fno-rtti " cmd)
;;; ;;        (setq-local flycheck-clang-no-rtti t))
;;; ;;      (when (string-match " -fblocks " cmd)
;;; ;;        (setq-local flycheck-clang-blocks t))
;;; ;;      (setq-local flycheck-clang-includes (get-includes comp))
;;; ;;      (setq-local flycheck-clang-definitions (get-defines comp))
;;; ;;      (setq-local flycheck-clang-include-path (get-include-path comp t))
;;; 
;;; 
;;; (add-hook 'ede-compdb-project-rescan-hook #'robb/flycheck-compdb-setup)
;;; 
;;; 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LSP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package lsp-mode
  ;; Possibly add --pch-storage=... for more speed
  :config
  (setq ;lsp-clients-clangd-args '("-j=20" "--background-index" "--log=verbose")
	;lsp-clients-clangd-args '("--compile-commands-dir=/home/matzke/rose-wip/rose" "-j=20" "--background-index" "--log=verbose")
	lsp-clients-clangd-args '("--compile-commands-dir=/home/matzke/sawyer" "-j=20" "--log=verbose")
	lsp-clients-clangd-executable "/usr/bin/clangd-10"
	lsp-prefer-flymake nil)
  ;; ROBB: :hook not available for 25.2.2
  ;;:hook ((c++-mode . lsp)
  ;;	 (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)

(use-package lsp-ui :commands lsp-ui-mode)
(use-package helm-lsp :commands helm-lsp-workspace-symbol)
;;(use-package lsp-ivy :commands lsp-ivy-workspace-symbol)
;;(use-package lsp-treemacs :commands lsp-treemacs-errors-list)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Projectile (requires emacs 25 or later)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; (if (version< emacs-version "25")
;;;     nil
;;;   (unless (package-installed-p 'projectile)
;;;     (package-install 'projectile))
;;;   (projectile-mode +1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Magit (git in emacs)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(if (version< emacs-version "25")
    nil
  (unless (package-installed-p 'magit)
    (package-install 'magit))

  (require 'magit)

  (defadvice magit-status (after robb-magit-fullscreen activate)
    "Open the magit-status window in full frame mode instead of splitting the current window."
    (delete-other-windows))

  (defun robb-magit-push-to-jenkins (source)
    "Push an arbitrary branch or commit to Jenkins. The source is read from the minibuffer."
    (interactive
     (let ((source (magit-read-local-branch-or-commit "to push")))
       (list source)))
    (magit-git-command-topdir (concat "git push jenkins +" source ":refs/heads/matzke/rose-dev")))

  (magit-define-popup-action 'magit-push-popup
    ?j
    "to jenkins matzke/rose-dev"
    'robb-magit-push-to-jenkins))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ws-butler -- unobtrusive whitespace cleanup at ends of lines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'ws-butler)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto-complete-el (Debian package)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; ;(add-to-list 'load-path "~/.emacs.d")
;;; (require 'auto-complete-config)
;;; (add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
;;; (ac-config-default)
;;; (setq ac-use-quick-help t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CEDET
;; Do not install Debian "ede" package. Use:
;; bzr checkout bzr://cedet.bzr.sourceforge.net/bzrroot/cedet/code/trunk cedet
;; See http://cedet.sourceforge.net/bzr-repo.shtml

;;; (load-file "~/cedet/cedet-devel-load.el")
;;; (load-file "~/cedet/contrib/semantic-tag-folding.el")
;;; (setq semantic-default-submodes '(; enables global support for Semanticdb
;;; 				  global-semanticdb-minor-mode
;;; 				  ; automatic bookmarking of tags that you edited, so you can return to them later with the
;;; 				  ; semantic-mrub-switch-tags command.
;;; 				  global-semantic-mru-bookmark-mode
;;; 				  ; activates CEDET's context menu that is bound to right mouse button
;;; 				  global-cedet-m3-minor-mode
;;; 				  ; activates highlighting of first line for current tag (function, class, etc)
;;; 				  global-semantic-highlight-func-mode
;;; 				  ; activates mode when name of current tag will be shown in top line of buffer
;;; 				  global-semantic-stickyfunc-mode
;;; 				  ; activates use of separate styles for tags decoration (depending on tag's class). These styles
;;; 				  ; are defined in the semantic-decoration-styles list.
;;; 				  ;global-semantic-decoration-mode
;;; 				  ; activates highlighting of local names that are the same as name of tag under cursor
;;; 				  global-semantic-idle-local-symbol-highlight-mode
;;; 				  ; activates automatic parsing of source code in the idle time
;;; 				  global-semantic-idle-scheduler-mode
;;; 				  ; activates displaying of possible name completions in the idle time. Requires that
;;; 				  ; global-semantic-idle-schedule-mode was enabled.
;;; 				  ;       global-semantic-idle-completions-mode
;;; 				  ; ?
;;; 				  global-semantic-tag-folding-mode
;;; 				  global-semantic-minor-mode))
;;; 
;;; ;(semantic-mode 1)                      ; COMMENTED OUT BECAUSE IT CAUSES "Wrong type argument: stringp, 1" when loading C++ files
;;; (require 'semantic/ia)			; advanced features
;;; (require 'semantic/bovine/gcc)		; system header file locations for GCC
;;; (require 'semantic/mru-bookmark)	; automatic bookmark tracking
;;; (require 'semantic-tag-folding)		; see cedet/contrib/semantic-tag-folding.el
;;; ;(semantic-add-system-include "~/boost/boost_1_47_0/include" 'c++-mode)
;;; (semantic-load-enable-code-helpers)
;;; 
;;; ;; Integrate cedet with imenu: creates a menu item that lists things in the buffer
;;; (setq imenu-sort-function 'imenu--sort-by-name)
;;; (setq imenu-max-items 100)		;maximum number of elements in a mouse menu
;;; ;(setq imenu-after-jump-hook (lambda () (recenter 3)))
;;; (defun robb-semantic-hook ()
;;;   (imenu-add-to-menubar "TAGS"))
;;; (add-hook 'semantic-init-hooks 'robb-semantic-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; filladapt -- better filling functions. "Filling" is the process of moving new-line characters
;; within a "paragraph" in order to make the lines all approximately the same length.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; (require 'filladapt)
;;; ;(setq-default filladapt-mode t)         ; enable filladapt for all buffers...
;;; ;(add-hook 'c-mode-hook 'turn-off-filladapt-mode) ; except C source code
;;; ;(setq filladapt-mode-line-string nil)   ; and don't advertise the minor mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Programming stuff follows...
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Compiling -- the `compile' command bound to `f5' above.  This will compile something (usually
;; with make(1) and capture the output in a separate window. You can visit each error/warning
;; with next-error (C-x `) or visit a specific error by middle-clicking (or C-c C-c) on that
;; error line.
;(load "compile")
(setq compilation-window-height 8)
(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))

;; Perl programming
(setq perl-indent-level 4)

;; Tup build system files
;(load-file "~/.emacs.d/tup-mode/tup-mode.el")

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
  (setq truncate-lines t)
  (ws-butler-mode 1)

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

(defun rpm-d-mode-hook ()
  (setq tab-width 8)
  (setq indent-tabs-mode nil)
  (setq truncate-lines t)
  (setq fill-column (- 132 5))
  (setq comment-column 64)
  (ws-butler-mode 1))

;(load "rpmc")				;Robb's C minor mode
(load "pilf")				;Robb's new C/C++ minor mode (2010)
(add-hook 'c-mode-hook 'rpm-c-mode-hook)
(add-hook 'c++-mode-hook 'rpm-c-mode-hook)
(add-hook 'd-mode-hook 'rpm-d-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Allow ANSI color code escapes in the compile window
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'ansi-color)
(defun colorize-compilation-buffer ()
  (toggle-read-only)
  (ansi-color-apply-on-region compilation-filter-start (point))
  (toggle-read-only))
(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Selectively hides C/C++ 'if' and 'ifdef' regions.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq hide-ifdef-mode-hook
      (lambda ()
	(if (not hide-ifdef-define-alist)
	    (setq hide-ifdef-define-alist
		  '((rose
		     ROSE_ENABLE_ASM_AARCH32
		     ROSE_ENABLE_ASM_AARCH64
		     ROSE_ENABLE_BINARY_ANALYSIS
		     ROSE_ENABLE_CONCOLIC_TESTING
		     ROSE_ENABLE_SIMULATOR
		     ROSE_SUPPORTS_SERIAL_IO
		     __linux)
		    (list2 ONE TWO THREE))))
	(hide-ifdef-use-define-alist 'rose) ; use this list by default
	))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org Mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq org-hide-leading-stars t)
(setq org-odd-levels-only t)
(setq org-log-done 'time)
(setq org-agenda-files '("~/Notes"))
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; E-mail
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(load-file "~/DeveloperScripts/xemacs/mu4e-config.el")

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
 '(custom-enabled-themes (quote (tsdh-dark)))
 '(delete-old-versions t)
 '(display-time-mode t)
 '(ecb-auto-activate t)
 '(ecb-options-version "2.32")
 '(global-linum-mode t)
 '(hide-ifdef-initially t)
 '(hide-ifdef-shadow t)
 '(next-error-highlight t)
 '(org-agenda-files nil)
 '(save-place t nil (saveplace))
 '(scroll-bar-mode (quote right))
 '(show-paren-mode t)
 '(show-paren-style (quote mixed))
 '(text-mode-hook (quote (turn-on-auto-fill text-mode-hook-identify)))
 '(tool-bar-mode nil)
 '(transient-mark-mode nil)
 '(vc-handled-backends (quote (RCS CVS SVN SCCS Bzr Hg Mtn Arch)))
 '(which-function-mode t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
