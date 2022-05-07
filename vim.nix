{ vim_configurable, vimPlugins, isDarwin, home-directory, ... }:

let
  vim = (vim_configurable.override {
    guiSupport = "no";
    darwinSupport = isDarwin;
  }).customize {
    name = "vim";
    vimrcConfig = {
      packages.myVimPackage = with vimPlugins; {
        start = [
          ale
          coc-nvim
          coc-rls
          vim-go
          vim-airline
          vim-airline-themes
        ];
      };

      customRC = ''
        " Disable Vi compatability,
        " fixes some issues with Vim
        set nocompatible

        " Enables copying from buffer
        " to system clipboard, and vice
        " versa
        set clipboard^=unnamed,unnamedplus

        " Enables syntax highlighting
        syntax on
        
        " Some file type detection stuff
        " I don't quite understand...
        " Plus UTF-8 encode all files.
        filetype on
        filetype plugin on
        filetype indent on
        set encoding=utf-8
        set fileencoding=utf-8

        " Enables backspacing
        set backspace=indent,eol,start

        " Set tabs to spaces, other
        " somewhat obvious settings
        set tabstop=4
        set shiftwidth=4
        set softtabstop=0
        set autoindent
        set expandtab
        set nowrap
        set number

        " Enable mouse in Vim
        set mouse=a

        " Enables Vim Airline plugin.
        " Specifically, using deus theme.
        let g:airline#extensions#coc#enabled = 1
        let g:airline_theme='deus'

        " COC.nvim
        set hidden
        set nobackup
        set nowritebackup
        set cmdheight=2
        set shortmess+=c
        set signcolumn=auto

        " Use tab for trigger completion with characters ahead and navigate.
        " NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
        " other plugin before putting this into your config.
        inoremap <silent><expr> <TAB>
              \ pumvisible() ? "\<C-n>" :
              \ <SID>check_back_space() ? "\<TAB>" :
              \ coc#refresh()
        inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
        function! s:check_back_space() abort
          let col = col('.') - 1
          return !col || getline('.')[col - 1]  =~# '\s'
        endfunction

        " Use <c-space> to trigger completion.
        if has('nvim')
          inoremap <silent><expr> <c-space> coc#refresh()
        else
          inoremap <silent><expr> <c-@> coc#refresh()
        endif

        " Remap keys for gotos
        nmap <silent> gd <Plug>(coc-definition)
        nmap <silent> gy <Plug>(coc-type-definition)
        nmap <silent> gi <Plug>(coc-implementation)
        nmap <silent> gr <Plug>(coc-references)

        " ALE settings.
        let g:airline#extensions#ale#enabled = 1
        let g:ale_disable_lsp = 1
        let g:ale_lint_on_save = 1
        let g:ale_fix_on_save = 1
        let g:ale_fixers = {
          \"go": [
            \"gofmt",
            \"goimports",
            \"trim_whitespace",
            \"remove_trailing_lines"
          \],
          \"rust": [
              \"rustfmt",
              \"trim_whitespace",
              \"remove_trailing_lines"
          \],
        \}
        let g:ale_linters = {
          \"go": [
            \"gotype",
            \"golint",
            \"gopls",
            \"gobuild",
            \"govet"
          \],
          \"rust": [
            \"analyzer"
          \],
        \}
        highlight ALEError ctermbg=darkred cterm=underline 
        highlight ALEWarning ctermbg=brown cterm=underline

        " Go settings.
        " Turn off gopls (coc.nvim already running)
        let g:go_gopls_enabled = 0
        let g:go_def_mapping_enabled = 0
        let g:go_code_completion_enabled = 0
        let g:go_auto_type_info = 0
        let g:go_jump_to_error = 0
        let g:go_fmt_autosave = 0
        let g:go_mod_fmt_autosave = 0
        let g:go_doc_keywordprg_enabled = 0
        let g:go_highlight_extra_types = 1
        let g:go_highlight_operators = 1
        let g:go_highlight_functions = 1
        let g:go_highlight_function_parameters = 1
        let g:go_highlight_function_calls = 1
        let g:go_highlight_types = 1
        let g:go_highlight_fields = 1
        let g:go_highlight_build_constraints = 1
        let g:go_highlight_variable_declarations = 1
        let g:go_highlight_variable_assignments = 1
        let g:go_highlight_diagnostic_errors = 0
        let g:go_highlight_diagnostic_warnings = 0

        let g:go_bin_path="${home-directory}/.vim/vim-go/bin"
     '';
    };
  };
in
  vim
