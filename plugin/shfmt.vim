" The "Vim shfmt" plugin runs shfmt and displays the results in Vim.
"
" Author:	 David Wooldridge
" URL:		 https://github.com/z0mbix/vim-shfmt
" Version:	 0.2
" Copyright: Copyright (c) 2017 David Wooldridge
" License:	 MIT
" ----------------------------------------------------------------------------

if exists("g:loaded_vimshfmt") || &cp || !executable('shfmt')
	finish
endif
let g:loaded_vimshfmt = 1

let s:save_cpo = &cpo
set cpo&vim

if !exists("g:shfmt_fmt_on_save")
	let g:shfmt_fmt_on_save = 0
endif

if !exists('g:shfmt_cmd')
	let g:shfmt_cmd = 'shfmt'
endif

" Options
if !exists('g:shfmt_extra_args')
	let g:shfmt_extra_args = ''
endif

let s:shfmt_switches = ['-p', '-i', '-bn', '-ci', '-ln', '-s']

function! s:ShfmtSwitches(...)
	return join(s:shfmt_switches, "\n")
endfunction

" Ref: 'rhysd/vim-clang-format' /autoload/clang_format.vim
function! s:has_vimproc() abort
	if !exists('s:exists_vimproc')
		try
			silent call vimproc#version()
			let s:exists_vimproc = 1
		catch
			let s:exists_vimproc = 0
		endtry
	endif
	return s:exists_vimproc
endfunction
function! s:success(result) abort
	let exit_success = (s:has_vimproc() ? vimproc#get_last_status() : v:shell_error) == 0
	return exit_success
endfunction

function! s:error_message(result) abort
	echohl ErrorMsg
	echomsg 'shfmt has failed to format.'
	for l in split(a:result, "\n")[0:1]
		echomsg l
	endfor
	echomsg ''
	echomsg ''
	echohl None
endfunction

let g:cnt = 0
function! s:Shfmt(current_args)
	let l:extra_args = g:shfmt_extra_args
	let l:shfmt_cmd = g:shfmt_cmd
	let l:shfmt_opts = ' ' . a:current_args . ' ' . l:extra_args
	if a:current_args != ''
		let l:shfmt_opts = a:current_args
	endif
	let l:source = join(getline(1, '$'), "\n")
	let l:shfmt_output = system(l:shfmt_cmd . ' ' . l:shfmt_opts, l:source)
	if s:success(l:shfmt_output)
		let l:view = winsaveview()
		let l:n=strlen(l:shfmt_output)
		normal! ggVG"_x
		call setline(1,split(l:shfmt_output, "\n"))
		silent call winrestview(l:view)
	else
		call s:error_message(l:shfmt_output)
	endif
endfunction

augroup shfmt
	autocmd!
	if get(g:, "shfmt_fmt_on_save", 1)
		autocmd BufWritePre *.sh Shfmt
		autocmd FileType sh autocmd BufWritePre <buffer> Shfmt
	endif
augroup END

command! -bar -complete=custom,s:ShfmtSwitches -nargs=? Shfmt :call <SID>Shfmt(<q-args>)

let &cpo = s:save_cpo
