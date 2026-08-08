;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;;;; GENERAL CONFIG
(setq doom-theme 'doom-dracula)

(setq display-line-numbers-type t)

;; Fine undo steps. Otherwise undo undoes too much.
(setq evil-want-fine-undo t)

;; Open Emacs in fullscreen
(push '(fullscreen . maximized) default-frame-alist)

;; Auto-centres windows
(use-package! perfect-margin
  :config
  (after! doom-modeline
    (setq mode-line-right-align-edge 'right-fringe))
  (perfect-margin-mode t))

;; Spell checking
(use-package! flyspell
  :init
  (setq flyspell-default-dictionary "en_GB-ise-w_accents")
  :config
  (add-hook! '(org-mode-hook
               LaTeX-mode-hook) 'flyspell-mode)
  (add-hook! '(python-mode-hook
               emacs-lisp-mode-hook
               sh-mode-hook) 'flyspell-prog-mode)
  (setq ispell-personal-dictionary "~/.aspell.en.pws"))

;; Syntax checking
(use-package! flycheck
  :config
  (setq flycheck-checker-error-threshold 1000))
;;;;; END OF GENERAL CONFIG

;;;;; ORG SETUP
(use-package! org
  :config
  (add-hook 'org-mode-hook 'doom-disable-line-numbers-h)
  (setq org-export-preserve-breaks t))

(use-package! org-id
  :config
  (setq org-id-link-to-org-use-id 'create-if-interactive-and-no-costum-id)
  (setq org-id-link-consider-parent-id t)
  (setq org-id-locations-file "~/Documents/.orgids"))

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
  (add-hook 'org-mode-hook #'org-latex-preview-mode)
  
  ;; Add packages to use in preview compilation
  (with-eval-after-load 'org
    (add-to-list 'org-latex-packages-alist '("" "tikz" t))
    (add-to-list 'org-latex-packages-alist '("" "tikz-cd" t))
    (add-to-list 'org-latex-packages-alist '("" "mathtools" t))
    (add-to-list 'org-latex-packages-alist '("" "mathrsfs")))

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
   org-pretty-entities-include-sub-superscripts nil
   org-agenda-tags-column 0
   org-ellipsis "…"

   line-spacing 0.1))
;;;;; END OF ORG SETUP

;;;;; LATEX SETUP
;; TODO - auctex setup does not work perfectly - when needing to run biber, it
;; does not automatically run LaTeX again. But this is relatively minor -
;; one can use "C-c C-c" and run "Biber."

(defun my/revert-document-buffer (file)
  "Alternative to 'TeX-revert-document-buffer'.

The function 'TeX-revert-document-buffer' enables 'pdf-view-mode' in the PDF buffer,
but sometimes another run of 'pdf-view-mode' is needed to actually see the PDF,
as it opens in text mode for some reason."
  (let ((buf (find-buffer-visiting file)))
    (when buf
      (with-current-buffer buf
        (revert-buffer nil t t)
        (pdf-view-mode)))))

(use-package! auctex 
  :config
  (add-hook 'LaTeX-mode-hook 'TeX-source-correlate-mode)
  
  (setq TeX-view-program-selection '((output-pdf "PDF Tools"))
        TeX-view-program-list '(("PDF Tools" TeX-pdf-tools-sync-view))
        TeX-source-correlate-start-server t)
    
  (setq-default TeX-engine 'xetex
                TeX-save-query t
                TeX-show-compilation nil
                TeX-command-extra-options "-shell-escape --synctex=1")
  
  (setq TeX-electric-sub-and-superscript nil)

  (setq TeX-parse-self t
        TeX-auto-save t)
  
  (add-hook 'TeX-after-compilation-finished-functions #'my/revert-document-buffer))

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
  (setq org-roam-dailies-directory "./daily-notes/"))
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

Requires the Python package BibtexParser."
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
  (setq pdf-view-continuous t)
  (setq pdf-links-child-frame-auto-preview-wait 1))

(use-package! image-roll
  :config
  (add-hook 'pdf-view-mode-hook 'pdf-view-roll-minor-mode))
;;;;; END OF PDF SETUP

;;;;; PROJECT MANAGEMENT SETUP
(use-package! projectile
  :config
  (projectile-mode))
;;;;; END OF PROJECT MANAGEMENT SETUP

;;;;; LSP SETUP
(use-package! lsp-mode
  :config
  (add-hook! '(c-mode-common-hook
               LaTeX-mode-hook) 'lsp)
  (add-hook! 'lsp-mode-hook 'lsp-inline-completion-company-integration-mode)
  (setq lsp-completion-enable-additional-text-edit nil)
  (setq lsp-eldoc-render-all t))
;;;;; END OF LSP SETUP

;;;;; COMPILATION SETUP
(use-package! make-mode)
(use-package! cmake-mode)
(use-package! compile
  :config
  (setq compilation-window-height 10)

  (defun my/run-program-in-pop (buf str)
    ;; Immediately remove the hook of this function, so that other compilations do not run it
    (remove-hook 'compilation-finish-functions #'my/run-program-in-pop)
    (if (null (string-match "abnormally" str))
        ;; no errors
        (progn
          ;; close the compilation window after 1 second
          (run-at-time "1 sec" nil
                     (lambda (buf)
                       (with-selected-window (get-buffer-window buf)
                         (delete-window)))
                     buf)
          ;; pop shell
          (shell-pop 1)
          ;; run
          (process-send-string (get-buffer-process (current-buffer)) "make run\n")))))

(use-package! shell-pop
  :custom
  (shell-pop-shell-type '("ansi-term" "*ansi-term*"
                          (lambda ()
                            (ansi-term shell-pop-term-shell))))
  (shell-pop-window-height 30) ; Percentage of the frame height
  (shell-pop-window-position "bottom"))

(defun my/compile-run-in-pop ()
  "Compile the current project or file, open a popup terminal and execute the binary if compilation succeeds."
  (interactive)

  ;; Run the program after compilation
  (add-hook 'compilation-finish-functions #'my/run-program-in-pop)

  (compile "make -k"))
;;;;; END OF SHELL POP SETUP

;;;;; TAB SETUP
(use-package! centaur-tabs
  :init
  (setq centaur-tabs-enable-key-bindings t)
  :config
  (centaur-tabs-mode)

  ;; Hide tabs by default, only show them in specific major modes
  (add-hook! 'change-major-mode-after-body-hook (if (centaur-tabs-mode-on-p) (centaur-tabs-local-mode)))
  (add-hook! '(c-mode-common-hook
               eshell-mode-hook
               makefile-mode-hook
               cmake-mode-hook) (centaur-tabs-local-mode -1))
  
  (setq centaur-tabs-style 'slant)
  (setq centaur-tabs-icon-type 'nerd-icons)
  (setq centaur-tabs-set-icons t)
  (setq centaur-tabs-set-bar 'left)
  (setq centaur-tabs-cycle-scope 'tabs)

  (defvar my/centaur-tabs-target-group nil
    "Used to store the active group name right before a shell buffer is created.")

  (defun my/centaur-tabs-capture-active-group (rest)
    "Capture the group name of the buffer we are currently in."
    (setq my/centaur-tabs-target-group (centaur-tabs-buffer-groups-result)))

  ;; Capture the source group before the term buffers open
  (advice-add 'eshell :before #'my/centaur-tabs-capture-active-group)
  (advice-add 'shell :before #'my/centaur-tabs-capture-active-group)
  (advice-add 'term :before #'my/centaur-tabs-capture-active-group)

  ;; Overwrite the grouping rules
  (defun centaur-tabs-buffer-groups ()
    "Custom rules for centaur-tabs grouping. Groups shell buffers with the buffers they were opened from."
    (list
     (cond
      ;; Check if this is in a project
      ((when-let* ((project-name (centaur-tabs-project-name)))
         project-name))
      
      ;; Check if this is a shell and we have a captured target group
      ((memq major-mode
             '( eshell-mode
                term-mode
                shell-mode))
       my/centaur-tabs-target-group)

      ;; Magit
      ((memq major-mode '( magit-process-mode
                           magit-status-mode
                           magit-log-mode
                           magit-file-mode
                           magit-blob-mode
                           magit-blame-mode
                           magit-diff-mode
                           magit-revision-mode
                           magit-stash-mode))
       "Magit")

      ;; Dired-derived modes
      ((derived-mode-p 'dired-mode) "Dired")

      ;; Hidden buffers
      ((string-equal "*" (substring (buffer-name) 0 1)) "Emacs")
      
      ;; Fallback to normal grouping rules
      (t
       (centaur-tabs-get-group-name (current-buffer)))))))
;;;;; END OF TAB SETUP

;;;;; WINDOW SETUP
(use-package! winum
  :config
  (winum-mode))

(use-package! switch-window
  :config
  (setq switch-window-shortcut-style 'quail))
;;;;; END OF WINDOW SETUP

;;;;; FILE MANAGER
(setq delete-by-moving-to-trash t)
(use-package! dirvish
  :config
  (dirvish-side-follow-mode)
  
  (setq dired-mouse-drag-files t) 
  (setq mouse-drag-and-drop-region-cross-program t)
  (setq mouse-1-click-follows-link nil))
;;;;; END OF FILE MANAGER

;;;;; KEYBINDINGS
;; Add scrolling in minibuffer
(map! :map minibuffer-local-map
      "C-S-<next>" 'scroll-up-command
      "C-S-<prior>" 'scroll-down-command) 

;; Company keybindings
(map! :map company-active-map
      "<tab>" 'company-complete-selection
      "RET" nil
      "<return>" nil)

;; Going up and down visual lines instead of logical lines in normal mode.
;; From https://github.com/syl20bnr/spacemacs/issues/9557#issuecomment-328253891
(map! :nv "<down>" 'evil-next-visual-line)
(map! :nv "<up>" 'evil-previous-visual-line)

;; Improved isearch
(map! "C-s" #'swiper-isearch)

;; Consult the kill ring and paste from it
(map! "M-y" #'consult-yank-from-kill-ring)

(map! :map flyspell-mode-map
      :desc "Correct words, moving backwards in the buffer" "C-;" 'flyspell-correct-wrapper)

(map! :desc "Navigate through errors in buffer" "C-c e" 'consult-flycheck)

;; Go back from an org link
(map! :desc "Go back from an org link" "C-c g b" 'org-mark-ring-goto)

;; Org-mode cross-reference links
(map! :desc "Insert cross-references" :map org-mode-map "C-c i c" 'my/org-insert-link)

;; auctex keybindings
(map! :map TeX-source-correlate-map
      :desc "Sync pdf with current cursor position" "C-<down-mouse-1>" #'TeX-view-mouse)

;; reftex keybindings
(map! :map LaTeX-mode-map
      :desc "Insert a label" "C-c i l" 'reftex-label
      :desc "Goto label" "C-c g l" 'consult-reftex-goto-label
      :desc "Insert a label reference" "C-c i r" 'consult-reftex-insert-reference
      :desc "Insert a citation" "C-c i c" 'ars/citation)

;; yasnippet keybindings
(map! :desc "New snippet" "C-c s n" 'yas-new-snippet
      :desc "Insert snippet" "C-c s i" 'consult-yasnippet
      :desc "Visit snippets of current major mode" "C-c s v" 'consult-yasnippet-visit-snippet-file
      :desc "Reload all snippets" "C-c s r" 'yas-reload-all)

;; org-roam-dailies menu. Creating my own map for convenience, and with descriptions
(map! :desc "Open org-dailies directory" "C-c o d ." 'org-roam-dailies-find-directory
      :desc "Open previous daily note" "C-c o d p" 'org-roam-dailies-goto-previous-note
      :desc "Open the next daily note" "C-c o d n" 'org-roam-dailies-goto-next-note
      :desc "Open an org daily note" "C-c o d d" 'org-roam-dailies-goto-date
      :desc "Open today's daily note" "C-c o d t" 'org-roam-dailies-goto-today
      :desc "Open yesterday's daily note" "C-c o d y" 'org-roam-dailies-goto-yesterday
      :desc "Open tomorrow's daily note" "C-c o d m" 'org-roam-dailies-goto-tomorrow
      :desc "Capture an entry in today's daily note" "C-c o d c" 'org-roam-dailies-capture-today
      :desc "Capture an entry in tomorrow's daily note" "C-c o d v" 'org-roam-dailies-capture-tomorrow)

;; Org-ref bibliography link
(map! :desc "Insert a citation link" :map org-mode-map "C-c i b" 'org-ref-insert-cite-link)

;; Open ivy-bibtex
;; Use "M-o" on an ivy-bibtex item for more actions.
(map! "C-c o b" 'ivy-bibtex)

;; Insert link to a bibliography note
(map! :desc "Insert link to a bib note" :map org-roam-bibtex-mode-map "C-c i n" 'orb-insert-link)

;; org-noter keybindings
(map! :map (pdf-view-mode-map org-mode-map)
      "C-c o n" 'org-noter)
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

;; LSP keybindings
(map! :map lsp-mode-map "C-c l" lsp-command-map)

;; Compile keybindings
(map! :map (c-mode-map
            c++-mode-map
            makefile-mode-map
            cmake-mode-map)
      "SPC c R"
      'my/compile-run-in-pop)

;; Tab keybindings
(map! :map centaur-tabs-prefix-map
      "k" 'centaur-tabs--kill-this-buffer-dont-ask
      "n" 'centaur-tabs--create-new-tab)
(map! :map centaur-tabs-mode-map
      "C-<prior>" 'centaur-tabs-backward
      "C-<next>" 'centaur-tabs-forward
      "C-S-<prior>" 'centaur-tabs-move-current-tab-to-left
      "C-S-<next>" 'centaur-tabs-move-current-tab-to-right)

;; Dirvish keybindings
(map! :desc "Dirvish" "C-c o f" 'dirvish)
(map! :map dirvish-mode-map
      "<mouse-1>" 'dirvish-subtree-toggle-or-open
      "<mouse-2>" 'dired-mouse-find-file-other-window
      "<mouse-3>" 'dired-mouse-find-file
      "M-p" 'dirvish-yank-menu
      :n "M-p" 'dirvish-yank-menu)

;; Window keybindings
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
      "M-0" 'dirvish-side)
(map! "C-c w o" 'switch-window
      "C-c w m" 'switch-window-then-maximize
      "C-c w v" 'switch-window-then-split-vertically
      "C-c w h" 'switch-window-then-split-horizontally
      "C-c w d" 'switch-window-then-delete
      "C-c w k" 'switch-window-then-kill-buffer
      "C-c w h" 'switch-window-mvborder-left
      "C-c w l" 'switch-window-mvborder-right
      "C-c w j" 'switch-window-mvborder-down
      "C-c w k" 'switch-window-mvborder-up)
(map! "C-c w b" 'balance-windows) ; can also use 'SPC w ='
;;;;; END OF KEYBINDINGS
