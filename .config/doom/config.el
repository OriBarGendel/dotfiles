;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;;;; GENERAL CONFIG
(setq doom-theme 'doom-nord)

(setq display-line-numbers-type t)

;; Fine undo steps. Otherwise undo undoes too much.
(setq evil-want-fine-undo t)

;; Open Emacs in fullscreen
(push '(fullscreen . maximized) default-frame-alist)

;; Open emacsclient in the main workspace
(after! persp-mode
  (setq persp-emacsclient-init-frame-behaviour-override "main"))

(use-package! perfect-margin
  :config
  (after! doom-modeline
    (setq mode-line-right-align-edge 'right-fringe))
  (perfect-margin-mode t))
;;;;; END OF GENERAL CONFIG

;;;;; ORG SETUP
(use-package! org
  :config
  (add-hook 'org-mode-hook 'doom-disable-line-numbers-h)
  (setq org-export-preserve-breaks t))

(use-package! org-id
  :config
  (setq org-id-link-to-org-use-id 'create-if-interactive-and-no-costum-id)
  (setq org-id-link-consider-parent-id t))

;; To show emphasis markers
(use-package! org-appear
  :config
  (add-hook 'org-mode-hook 'org-appear-mode))

;; Insert cross-reference links
;; Need to load consult-org to have 'consult-org-headings' and other functions.
(use-package! consult-org)
(defun my/consult--insert (pos)
  (let ((link nil))
    (save-excursion
      (with-current-buffer (marker-buffer pos)
        (beginning-of-buffer)
        (org-id-get-create)
        (goto-char pos)
        (org-id-get-create)
        (setq link (org-store-link t))))
    (insert link)))

(defun my/consult--insert-state ()
  (consult--state-with-return (save-excursion (consult--jump-preview)) #'my/consult--insert))

(defun my/org-insert-link ()
  "Insert cross-reference Org links in an Org file"
  (interactive (unless (derived-mode-p #'org-mode)
                 (user-error "Must be called from an Org buffer")))
  (let ((file (read-file-name "Choose file: ")))
    (consult--read
     (consult--slow-operation "Collecting headings..."
       (or (consult-org--headings nil nil (list file))
           (user-error "No headings")))
     :prompt "Go to heading: "
     :category 'org-heading
     :sort nil
     :require-match t
     :history '(:input consult-org--history)
     :narrow (consult-org--narrow)
     :state (my/consult--insert-state)
     :annotate #'consult-org--annotate
     :group (and nil #'consult-org--group)
     :lookup (apply-partially #'consult--lookup-prop 'org-marker))))

(defun org-latex-preview-whole-buffer ()
  "Render all previews in buffer (which is the same as running 'org-latex-preview' with a double prefix argument)."
  (interactive)
  (let ((current-prefix-arg '(16)))
    (call-interactively 'org-latex-preview)))

;; LaTeX preview in org mode
(use-package! org-latex-preview
  :config
  (add-hook 'org-mode-hook #'org-latex-preview-whole-buffer)
  ;; Add packages to use in preview compilation
  (with-eval-after-load 'org
    (add-to-list 'org-latex-packages-alist '("" "tikz" t))
    (add-to-list 'org-latex-packages-alist '("" "tikz-cd" t))
    (add-to-list 'org-latex-packages-alist '("" "mathtools" t)))

  ;; Increase font size
  (plist-put org-latex-preview-appearance-options :scale 1.25)
  (plist-put org-latex-preview-appearance-options :zoom 1.25)

  ;; Block C-n, C-p etc from opening up previews when using auto-mode
  (setq org-latex-preview-auto-ignored-commands
        '(next-line previous-line mwheel-scroll
          scroll-up-command scroll-down-command))

  ;; Enable consistent equation numbering
  (setq org-latex-preview-numbered t)

  ;; Bonus: Turn on live previews.  This shows you a live preview of a LaTeX
  ;; fragment and updates the preview in real-time as you edit it.
  ;; To preview only environments, set it to '(block edit-special) instead
  (setq org-latex-preview-live t)

  ;; More immediate live-previews -- the default delay is 1 second
  (setq org-latex-preview-live-debounce 0.25)


  ;; Centering Latex preview
  (defun my/org-latex-preview-uncenter (ov)
    (overlay-put ov 'before-string nil))
  (defun my/org-latex-preview-recenter (ov)
    (overlay-put ov 'before-string (overlay-get ov 'justify)))
  (defun my/org-latex-preview-center (ov)
    (save-excursion
      (goto-char (overlay-start ov))
      (when-let* ((elem (org-element-context))
                  ((or (eq (org-element-type elem) 'latex-environment)
                       (string-match-p "^\\\\\\[" (org-element-property :value elem))))
                  (img (overlay-get ov 'display))
                  (prop `(space :align-to (- center (0.55 . ,img))))
                  (justify (propertize " " 'display prop 'face 'default)))
        (overlay-put ov 'justify justify)
        (overlay-put ov 'before-string (overlay-get ov 'justify)))))
  (define-minor-mode org-latex-preview-center-mode
    "Center equations previewed with `org-latex-preview'."
    :global nil
    (if org-latex-preview-center-mode
        (progn
          (add-hook 'org-latex-preview-overlay-open-functions
                    #'my/org-latex-preview-uncenter nil :local)
          (add-hook 'org-latex-preview-overlay-close-functions
                    #'my/org-latex-preview-recenter nil :local)
          (add-hook 'org-latex-preview-overlay-update-functions
                    #'my/org-latex-preview-center nil :local))
      (remove-hook 'org-latex-preview-overlay-close-functions
                   #'my/org-latex-preview-recenter)
      (remove-hook 'org-latex-preview-overlay-update-functions
                   #'my/org-latex-preview-center)
      (remove-hook 'org-latex-preview-overlay-open-functions
                   #'my/org-latex-preview-uncenter)))

  (add-hook 'org-mode-hook 'org-latex-preview-center-mode))

(use-package! org-modern
  :config
  (add-hook 'org-mode-hook 'org-modern-mode)
  (setq
   ;; Edit settings
   org-auto-align-tags nil
   org-tags-column 0
   org-catch-invisible-edits 'show-and-error
   org-special-ctrl-a/e t
   org-insert-heading-respect-content t

   ;; Org styling, hide markup etc.
   org-hide-emphasis-markers t
   org-pretty-entities t
   org-agenda-tags-column 0
   org-ellipsis "…"

   line-spacing 0.1))
;;;;; END OF ORG SETUP

;;;;; LATEX SETUP
;; TODO - auctex setup does not work perfectly - when needing to run biber, it
;; does not automatically run LaTeX again. But this is relatively minor -
;; one can use "C-c C-c" and run "my biber" (see below).
(defun my-revert-document-buffer (file)
  (let ((buf (find-buffer-visiting file)))
    (when buf
      (with-current-buffer buf
        (revert-buffer nil t t)
        (pdf-view-mode)))))

;; For some reason, the default "Biber" TeX-command complains that
;; "Text is read-only," with no context whatsoever. Run "my-biber" instead.
(defun my-biber ()
  (add-to-list
   'TeX-command-list
   '("my biber"
     "biber %(output-dir) %s"
     TeX-run-silent ;TeX-run-shell
     nil
     t
     :help "Run Biber")))

(use-package! auctex
  :config
  (add-hook 'latex-mode-hook 'LaTeX-mode)
  (add-hook 'TeX-mode-hook #'my-biber)
  
  (setq TeX-view-program-selection '((output-pdf "PDF Tools"))
        TeX-view-program-list '(("PDF Tools" TeX-pdf-tools-sync-view))
        TeX-source-correlate-start-server t)
  (setq-default TeX-engine 'xetex
                TeX-PDF-mode t
                TeX-save-query t
                TeX-show-compilation t
                TeX-command-extra-options "-shell-escape --synctex=1"
                TeX-command-Biber "my biber")
  (with-eval-after-load 'tex
    (define-key TeX-source-correlate-map [C-down-mouse-1]
                #'TeX-view-mouse))

  (add-hook 'LaTeX-mode-hook 'TeX-interactive-mode)
  (setq TeX-source-correlate-mode t
        TeX-source-correlate-method 'synctex)

  (setq TeX-electric-sub-and-superscript nil)

  (setq TeX-parse-self t)
  (setq TeX-auto-save t)
  
  (add-hook 'TeX-after-compilation-finished-functions #'my-revert-document-buffer)

  (setq LaTeX-indent-environment-check nil))

(use-package! cdlatex
  :config
  (add-hook 'LaTeX-mode-hook 'turn-on-cdlatex)
  (add-hook 'org-mode-hook 'turn-on-org-cdlatex)
  (setq cdlatex-math-symbol-alist
        '(
          ( ?c ("\\circ" "" "\\cos"))
          ( ?. ("\\cdot" "\\bullet"))
          ( ?@ ("\\sharp" "\\flat" "\\dag"))
          ( ?+ ("\\oplus" "\\bigoplus"))
          ( ?* ("\\times" "\\otimes" "\\bigotimes"))
          ( ?i ("\\iota" "\\imath" "\\in"))
          ( ?& ("\\wedge" "\\bigwedge") )
          ( ?~ ("\\cong" "\\simeq" "\\approx") )
          )))

(use-package! reftex
  :config
  (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
  (setq reftex-ref-style-default-list '("Default" "Cleveref")))

(use-package! consult-reftex
  :config
  (setq consult-reftex-preferred-style-order '("\\Cref" "\\cref")))

;; FROM https://gist.github.com/astoff/4eb12114ecc86c5fd9b194a9d6ed7dd3
;; modified from company-reftex  
(defun ars/citation--make-candidates (prefix)
  (reftex-access-scan-info)
  ;; Reftex will ask for a regexp by using `completing-read'
  ;; Override this programatically with a regexp from the prefix
  (cl-letf (((symbol-function 'reftex--query-search-regexps)
             (lambda (_) (list (regexp-quote prefix)))))
    (let* ((reftex-use-fonts nil)
           (bibtype (reftex-bib-or-thebib))
           (candidates
            (cond
             ((eq 'thebib bibtype)
              (reftex-extract-bib-entries-from-thebibliography
               (reftex-uniquify
                (mapcar 'cdr
                        (reftex-all-assq
                         'thebib (symbol-value reftex-docstruct-symbol))))))
             ((eq 'bib bibtype)
              (reftex-extract-bib-entries (reftex-get-bibfile-list)))
             (reftex-default-bibliography
              (reftex-extract-bib-entries (reftex-default-bibliography))))))
      (cl-loop
       for entry in candidates
       collect
       (propertize
        (format "%-18s %-40s %s"
                (propertize (reftex-format-citation entry "%l") 'face reftex-label-face)
                (reftex-format-citation entry "%4a %y")
                (reftex-format-citation entry "%t"))
        'data entry)))))

(defun ars/citation--insert (item fmt)
  (insert (reftex-format-citation (get-text-property 0 'data item) fmt)))

(defun ars/citation ()
  "Insert a citation with ivy."
  (interactive (unless (derived-mode-p #'LaTeX-mode)
                 (user-error "Must be called from a LaTeX buffer")))
  (require 'reftex-cite)
  (ivy-read
   "Citation: "
   (ars/citation--make-candidates "=")
   :action '(1
             ("o" (lambda (s) (ars/citation--insert s "\\cite{%l}"))
              "cite")
             ("t" (lambda (s) (ars/citation--insert s "\\textcite{%l}"))
              "textcite")
             ("p" (lambda (s) (ars/citation--insert s "\\parencite{%l}"))
              "parencite")
             ("a" (lambda (s) (ars/citation--insert s "%3a \\cite{%l}"))
              "cite with author")
             ("i" (lambda (s) (ars/citation--insert s "%l"))
              "insert"))
   :sort t
   :caller 'ars/citation))
;;;;; END OF LATEX SETUP

;;;;; SNIPPETS SETUP
(use-package! yasnippet
  :config
  (setq yas-snippet-dirs '("~/.config/doom/snippets/"))

  (defun my-yas-try-expanding-auto-snippets ()
    (when yas-minor-mode
      (let ((yas-buffer-local-condition ''(require-snippet-condition . auto)))
        (yas-expand))))
  (add-hook 'post-self-insert-hook #'my-yas-try-expanding-auto-snippets)

  (setq yas-key-syntaxes '(yas-longest-key-from-whitespace "w_.()" "w_." "w_" "w"))

  (setq yas-triggers-in-field t)

  (add-hook 'org-mode-hook 'yas-reload-all)
  (add-hook 'LaTeX-mode-hook 'yas-reload-all)

  (add-hook 'snippet-mode-hook 'my-snippet-mode-hook)
  (defun my-snippet-mode-hook ()
    "Custom behaviours for `snippet-mode'."
    (setq-local require-final-newline nil)
    (setq-local mode-require-final-newline nil)))
;;;;; END OF SNIPPETS SETUP

;;;;; ORG ROAM SETUP
(use-package! org-roam
  :config
  (setq org-roam-directory "~/Documents/notes/")
  ;; Otherwise have to restart emacs after creating new notes file for ivy-bibtex to recognise it 
  (org-roam-db-autosync-mode))

(use-package! org-roam-dailies
  :config
  (setq org-roam-dailies-directory "./daily-notes/")
  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry
           "* %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%Y-%m-%d>\n")))))
;;;;; END OF ORG ROAM SETUP

;;;; BIBLIOGRAPHY SETUP
(use-package! org-ref
  :config
  (setq org-ref-insert-cite-function 'org-ref-insert-cite-link
        org-ref-cite-onclick-function (lambda (_) (org-ref-citation-menu))))

;; https://org-roam.discourse.group/t/guide-bibliography-system-with-org-roam-bibtex-and-org-noter-integration/3293
(use-package! ivy-bibtex
  :config
  (setq bibtex-completion-bibliography '("~/Zotero/bib-files/refs.bib")) 
  (setq bibtex-completion-pdf-field "File")
  (setq bibtex-completion-notes-path "~/Documents/notes/pdf-notes/")

  ;; BEGIN: Change insert citation (<f3>) behaviour of ivy-bibtex for org-mode
  (defun custom/bibtex-completion-format-citation-org (keys)
    "Custom cite definition for org-mode"
    (s-join ", "
            (--map (format "cite:&%s" it) keys)))

  (setq bibtex-completion-format-citation-functions
        '((org-mode      . custom/bibtex-completion-format-citation-org)
          (LaTeX-mode    . bibtex-completion-format-citation-cite)
          (markdown-mode . bibtex-completion-format-citation-pandoc-citeproc)
          (default       . bibtex-completion-format-citation-default)))
  ;; END: Change insert citation (<f3>) behaviour of ivy-bibtex for org-mode

  (add-to-list 'bibtex-completion-additional-search-fields "journal")
  (add-to-list 'bibtex-completion-additional-search-fields "booktitle")
  
  (setq bibtex-completion-display-formats
        '((article       . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:36} ${title:*} ${journal:40}")
          (inbook        . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:36} ${title:*} Chapter ${chapter:32}")
          (incollection  . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
          (inproceedings . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
          (t             . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:36} ${title:*}")))
  
  ;; Reverse order of entries. Zotero betterBibTex exports them in alphabetical order and
  ;; ivy-bibtex shows them in reverse order of appearance in file.
  (advice-add 'bibtex-completion-candidates
              :filter-return 'reverse)

  (setq ivy-bibtex-default-action 'ivy-bibtex-open-pdf))

;; BUG - for some reason, when creating a new notes file from ivy-bibtex, it does not
;; ask for a template in the first try, only in the second.
(add-to-list 'org-roam-capture-templates
             '("b" "bibliography notes" plain             ; Org-noter integration
               (file "~/Documents/notes/pdf-notes/notes-template.org")
               :target (file+head "~/Documents/notes/pdf-notes/${citekey}.org" ;"~/Documents/notes/pdf-notes/${title}.org"
                                  "#+title: ${title}")
               :empty-lines 1
               :unarrowed t))

(use-package! org-roam-bibtex
  :config
  (add-hook 'org-mode-hook 'org-roam-bibtex-mode)
  (setq bibtex-completion-edit-notes-function 'orb-bibtex-completion-edit-note) ; use org-roam-capture-templates for notes

  (setq orb-preformat-keywords '("citekey" "title" "url" "author-or-editor" "keywords" "file") ; customisation for notes, org-noter integration
        orb-process-file-keyword t
        orb-attached-file-extensions '("pdf"))
  (setopt orb-insert-interface 'ivy-bibtex)
  (setq orb-roam-ref-format 'org-ref-v3))
;;;;; END OF BIBLIOGRAPHY SETUP

;;;;; ORG NOTER SETUP
(defun find-org-notes-file (pdf-file)
  "Find org-notes file associated with a pdf file, created by ivy-bibtex.

  'org-noter' looks for org files with the same name as the pdf file, but ivy-bibtex creates a file called ${citekey}.org.

  Requires BibtexParser."
  ;; For some reason 'shell-command-to-string' returns a string with a '\n' at the end, which messes up everything.
  ;; The solution is from here 'https://stackoverflow.com/a/5020475/13780781'. 
  (substring
   (shell-command-to-string (concat "python3 " doom-user-dir "find-org-notes-file.py \"" pdf-file "\""))
   0 -1))

(use-package! org-noter
  :config
  (setq org-noter-notes-search-path '("~/Documents/notes/pdf-notes/"))
  (setq org-noter-always-create-frame nil)
  (setq org-noter-find-additional-notes-functions 'find-org-notes-file)
  (setq org-noter-hide-other t))
;;;;; END OF ORG NOTER SETUP

;;;;; PDF SETUP
(use-package! pdf-tools
  :config
  (add-hook! 'pdf-view-mode-hook '(pdf-links-minor-mode pdf-view-midnight-minor-mode))
  (pdf-tools-install)
  (setq-default pdf-view-display-size 'fit-width)
  (setq pdf-view-resize-factor 1.05)
  (setq pdf-view-continuous t))

(use-package! image-roll
  :config
  (add-hook 'pdf-view-mode-hook 'pdf-view-roll-minor-mode))
;;;;; END OF PDF SETUP

;;;;; PROJECT MANAGEMENT SETUP
(use-package! projectile
  :config
  (projectile-mode))
;;;;; END OF PROJECT MANAGEMENT SETUP

;;;;; WINDOW SETUP
(use-package! winum
  :config
  (winum-mode))

(use-package! switch-window
  :config
  (setq switch-window-shortcut-style 'quail))
;;;;; END OF WINDOW SETUP

;;;;; FILE MANAGER
;; TODO - enable treemacs on startup. Couldn't find a way to do it (that works) :/
(use-package! treemacs
  :config
  (treemacs-set-width 27)
  (add-hook 'treemacs-mode-hook (balance-windows))
  (add-hook 'treemacs-mode-hook (treemacs-follow-mode)))
;;;;; END OF FILE MANAGER

;;;;; KEYBINDINGS
;; Add scolling in minibuffer
(map! :map minibuffer-local-map
      "C-S-<next>" 'scroll-up-command
      "C-S-<prior>" 'scroll-down-command) 

;; Going up and down visual lines instead of logical lines in normal mode.
;; From https://github.com/syl20bnr/spacemacs/issues/9557#issuecomment-328253891
(map! :nv "<down>" 'evil-next-visual-line)
(map! :nv "<up>" 'evil-previous-visual-line)

;; Backward search
(map! "C-S-s" 'isearch-backward)

;; Go back from an org link
(map! :desc "Go back from an org link" "C-c g" 'org-mark-ring-goto)

;; Org-mode cross-reference links
(map! :desc "Insert cross-references" :map org-mode-map "C-c i c" 'my/org-insert-link)

;; reftex keybindings
(map! :map LaTeX-mode-map
      :desc "Open TOC" "C-c t" 'reftex-toc
      :desc "Insert a label" "C-c l i" 'reftex-label
      :desc "Goto label" "C-c l g" 'consult-reftex-goto-label
      :desc "Insert a label reference" "C-c r" 'consult-reftex-insert-reference
      :desc "Insert a citation" "C-c c" 'ars/citation)

;; yasnippet keybindings
(map! "C-c s n" 'yas-new-snippet
      "C-c s i" 'yas-insert-snippet
      "C-c s v" 'yas-visit-snippet-file
      "C-c s r" 'yas-reload-all)

;; Open org-roam-dailies menu
(map! "C-c d" 'org-roam-dailies-map)

;; Org-ref bibliography link
(map! :desc "Insert a citation link" :map org-mode-map "C-c i b" 'org-ref-insert-cite-link)

;; Open ivy-bibtex
(map! "C-c b" 'ivy-bibtex)

;; Insert link to a bibliography note
(map! :desc "Insert link to a bib note" :map org-roam-bibtex-mode-map "C-c i n" 'orb-insert-link)

;; org-noter keybindings
(map! :map (pdf-view-mode-map org-mode-map)
      "C-c n" 'org-noter)
(map! :map org-noter-doc-mode-map
      "C-c i" 'org-noter-insert-note
      "C-c k" 'org-noter-kill-session)
(map! :map org-noter-notes-mode-map
      "C-c k" 'org-noter-kill-session)

;; pdf-tools keybindings
(map! :map pdf-view-roll-minor-mode-map
      "<next>" 'pdf-roll-scroll-screen-forward
      "<prior>" 'pdf-roll-scroll-screen-backward
      "S-<next>" nil
      "S-<prior>" nil)
(map! :map pdf-view-mode-map
      "S-<next>" 'pdf-view-next-page
      "S-<prior>" 'pdf-view-previous-page
      "<next>" nil
      "<prior>" nil
      :n "<next>" nil
      :n "<prior>" nil)

;; Projectile keybindings
(map! "C-c o" 'projectile-command-map)

;; Switch windows with numbers
(map! :map winum-keymap
      "C-`" 'winum-select-window-by-number
      "M-1" 'winum-select-window-1
      "M-2" 'winum-select-window-2
      "M-3" 'winum-select-window-3
      "M-4" 'winum-select-window-4
      "M-5" 'winum-select-window-5
      "M-6" 'winum-select-window-6
      "M-7" 'winum-select-window-7
      "M-8" 'winum-select-window-8
      "M-9" 'winum-select-window-9
      "M-0" 'treemacs-select-window)

;; switch-window keybindings
(map! "C-c w o" 'switch-window
      "C-c w m" 'switch-window-then-maximize
      "C-c w v" 'switch-window-then-split-vertically
      "C-c w h" 'switch-window-then-split-horizontally
      "C-c w d" 'switch-window-then-delete
      "C-c w k" 'switch-window-then-kill-buffer)
;;;;; END OF KEYBINDINGS
