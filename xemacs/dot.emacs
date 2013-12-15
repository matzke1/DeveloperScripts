;; Robb's emacs startup file                                                                           -*- lisp -*-

(setq load-path (append load-path (list (expand-file-name "~/.xemacs"))))

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
(tool-bar-mode 0)			;turn off the tool bar since it just wastes space
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

;; Semanticdb can also use databases generated by external utilities: gtags (from Debian packages global (gtags) and
;; exuberant-ctags (ctags-exuberant).
;(when (cedet-gnu-global-version-check t)
;  (semanticdb-enable-gnu-global-databases 'c-mode)
;  (semanticdb-enable-gnu-global-databases 'c++-mode))
;(when (cedet-ectag-version-check)
;  (semantic-load-enable-primary-exuberent-ctags-support))

;; Support for projects
;(global-ede-mode t)

;;;;; Rose src directories that contain *.h or *.hpp files, relative to the "src" directory.
;;;(setq rose-src-include-directories
;;;      '("/3rdPartyLibraries/MSTL"
;;;	"/3rdPartyLibraries/POET"
;;;	"/3rdPartyLibraries/UPR/examples/cuda/test-cuda-runtime.hpp"
;;;	"/3rdPartyLibraries/UPR/examples/opencl/test-opencl-runtime.hpp"
;;;	"/3rdPartyLibraries/UPR/examples/xomp/test-xomp-runtime.hpp"
;;;	"/3rdPartyLibraries/UPR/include/UPR/cuda-runtime.hpp"
;;;	"/3rdPartyLibraries/UPR/include/UPR/opencl-runtime.hpp"
;;;	"/3rdPartyLibraries/UPR/include/UPR/runtime.hpp"
;;;	"/3rdPartyLibraries/UPR/include/UPR/xomp-runtime.hpp"
;;;	"/3rdPartyLibraries/checkPointLibrary"
;;;	"/3rdPartyLibraries/ckpt"
;;;	"/3rdPartyLibraries/libharu-2.1.0/demo"
;;;	"/3rdPartyLibraries/libharu-2.1.0/include"
;;;	"/3rdPartyLibraries/libharu-2.1.0/win32/include"
;;;	"/3rdPartyLibraries/qrose/Components/Common"
;;;	"/3rdPartyLibraries/qrose/Components/QueryBox"
;;;	"/3rdPartyLibraries/qrose/Components/SourceBox"
;;;	"/3rdPartyLibraries/qrose/Components/TreeBox"
;;;	"/3rdPartyLibraries/qrose/Framework"
;;;	"/3rdPartyLibraries/qrose/Widgets"
;;;	"/ROSETTA/src"
;;;	"/backend/asmUnparser"
;;;	"/backend/unparser"
;;;	"/backend/unparser/CxxCodeGeneration"
;;;	"/backend/unparser/FortranCodeGeneration"
;;;	"/backend/unparser/JavaCodeGeneration"
;;;	"/backend/unparser/PHPCodeGeneration"
;;;	"/backend/unparser/PythonCodeGeneration"
;;;	"/backend/unparser/X10CodeGeneration"
;;;	"/backend/unparser/formatSupport"
;;;	"/backend/unparser/languageIndependenceSupport"
;;;	"/frontend/BinaryDisassembly"
;;;	"/frontend/BinaryFormats"
;;;	"/frontend/BinaryLoader"
;;;	"/frontend/Disassemblers"
;;;	"/frontend/ECJ_ROSE_Connection"
;;;	"/frontend/OpenFortranParser_SAGE_Connection"
;;;	"/frontend/PHPFrontend"
;;;	"/frontend/PythonFrontend"
;;;	"/frontend/SageIII"
;;;	"/frontend/SageIII/astFileIO"
;;;	"/frontend/SageIII/astFixup"
;;;	"/frontend/SageIII/astFromString"
;;;	"/frontend/SageIII/astFromString/ParserBuilder.hpp"
;;;	"/frontend/SageIII/astHiddenTypeAndDeclarationLists"
;;;	"/frontend/SageIII/astMerge"
;;;	"/frontend/SageIII/astPostProcessing"
;;;	"/frontend/SageIII/astTokenStream"
;;;	"/frontend/SageIII/astVisualization"
;;;	"/frontend/SageIII/includeDirectivesProcessing"
;;;	"/frontend/SageIII/sageInterface"
;;;	"/frontend/SageIII/sage_support"
;;;	"/frontend/SageIII/virtualCFG"
;;;	"/frontend/X10_ROSE_Connection"
;;;	"/midend/abstractHandle"
;;;	"/midend/abstractMemoryObject"
;;;	"/midend/astDiagnostics"
;;;	"/midend/astProcessing"
;;;	"/midend/astQuery"
;;;	"/midend/astRewriteMechanism"
;;;	"/midend/astUtil/annotation"
;;;	"/midend/astUtil/astInterface"
;;;	"/midend/astUtil/astSupport"
;;;	"/midend/astUtil/symbolicVal"
;;;	"/midend/binaryAnalyses"
;;;	"/midend/binaryAnalyses/dataflowanalyses"
;;;	"/midend/binaryAnalyses/instructionSemantics"
;;;	"/midend/binaryAnalyses/libraryIdentification"
;;;	"/midend/programAnalysis/CFG"
;;;	"/midend/programAnalysis/CallGraphAnalysis"
;;;	"/midend/programAnalysis/CallGraphAnalysisMySQL"
;;;	"/midend/programAnalysis/OAWrap"
;;;	"/midend/programAnalysis/OpenAnalysis/CFG"
;;;	"/midend/programAnalysis/OpenAnalysis/CallGraph"
;;;	"/midend/programAnalysis/OpenAnalysis/Interface"
;;;	"/midend/programAnalysis/OpenAnalysis/SSA"
;;;	"/midend/programAnalysis/OpenAnalysis/Utils"
;;;	"/midend/programAnalysis/VirtualFunctionAnalysis"
;;;	"/midend/programAnalysis/annotationLanguageParser"
;;;	"/midend/programAnalysis/bitvectorDataflow"
;;;	"/midend/programAnalysis/dataflowAnalysis"
;;;	"/midend/programAnalysis/defUseAnalysis"
;;;	"/midend/programAnalysis/distributedMemoryAnalysis"
;;;	"/midend/programAnalysis/distributedMemoryAnalysis/distributedVerificationExample"
;;;	"/midend/programAnalysis/dominanceAnalysis"
;;;	"/midend/programAnalysis/dominatorTreesAndDominanceFrontiers"
;;;	"/midend/programAnalysis/genericDataflow"
;;;	"/midend/programAnalysis/genericDataflow/analysis"
;;;	"/midend/programAnalysis/genericDataflow/arrIndexLabeler"
;;;	"/midend/programAnalysis/genericDataflow/cfgUtils"
;;;	"/midend/programAnalysis/genericDataflow/lattice"
;;;	"/midend/programAnalysis/genericDataflow/rwAccessLabeler"
;;;	"/midend/programAnalysis/genericDataflow/simpleAnalyses"
;;;	"/midend/programAnalysis/genericDataflow/state"
;;;	"/midend/programAnalysis/genericDataflow/variables"
;;;	"/midend/programAnalysis/graphAnalysis"
;;;	"/midend/programAnalysis/pointerAnal"
;;;	"/midend/programAnalysis/proceduralSlicing"
;;;	"/midend/programAnalysis/proceduralSlicing/test"
;;;	"/midend/programAnalysis/sideEffectAnalysis"
;;;	"/midend/programAnalysis/ssaUnfilteredCfg"
;;;	"/midend/programAnalysis/staticInterproceduralSlicing"
;;;	"/midend/programAnalysis/staticSingleAssignment"
;;;	"/midend/programAnalysis/systemDependenceGraph"
;;;	"/midend/programAnalysis/valuePropagation"
;;;	"/midend/programAnalysis/variableRenaming"
;;;	"/midend/programTransformation/astInlining"
;;;	"/midend/programTransformation/constantFolding"
;;;	"/midend/programTransformation/extractFunctionArgumentsNormalization"
;;;	"/midend/programTransformation/finiteDifferencing"
;;;	"/midend/programTransformation/functionCallNormalization"
;;;	"/midend/programTransformation/implicitCodeGeneration"
;;;	"/midend/programTransformation/loopProcessing/computation"
;;;	"/midend/programTransformation/loopProcessing/depGraph"
;;;	"/midend/programTransformation/loopProcessing/depInfo"
;;;	"/midend/programTransformation/loopProcessing/driver"
;;;	"/midend/programTransformation/loopProcessing/outsideInterface"
;;;	"/midend/programTransformation/loopProcessing/prepostTransformation"
;;;	"/midend/programTransformation/loopProcessing/slicing"
;;;	"/midend/programTransformation/ompLowering"
;;;	"/midend/programTransformation/partialRedundancyElimination"
;;;	"/roseExtensions/dataStructureTraversal"
;;;	"/roseExtensions/qtWidgets/AsmInstructionBar"
;;;	"/roseExtensions/qtWidgets/AsmView"
;;;	"/roseExtensions/qtWidgets/AstBrowserWidget"
;;;	"/roseExtensions/qtWidgets/AstGraphWidget"
;;;	"/roseExtensions/qtWidgets/AstProcessing"
;;;	"/roseExtensions/qtWidgets/BeautifiedAst"
;;;	"/roseExtensions/qtWidgets/FlopCounter"
;;;	"/roseExtensions/qtWidgets/InstructionCountAnnotator"
;;;	"/roseExtensions/qtWidgets/KiviatView"
;;;	"/roseExtensions/qtWidgets/MetricFilter"
;;;	"/roseExtensions/qtWidgets/MetricsConfig"
;;;	"/roseExtensions/qtWidgets/MetricsKiviat"
;;;	"/roseExtensions/qtWidgets/NodeInfoWidget"
;;;	"/roseExtensions/qtWidgets/ProjectManager"
;;;	"/roseExtensions/qtWidgets/PropertyTreeWidget"
;;;	"/roseExtensions/qtWidgets/QCodeEditWidget"
;;;	"/roseExtensions/qtWidgets/QCodeEditWidget/QCodeEdit"
;;;	"/roseExtensions/qtWidgets/QCodeEditWidget/QCodeEdit/document"
;;;	"/roseExtensions/qtWidgets/QCodeEditWidget/QCodeEdit/qnfa"
;;;	"/roseExtensions/qtWidgets/QCodeEditWidget/QCodeEdit/widgets"
;;;	"/roseExtensions/qtWidgets/QtGradientEditor"
;;;	"/roseExtensions/qtWidgets/RoseCodeEdit"
;;;	"/roseExtensions/qtWidgets/RoseFileSelector"
;;;	"/roseExtensions/qtWidgets/SrcBinView"
;;;	"/roseExtensions/qtWidgets/TaskSystem"
;;;	"/roseExtensions/qtWidgets/TreeModel"
;;;	"/roseExtensions/qtWidgets/WidgetCreator"
;;;	"/roseExtensions/qtWidgets/util"
;;;	"/roseExtensions/sqlite3x"
;;;	"/roseIndependentSupport/dot2gml"
;;;	"/roseIndependentSupport/graphics"
;;;	"/roseIndependentSupport/visualization"
;;;	"/roseSupport"
;;;	"/util"
;;;	"/util/commandlineProcessing"
;;;	"/util/graphs"
;;;	"/util/stringSupport"
;;;	"/util/support"))
;;;(setq rose-include-directories (append '("/src") (mapcar (lambda (x) (concat "/src" x)) rose-src-include-directories)))
;;;
;;;;; Parsing ROSE automake files doesn't work, so use this instead
;;;(ede-cpp-root-project "rose-semantics2"
;;;		      :file "/home/matzke/GS-CAD/ROSE/sources/semantics2/rose_config.h.in"
;;;		      :include-path rose-include-directories)
;;;(ede-cpp-root-project "rose-simulator"
;;;		      :file "/home/matzke/GS-CAD/ROSE/sources/edg4x-simulator/rose_config.h.in"
;;;		      :include-path rose-include-directories)
;;;
;;;;; Stone Soup
;;;(ede-cpp-root-project "ss-vuln-injector"
;;;		      :file "/home/matzke/GS-CAD/ROSE/StoneSoup/ss_vuln_injector/README.txt"
;;;		      :include-path '("/src"
;;;				      "/src/control-flow"
;;;				      "/src/data-flow"
;;;				      "/src/data-type"
;;;				      "/src/source-taint"
;;;				      "/src/weakness"
;;;				      "/src/weakness/injection"
;;;				      "/src/weakness/null-pointer-errors"
;;;				      "/src/weakness/number-handling"
;;;				      "/src/weakness/resource-drains"
;;;				      "/src/weakness/tainted-data"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; filladapt -- better filling functions. "Filling" is the process of moving new-line characters
;; within a "paragraph" in order to make the lines all approximately the same length.
(require 'filladapt)
(setq-default filladapt-mode t)         ; enable filladapt for all buffers...
;(add-hook 'c-mode-hook 'turn-off-filladapt-mode) ; except C source code
;(setq filladapt-mode-line-string nil)   ; and don't advertise the minor mode

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
;(setq tags-build-completion-table t)    ;always build, don't ask
;(setq tags-auto-read-changed-tag-files t) ;automatically reread TAGS files

;; Compiling -- the `compile' command bound to `f5' above.  This will compile something (usually
;; with make(1) and capture the output in a separate window. You can visit each error/warning
;; with next-error (C-x `) or visit a specific error by middle-clicking (or C-c C-c) on that
;; error line.
;(load "compile")
;(setq remote-shell-program "ssh")
(setq compilation-window-height 8)
;(setq remote-compile-prompt-for-host t)
;(setq remote-compile-prompt-for-user t)
;(compilation-build-compilation-error-regexp-alist)
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
				   (namespace-open after)
				   (namespace-close before after)
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

;; Function menu stuff (fume). This is for the `Functions' pulldown menu in the toolbar.
;(require 'func-menu)
;(define-key global-map 'f8 'function-menu)
;(add-hook 'find-file-hooks 'fume-add-menubar-entry)
;(define-key global-map "\C-cl" 'fume-list-functions)
;(define-key global-map "\C-cg" 'fume-prompt-function-goto)
;(define-key global-map '(shift button3) 'mouse-function-menu) ;note: conflicts with Hyperbole
;(setq fume-max-items 40
;      fume-fn-window-position 3
;      fume-auto-position-popup t
;      fume-display-in-modeline-p t
;      fume-menubar-menu-location nil	;right-most left justified
;      fume-buffer-name "*Function List*"
;      fume-no-prompt-on-valid-default nil)

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
;; Fixes for dired. Dired on debian has //DIRED garbage at end of buffer.
;; See http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=399483
;; This will no longer be necessary when it's fixed up stream.
;; Added by RPM 2010-02-08, XEmacs 21.4 (patch 21)
;(add-hook 'dired-load-hook
;  (lambda ()
;    (set-variable 'dired-use-ls-dired
;      (and (string-match "gnu" system-configuration)
;           ;; Only supported for XEmacs >= 21.5 and GNU Emacs >= 21.4 (I think)
;           (if (featurep 'xemacs)
;               (and
;		(fboundp 'emacs-version>=)
;		(emacs-version>= 21 5))
;             (and (boundp 'emacs-major-version)
;                  (boundp 'emacs-minor-version)
;                  (or (> emacs-major-version 21)
;                      (and (= emacs-major-version 21)
;                           (>= emacs-minor-version 4)))))))))
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
