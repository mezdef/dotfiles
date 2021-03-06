".vimrc
"              _
"      __   __(_)_ __ ___  _ __  ___
" _____\ \ / /| | '_ ` _ \| / _|/ __|
"|_____|\ V / | | | | | | |  / | |__
"        \_/  |_|_| |_| |_|_|   \___|
"
" Author: Marc Ziani de Ferranti
"
"
" STARTING CONFIG //////////////////////////////////////////////////////////////////////////////////
"
filetype off
set nocompatible                                  " Choose no compatibility with legacy vi
set cpoptions+=J                                  " Compatability options
syntax on                                         " Turn on syntax highlighting
set mouse=a                                       " Automatically enable mouse usage
au FileType python source <rope-vim>

" VUNDLE ///////////////////////////////////////////////////////////////////////////////////////////

" set rtp+=~/dotfiles/vim/bundle/vundle/
" call vundle#rc()

" let Vundle manage Vundle  required!
" Bundle 'gmarik/vundle'

" Bundle 'tpope/vim-fugitive'
" Bundle 'tpope/vim-surround'
" Bundle 'tpope/vim-commentary'
" Bundle 'tpope/vim-repeat'
" Bundle 'YankRing.vim'
" Bundle 'Yggdroot/indentLine'
" Bundle 'scrooloose/syntastic'
" Bundle 'Lokaltog/vim-easymotion'
" Bundle 'kien/ctrlp.vim'
" Bundle 'mezdef/vim-airline.git'

" Bundle 'tpope/vim-rails'
" Bundle 'tpope/vim-haml'
" Bundle 'kchmck/vim-coffee-script'
" Bundle 'othree/html5.vim'
" Bundle 'hail2u/vim-css3-syntax'
" Bundle 'cakebaker/scss-syntax.vim'
" Bundle 'plasticboy/vim-markdown'


filetype plugin indent on                         " Load file type plugins + indentation

" DEFAULT OPTIONS //////////////////////////////////////////////////////////////////////////////////

set encoding=utf-8                                " Sets Vim's character encoding
set modelines=0                                   " Fixes security exploits
set showmode                                      " Displays current editing mode in status line
set showcmd                                       " Displays incomplete commands in status line
set hidden                                        " Buffer becomes hidden when abandoned
set visualbell                                    " Uses a visual que instead of audio
set cursorline                                    " Highlights current cursor position's line
set ttyfast                                       " Fast terminal connection
set ruler                                         " Shows position in current file
set backspace=indent,eol,start                    " Allows backspace in insert mode
set shell=/bin/bash                               " Sets Vim's terminal environment

" UNDO, BACKUPS & HISTORY //////////////////////////////////////////////////////////////////////////

set undodir=~/dotfiles/vim/tmp/undo//             " Undo file location
set undofile                                      " Enable undo file
set backupdir=~/dotfiles/vim/tmp/backup//         " Backup file location
set backup                                        " Enable backup file
set directory=~/dotfiles/vim/tmp/swap//           " Swap file location
set noswapfile                                    " Disables swp file

set history=1000                                  " Store lots of :cmdline history
if exists("&undoreload")
  set undoreload=10000
endif

" LEADER ///////////////////////////////////////////////////////////////////////////////////////////

let mapleader = ","
let maplocalleader = "\\"

" LINE NUMBERING ///////////////////////////////////////////////////////////////////////////////////

set number                                        " Line numbers on
set numberwidth=4                                 " Fixed coloumn width
set relativenumber                                " Set line numbers to relative positioning
autocmd InsertEnter * :set number
autocmd InsertLeave * :set relativenumber

" INDENTATION  /////////////////////////////////////////////////////////////////////////////////////

filetype indent on                                " Activates indenting for files
set autoindent                                    " Use current indent on subsaquent lines
set smartindent                                   " Indents lines after appropriate braces etc
set smarttab                                      " Inserts blank space according to shiftwidth

set tabstop=2                                     " Number of <space>s a <tab> inserts
set shiftwidth=2                                  " Number of <space>s a '>>' inserts
set softtabstop=2                                 " Number of <space>s inserted when editing
set expandtab                                     " <tab>s are replaced with <space> characters

" IndentLine plugin config
let g:indentLine_color_term = 239
let g:indentLine_char = '|'
let g:indentLine_color_gui = '#CCCCCC'

" WRAPPING /////////////////////////////////////////////////////////////////////////////////////////

set wrap                                          " Wraps lines that are too long for the window
set textwidth=100                                 " Set character width of splitter
set formatoptions=qrn1
if exists("&colorcolumn")
  set colorcolumn=+1
endif
set synmaxcol=100                                 " Turns off syntax on long lines to prevent slow

" SCROLLING ////////////////////////////////////////////////////////////////////////////////////////

set scrolloff=3                                   " Begin scroll x lines from top / bottom
set sidescroll=1                                  " Minimum number of columns to scroll horizontally
set sidescrolloff=10

" INVISIBLE CHARACTERS /////////////////////////////////////////////////////////////////////////////

set list                                          " Display invisible characters
set listchars=tab:▸\ ,eol:¬,extends:❯,precedes:❮  " Set invis charactes for tab, eol, extm precd
set showbreak=↪                                   " Invisible character to indicate wrapped line
" Characters to fill the statuslines and vertical separators
set fillchars=diff:\

set autowriteall                                  " Write the file, if modified on various actions
set shiftround
set autoread                                      "Reload files changed outside vim
set dictionary=/usr/share/dict/words

" SPLITS ////////////////////////////////////////////////////////////////////////////////////////////

set splitbelow                                    " New horizontal split window is below current
set splitright                                    " New vertical split window is on the right

" FOLDS ////////////////////////////////////////////////////////////////////////////////////////////

set foldcolumn=1
set columns=106
set foldmethod=indent                             "fold based on indent
set foldnestmax=3                                 "deepest fold is 3 levels
set nofoldenable                                  "dont fold by default

" MISC /////////////////////////////////////////////////////////////////////////////////////////////

set lazyredraw                                    " Screen is not redrawn while using macros

set laststatus=2                                  " Show the statusline

set ttimeout
set notimeout
set nottimeout
set timeout timeoutlen=1000 ttimeoutlen=100

set matchtime=3                                   " Tenths of a second to show matching paren

" WILDMENU /////////////////////////////////////////////////////////////////////////////////////////

set wildmenu
set wildmode=list:longest

set wildignore+=.hg,.git,.svn                    " Version control
set wildignore+=*.aux,*.out,*.toc                " LaTeX intermediate files
set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg   " binary images
set wildignore+=*.luac                           " Lua byte code
set wildignore+=*.o,*.obj,*.exe,*.dll,*.manifest " compiled object files
set wildignore+=*.pyc                            " Python byte code
set wildignore+=*.spl                            " compiled spelling word lists
set wildignore+=*.sw?                            " Vim swap files
set wildignore+=*.DS_Store?                      " OSX bullshit

set backupskip=/tmp/*,/private/tmp/*"             " Make Vim able to edit crontab files again.

au FocusLost * :wa                                " Save when losing focus

" Resize splits when the window is resized
au VimResized * exe "normal! \<c-w>="

" COLOUR SCHEME ////////////////////////////////////////////////////////////////////////////////////

" set background=light                               " Dark / light background / color scheme
" colorscheme hemisu
" set transparency=1

match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'  " Highlight VCS conflict markers
" let g:Powerline_symbols = 'fancy'                 " Powerline
let g:airline_powerline_fonts = 1
let g:airline_theme='palefire'

" ABBREVIATIONS ////////////////////////////////////////////////////////////////////////////////////


" SEARCHING ////////////////////////////////////////////////////////////////////////////////////////

set ignorecase                                    " Case insensitive serarching
set smartcase                                     " Case insensitive serarching
set incsearch                                     " Find the next match as we type the search
set showmatch
set hlsearch                                      " Hilight searches by default

" Use sane regexes.
nnoremap / /\v
vnoremap / /\v

" Clear current search
noremap <leader><space> :noh<cr>:call clearmatches()<cr>

" Smart % jumping
runtime macros/matchit.vim
" % Matching with tab key in command mode
map <tab> %

" Don't move on *
nnoremap * *<c-o>

" VISUAL MODE //////////////////////////////////////////////////////////////////////////////////////
"
set virtualedit+=block

" Easier linewise reselection
nnoremap <leader>v V`]
noremap <leader>v V`]


" NAVIGATION ///////////////////////////////////////////////////////////////////////////////////////

" Disable arrow keys in Command Mode
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
" Disable arrow keys in Insert Mode
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Up and Down work like you expect
noremap j gj
noremap k gk

" Easy buffer navigation
noremap <C-h>  <C-w>h
noremap <C-j>  <C-w>j
noremap <C-k>  <C-w>k
noremap <C-l>  <C-w>l

" Faster Esc
inoremap jj <ESC>
inoremap jk <esc>

" Highlight word
nnoremap <silent> <leader>hh :execute 'match InterestingWord1 /\<<c-r><c-w>\>/'<cr>
nnoremap <silent> <leader>h1 :execute 'match InterestingWord1 /\<<c-r><c-w>\>/'<cr>
nnoremap <silent> <leader>h2 :execute '2match InterestingWord2 /\<<c-r><c-w>\>/'<cr>
nnoremap <silent> <leader>h3 :execute '3match InterestingWord3 /\<<c-r><c-w>\>/'<cr>

" Visual Mode */# from Scrooloose {{{
function! s:VSetSearch()
  let temp = @@
  norm! gvy
  let @/ = '\V' . substitute(escape(@@, '\'), '\n', '\\n', 'g')
  let @@ = temp
endfunction

vnoremap * :<C-u>call <SID>VSetSearch()<CR>//<CR><c-o>
vnoremap # :<C-u>call <SID>VSetSearch()<CR>??<CR><c-o>


" CSS & LESSCSS ////////////////////////////////////////////////////////////////////////////////////

augroup ft_css
  au!

  au BufNewFile,BufRead *.less setlocal filetype=less
  au Filetype less,css setlocal foldmethod=marker
  au Filetype less,css setlocal foldmarker={,}
  au Filetype less,css setlocal omnifunc=csscomplete#CompleteCSS
  au Filetype less,css setlocal iskeyword+=-
augroup END

" SCSS /////////////////////////////////////////////////////////////////////////////////////////////
"
au BufRead,BufNewFile *.scss set filetype=scss

" DJANGO ///////////////////////////////////////////////////////////////////////////////////////////

augroup ft_django
  au!

  au BufNewFile,BufRead urls.py           setlocal nowrap
  au BufNewFile,BufRead urls.py           normal! zR
  au BufNewFile,BufRead dashboard.py      normal! zR
  au BufNewFile,BufRead local_settings.py normal! zR

  au BufNewFile,BufRead admin.py     setlocal filetype=python.django
  au BufNewFile,BufRead urls.py      setlocal filetype=python.django
  au BufNewFile,BufRead models.py    setlocal filetype=python.django
  au BufNewFile,BufRead views.py     setlocal filetype=python.django
  au BufNewFile,BufRead settings.py  setlocal filetype=python.django
  au BufNewFile,BufRead settings.py  setlocal foldmethod=marker
  au BufNewFile,BufRead forms.py     setlocal filetype=python.django
  au BufNewFile,BufRead common_settings.py  setlocal filetype=python.django
  au BufNewFile,BufRead common_settings.py  setlocal foldmethod=marker
augroup END

" }}}

" HTML & HTMLDJANGO ////////////////////////////////////////////////////////////////////////////////

au BufNewFile,BufRead *.j2 setlocal filetype=htmljinja

" JAVASCRIPT ///////////////////////////////////////////////////////////////////////////////////////

augroup ft_javascript
  au!

  au FileType javascript setlocal foldmethod=marker
  au FileType javascript setlocal foldmarker={,}
augroup END

" MARKDOWN /////////////////////////////////////////////////////////////////////////////////////////

augroup ft_markdown
    au!

    au BufNewFile,BufRead *.m*down setlocal filetype=markdown foldlevel=20

    " Use <localleader>1/2/3 to add headings.
    au Filetype markdown nnoremap <buffer> <localleader>1 yypVr=
    au Filetype markdown nnoremap <buffer> <localleader>2 yypVr-
    au Filetype markdown nnoremap <buffer> <localleader>3 I### <ESC>
augroup END

" PYTHON ///////////////////////////////////////////////////////////////////////////////////////////

" RUBY /////////////////////////////////////////////////////////////////////////////////////////////

augroup ft_ruby
  au!
  au Filetype ruby setlocal foldmethod=syntax
augroup END

" QUICK FILE EDITING  //////////////////////////////////////////////////////////////////////////////

nnoremap <leader>ev <C-w>s<C-w>j<C-w>L:e ~/dotfiles/vim/vimrc<cr>
nnoremap <leader>ez <C-w>s<C-w>j<C-w>L:e ~/dotfiles/zshrc<cr>

" Auto re-load vimrc on save
augroup reload_vimrc " {
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END " }

" MISC MAPPINGS ////////////////////////////////////////////////////////////////////////////////////

" Search/Replace current word with checking
nnoremap <Leader>s :%s/<c-r><c-w>/<c-r><c-w>/gc<Left><Left><Left>
vnoremap <Leader>s "hy:%s/\%V/g<Left><Left>
vnoremap <Leader>S "hy:%s/<C-r>h//gc<left><left><left>

" Substitute
nnoremap <leader>s :%s//<left>

"This allows for change paste motion cp{motion}
nmap <silent> cp :set opfunc=ChangePaste<CR>g@
function! ChangePaste(type, ...)
    silent exe "normal! `[v`]\"_c"
    silent exe "normal! p"
endfunction

" Change case
noremap <C-u> gUiw
inoremap <C-u><esc> gUiwea

" Formatting, TextMate-style
nnoremap Q gqip

" HTML tag closing
inoremap <C-_> <Space><BS><Esc>:call InsertCloseTag()<cr>a

" New line and indentation after braces
inoremap {<cr> {<cr>}<c-o>O
inoremap [<cr> [<cr>]<c-o>O
inoremap (<cr> (<cr>)<c-o>O

" Align text
nnoremap <leader>Al :left<cr>
nnoremap <leader>Ac :center<cr>
nnoremap <leader>Ar :right<cr>
vnoremap <leader>Al :left<cr>
vnoremap <leader>Ac :center<cr>
vnoremap <leader>Ar :right<cr>


" Cmdheight switching
nnoremap <leader>1 :set cmdheight=1<cr>
nnoremap <leader>2 :set cmdheight=2<cr>

" Replaste
nnoremap <D-p> "_ddPV`]=

" Marks and Quotes
noremap ' `
noremap æ '
noremap ` <C-^>

" Calculator
inoremap <C-B> <C-O>yiW<End>=<C-R>=<C-R>0<CR>

" REMAP ANNOYING KEYS ////////////////////////////////////////////////////////////////////////////////////

" Fuck you, help key.
if exists("fuoptions")
  set fuoptions=maxvert,maxhorz
endif
noremap  <F1> :set invfullscreen<CR>
inoremap <F1> <ESC>:set invfullscreen<CR>a

" Fuck you too, manual key.
nnoremap K <nop>

" Stop it, hash key.
inoremap # X<BS>#



" Better Completion
set completeopt=longest,menuone,preview

" Sudo to write
cmap w!! w !sudo tee % >/dev/null

" I suck at typing.
nnoremap <localleader>= ==

" Made D behave
nnoremap D d$

" Keep search matches in the middle of the window.
nnoremap n nzzzv
nnoremap N Nzzzv


" Same when jumping around
nnoremap g; g;zz
nnoremap g, g,zz

" Easier to type, and I never use the default behavior.
noremap H ^
noremap L $

" Heresy
inoremap <c-a> <esc>I
inoremap <c-e> <esc>A

" Open a Quickfix window for the last search.
nnoremap <silent> <leader>/ :execute 'vimgrep /'.@/.'/g %'<CR>:copen<CR>

" Ack for the last search.
nnoremap <silent> <leader>? :execute "Ack! '" . substitute(substitute(substitute(@/, "\\\\<", "\\\\b", ""), "\\\\>", "\\\\b", ""), "\\\\v", "", "") . "'"<CR>

" Fix linewise visual selection of various text objects
nnoremap VV V
nnoremap Vit vitVkoj
nnoremap Vat vatV
nnoremap Vab vabV
nnoremap VaB vaBV

" Error navigation {{{
"
"             Location List     QuickFix Window
"            (e.g. Syntastic)     (e.g. Ack)
"            ----------------------------------
" Next      |     M-k               M-Down     |
" Previous  |     M-l                M-Up      |
"            ----------------------------------
"
nnoremap ˚ :lnext<cr>zvzz
nnoremap ¬ :lprevious<cr>zvzz
inoremap ˚ <esc>:lnext<cr>zvzz
inoremap ¬ <esc>:lprevious<cr>zvzz
nnoremap <m-Down> :cnext<cr>zvzz
nnoremap <m-Up> :cprevious<cr>zvzz
" Toggle paste
set pastetoggle=<F8>

" Quickreturn
inoremap <c-cr> <esc>A<cr>
inoremap <s-cr> <esc>A:<cr>

" Indent Guides {{{
let g:indentguides_state = 0
function! IndentGuides() " {{{
    if g:indentguides_state
        let g:indentguides_state = 0
        2match None
    else
        let g:indentguides_state = 1
        execute '2match IndentGuides /\%(\_^\s*\)\@<=\%(\%'.(0*&sw+1).'v\|\%'.(1*&sw+1).'v\|\%'.(2*&sw+1).'v\|\%'.(3*&sw+1).'v\|\%'.(4*&sw+1).'v\|\%'.(5*&sw+1).'v\|\%'.(6*&sw+1).'v\|\%'.(7*&sw+1).'v\)\s/'
    endif
endfunction " }}}
nnoremap <leader>i :call IndentGuides()<cr>

" }}}
" Insert Mode Completion {{{

inoremap <c-l> <c-x><c-l>
inoremap <c-f> <c-x><c-f>

" PLUGINS - CTRL-P ////////////////////////////////////////////////////////////////////////////////////////
"
let g:ctrlp_dont_split = 'NERD_tree_2'
let g:ctrlp_jump_to_buffer = 0
let g:ctrlp_map = '<leader>,'
" let g:ctrlp_working_path_mode = 0
" let g:ctrlp_regexp = 1
let g:ctrlp_match_window_reversed = 1
let g:ctrlp_split_window = 0
let g:ctrlp_max_height = 20
let g:ctrlp_extensions = ['tag']

let g:ctrlp_prompt_mappings = {
  \ 'PrtSelectMove("j")':   ['<c-j>', '<down>', '<s-tab>'],
  \ 'PrtSelectMove("k")':   ['<c-k>', '<up>', '<tab>'],
  \ 'PrtHistory(-1)':       ['<c-n>'],
  \ 'PrtHistory(1)':        ['<c-p>'],
  \ 'ToggleFocus()':        ['<c-tab>'],
  \ }

let ctrlp_filter_greps = "".
  \ "egrep -iv '\\.(" .
  \ "jar|class|swp|swo|log|so|o|pyc|jpe?g|png|gif|mo|po" .
  \ ")$' | " .
  \ "egrep -v '^(\\./)?(" .
  \ "deploy/|lib/|classes/|libs/|deploy/vendor/|.git/|.hg/|.svn/|.*migrations/|docs/build/" .
  \ ")'"

let g:ctrlp_user_command = ['.git/', 'cd %s && git ls-files --exclude-standard -co']

nnoremap <leader>. :CtrlPTag<cr>}


" PLUGINS - COMMENTARY /////////////////////////////////////////////////////////////////////////////

nmap <leader>c <Plug>CommentaryLine
xmap <leader>c <Plug>Commentary
au FileType htmldjango setlocal commentstring={#\ %s\ #}

" PLUGINS - EASYMOTION /////////////////////////////////////////////////////////////////////////////

let g:EasyMotion_leader_key = '<Leader>'
hi link EasyMotionTarget Function
hi link EasyMotionShade  Comment

" PLUGINS - FUGITIVE ///////////////////////////////////////////////////////////////////////////////

nnoremap <leader>gd :Gdiff<cr>
nnoremap <leader>gs :Gstatus<cr>
nnoremap <leader>gw :Gwrite<cr>
nnoremap <leader>ga :Gadd<cr>
nnoremap <leader>gb :Gblame<cr>
nnoremap <leader>gco :Gcheckout<cr>
nnoremap <leader>gci :Gcommit<cr>
nnoremap <leader>gm :Gmove<cr>
nnoremap <leader>gr :Gremove<cr>

augroup ft_fugitive
  au!

  au BufNewFile,BufRead .git/index setlocal nolist
augroup END

" HTML5 ////////////////////////////////////////////////////////////////////////////////////////////

let g:event_handler_attributes_complete = 0
let g:rdfa_attributes_complete = 0
let g:microdata_attributes_complete = 0
let g:atia_attributes_complete = 0

" PLUGINS - NERDTREE /////////////////////////////////////////////////////////////////////////////////////////

noremap  <F2> :NERDTreeToggle<cr>
inoremap <F2> <esc>:NERDTreeToggle<cr>

au Filetype nerdtree setlocal nolist

let NERDTreeHighlightCursorline=1
let NERDTreeIgnore=['.vim$', '\~$', '.*\.pyc$', 'pip-log\.txt$', 'whoosh_index', 'xapian_index', '.*.pid', 'monitor.py', '.*-fixtures-.*.json', '.*\.o$', 'db.db']

" PLUGINS - SPARKUP //////////////////////////////////////////////////////////////////////////////////////////

let g:sparkupNextMapping = '<c-s>'

" PLUGINS - SYNTASTIC ////////////////////////////////////////////////////////////////////////////////////////

let g:syntastic_enable_signs = 1
let g:syntastic_disabled_filetypes = ['html']
let g:syntastic_stl_format = '[%E{Error 1/%e: line %fe}%B{, }%W{Warning 1/%w: line %fw}]'
let g:syntastic_jsl_conf = '$HOME/.vim/jsl.conf'


" Shortcut for [] {{{

onoremap id i[
onoremap ad a[
vnoremap id i[
vnoremap ad a[


" MACVIM ///////////////////////////////////////////////////////////////////////////////////////////

if has('gui_running')
  set guifont=DejaVu\ Sans\ Mono\ for\ Powerline:h14

  " Remove all the UI cruft
  set go-=T
  set go-=l
  set go-=L
  set go-=r
  set go-=R

  noremap <c-tab> :tabn<cr>
  noremap <c-s-tab> :tabp<cr>

  if has("gui_macvim")

      " PeepOpen on OS X, Command-T elsewhere.
      macmenu &File.New\ Tab key=<nop>
      " map <leader><leader> <Plug>PeepOpen

    "Use the normal HIG movements, except for M-Up/Down
      let macvim_skip_cmd_opt_movement = 1
      no   <D-Left>       <Home>
      no!  <D-Left>       <Home>
      no   <M-Left>       <C-Left>
      no!  <M-Left>       <C-Left>

      no   <D-Right>      <End>
      no!  <D-Right>      <End>
      no   <M-Right>      <C-Right>
      no!  <M-Right>      <C-Right>

      no   <D-Up>         <C-Home>
      ino  <D-Up>         <C-Home>
      imap <M-Up>         <C-o>{

      no   <D-Down>       <C-End>
      ino  <D-Down>       <C-End>
      imap <M-Down>       <C-o>}

      imap <M-BS>         <C-w>
      inoremap <D-BS>     <esc>my0c`y
  else
      map <leader><leader> :CommandT<cr>

      " Dammit, PeepOpen
      " map gxxxxx <Plug>PeepOpen
  end

  highlight SpellBad term=underline gui=undercurl guisp=Orange

  " Use a line-drawing char for pretty vertical splits.
  set fillchars+=vert:\│
  highlight VertSplit cterm=none gui=none

  " Different cursors for different modes.
  set guicursor=n-c:block-Cursor-blinkon0
  set guicursor+=v:block-vCursor-blinkon0
  " set guicursor+=i-ci:ver20-iCursor


else
    " Command-T if we don't have a GUI.
    " noremap <leader><leader> :CommandT<cr>

    " Dammit, PeepOpen
    map gxxxxx <Plug>PeepOpen
endif


nnoremap <Leader>s :%s/<c-r><c-w>/<c-r><c-w>/gc<Left><Left><Left>
