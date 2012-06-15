let g:CompleteNearestTriggerKey = "<D-j>"
"let g:CompleteNearestWordChars = '[0-9A-Za-z_\-]'
" Not used at the moment: better to change iskeyword, I think


" Comparison function used for sorting a list of lists.
" Sorts based on the first value of each sublist
func! s:FirstListItemCompare(i1, i2)
   return a:i1[0] ==# a:i2[0] ? 0 : a:i1[0] > a:i2[0] ? 1 : -1
endfunc



" Finds all the words starting with a:base and returns them along with the
" distance in lines from the initial cursor position:
"      [[first_word_line_distance, first_word], [second_word_line_distance, second_word], ...]
" Searches above or below the cursor based on a:go_backwards
func! s:FindWords(base, go_backwards)

  let flags = ''
  if a:go_backwards
    let flags = 'b'
  endif

  let orig_cursor = getpos('.') 
  let words = []

  let start = searchpos('\<' . a:base, 'W' . flags)
  while start !=# [0, 0]
    let end = searchpos('\>', 'W')
    " If we moved to a new line it's an exact match, which we don't want
    " anyway
    if start[0] ==# end[0]
      let word = getline('.')[start[1]-1:end[1]-2]
      if word !=? a:base
        if a:go_backwards
          let line_dist = orig_cursor[1] - start[0]
        else
          let line_dist = start[0] - orig_cursor[1]
        endif
        call add(words, [line_dist, word])
      endif
    endif
    call cursor(start)
    let start = searchpos('\<' . a:base, 'W' . flags)
  endwhile

  call cursor(orig_cursor[1], orig_cursor[2])

  return words

endfunc





" The completefunc for nearest-word completion
" TODO: Ignore comments and keywords?
func! CompleteNearest(findstart, base) 

  if a:findstart 

    " locate the start of the word 
    let line = getline('.') 
    let start = col('.') - 1 
    while start > 0 && line[start - 1] =~ '\a' 
      let start -= 1 
    endwhile 
    return start 

  else 

    " Don't show anything if we're searching for the empty string
    if a:base ==# ''
      return []
    endif

    let words = s:FindWords(a:base, 0) + s:FindWords(a:base, 1)

    " Order the words by distance from the original cursor position
    let sorted = sort(words, "s:FirstListItemCompare")

    " Remove the distance variable and any duplicates
    let res = []
    for i in sorted
      if index(res, i[1]) == -1
        call add(res, i[1])
      endif
    endfor

    return res

  endif 
endfun

set completefunc=CompleteNearest

" Pressing g:CompleteNearestTriggerKey opens the autocomplete popup, or moves
" to the next option if the popup is already open
inoremap <silent><expr> <D-j>      pumvisible() ? "\<C-n>" : "\<C-x><C-u>"
"exec 'imap ' . g:CompleteNearestTriggerKey . ' pumvisible() ? ' . "\<C-n>" . ' : ' . "\<C-x><C-u>"
" Pressing <esc> when the omnicomplete menu is shown doesn't exit insert mode
imap <expr> <Esc>      pumvisible() ? "\<C-e>" : "\<Esc>"
" Pressing <CR> when the omnicomplete menu selects the current option and
" closes the popup
imap <expr> <CR>       pumvisible() ? "\<C-y>" : "\<CR>"
