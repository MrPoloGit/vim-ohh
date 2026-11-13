" synID()-based verification for syntax/ohh.vim, run via:
"   vim -N -u NONE -es -c "source vim-ohh/test/synid_test.vim"
"
" Same discipline as vim-phh/test/synid_test.vim: checks the real
" resolved highlight group at specific positions in real corpus files via
" synID()/synIDattr(), not by reading the syntax file and assuming it
" behaves as written. In particular this probes the two risks reasoned
" about while writing syntax/ohh.vim rather than assumed safe:
"   1. a trailing comma/brace/bracket lookahead spanning a real line
"      break (a number or boolean that is the LAST field in an object,
"      with the closing `}` on the next, indented line), the exact kind
"      of case this project's testing discipline has caught real bugs in
"      before (tree-sitter-phh's string rule, vscode-phh's card regex).
"   2. a digit-only or keyword-shaped STRING VALUE (e.g. "game_number":
"      "226935652098") is not mistaken for a bare number/keyword by an
"      ambient (non-contained) match, this project's vim-phh package
"      already found that Vim's `contains=` is not an exhaustive
"      allow-list, so a naive number/boolean pattern could bleed into a
"      string region if its own lookahead doesn't rule that out.

set nocompatible
let g:ohh_root = fnamemodify(getcwd(), ':p')
let &runtimepath = &runtimepath . ',' . g:ohh_root . 'vim-ohh'
syntax on
filetype on

let s:failures = 0
let s:report = []

function! s:Check(label, cond)
  if a:cond
    call add(s:report, '[ok] ' . a:label)
  else
    call add(s:report, '[FAIL] ' . a:label)
    let s:failures += 1
  endif
endfunction

function! s:GroupAt(line, col)
  return synIDattr(synID(a:line, a:col, 1), 'name')
endfunction

" 1. ftdetect + syntax load.
execute 'edit ' . g:ohh_root . 'ohh/corpus/valid/holdem-cash-pokerstars.ohh'
call s:Check('ftdetect sets filetype=ohh', &filetype ==# 'ohh')
call s:Check('syntax item defined (b:current_syntax)', get(b:, 'current_syntax', '') ==# 'ohh')

" 2. Key vs. value-string distinction (line 7: "game_type": "Holdem").
"    The opening/closing quote CHARACTERS get the matchgroup-assigned
"    ohhQuote group, not the region's own ohhKey/ohhString group, same
"    design as Vim's own bundled json.vim (matchgroup=jsonQuote), so
"    these checks target a quote character and a content character
"    separately, rather than assuming both would report the same group.
call s:Check('line 7 col 9  ("game_type" key, opening quote char) is ohhQuote',  s:GroupAt(7, 9)  ==# 'ohhQuote')
call s:Check('line 7 col 12 (inside "game_type" key) is ohhKey',         s:GroupAt(7, 12) ==# 'ohhKey')

" 3. The enum-value special-case (game_type's VALUE, not an ordinary
"    string), mirroring tree-sitter-ohh/queries/highlights.scm and
"    vscode-ohh/syntaxes/ohh.tmLanguage.json's own special-casing of the
"    same four keys. ohhEnumValueString is a single flat `match` (no
"    matchgroup split), so its opening quote IS part of its own group.
call s:Check('line 7 col 22 (opening quote of "Holdem" value) is ohhEnumValueString',
      \ s:GroupAt(7, 22) ==# 'ohhEnumValueString')
call s:Check('line 7 col 25 (inside "Holdem" value) is ohhEnumValueString',
      \ s:GroupAt(7, 25) ==# 'ohhEnumValueString')

" 4. An ordinary string value (network_name, line 5) must stay ohhString,
"    NOT get the enum-value treatment meant only for the four named keys.
"    Col 26 is content (col 25 is the matchgroup-assigned opening quote).
call s:Check('line 5 col 26 (inside "PokerStars" value of network_name) is plain ohhString, not ohhEnumValueString',
      \ s:GroupAt(5, 26) ==# 'ohhString')

" 5. A digit-only STRING VALUE (game_number, line 13) must stay ohhString,
"    never ohhNumber, the ambient-match risk named above. Col 25 is the
"    first actual digit (col 24 would be the opening quote).
call s:Check('line 13 col 25 (first digit of "226935652098" inside quotes) is ohhString, not ohhNumber',
      \ s:GroupAt(13, 25) ==# 'ohhString')
call s:Check('line 13 col 36 (last digit of "226935652098" inside quotes) is ohhString, not ohhNumber',
      \ s:GroupAt(13, 36) ==# 'ohhString')

" 6. A genuine bare number (table_size, line 12) is ohhNumber.
call s:Check('line 12 col 23 (the "9" in table_size) is ohhNumber', s:GroupAt(12, 23) ==# 'ohhNumber')

" 7. The cross-line-boundary case: "amount": 0.77 is the LAST field in its
"    object, with the closing "}" on the FOLLOWING line (no trailing
"    comma on this line at all), confirms the lookahead actually spans
"    the real line break rather than silently failing to match.
call s:Check('line 271 col 27 (the "0" of 0.77, last field before a closing brace on the next line) is ohhNumber',
      \ s:GroupAt(271, 27) ==# 'ohhNumber')

" 8. Same cross-line-boundary case for a boolean: "is_allin": true is the
"    last field in its action object, closing "}" on the next line.
call s:Check('line 190 col 37 ("true", last field before a closing brace on the next line) is ohhBoolean',
      \ s:GroupAt(190, 37) ==# 'ohhBoolean')

" 9. Tested a real worry before trusting it: vim-phh's README documents
"    Vim's syntax engine treating a plain (non-contained) match as
"    "ambient" inside an unrelated region, regardless of that region's
"    own contains= list. ohhNoise's ":" match is exactly such a plain,
"    non-contained item, so a colon inside an ISO-8601 timestamp VALUE
"    (ohhString's span) seemed like a plausible place for the same
"    quirk to resurface. It does NOT: confirmed via synstack() that this
"    position resolves to ohhString, not ohhNoise, a single `oneline`
"    region with no competing nested region apparently does not exhibit
"    vim-phh's finding, which involved more complex nested-region
"    competition. Recorded as a verified negative result, not assumed.
call s:Check('line 14 col 41 (a ":" inside the "...T07:53:30" timestamp VALUE) is correctly ohhString, not ambiently ohhNoise',
      \ s:GroupAt(14, 41) ==# 'ohhString')

" 10. Full-corpus sweep: every valid/invalid fixture loads with
"     filetype=ohh and the syntax file applied, no crash.
for path in glob(g:ohh_root . 'ohh/corpus/valid/*.ohh', 0, 1)
      \ + glob(g:ohh_root . 'ohh/corpus/invalid/*.ohh', 0, 1)
  execute 'edit ' . fnameescape(path)
  call s:Check(fnamemodify(path, ':t') . ': loads with filetype=ohh and syntax applied',
        \ &filetype ==# 'ohh' && get(b:, 'current_syntax', '') ==# 'ohh')
endfor

call add(s:report, '')
if s:failures > 0
  call add(s:report, s:failures . ' FAILURE(S)')
else
  call add(s:report, 'All checks passed.')
endif
call writefile(s:report, g:ohh_root . 'vim-ohh/test/synid_test_output.txt')

if s:failures > 0
  cquit!
else
  qa!
endif
