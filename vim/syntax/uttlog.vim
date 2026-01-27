if exists("b:current_syntax")
  finish
end

" Define syntax highlighting for the uttlog filetype
syntax match uttlogDate "^\d\{4}-\d\{2}-\d\{2}"
syntax match uttlogTime "\<\d\{2}:\d\{2}\>"
syntax match uttlogTask "\<\k\+\( \|$\)"
syntax match uttlogBreak "\*\*$"
syntax match uttlogIgnore "\*\*\*$"
syntax match uttlogHello "\<\(hello\)\ze"

let s:projects_file = '/mnt/d/val/time/utt.projects'
if filereadable(s:projects_file)
  let s:categories = []
  let s:lines = readfile(s:projects_file)

  " Trim whitespace, ignore empty lines and comments
  for l in s:lines
    let l = trim(l)
    if empty(l) || l =~# '^#'
      continue
    endif
    call add(s:categories, l)
  endfor
  execute 'syntax match uttlogSpecialCategory "\<\%('
        \ . join(s:categories, '\|')
        \ . '\)\>\ze:"'
endif

" Highlight groups
hi def link uttlogDate Function
hi def link uttlogTime Number
hi def link uttlogTask Normal
hi def link uttlogBreak Operator
hi def link uttlogIgnore Operator
hi def link uttlogHello Keyword
hi def link uttlogSpecialCategory Identifier

let b:current_syntax = 'uttlog'
