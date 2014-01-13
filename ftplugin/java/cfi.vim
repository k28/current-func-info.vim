" vim:foldmethod=marker:fen:
scriptencoding utf-8


if get(g:, 'cfi_disable') || get(g:, 'loaded_cfi_ftplugin_java')
    finish
endif
let g:loaded_cfi_ftplugin_java = 1

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}
"

let s:FUNCTION_PATTERN = '\C'.'\(\w\+\)\s*('

let s:finder = cfi#create_finder('java')

function! s:finder.get_func_name() "{{{
	let NONE = ''
	if self.phase isnot 2 || !has_key(self.temp, 'funcname')
		return NONE
	endif

	return self.temp.funcname
endfunction " }}}

function! s:finder.find_begin() "{{{
    let NONE = []
    let [orig_lnum, orig_col] = [line('.'), col('.')]

    let vb = &vb
    setlocal vb t_vb=
    try
        " Jump to function-like word, and check arguments, and block.
		normal! [m
        while 1
			if search(s:FUNCTION_PATTERN, 'bW') == 0
				return NONE
			endif

            let funcname = get(matchlist(getline('.'), s:FUNCTION_PATTERN), 1, '')
            if funcname ==# ''
                return NONE
            endif

            for [fn; args] in [
            \   ['search', '(', 'W'],
            \   ['searchpair', '(', '', ')'],
            \]
                if call(fn, args) == 0
                    return NONE
                endif
            endfor

			let self.temp.funcname = funcname

			break
        endwhile
    finally
        let &vb = vb
    endtry

    if search('{') == 0
        return NONE
    endif
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
    normal! ]M
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

call cfi#register_finder('java', s:finder)
unlet s:finder


let &cpo = s:save_cpo
