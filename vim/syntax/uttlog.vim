if exists("b:current_syntax")
  finish
end

" Define syntax highlighting for the uttlog filetype
syntax match uttlogDate "^\d\{4}-\d\{2}-\d\{2}"
syntax match uttlogTime "\<\d\{2}:\d\{2}\>"
syntax match uttlogCategory "\<[^0-9]\+:"
syntax match uttlogTask "\<\k\+\( \|$\)"
syntax match uttlogBreak "\*\*$"
syntax match uttlogIgnore "\*\*\*$"

" Highlight groups
hi def link uttlogDate Function
hi def link uttlogTime Number
hi def link uttlogCategory Type
hi def link uttlogTask Normal
hi def link uttlogBreak Operator
hi def link uttlogIgnore Operator

let b:current_syntax = 'uttlog'
