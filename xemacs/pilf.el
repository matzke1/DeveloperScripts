;; pilf.el -- program intra-line formatting
;; Copyright (C) 2010 Robb Matzke.
;;
;; Pilf (a minor mode) works in conjunction with c-mode to automatically format C/C++ source code as it is typed.
;; While c-mode is primarily in charge of indentation of lines, pilf minor mode operates on a single line at a time to
;; adjust white space within the line.

(defconst pilf-version "1.2.0")

;(defvar pilf-configuration-alist

(setq pilf-configuration-alist
  '((author-name . user-full-name)

    ;; Comment text to insert after a '}' and on the same line.  For instance, it's useful to add the comment "namespace" to
    ;; the closing brace of a namespace, especially when the contents of the namespace is not indented and the opening of the
    ;; namespace is far away.  Beware that it can be a hindrance to add comments that contain the name of the thing being
    ;; closed since programers don't typically know that they need to update that far-away comment if they change the name.
    ;;
    ;; The value is one of the following:
    ;;   + A single-line string that will serve as the text of a comment (excludes comment delimiters).
    ;;   + A function or function symbol that returns the value. The function is called with one argument: a symbol
    ;;     returned from pilf-at-closing-brace that describes the language construct being closed.
    ;;   + An association list whose keys are language constructs returned by pilf-at-closing-brace and whose values
    ;;     are either strings or functions like above.
    ;; The default is nil, which prevents a comment from being produced (empty string does the same).
    (closing-brace-annotation (namespace . "namespace"))

    ;; String to replace the white space that appears before a '{' when the brace is not the only non-space on the line.
    ;; The value is the same as for the "closing-brace-annotation" property.  The default, nil, prevents any changes from
    ;; being made to the white space.
    (hanging-brace-pre-space . " ")

    ;; White space to insert between a keyword and a left paren, such as after 'for', 'if', 'while', etc.  The value is
    ;; the same as for the "closing-brace-annotation" property.  The default, nil, prevents any changes from being made
    ;; to the white space.
    (keyword-paren-pre-space
     (and . " ") (bitand . " ") (bitor . " ") (catch . " ") (compl . " ") (delete . " ") (for . " ") (foreach . " ")
     (if . " ") (new . " ") (not . " ") (not_eq . " ") (or . " ") (return . " ") (sizeof . "") (switch . " ") (throw . " ")
     (typeid . "") (while . " ") (xor . " ") (BOOST_FOREACH . " "))

    ;; White space to insert after a left paren after a keyword, such as after 'for', 'if', 'while', etc.  The value is
    ;; the same as for the "closing-brace-annotation" property.  The default, nil, prevents any changes from being made
    ;; to the white space.
    (keyword-paren-post-space . "")

    ;; White space to insert between a function name and the '(' of its argument list in a function call.  The value is
    ;; nil (the default, indicates no change to white space), or a string of white space, or a function or function symbol
    ;; that will be invoked with one argument (the function name string) to produce a string or nil.
    (function-paren-pre-space . "")

    ;; White space to insert after the left paren of a function name. The value is nil (the default, indicates no change
    ;; to white space), or a string of white space, or a function or function symbol that will be invoked with one argument
    ;; (the function name string) to produce a string or nil.
    (function-paren-post-space . "")

    ;; White space to place after commas.
    (comma-post-space . " ")

    ;; White space before semicolons
    (semicolon-pre-space . "")

    ;; White space after semicolons in the middle of a line.
    (semicolon-post-space . " ")

    ;; Maximum width for code, comments, etc.  E.g., the ROSE style guide says on line should be wider than 132 columns, so
    ;; we could set this appropriately.  Code often looks better (and is easier to edit) if one stays slightly below the
    ;; maximum allowed by the style guide.
    (maximum-line-width . 128)

    ;; Column number for comments that are at the end of a line with other stuff
    (trailing-comment-column . 56)

    ;; Determines when a whole-line comment should be moved to the end of the previous line.  This property is only consulted
    ;; when it's already been determined that the comment could be moved.
    (hoist-trailing-comment . pilf-previous-line-ends-with-semicolon-p)

    ;; If t (or a function that returns t) then CPP directives are automatically terminated by inserting a line feed and
    ;; indenting.
    (terminate-cpp-directive . nil)

    ;; If t (or a function that returns t) then automatically start a new line when a C-style comment is closed.
    (terminate-c-comment . t)

    ))

(defvar pilf-fixups-alist nil
  "Maps keys to the list of fixup functions that need to be called for that key.")

(defvar pilf-mode-map nil
  "Keymap used in pilf minor mode overrides the cc-mode key map.")

(defun pilf-mode (&optional arg)
  "Minor mode under cc-mode for formatting C/C++ source code.

If ARG is not supplied then toggle the state of this minor mode. If
ARG is a number then turn the mode on if positive, off otherwise.  If
ARG is a string then turn the mode on and set the indentation style as
specified by the string."
  (interactive "P")

  ;; Localize configuration to this buffer.  Especially localize pilf-mode, which turns this mode on an off.
  (make-local-variable 'pilf-mode)

  ;; Turn this minor mode on or off according to ARG or toggle its current state.
  (setq pilf-mode
	(cond
	 ((null arg) (not pilf-mode))
	 ((stringp arg) (c-set-style arg) t)
	 ((> (prefix-numeric-value arg) 0))))

  ;; Add the minor mode name to the mode line.
;  (setq minor-mode-alist '(pilf-mode " Pilf"))

  ;; Build the minor-mode keymap
  (when (not pilf-mode-map)
    (setq pilf-mode-map (make-sparse-keymap "pilf-mode-map"))
    (define-key pilf-mode-map [return] 'pilf-electric-return)
    (mapcar (lambda (key-fixups)
	      (define-key pilf-mode-map (vector (car key-fixups)) 'pilf-electric-key))
	    pilf-fixups-alist))

  ;; Add the minor-mode key map if not done already.
  (or (assq 'pilf-mode minor-mode-map-alist)
      (setq minor-mode-map-alist
	    (cons (cons 'pilf-mode pilf-mode-map) minor-mode-map-alist))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;
;;;;;                                        Configuration functions
;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun pilf-get-config (property-name &rest args)
  "Returns the configuration value associated with the specified name, or nil.

If the value is a function symbol or a lambda then the function is invoked with the given arguments and that value is returned."
  (let* ((value (cdr (assoc property-name pilf-configuration-alist)))
	 (function (indirect-function value t)))
    (if (functionp function)
	(setq value (apply function args)))
    value))


(defun pilf-get-config-nonlist (property-name alist-key default)
  "Returns a configuration value by recursive function invocation and alist lookups.

Looks up PROPERTY-NAME in the configuration settings. If the value is a function or a function symbol then the function is
invoked with ALIST-KEY as its argument and the return value is used; if the value is a list then it is treated as an association
list and the value associated with ALIST-KEY is returned.  The previous step repeats until the value is is neither a function,
function symbol, or list. This function returns either the final value, or DEFAULT if the final value is nil."
  (let* ((value (cdr (assoc property-name pilf-configuration-alist)))
	 (keep-going t))
    (while keep-going
      (cond ((null value)
	     (setq keep-going nil))
	    ((functionp value)
	     (setq value (funcall value alist-key)))
	    ((listp value)
	     (setq value (cdr (assoc alist-key value))))
	    (t
	     (setq keep-going nil))))
    (or value default)))

	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;
;;;;;                                        Language syntax queries
;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun pilf-nonliteral-p ()
  "Returns t if point is not in a comment, string, or other literal element."
  (not (c-in-literal)))


(defun pilf-at-opening-brace ()
  "Returns non-nil if point is at (left of) an opening brace.

The return value is a symbol indicating the language construct that is being opened, and is one of the following:
   namespace
   while
   do
   for        'for', 'foreach', 'BOOST_FOREACH'
   if
   else
   switch
   case       for switch cases, including 'default'
   try
   catch
   t          anything else"
  (condition-case nil
      (save-excursion
	(if (or (c-in-literal) (not (looking-at "{")))
	    nil
	  (cond ((looking-back "\\bnamespace[ \t\n\r]+\\sw+[ \t\n\r]*") 'namespace)
		((looking-back "\\bdo[ \t\n\r]*")                       'do)
		((looking-back "\\belse[ \t\n\r]*")                     'else)
		((looking-back "\\bcase[ \t]+[a-zA-Z_0-9]+[ \t]*:[ \t\n\r]*")   'case)
		((looking-back "\\bdefault[ \t]*:[ \t\n\r]*")           'case)
		((looking-back "\\btry[ \t\n\r]*")                      'try)
		((looking-back ")[ \t\n\r]*")
		 (backward-sexp)	;back to the matching '(' or error
		 (cond ((looking-back "\\bfor[ \t\n\r]*")     	    	'for)
		       ((looking-back "\\bforeach[ \t\n\r]*") 	    	'for)
		       ((looking-back "\\bBOOST_FOREACH[ \t\n\r]*") 	'for)
		       ((looking-back "\\bif[ \t\n\r]*")      	    	'if)
		       ((looking-back "\\bswitch[ \t\n\r]*")            'switch)
		       ((looking-back "\\bwhile[ \t\n\r]*")   	    	'while)
		       ((looking-back "\\bcatch[ \t\n\r]*")             'catch)
		       (t t)))
		(t t))))))


(defun pilf-after-opening-brace ()
  "Returns non-nil if point is after an opening brace.

White space may appear between the opening brace and point. The return value is the same as for pilf-at-opening-brace."
  (condition-case nil
      (save-excursion
	(if (or (c-in-literal) (not (re-search-backward "{[ \t\n\r]*" nil t)))
	    nil
	  (pilf-at-opening-brace)))))


(defun pilf-after-closing-brace ()
  "Returns non-nil if point is after a closing brace.

White space may appear between the closing brace and point. The return value is the same as for pilf-at-opening-brace."
  (condition-case nil
      (save-excursion
	(if (or (c-in-literal) (not (looking-back "}[ \t\n\r]*")))
	    nil
	  (backward-sexp)		;back to the matching '{' or error
	  (pilf-at-opening-brace)))))


(defun pilf-in-trailing-comment-p ()
  "Returns t if there's something to the left of the start of this comment."
  (let* ((in-comment (pilf-in-comment)))
    (and in-comment
	 (save-excursion
	   (goto-char (cdr in-comment))
	   (not (looking-back "^[ \t]*")))
	 t)))


(defun pilf-line-ends-with-comment-p ()
  "Returns non-nil if the current line ends with a comment.

The return value is the same as for pilf-in-comment: a list containing the type of comment and the starting position."
  (save-excursion
    (end-of-line)
    (or (pilf-in-comment)
	(and (looking-back "\\*/[ \t]*")
	     (progn (backward-char 2) (pilf-in-comment))))))


(defun pilf-previous-line-ends-with-comment-p ()
  "Returns t if the previous line ends with a comment."
  (condition-case nil
      (save-excursion
	(previous-line)
	(pilf-line-ends-with-comment-p))
    (beginning-of-buffer nil)))


(defun pilf-previous-line-blank-p ()
  "Returns t if the previous line exists and contains only white space."
  (condition-case nil
      (save-excursion
	(previous-line)
	(end-of-line)
	(looking-back "^[ \t]*"))
    (beginning-of-buffer nil)))


(defun pilf-previous-line-ends-with-semicolon-p ()
  "Returns true if the previous line ends with a semicolon."
  (condition-case nil
      (save-excursion
	(previous-line)
	(end-of-line)
	(looking-back ";[ \t]*"))
    (beginning-of-buffer nil)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;
;;;;;                                        Buffer-altering utility functions
;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun pilf-insert-line ()
  "Move point to the indented position of a newly inserted line."
  (let* ((in-comment (pilf-in-comment))
	 (at-start-of-comment (and in-comment (= (point) (cdr in-comment)))))
    ;;FIXME: This behaves oddly when point is in the "/*" or "//" token
    (cond ((and in-comment (not at-start-of-comment))
	   (pilf-comment-insert-line))
	  (t
	   (delete-horizontal-space)
	   (insert "\n")
	   (c-indent-line)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;
;;;;;                                        Comment query functions (do not alter buffer)
;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pilf-beginning-of-comment ()
  "Moves point backward to the slash that begins the current comment.

When called from inside a comment, point is moved to the slash that starts the C or C++ style comment and the function returns
the symbol c for C-style comments and c++ for c++ style comments. When called from outside a comment, point is unmoved
and the function returns nil."
  (save-match-data
    (let* ((comment-type (c-in-literal))
	   (retval comment-type))
      (cond ((eq comment-type 'c++)
	     (while (eq comment-type 'c++)
	       (re-search-backward "/" nil t)
	       (skip-chars-backward "/")
	       (setq comment-type (c-in-literal))))
	    ((eq comment-type 'c) (when (and (looking-back "/") (looking-at "\\*")) (forward-char))
	     (while (eq comment-type 'c)
	       (re-search-backward "/\\*" nil t)
	       (setq comment-type (c-in-literal))))
	    ((and (null comment-type) (looking-at "//"))
	     (setq retval 'c++))
	    ((and (null comment-type) (looking-at "/\\*"))
	     (setq retval 'c)))
      retval)))

(defun pilf-end-of-comment ()
  "Moves point to the end of the current comment (if any).

For C++ comments, moves point to the end of the current line; for C comments moves point after the '*/'."
  (let ((comment-type (pilf-beginning-of-comment)))
    (cond ((eq comment-type 'c)
	   (re-search-forward "\\*/" nil 'eof))
	  ((eq comment-type 'c++)
	   (end-of-line)))))
	  
(defun pilf-in-comment ()
  "Returns information about the current comment (if any).

If point is inside a comment (as defined by c-in-literal) then return a cons cell whose car is either the symbol c for a C
comment or c++ for a C++ comment and whose cdr is the buffer position where the comment starts. If point is not in a comment
then return nil.  A comment starts when point is at the beginning of the comment start token."
  (save-excursion
    (let ((comment-type (pilf-beginning-of-comment)))
      (and comment-type (cons comment-type (point))))))

(defun pilf-in-doxygen-comment ()
  "Like pilf-in-comment, but return non-nill only for doxygen comments."
  (save-excursion
    (let ((comment-type (pilf-beginning-of-comment)))
      (cond ((and (eq comment-type 'c) (looking-at "/\\*\\*[ \t\n\r]"))
	     (cons comment-type (point)))
	    ((and (eq comment-type 'c) (looking-at "/\\*!"))
	     (cons comment-type (point)))
	    ((and (eq comment-type 'c++) (looking-at "//!"))
	     (cons comment-type (point)))))))

(defun pilf-comment-text-hanging-p ()
  "Returns t if the comment text hangs on the same line as the comment opening token."
  (save-excursion
    (let ((in-comment (pilf-beginning-of-comment)))
      (cond (in-comment
	     (looking-at "/[*/].*?[[:alnum:]]"))))))

(defun pilf-comment-hanging-p ()
  "Returns t if the line contains other stuff to the left of the comment."
  (save-excursion
    (let ((in-comment (pilf-beginning-of-comment)))
      (cond (in-comment
	     (not (looking-back "^[ \t]*")))))))

(defun pilf-comment-forward-over-doxygen ()
  "If point is at the beginning of a C or C++ comment, then move over the comment start token and doxygen stuff."
  (cond ((or (looking-at "/\\*[*!]<$")
	     (looking-at "//[/!]<$")
	     (looking-at "/\\*[*!]<[ \t]*[\\@[:alnum:]\n\r]")
	     (looking-at "//[/!]<[ \t]*[\\@[:alnum:]\n\r]"))
	 (forward-char 4))

	((or (looking-at "/\\*[*!]$")
	     (looking-at "/\\*[*!][ \t]*[\\@[:alnum:]\n\r]")
	     (looking-at "//[/!]$")
	     (looking-at "//[/!][ \t]*[\\@[:alnum:]\n\r]"))
	 (forward-char 3))

	((looking-at "/[*/]")
	 (forward-char 2))))

(defun pilf-comment-open-decoration ()
  "Returns a string representing the comment opening decoration.

Comment opening decoration will be used when closing the comment.  It's only meaningful for C comments since C++ comments
aren't explicitly closed (so C++ comment decoration is always the empty string). Comment decoration is defined as any
non-alpha-numeric characters that follow the '/*' and are on the same line, but never includes '*/' if the comment happens
to be closed on the same line where it is opened."
  (save-excursion
    (save-match-data
      (let* ((end-of-comment (save-excursion (pilf-end-of-comment) (- (point) 2)))
	     (comment-type (pilf-beginning-of-comment))
	     (decoration))
	(cond ((eq comment-type 'c++)
	       (setq decoration ""))

	      ((eq comment-type 'c)
	       (pilf-comment-forward-over-doxygen)
	       (re-search-forward "\\=[^\\@[:alnum:]\n\r]*" end-of-comment t)
	       (setq decoration (match-string 0))))

	decoration))))

(defun pilf-comment-empty-p ()
  "Determines if a comment contains any text."
  (save-excursion
    (save-match-data
      (let ((comment-type (pilf-beginning-of-comment))
	    (end-of-comment (save-excursion (pilf-end-of-comment) (point))))
	(and comment-type
	     (not (re-search-forward "[[:alnum:]]" end-of-comment t))
	     t)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;
;;;;;                                        Comment editing functions (that change the buffer)
;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pilf-comment-maybe-hoist ()
  "Maybe attach comment to end of previous line.

If we are sitting after '//' or '/*' that opens a comment and the previous line is non-blank and not ending with a comment
and the hoist-trailing-comment property returns true then move the comment to the end of the previous line. Returns t if
the comment was moved."
  (let* ((in-comment (pilf-in-comment))	                                  ;are we in a comment right now?
	 (comment-hangs (and in-comment (pilf-comment-hanging-p)))        ;does the current comment hang on previous line?
	 (start-of-comment (cdr in-comment))                              ;where does this comment start?
	 (at-start-of-comment (and in-comment				  ;are we at the start of a whole-line comment?
				   (eq (+ start-of-comment 2) (point))
				   (looking-back "^[ \t]*//\\|/\\*")))
	 (prev-blank (condition-case nil                                  ;is the previous line blank (and existing)
			 (save-excursion
			   (previous-line)
			   (beginning-of-line)
			   (looking-at "[ \t]*$"))
		       (beginning-of-buffer nil)))
	 (prev-comment (pilf-previous-line-ends-with-comment-p)))         ;does the previous line end with a comment?

    (if (and at-start-of-comment
	     (not comment-hangs)
	     (not (pilf-previous-line-blank-p))
	     (not (pilf-previous-line-ends-with-comment-p))
	     (or (pilf-get-config 'hoist-trailing-comment) (pilf-previous-line-ends-with-semicolon-p)))
	(condition-case nil
	    (progn
	      (previous-line)
	      (end-of-line)
	      (kill-line 1)
	      (delete-horizontal-space)
	      (forward-char 2)		;over "//" or "/*"
	      t)
	  (beginning-of-buffer nil))
      nil)))

(defun pilf-comment-indent-to (column)
  "Move the comment to the target column.

Point should be immediately after the '//' or '/*'. If column is not a number then nothing happens."
  (let* ((in-comment (pilf-in-comment))                              	;are we in a comment right now?
	 (start-of-comment (cdr in-comment))				;where does this comment start?
	 (at-start-of-comment (and in-comment				;are we at the start of the comment
				   (eq (+ start-of-comment 2) (point)))))
    (when (and at-start-of-comment (numberp column))
      (backward-char 2)
      (indent-to column)
      (forward-char 2))))

(defun pilf-comment-delete-decoration-backward (&optional char-class)
  "Deletes backward from point over comment noise.

Noise is defined as horizontal and vertial white space and decorative characters. The deletion stops before we hit the comment
opening token.  CHAR-CLASS should be a regular expression that will be repeatedly matched and deleted. The default CHAR-CLASS
matches hyphens, equal signs, asterisks, and horizontal and vertical white space."
  (if (null char-class) (setq char-class "[-=\\* \t\n]"))
  (save-match-data
    (let ((in-comment (pilf-in-comment)))
      (if (eq (car in-comment) 'c)
	  (while (looking-back char-class (+ 2 (cdr in-comment)) t)
	    (delete-char -1))))))


(defun pilf-comment-insert-line ()
  "Insert a linefeed in a comment, indenting to the next line."
  (let ((in-comment (pilf-in-comment)))
    (cond ((not (eq (car in-comment) 'c))
	   (delete-horizontal-space)
	   (insert "\n")
	   (c-indent-line))

	  (t
	   (let* ((comment-start-column (save-excursion (goto-char (cdr in-comment)) (current-column)))
		  (orig-point (point))
		  ;;character class for stuff that should be considered comment text (backslash and @ are for doxygen)
		  (significant-text      "[[:alnum:]\\@]")
		  (non-significant-text "[^[:alnum:]\\@]")
		  ;; t if point is on the first line of the comment
		  (first-line (save-excursion
				(goto-char (cdr in-comment))
				(not (re-search-forward "\n" orig-point t))))
		  ;;position of first non-space character right of comment start column and left of (point), or nil if none
		  (non-space-position (save-excursion
				     (beginning-of-line)
				     (while (and (< (current-column) comment-start-column) (not (looking-at "\n\r")))
				       (forward-char))
				     (and (re-search-forward "[^[:space:]]" orig-point t)
					  (- (point) 1))))
		  ;;column for non-space-position or nil
		  (non-space-column (if non-space-position
					(save-excursion
					  (goto-char non-space-position)
					  (current-column))))
		  ;;decoration between non-space-start and (point)
		  (decoration (if non-space-position
				  (save-excursion
				    (goto-char non-space-position)
				    (and (re-search-forward (concat "\\=" non-significant-text "*") orig-point t)
					 (setq s (match-string 0))))))
		  ;;column of first alpha-numeric or nil
		  (text-start-column (save-excursion
				       (beginning-of-line)
				       (goto-char (max (point) (cdr in-comment)))
				       (and (re-search-forward significant-text orig-point t) (- (current-column) 1)))))

	     ;; If the decoration includes doxygen stuff then replace it with something else
	     (cond ((or (not first-line) (not decoration)))
		   ((string-match "^/\\*[*!][ \t]*$" decoration)
		    (aset decoration 2 ?\s))
		   ((string-match "^/\\*[*!]<[ \t]*$" decoration)
		    (aset decoration 2 ?\s)
		    (aset decoration 3 ?\s)))

	     ;; Make sure decoration doesn't accidentally insert another "/*" token
	     (when (and (>= (length decoration) 2) (eq (aref decoration 0) ?/) (eq (aref decoration 1) ?*))
	       (aset decoration 0 ?\s))

	     ;; Advance to beginning of next line
	     (delete-horizontal-space)
	     (insert "\n")
	     (cond
	      ;; New line tries to replicate the decoration of the previous line.
	      ((and non-space-column decoration (or (not first-line) text-start-column))
	       (indent-to non-space-column)
	       (insert decoration)
	       (when text-start-column (indent-to text-start-column))
	       (when (not (looking-back "[ \t]")) (insert " ")))
	      ;; New line doesn't replicate decoration, just indents to previous text (if any)
	      (t
	       (indent-to comment-start-column)
	       (insert " * ")
	       (when text-start-column (indent-to text-start-column)))))))))


(defun pilf-comment-close ()
  "Close a C comment.

Inserts '*/' at the cursor, adjusting white space. Does nothing when not in a C comment."
  (let ((in-comment (pilf-in-comment)))
    (when (eq (car in-comment) 'c)
      (insert "*/")
      (backward-char 2)
      (let* ((decoration (pilf-comment-open-decoration))
	     (orig-point (point))
	     (comment-start-column (save-excursion (goto-char (cdr in-comment)) (current-column)))
	     (one-line (save-excursion
			 (goto-char (cdr in-comment))
			 (not (re-search-forward "[\n\r]" orig-point t))))
	     (empty (pilf-comment-empty-p))
	     (text-hangs (pilf-comment-text-hanging-p))
	     (trim-last-star))
	(cond
	 ;; One-line comment with only decoration: just add "*/" without any adjustments
	 ((and one-line empty))
	 
	 ;; Multi-line comment that's empty: 
	 (empty
	  (pilf-delete-backward-to-column comment-start-column t)
	  (insert " *")
	  (insert (pilf-reflect-string decoration))
	  (setq trim-last-star t))

	 ;; One-line text with no spaces or decorations: remove white space from each end, like "/*void*/"
	 ((and one-line (looking-back "/\\*[ \t]*[[:alnum:]][^ \t\n\r]*[ \t]*" (cdr in-comment)))
	  (save-excursion (goto-char (cdr in-comment)) (forward-char 2) (delete-horizontal-space))
	  (delete-horizontal-space))

	 ;; One-line with text: use reflected decoration, like "/*--[-- hello --]--*/
	 ((and one-line)
	  (pilf-comment-delete-decoration-backward)
	  (insert (pilf-reflect-string decoration)))

	 ;; Multiline, first line is hanging: just add "*/" (separated by one space).
	 (text-hangs
	  (pilf-comment-delete-decoration-backward)
	  (insert " "))

	 ;; Multiline, first line doesn't hang: end comment on next line with decoration
	 (t
	  (pilf-comment-delete-decoration-backward)
	  (insert "\n")
	  (indent-to comment-start-column)
	  (insert " *")
	  (insert decoration)
	  (setq trim-last-star t)))

	;; Skip back over the closing token again
	(re-search-forward "\\*/" nil t)

	;; Replace "**/" with "*/", but only if the first star is not part of the opening "/*" token.
	(when (and trim-last-star (looking-back "\\*\\*/") (> (point) (+ (cdr in-comment) 3)))
	  (replace-match "*/" t t))))))
	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;
;;;;;                                        Point-local adjustments
;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pilf-register-fixup (fixup &rest keys)
  "Appends FIXUP to the list of fixups that need to be called for each of the KEYS."
  (mapcar (lambda (key)
	    (let* ((fixups (cdr (assoc key pilf-fixups-alist)))
		   (newfixups (append fixups (list fixup))))
	      (setq pilf-fixups-alist
		    (cons (cons key newfixups) (assq-delete-all key pilf-fixups-alist)))))
	  keys))

(defun pilf-run-fixups-for-key (key)
  "Calls all fixups registered for the specified key."
  (pilf-run-fixups (cdr (assoc key pilf-fixups-alist))))

(defun pilf-run-fixups (fixups)
  "Calls each of the specified fixups."
  (mapc (lambda (fixup)
	  (message "running fixup: %s" fixup)
	  (funcall fixup))
	fixups))

(pilf-register-fixup 'pilf-fixup-c++-comments ?/ ?* ?< ?! ?- ?= ?> ?<)
(defun pilf-fixup-c++-comments ()
  "Various fixups for C++ comments."
  (let ((in-comment (pilf-in-comment))
	(decoration-char-class "[-~!@#$%^&*_+=|\\;:,.'\"{}()<>]"))
    (cond
     ((not (eq (car in-comment) 'c++)) nil)

     ;; When we start a C++ comment, optionally hoist it to the end of the previous line (as a trailing comment) and/or indent
     ;; it to the comment column.  Insert a space after the '//' token.
     ((and (looking-back "//")
	   (eq (+ (cdr in-comment) 2) (point)))
      (pilf-comment-maybe-hoist)
      (when (pilf-in-trailing-comment-p)
	(pilf-comment-indent-to (pilf-get-config 'trailing-comment-column)))
      (insert " "))

     ;; If we started a C++ comment with "// /" or "// !" (space probably inserted above) then swap the last to characters
     ((and (looking-back "// \\([!/]\\)")
	   (eq (+ (cdr in-comment) 4) (point)))
      (replace-match (concat "//" (match-string 1) " ") t t))

     ;; If we started a C++ comment with "/// /" then fill the whole line with slashes and go to the next line, but only
     ;; if there's nothing else on this line.
     ((and (looking-at "[ \t]*$")
	   (looking-back "/// /")
	   (eq (+ (cdr in-comment) 5) (point)))
      (replace-match "////" t t)
      (let* ((max-width (or (pilf-get-config 'maximum-line-width) (- (frame-width) 5)))
	     (nchars (- max-width (current-column))))
	(when (> nchars 0)
	  (insert (make-string nchars ?/))
	  (delete-horizontal-space)
	  (insert "\n")
	  (c-indent-line))))

     ;; If the "<" is the first character of a C++ comment with three slashes then treat it as a doxygen comment.
     ((and (looking-back "/// <")
	   (eq (+ (cdr in-comment) 5) (point)))
      (replace-match "///< " t t))

     ;; Remove space before some decoration characters. These don't all have to appear in the pilf-register-fixup.
     ((and (looking-back (concat "\\(//" decoration-char-class "*\\) \\(" decoration-char-class "\\)"))
	   (= (+ (cdr in-comment) (length (match-string 0))) (point)))
      (replace-match (concat (match-string 1) (match-string 2) " "))))))


(pilf-register-fixup 'pilf-fixup-c-comments ?/ ?* ?< ?! ?- ?= ?> ?< ?{ ?} )
(defun pilf-fixup-c-comments ()
  "Various fixups for C comments."
  (let ((in-comment (pilf-in-comment))
	(in-doxygen (pilf-in-doxygen-comment))
	(decoration-char-class "[-~!@#$%^&*_+=|\\;:,.'\"{}()<>]"))
    (cond
     ;; If we just ended a C-style comment then advance to the next line. However, if the comment is a single word, like
     ;; "/*void*/" or "/*override*/" then nestle it up to the rest of the line.
     ((and (not in-comment)
	   (save-excursion
	     (re-search-backward "\\*/[ \t]*\\=" nil t)
	     (eq (car (pilf-in-comment)) 'c)))
      (looking-back "\\*/[ \t]*")
      (replace-match "" t t)
      (pilf-comment-close)
      (cond ((or (not (pilf-get-config 'terminate-c-comment))
		 (looking-back "\\([^[:space:]]\\)[ \t]*\\(/\\*[^[:space:]]+\\*/\\)"
			       (save-excursion (beginning-of-line) (point))))
	     (replace-match (concat (match-string 1)
				    (if (string-match-p "[;)}[:alnum:]]" (match-string 1)) " " "")
				    (match-string 2))))
	    ((looking-back "/")
	     (pilf-insert-line)))
      (c-indent-line))

     ;; Not in comment
     ((not (eq (car in-comment) 'c)) nil)

     ;; Are we trying to close a comment but there's white space in between?
     ((and (looking-back "\\*[ \t]+/")
	   (< (+ (cdr in-comment) 2 (length (match-string 0))) (point)))
      (replace-match "" t t)
      (pilf-comment-close)
      (when (and (pilf-get-config 'terminate-c-comment) (looking-back "/"))
	(pilf-insert-line))
      (c-indent-line))

     ;; If we just started a "/*" comment then change it to "/* ". Also, if we're at the end of a line and there's something
     ;; to the left of the comment, optionally indent the comment to the trailing-comment-column.
     ((and (looking-back "/\\*")
	   (eq (+ (cdr in-comment) 2) (point)))
      (pilf-comment-maybe-hoist)
      (when (pilf-in-trailing-comment-p)
	(pilf-comment-indent-to (pilf-get-config 'trailing-comment-column)))
      (insert " "))

     ;; Change beginning of C comment "/* *" to "/** " and change "/* !" to "/*! " doxygen comment
     ((and (looking-back "/\\* \\([*!]\\)")
	   (eq (+ (cdr in-comment) 4) (point)))
      (replace-match (concat "/*" (match-string 1) " ") t t))

     ;; Change beginning of C comment "/** *" by filling the whole line with stars
     ((and (looking-at "[ \t]*$")
	   (looking-back "/\\*\\* \\*")
	   (eq (+ (cdr in-comment) 5) (point)))
      (replace-match "/***" t t)
      (let* ((max-width (or (pilf-get-config 'maximum-line-width) (- (frame-width) 5)))
	     (nchars (- max-width (current-column))))
	(when (> nchars 0)
	  (insert (make-string nchars ?*))
	  (pilf-insert-line))))

     ;; Look out for doxygen comments like "/***<"
     ((and (looking-back "/\\*\\* <")
	   (eq (+ (cdr in-comment) 5) (point)))
      (replace-match "/**< " t t))

     ;; If we just typed "@{" in a doxygen comment, then close the comment, add a closing "@}" comment, and position
     ;; point on a blank, indented line between them.
     ((and (eq (car in-doxygen) 'c) (looking-back "^[ \t*]*@{"))
      (insert " */")
      (pilf-insert-line)
      (pilf-insert-line)
      (insert "/** @} */")
      (previous-line)
      (delete-horizontal-space)
      (c-indent-line))

     ;; Remove space before some decoration characters. These don't all have to appear in the pilf-register-fixup.
     ((and (looking-back (concat "\\(/\\*" decoration-char-class "*\\) \\(" decoration-char-class "\\)"))
	   (= (+ (cdr in-comment) (length (match-string 0))) (point)))
      (replace-match (concat (match-string 1) (match-string 2) " "))))))


(pilf-register-fixup 'pilf-fixup-ltbrace ?{)
(defun pilf-fixup-ltbrace ()
  "Various fixups for left curly braces."
  (let* ((language-construct (pilf-after-opening-brace))
	 (white-space (and language-construct (pilf-get-config-nonlist 'hanging-brace-pre-space language-construct nil))))

    ;; cc-mode doesn't hoist the curly brace to the previous line when it's on its own line already, and a case statement
    ;; will probably already have moved us to the next line (because of the ':') by time the '{' is entered. Therefore, if
    ;; the c-hanging-braces-alist contains a statement-case-open property whose value doesn't include 'before', then move it
    ;; to the prvious line.
    (when (and
	   (eq language-construct 'case)
	   (looking-back ":[ \t]*[\n\r]+[ \t]*{\\([ \t\n\r]*\\)"))
      (replace-match (concat ": {" (match-string 1)) t t))

    ;; Insert the appropriate amount of white space left of the curly brace
    (when (and (stringp white-space)
	       (not (looking-back "^[ \t]*{[ \t\n\r]*"))
	       (looking-back "[ \t]*{\\([ \t\n\r]*\\)" nil t))
      (replace-match (concat white-space "{" (match-string 1))))))


(pilf-register-fixup 'pilf-fixup-rtbrace ?})
(defun pilf-fixup-rtbrace ()
  "Various fixups for right curly braces."

  ;; If the opening brace is on the previous line and is followed by something that isn't a comment, then make the
  ;; closing brace hang regardless of the brace hanging setting.  Note that cc-mode might have already moved point
  ;; to the line after the closing brace.  This is intended to handle situations like the following:
  ;;    void getMember() const { return member_; }
  (let* ((end (point))
	 (begin (save-excursion (c-backward-sexp) (point)))
	 (text-follows (save-excursion (goto-char begin) (looking-at "{[ \t]*[^ \t\n\r]")))
	 (comment-follows (save-excursion (goto-char begin) (looking-at "{[ \t]*/[*/]")))
	 (white-space (save-excursion (goto-char begin) (looking-at "{\\([ \t]*\\)") (match-string 1)))
	 (nlines (count-lines begin end))
	 (in-comment (pilf-in-comment)))
    ;(message "begin=%s end=%s text-follows=%s comment-follows=%s white-space=\"%s\" nlines=%s in-comment=%s"
    ;         begin end text-follows comment-follows white-space nlines in-comment)
    (when (and (not in-comment) text-follows (not comment-follows)
	       (or (and (= 2 nlines) (looking-back "}"))
		   (and (= 3 nlines) (looking-back "}\r?\n[ \t]*"))))
      (looking-back "[ \t\n\r]*\\(}[ \t\n\r]*\\)" begin t)
      (replace-match (concat white-space (match-string 1)))))

  ;; Annotate a closing brace with a comment, but only if cc-mode has moved us to the next line.
  (let* ((language-construct (pilf-after-closing-brace))
	 (annotation (pilf-get-config-nonlist 'closing-brace-annotation language-construct "")))
    (when (and (stringp annotation) (not (string= annotation "")) (looking-back "}[ \t]*\\([\n\r]+[ \t]*\\)"))
      (replace-match (concat "} // " annotation (match-string 1)) t t))))


(pilf-register-fixup 'pilf-fixup-ltparen ?\()
(defun pilf-fixup-ltparen ()
  "Various fixups for left parentheses."
  (let* ((keywords-before-paren '("and" "bitand" "bitor" "catch" "compl" "delete" "for" "foreach" "if" "new"
				  "not" "not_eq" "or" "return" "sizeof" "switch" "throw" "typeid" "while" "xor"
				  "BOOST_FOREACH")))
    (cond
     ;; Do not adjust white space in string literals or comments
     ((c-in-literal) nil)

     ;; Do not adjust white space in a #define directive after the symbol being defined. This is for
     ;;    #define FOO(X, Y) ((X)+(Y))           versus
     ;;    #define FOO (X+Y)
     ;; when point is after the first paren in either line.
     ((looking-back "^[ \t]*#[ \t]*define[ \t]+\\w+[ \t]*(") nil)

     ;; Insert white space before and/or after a parenthesis that follows a keyword.  We can't use "\b" as a word separator
     ;; because, for example, "\\bor" will match "get_value_or".   So we do it the hard way but make it a little easier by
     ;; not trying to match at the beginning of a buffer or narrowed region.
     ((looking-back (concat "\\([^_a-zA-Z0-9]\\)\\(" (pilf-join-strings "\\|" keywords-before-paren) "\\)[ \t]*("))
      (let* ((language-construct (intern (match-string 2)))
	     (pre-white-space (pilf-get-config-nonlist 'keyword-paren-pre-space language-construct nil))
	     (post-white-space (pilf-get-config-nonlist 'keyword-paren-post-space language-construct nil)))
	(when (looking-back "[ \t]*(" nil t)
	  (when (stringp pre-white-space)
	    (replace-match (concat pre-white-space "(") t t))
	  (when (stringp post-white-space)
	    (looking-at "[ \t]*")
	    (replace-match post-white-space t t)))))

     ;; Insert white space before and/or after a function paren
     ((looking-back "\\(\\sw+\\)[ \t]*(" nil t)
      (let* ((pre-white-space (pilf-get-config 'function-paren-pre-space (match-string 1)))
	     (post-white-space (pilf-get-config 'function-paren-post-space (match-string 1))))
	(when (stringp pre-white-space)
	  (replace-match (concat (match-string 1) pre-white-space "(") t t))
	(when (stringp post-white-space)
	  (looking-at "[ \t]*")
	  (replace-match post-white-space t t))))

     ;; Consecutive parentheses should not have intervening white space
     ((looking-back "([ \t]+(")
      (replace-match "((" t t)))))


(pilf-register-fixup 'pilf-fixup-rtparen ?\))
(defun pilf-fixup-rtparen ()
  "Various fixups for right parentheses."
  (cond
   ;; Consecutive parentheses should not have intervening white space
   ((and (looking-back ")[ \t]+)") (pilf-nonliteral-p))
    (replace-match "))" t t))))


(pilf-register-fixup 'pilf-fixup-comma ?,)
(defun pilf-fixup-comma ()
  "Various fixups for commas."
  (cond
   ((and (looking-back ",[ \t]*") (pilf-nonliteral-p))
    (let ((white-space (pilf-get-config 'comma-post-space)))
      (when (stringp white-space)
	(replace-match (concat "," white-space) t t))))))


(pilf-register-fixup 'pilf-fixup-semicolon ?\;)
(defun pilf-fixup-semicolon ()
  "Various fixups for semicolons."
  (cond
   ((c-in-literal) nil)

   ;; If cc-mode has left us on the same line as the semicolon, then its probably because the line is not just a statement
   ;; (e.g., in a "for" statement)
   ((looking-back "\\([ \t]*\\);\\([ \t]*\\)" nil t)
    (let* ((pre-white-space (pilf-get-config 'semicolon-pre-space)) 
	   (post-white-space (pilf-get-config 'semicolon-post-space))
	   (replacement (concat (or pre-white-space (match-string 1)) ";" (or post-white-space (match-string 2)))))
      (replace-match replacement t t)))

   ;; If cc-mode has put us on the next line then only add the semicolon-pre-space
   ((looking-back "\\([ \t]*\\);[ \t]*\\([\n\r][ \t]*\\)" nil t)
    (let* ((pre-white-space (pilf-get-config 'semicolon-pre-space))
	   (replacement (concat (or pre-white-space (match-string 1)) ";" (match-string 2))))
      (replace-match replacement t t)))))


(pilf-register-fixup 'pilf-fixup-tilde ?~)
(defun pilf-fixup-tilde ()	 
  (let ((in-comment (pilf-in-comment)))
    (cond
     ;; Replace "~~~" in a comment with the author citation
     ((and in-comment
	   (looking-back "~~~")
	   (not (looking-back "~~~~")))
      (replace-match (pilf-cite-author) t t))

     ;; Replace "#~~~" at the beginning of a line with "#if 1 /*DEBUGGING [citation]*/ and advance to the next line
     ((and (looking-at "[ \t]*$") (looking-back "^#~~~"))
      (replace-match (concat "#if 1 /*DEBUGGING " (pilf-cite-author) "*/") t t)
      (pilf-insert-line)
      (pilf-insert-line)
      (delete-horizontal-space)
      (insert "#endif")
      (previous-line)
      (c-indent-line)))))

(pilf-register-fixup 'pilf-fixup-comment-abbrevs '?e ?E)
(defun pilf-fixup-comment-abbrevs ()
  "Fixup certain things that might be typed in comments."
  (cond
   ((not (pilf-in-comment)))
   ((looking-back "\\b\\(fixme\\|todo\\)") 
    (replace-match (concat (upcase (match-string 0)) (pilf-cite-author)) t t))))


(pilf-register-fixup 'pilf-fixup-cpp-directives ?d ?e ?f ?i ?n ?\" ?< ?> ?0)
(defun pilf-fixup-cpp-directives ()
  "Fixup CPP directives."
  (cond
   ((c-in-literal))

   ;; Add space after directives that have arguments
   ((looking-back "^[ \t]*#[ \t]*\\(if\\|ifn?def\\|include\\|define\\|undef\\)")
    (insert " "))

   ;; Start a new line after directives that don't have arguments
   ((looking-back "^[ \t]*#[ \t]*\\(else\\|endif\\)")
    (when (pilf-get-config 'terminate-cpp-directive) (pilf-insert-line)))

   ;; Remove space from "#if d" or "#if n" since we're probably typing "#ifdef" or "#ifndef"
   ((looking-back "^\\([ \t]*#[ \t]*if\\) \\([dn]\\)")
    (replace-match (concat (match-string 1) (match-string 2)) t t))

   ;; Re-insert the space we removed from "#if d" if it becomes "#ifdefi" (as in "#if defined")
   ((looking-back "^\\([ \t]*#[ \t]*if\\)defi")
    (replace-match (concat (match-string 1) " defi")))

   ;; Insert a single space before the quote or '<' for an #include directive
   ((looking-back "^\\([ \t]*#[ \t]*include\\)[ \t]*\\([<\"]\\)")
    (replace-match (concat (match-string 1) " " (match-string 2)) t t))

   ;; Start a new line after the closing quote or '>' for an include statement
   ((or (looking-back "^[ \t]*#[ \t]*include[ \t]*\"[^\"\n]+\"")
	(looking-back "^[ \t]*#[ \t]*include[ \t]*<[^\"\n]+>"))
    (when (pilf-get-config 'terminate-cpp-directive) (pilf-insert-line)))

   ;; Using "#if 0" to comment out code is a bit annoying, so help the user to delete it later by citing the author.
   ((and (looking-back "^[ \t]*#[ \t]*if[ \t]+0")
	 (not (looking-at "[ \t]*/[*/]")))
    (insert (concat " // " (pilf-cite-author)))
    (when (pilf-get-config 'terminate-cpp-directive) (pilf-insert-line)))))

(pilf-register-fixup 'pilf-fixup-extra-space '?\ )
(defun pilf-fixup-extra-space ()
  "Remove double spaces."
  (cond
   ((c-in-literal) nil)
   ((looking-back "\\([^ ] \\) ") (replace-match (match-string 1) t t))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;
;;;;;                                        Miscellaneous
;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pilf-cite-author ()
  "Returns an author citation.

The citation consists of the author name or nickname followed by a date, all enclosed in square brackets."
  (let* ((author-name (or (pilf-get-config 'author-name) ""))
	 (author-nonempty (not (string= author-name "")))
	 (time-stamp (format-time-string "%Y-%m-%d"))
	 (separator (if author-nonempty " " "")))
    (concat "[" author-name separator time-stamp "]")))


(defun pilf-reverse-string (s)
  "Reverse the characters of a string."
  (concat (reverse (append s nil))))


(defun pilf-reflect-string (s)
  "Makes a mirror image of a string, reversing the string and replacing perentheses, etc. with their counterparts."
  (let ((retval (pilf-reverse-string s))
	(char))
    (dotimes (i (length retval))
      (setq char (aref retval i))
      (cond ((eq char ?\() (aset retval i ?\)))
	    ((eq char ?\)) (aset retval i ?\())
	    ((eq char ?<) (aset retval i ?>))
	    ((eq char ?>) (aset retval i ?<))
	    ((eq char ?[) (aset retval i ?]))
	    ((eq char ?]) (aset retval i ?[))
	    ((eq char ?{) (aset retval i ?}))
	    ((eq char ?}) (aset retval i ?{))))
    retval))


(defun pilf-join-strings (separator strings)
  "Join STRINGS together, separating each with SEPARATOR."
  (cond
   ((null strings) "")
   ((= 1 (length strings)) (car strings))
   (t (concat (car strings) separator (pilf-join-strings separator (cdr strings))))))


(defun pilf-delete-backward-to-column (column &optional then-indent)
  "Delete characters backward from point until point is less than or equal to column.

If THEN-INDENT is true, call indent-to-column to make sure point is not left of the target COLUMN."
  (while (> (current-column) column)
    (delete-char -1))
  (when (and then-indent (< (current-column) column))
    (indent-to column)))

(defun pilf-normal-behavior ()
  "Does the normal thing that would happen without pilf-mode."
  (let* ((keys (this-command-keys))
	 (binding (let ((pilf-mode nil)) (key-binding keys t))))
    (when (and (symbolp binding) (commandp binding))
      (call-interactively binding))))

(defun pilf-electric-key (&optional arg)
  "Interactive command called in place of self-insert-command."
  (interactive "P")
  (pilf-normal-behavior)
  (pilf-run-fixups-for-key last-command-event))
    
(defun pilf-electric-return (&optional arg)
  "Inserts a return and does other magic stuff."
  (interactive "P")
  (if (null arg)
      (pilf-insert-line)
    (pilf-normal-behavior)))
