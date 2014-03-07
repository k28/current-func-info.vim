scriptencoding utf-8

if get(g:, 'cfi_disable') || get(g:, 'loaded_cfi_ftplugin_objc')
    finish
endif
let g:loaded_cfi_ftplugin_objc = 1

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

let s:FUNCTION_PATTERN = '\C'.'\s*-\s*(\s*\w\+\s*\*\?)\s*\(\w\+\)\s*'
let s:FUNCTION_VAR_PATTERN = '\C' . '\(\w\+\)\s*:\s*('

let s:finder = cfi#create_finder('objc')

function! s:finder.get_func_name() " {{{
	let NONE = ''
	if self.phase isnot 2 || !has_key(self.temp, 'funcname')
		return NONE
	endif

	return self.temp.funcname
endfunction "}}}

function! s:finder.find_begin() " {{{
	let NONE = []
	let [orig_lnum, orig_col] = [line('.'), col(',')]

	let vb = &vb
	setlocal vb t_vb=
	try
		" Junp to function-like word, and check arguments, and block.
		while 1
			if search(s:FUNCTION_PATTERN, 'bw') == 0
				return NONE
			endif

			let line = getline('.')
			let funcname = get(matchlist(line, s:FUNCTION_PATTERN), 1, '')
			if funcname ==# ''
				return NONE
			endif

			" search start and end of the function name
			let func_start_lnum = line('.')
			if search('{', 'w') == 0
				return NONE
			endif
			let func_last_lnum = line('.')

			let search_index = match(line, ':') + 1
			let index = func_start_lnum
			while index <= func_last_lnum
				let line = getline(index)
				while 1
					let var_name = get(matchlist(line, s:FUNCTION_VAR_PATTERN, search_index), 1, '')
					if var_name ==# ''
						break
					else
						let funcname = funcname . ':' . var_name
						let search_index = match(line, ':', search_index) + 1
					endif
				endwhile

				let index += 1
				let search_index = 0
			endwhile

			if join(getline('.', '$'), '')[col('.') :] =~# '\s*[^;]'
				let self.temp.funcname = funcname
				break
			endif
		endwhile
	finally
		let &vb = vb
	endtry

	if line('.') == orig_lnum && col('.') == orig_col
		return NONE
	endif

	return [line('.'), col('.')]
endfunction "}}}

function! s:finder.find_end() "{{{
	let NONE = []
	let [orig_lnum, orig_col] = [line('.'), col('.')]

	let vb = &vb
	setlocal vb t_vb=
	keepjumps normal! ][
	let &vb = vb

	if line('.') == orig_lnum && col('.') == orig_col
		return NONE
	endif

	if getline('.')[col('.')-1] !=# '}'
		return NONE
	endif
	let self.is_ready = 1

	return [line('.'), col('.')]
endfunction "}}}

call cfi#register_finder('objc', s:finder)
unlet s:finder

let &cpo = s:save_cpo
