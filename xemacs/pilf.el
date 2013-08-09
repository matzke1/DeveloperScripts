;; pilf.el -- program intra-line formatting
;; Copyright (C) 2010 Robb Matzke.
;;
;; Pilf (a minor mode) works in conjunction with c-mode to automatically format C/C++ source code as it is typed.
;; While c-mode is primarily in charge of indentation of lines, pilf minor mode operates on a single line at a time to
;; adjust white space within the line.

(defconst pilf-author-name (user-full-name))

(defvar pilf-mode-map nil
  "Keymap used in pilf minor mode overrides the cc-mode key map.")
(if pilf-mode-map
    ()
  (setq pilf-mode-map (make-sparse-keymap "pilf-mode-map"))
  (define-key pilf-mode-map (kbd "SPC") 'pilf-electric-space)
  (define-key pilf-mode-map [return] 'pilf-electric-return)
  (define-key pilf-mode-map [?{] 'pilf-electric-ltcurly)
  (define-key pilf-mode-map [?}] 'pilf-electric-rtcurly)
  (define-key pilf-mode-map [?\(] 'pilf-electric-ltparen)
  (define-key pilf-mode-map [?\)] 'pilf-electric-rtparen)
  (define-key pilf-mode-map [?<] 'pilf-electric-ltangle)
  (define-key pilf-mode-map [?>] 'pilf-electric-rtangle)
  (define-key pilf-mode-map [?,] 'pilf-electric-comma)
  (define-key pilf-mode-map [?\;] 'pilf-electric-semi)
  (define-key pilf-mode-map [?/] 'pilf-electric-slash)
  (define-key pilf-mode-map [?\"] 'pilf-electric-dquote)
  (define-key pilf-mode-map [?*] 'pilf-electric-star)
  (define-key pilf-mode-map [?~] 'pilf-electric-tilde)
  )

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

  ;; Add the minor-mode key map if not done already.
  (or (assq 'pilf-mode minor-mode-map-alist)
      (setq minor-mode-map-alist
	    (cons (cons 'pilf-mode pilf-mode-map) minor-mode-map-alist))))

(defun pilf-cite-author ()
  "Returns an author citation.

The citation consists of the author name or nickname followed by a date, all enclosed in square brackets."
  (concat "[" pilf-author-name " " (format-time-string "%Y-%m-%d") "]"))

(defun pilf-beginning-of-comment ()
  "Moves point backward to the slash that begins the current comment.

When called from inside a comment, point is moved to the slash that
starts the C or C++ style comment and the function returns the symbol
c for C-style comments and c++ for c++ style comments. When called from
outside a comment, point is unmoved and the function returns nil. The
determination of whether this function was called from inside or
outside a comment is made by c-in-literal. Specifically, we are not
considered to be in a comment until point is after the \"/*\" or
\"//\", and the comment continues until we are after the \"*/\" or
line feed."
  (save-match-data
    (let ((was-in-comment (or (eq (c-in-literal) 'c) (eq (c-in-literal) 'c++))))
      (while (and (or (eq (c-in-literal) 'c) (eq (c-in-literal) 'c++))
		  (re-search-backward "//\\|/\\*" nil t)))
      (cond
       ((not was-in-comment) nil)
       ((looking-at "/\\*") 'c)
       ((looking-at "//")
	(while (re-search-backward "/\\=" nil t))
	'c++)))))

(defun pilf-in-comment ()
  "Returns information about the current comment.

If point is inside a comment (as defined by c-in-literal) then return
a cons cell whose car is either the symbol c for a C comment or c++ for
a C++ comment and whose cdr is the buffer position where the comment
starts. If point is not in a comment then return nil."
  (save-excursion
    (let ((comment-type (pilf-beginning-of-comment)))
      (and comment-type (cons comment-type (point))))))

(defun pilf-comment-open-decoration ()
  "Returns a string representing the comment decoration.

Comment decoration is defined as any non-alpha-numeric characters that
follow the \"/*\" and are on the same line, but not including the
\"*/\" if it's also on the same line.  The decoration includes
trailing white space.  Returns nil if point is not inside a C-like
comment.

Doxygen comments are special.  If the comment starts with \"/**\"
followed by horizontal or vertical white space then the decoration is
only the horizontal white space.  Similarly if the comment starts with
\"/**<\" followed by white space."
  (save-excursion
    (save-match-data
      (let ((in-comment (pilf-in-comment)))
	(goto-char (cdr in-comment))	;goto beginning of comment
	(cond

	 ;; This must be a C++ comment. We don't handle them here.
	 ((not (eq (car in-comment) 'c))
	  nil)

	 ;; C doxygen comment like "/**" followed by horizontal or vertical space.
	 ;; Return the horizontal space, if any.
	 ((looking-at "/\\*\\*[ \t\n]")
	  (re-search-forward "\\=/\\*\\*\\([ \t]*\\)") ; should never fail
	  (match-string 1))

	 ;; C doxygen comment like "/**<" followed by horizontal or vertical space.
	 ;; Return the horizontal space, if any.
	 ((looking-at "/\\*\\*<[ \t\n]")
	  (re-search-forward "\\=/\\*\\*<\\([ \t]*\\)") ; should never fail
	  (match-string 1))

	 ;; Default is to return non alpha-numeric stuff after the "/*" and on the same line.
	 (t
	  (re-search-forward "\\=/\\*\\([^_a-zA-Z0-9\n]*\\)" nil t)
	  (match-string 1)))))))

(defun pilf-comment-open-hangs ()
  "Returns t if the first line of comment text is on the same line as
the beginning of the comment.

Returns nil if there is no first line of text, if we're not in a
comment, or the first line of text is not on the same line as the
opening of the comment."
  (save-excursion
    (save-match-data
      (let ((in-comment (pilf-in-comment)))
	(and (eq (car in-comment) 'c)
	     (goto-char (cdr in-comment))
	     (re-search-forward "\\=/\\*[^\n]*[_a-zA-Z0-9]" nil t)
	     t)))))

(defun pilf-comment-emptyp ()
  "Determines if a comment contains anything useful.

Returns t if the current comment has no text before point. Returns nil
if point is not in a comment."
  (save-excursion
    (save-match-data
      (let ((in-comment (pilf-in-comment)))
	(and (eq (car in-comment) 'c)
	     (not (re-search-backward "[_a-zA-Z0-9]" (cdr in-comment) t)))))))

(defun pilf-comment-delete-some (&optional char-class)
  "Deletes backward from point over comment noise.

Noise is defined as horizontal and vertial white space and decorative
characters. The deletion stops before we hit the comment opening
token.  CHAR-CLASS should be a regular expression that will be
repeatedly matched and deleted (it should not contain the \\=
anchor). The default CHAR-CLASS matches hyphens, equal signs,
asterisks, and horizontal and vertical white space."
  (if (null char-class) (setq char-class "[-=\\* \t\n]"))
  (save-match-data
    (let ((in-comment (pilf-in-comment)))
      (if (eq (car in-comment) 'c)
	  (while (re-search-backward (concat char-class "\\=") (+ 2 (cdr in-comment)) t)
	    (delete-char 1))))))

(defun pilf-close-comment ()
  "Closes a C comment.

This should be called when point is inside a comment.  It will look at
how the comment was opened and then close the comment with appropriate
decoration and line feeds."
  (let* ((in-comment (pilf-in-comment))
	 (decoration (pilf-comment-open-decoration))                                ;entire decoration
	 (decor-lead (substring decoration 0 (string-match "[ \t]*$" decoration)))  ;decor w/o trailing space
	 (decor-trail (substring decoration (string-match "[ \t]*$" decoration)))   ;decor trailing space
	 (empty (pilf-comment-emptyp))
	 (hanging (pilf-comment-open-hangs)))
    (cond
     ;; If the comment is empty then just close it
     (empty
      (pilf-comment-delete-some "[ \t\n]")
      (insert "*/\n"))

     ;; If comment opening is hanging then hang the closing. If the comment text is a single lower-case
     ;; word then remove the white space around it and do not advance point to the next line.
     ((and hanging decoration)
      (pilf-comment-delete-some)
      (if (re-search-backward "/\\*[ \t]*\\([a-z]+\\)\\=" nil t)
	  (replace-match (concat "/*" (match-string 1) "*/"))
	(insert (concat decor-trail decor-lead "*/\n"))))

     ;; If comment opening is not hanging then don't hang the closing
     (decoration
      (pilf-comment-delete-some)
      (insert (concat "\n" decoration "*/"))
      (c-indent-line)
      (pilf-electric-return)))))

(defun pilf-normal-behavior (&optional key arg)
  "Does the normal thing that would happen without pilf-mode."

  (if (not key) (setq key last-command-event))
  (let ((binding (let ((pilf-mode nil))
		   (key-binding key t))))
    (if (and (symbolp binding)
	     (commandp binding))
	(call-interactively binding))))

(defun pilf-electric-ltcurly (&optional arg)
  "Inserts a left curly brace and does other magic stuff."
  (interactive "P")
  (pilf-normal-behavior [?{] arg)

  ;; Allow cc-mode to determine whether the brace should be hanging. If we then see that the brace is hanging, make sure
  ;; there's one space separating it from anything else on the line.  Watch out for left braces that are by themselves
  ;; on the line.
  (cond
   (arg nil)
   ((c-in-literal) nil)

   ((re-search-backward "\\([^ \t\n]\\)[ \t]*{\\([ \t\n]*\\)\\=" nil t)
    (replace-match (concat (match-string 1) " {" (match-string 2)) t t))))

(defun pilf-electric-rtcurly (&optional arg)
  "Inserts a right curly brace and does other magic stuff."
  (interactive "P")
  (pilf-normal-behavior [?}] arg)

  (cond
   (arg nil)

   ;; If this is the end of a "namespace" then append "// namespace" to the curly brace before advancing to the next line
   ((condition-case nil
	(save-excursion
	  (backward-sexp)
	  (re-search-backward "namespace\\s-+\\sw+\\s-*\\=" nil t))
      (error nil))
    (re-search-backward "}[ \t\n]*\\=" nil nil)
    (replace-match "} // namespace\n" t t)
    (c-indent-line))))

(defun pilf-electric-ltparen (&optional arg)
  "Inserts a left parenthesis and does other magic stuff."
  (interactive "P")
  (pilf-normal-behavior [?\(] arg)

  (cond
   ((or arg (c-in-literal)))
   ;; symbol followed by left paren should be separated by a space for keywords; no space otherwise
   ((re-search-backward
     (concat "\\([^a-zA-Z_0-9]\\)"		; at a word boundary
	     "\\([a-zA-Z_][a-zA-Z_0-9]*\\)"	        ; symbol
	     "[ \t]*"			        ; optional horizontal white space
	     "(\\=")				; point after lt paren
     nil t)
    (if (or (equal (match-string 2) "catch")
	    (equal (match-string 2) "for")
	    (equal (match-string 2) "foreach")
	    (equal (match-string 2) "if")
	    (equal (match-string 2) "return")
	    (equal (match-string 2) "switch")
	    (equal (match-string 2) "while"))
	(replace-match (concat (match-string 1) (match-string 2) " (") t t)
      (replace-match (concat (match-string 1) (match-string 2) "(") t t)))

   ;; adjacent left parens have no intervening white space
   ((re-search-backward "(\\([ \t\n]+\\)(\\=" nil t)
    (replace-match "((" t t))))

(defun pilf-electric-rtparen (&optional arg)
  "Inserts a right parenthesis and does other magic stuff."
  (interactive "P")
  (pilf-normal-behavior [?\)] arg)
  (cond
   ((or arg (c-in-literal)))
   ;; No space before a right paren -- they nestle up
   ((re-search-backward "\\([^ \t\n]\\)[ \t\n]*)\\=" nil t)
    (replace-match (concat (match-string 1) ")") t t))))

(defun pilf-electric-comma (&optional arg)
  "Inserts a comma and does other magic stuff."
  (interactive "P")
  (pilf-normal-behavior [?,] arg)
  (cond
   ((or arg (c-in-literal)))
   ((re-search-backward "\\([^ \t\n]\\)[ \t\n]*,[ \t\n]*\\=" nil t)
    (replace-match (concat (match-string 1) ", ") t t))))

(defun pilf-electric-semi (&optional arg)
  "Inserts a semicolon and does other magic stuff."
  (interactive "P")
  (pilf-normal-behavior [?\;] arg)
  (cond
   ((or arg (c-in-literal)))
   ((re-search-backward ";[ \t]*\\=" nil t)
    (replace-match "; " t t))))

(defun pilf-electric-ltangle (&optional arg)
  "Inserts a left angle bracket and does other magic stuff.

* When inserting an angle bracket in a #include statement, this
  function ensures that there is exactly one space before the angle
  bracket.

* When starting a doxygen comment (C or C++ style), pressing a left
  angle bracket after the start-of-comment will make sure that the
  angle bracket nestles up against the start-of-comment."
  (interactive "P") (pilf-normal-behavior [?<] arg) (let ((in-comment
  (pilf-in-comment)))
    (cond
     (arg nil)

     ;; Make sure there's one space in "#include <"
     ((and (not (c-in-literal))
	   (re-search-backward "^\\([ \t]*#[ \t]*include\\)[ \t]*<\\=" nil t))
      (replace-match (concat (match-string 1) " <") t t))

     ;; If we're starting a C++ doxygen comment, then change "/// <" to "///<"
     ((and (eq (car in-comment) 'c++)
	   (eq (cdr in-comment) (save-excursion (re-search-backward "/// <\\=" nil t))))
      (replace-match "///< " t t))

     ;; If we're starting a C doxygen comment, then change "/** <" to "/**< "
     ((and (eq (car in-comment) 'c)
	   (eq (cdr in-comment) (save-excursion (re-search-backward "/\\*\\* <\\=" nil t))))
      (replace-match "/**< " t t)))))

(defun pilf-electric-rtangle (&optional arg)
  "Inserts a right angle bracket and does other magic stuff."
  (interactive "P")
  (pilf-normal-behavior [?>] arg)
  (cond
   ((or arg (c-in-literal)))
   ((re-search-backward "^\\([ \t]*#[ \t]*include\\)[ \t]*\\(<[^\n]*>\\)\\=" nil t)
    (replace-match (concat (match-string 1) " " (match-string 2)) t t)
    (c-indent-line))))

(defun pilf-electric-slash (&optional arg)
  "Inserts a slash and does other magic stuff.

* Typing two slashes to start a C++ comment will also insert a space.

* Typing three slashes to start a C++ doxygen comment will also insert
  a space.

* Typing four slashes to start a C++ comment will fill the line to the
  right margin"
  (interactive "P")
  (pilf-normal-behavior [?/] arg)
  (let ((in-comment (pilf-in-comment)))
    (cond
     (arg nil)

     ;; If we just started a '//' comment then insert one space after the '//'
     ((and (eq (car in-comment) 'c++)
	   (eq (cdr in-comment) (save-excursion (re-search-backward "//\\=" nil t))))
      (replace-match "// " t t))

     ;; If we entered a third slash to get "// /" then swap the slash and space.
     ((and (eq (car in-comment) 'c++)
	   (eq (cdr in-comment) (save-excursion (re-search-backward "// /\\=" nil t))))
      (replace-match "/// " t t))

     ;; If we entered a fourth slash to get "/// /" then remove the space and fill the rest of the line with slashes.
     ((and (eq (car in-comment) 'c++)
	   (eq (cdr in-comment) (save-excursion (re-search-backward "/// /\\=" nil t))))
      (replace-match "////" t t)
      (let* ((right-margin 5)		; FIXME: right margin should be a configuration variable
	     (nchars (- (frame-width) (current-column) right-margin)))
	(if (> nchars 0)
	    (insert (make-string nchars ?/))))
      (pilf-electric-return))

     ;; If we just ended a C-style comment then insert and indent a new line.
     ((and (not in-comment)
	   (re-search-backward "\\*/[ \t\n]*\\=" nil t)
	   (eq (car (pilf-in-comment)) 'c))
      (replace-match "" t t)
      (pilf-close-comment)
      (c-indent-line))

     ;; If we are in a C-style comment and just typed "* /" (with any amount of white space) then remove the space and advance
     ;; to the next line.
     ((and (eq (car in-comment) 'c)
	   (re-search-backward "\\([^/]\\)\\*[ \t]+/\\=" nil t))
      (replace-match (match-string 1) t t)
      (pilf-close-comment)
      (c-indent-line)))))





(defun pilf-electric-star (&optional arg)
  "Inserts and asterisk and does other magic stuff."
  (interactive "P")
  (pilf-normal-behavior [?*] arg)
  (let ((in-comment (pilf-in-comment)))
    (cond
     (arg nil)

     ;; If we just started a '/*' comment then insert one space after the '/*'
     ((and (eq (car in-comment) 'c)
	   (eq (cdr in-comment) (save-excursion (re-search-backward "/\\*\\=" nil t))))
      (replace-match "/* " t t))

     ;; If we entered a second star to get "/* *" then swap the space and star in order to start a doxygen comment.
     ((and (eq (car in-comment) 'c)
	   (eq (cdr in-comment) (save-excursion (re-search-backward "/\\* \\*\\=" nil t))))
      (replace-match "/** " t t))

     ;; If we entered a third star to get "/** *" then remove the space and fill the rest of the line with stars.
     ((and (eq (car in-comment) 'c)
	   (eq (cdr in-comment) (save-excursion (re-search-backward "/\\*\\* \\*\\=" nil t))))
      (replace-match "/***" t t)
      (let* ((right-margin 5)		; FIXME: right margin should be a configuration variable
	     (nchars (- (frame-width) (current-column) right-margin)))
	(if (> nchars 0)
	    (insert (make-string nchars ?*))))
      (pilf-electric-return)))))

(defun pilf-electric-return (&optional arg)
  "Inserts a return and does other magic stuff."
  (interactive "P")
  (pilf-normal-behavior "\r" arg)

  ;; remove trailing white space from previous line
  (if (re-search-backward "\\([^ \t]\\)[ \t]*\\(\n[ \t]*\\)\\=" nil t)
      (replace-match (concat (match-string 1) (match-string 2)) t t))

  ;; if we're inside a comment then insert the comment prefix. We'll indent it in a sec.
  (if (eq (c-in-literal) 'c)
     (insert " * "))

  (c-indent-line))

(defun pilf-electric-dquote (&optional arg)
  "Inserts a double quote and does other magic stuff."
  (interactive "P")
  (pilf-normal-behavior [?\"] arg)
  (cond
   (arg nil)
   ((save-excursion (and (eq (c-in-literal) 'string)
			 (condition-case nil (progn (backward-char) t) (beginning-of-buffer nil))
			 (not (eq (c-in-literal) 'string))))
    ;; OPENING QUOTE CONDITIONS
    (cond
     ;; first quote in #include directive
     ((re-search-backward "^\\([ \t]*#[ \t]*include\\)[ \t]*\"\\=" nil t)
      (replace-match (concat (match-string 1) " \"") t t))))

   ((eq (c-in-literal) 'string)
    ;; INTERNAL QUOTE CONDITIONS
    (cond))

   (t
    ;; CLOSING QUOTE CONDITIONS
    (cond
     ;; closing quote in #include directive
     ((re-search-backward "^\\([ \t]*#[ \t]*include\\)[ \t]*\\(\"[^\n]*\"\\)\\=" nil t)
      (replace-match (concat (match-string 1) " " (match-string 2) "\n") t t)
      (c-indent-line))))))

(defun pilf-electric-space (&optional arg)
  "Inserts a space and does other magic stuff.

One of the important magic things this function does is make sure
there's only one space after commas and the start of comments.  This
is because a space is automatically inserted at those locations, and
if an author isn't used to that they will probably hit another space
without realizing what has happened. If you really want more than one
space, then allow pilf to insert the first space, then insert the
second space with a prefix argument (i.e., \C-u space), and then
insert as many additional spaces you want by just hitting the space
bar.  The \"Tab\" key also works to insert white space."
  (interactive "P")
  (pilf-normal-behavior " " arg)
  (let ((in-comment (pilf-in-comment)))
    (cond
     (arg nil)

     ;; Keep only one space after a comma
     ((and (not (c-in-literal))
	   (re-search-backward ",  \\=" nil t))
      (replace-match ", " t t))

     ;; Delete space after a left paren
     ((and (not (c-in-literal))
	   (re-search-backward "( \\=" nil t))
      (replace-match "(" t t))

     ;; When starting a C comment, keep only one space after the "/*", "/**", or "/**<".
     ((and (eq (car in-comment) 'c)
	   (eq (cdr in-comment) (save-excursion (re-search-backward "/\\*\\(\\|\\*\\|\\*<\\)  \\=" nil t))))
      (replace-match (concat "/*" (match-string 1) " ") t t))

     ;; When starting a C++ comment, keep only one space after the "//", "///", or "///<"
     ((and (eq (car in-comment) 'c++)
	   (eq (cdr in-comment) (save-excursion (re-search-backward "\\(//\\|///\\|///<\\)  \\=" nil t))))
      (replace-match (concat (match-string 1) " ") t t)))))
   
(defun pilf-electric-tilde (&optional arg)
  "Inserts author name and date.

Cites an author by inserting the author name and date in square brackets when three tilde's appear in a row in a comment."
  (interactive "P")
  (pilf-normal-behavior [?~] arg)
  (cond
   (arg nil)

   ;; If this is the third tilde in a row in a comment and there are not four tildes in a row, replace the three with an
   ;; author citation.
   ((and (pilf-in-comment)
	 (save-excursion (not (re-search-backward "~~~~\\=" nil t)))
	 (save-excursion (re-search-backward "~~~\\=" nil t)))
    (replace-match (pilf-cite-author) t t))

   ;; If this is the third tilde and the line contains "#~~~" then replace it with '#if 1 /*DEBUGGING [citation]*/ and
   ;; advance to the next line.
   ((save-excursion (re-search-backward "^#~~~\\=" nil t))
    (replace-match (concat "#if 1 /*DEBUGGING " (pilf-cite-author) "*/\n") t t)
    (save-excursion (insert "\n#endif"))
    (c-indent-line))))

