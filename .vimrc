set encoding=utf-8

source $VIMRUNTIME/mswin.vim
behave mswin

call plug#begin()

Plug 'sirver/ultisnips'

Plug 'lervag/vimtex'

Plug 'KeitaNakamura/tex-conceal.vim'

Plug 'arcticicestudio/nord-vim'

" Plug 'dylanaraps/wal'
" Plug 'dense-analysis/ale'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" Miscellaneous
	let g:tex_indent_brace = 0
	let g:tex_indent_items = 0

" Theme
set background=dark
colorscheme nord

set guifont=Iosevka_Extended:h12:cANSI:qDRAFT

" Languages
	setlocal spell
	set spelllang=en_gb
	inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u


" Ultisnips
    let g:UltiSnipsExpandTrigger = '<tab>'
    let g:UltiSnipsJumpForwardTrigger = '<tab>'
    let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'


" Vimtex
	let g:tex_flavor='latex'
	let g:vimtex_compiler_latexmk_engines = {
    \ '_'                : '-xelatex',
    \}
	let g:vimtex_compiler_latexmk = {
		\ 'callback' : 1,
		\ 'continuous' : 1,
		\ 'executable' : 'latexmk',
		\ 'options' : [
		\ '-verbose',
		\ '-file-line-error',
		\ '-synctex=1',
		\ '-interaction=nonstopmode',
		\ '-shell-escape',
	\ ],
	\}

	let g:vimtex_view_general_viewer = 'okular'
	let g:vimtex_view_general_options = '--unique file:@pdf\#src:@line@tex'

"	let g:vimtex_view_general_viewer = 'SumatraPDF'
"	let g:vimtex_view_general_options = '-reuse-instance -forward-search @tex @line @pdf'

	let g:vimtex_quickfix_mode = 1
	let g:vimtex_quickfix_open_on_warning = 0
	

" tex-conceal
	set conceallevel=1
	let g:tex_conceal='abdmg'
	hi Conceal ctermbg=none


" Ale options
" let g:ale_completion_enabled = 1
" let g:ale_tex_texlab_executable = 'C:\Users\oriba\Downloads\texlab-x86_64-windows\texlab.exe'

" Coc options
" inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
" inoremap <expr> <Up> coc#pum#visible() ? coc#pum#prev(1) : "\<Up>"
" inoremap <expr> <Down> coc#pum#visible() ? coc#pum#next(1) : "\<Down>"
" inoremap <expr> <Right> coc#pum#visible() ? "\<C-Y>" : "\<Right>"
