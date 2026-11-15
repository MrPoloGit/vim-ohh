" Vim syntax file for OHH (Open Hand History, .ohh), 
"
" Structurally adapted (match/region split to avoid "a region by itself is
" always greedy", and the key-vs-value lookahead distinction) from Vim's
" own bundled MIT-licensed $VIMRUNTIME/syntax/json.vim (Vito, Eli Parra and
" contributors), OHH is plain JSON, so this starts from a proven base
" rather than reinventing JSON highlighting, per
" 's own suggestion. Everything OHH-
" specific (the enum-value highlight below; no error-warning patterns, no
" JSONP padding, no concealing) is new.
"
" Unlike vim-phh, nothing here hit Vim's contains=-is-not-exhaustive
" precedence quirk, and deliberately so: every rule below is either a
" single flat `match` (no containment question arises at all) or uses a
" negative lookbehind to make two patterns mutually exclusive by
" construction, rather than relying on `contains=` to carve an exception
" out of an ambient rule, or on same-position match priority to pick a
" winner. Confirmed by testing (see test/synid_test.vim), not assumed safe
" by design alone.

if exists("b:current_syntax")
  finish
endif

syn match ohhNoise /\%(:\|,\)/

" Keys: a quoted string immediately followed by a colon.
syn match ohhKeyMatch /"\%([^"\\]\|\\.\)*"\ze[[:blank:]\r\n]*:/ contains=ohhKey
syn region ohhKey matchgroup=ohhQuote start=/"/ end=/"\ze[[:blank:]\r\n]*:/ contained

" Enum-valued fields (ohh-data/registry/enums.json: game_type, bet_type, street,
" action) get their VALUE string highlighted distinctly, mirroring
" tree-sitter-ohh/queries/highlights.scm's #any-of? special-casing and
" vscode-ohh/syntaxes/ohh.tmLanguage.json's lookbehind-based rule. The
" generic value-string pattern below excludes exactly this text via a
" negative lookbehind (\@<!), so there is no same-start-position
" competition between the two rules to begin with, a different, more
" robust strategy than vim-phh's dropped variant-pair attempt, which
" relied on relative rule-definition order and broke when an unrelated
" rule was inserted elsewhere.
" Written with a zero-width lookbehind (\@<=) for the key/colon context,
" NOT as literal text before \zs, found necessary by testing, not
" assumed: embedding the context as ordinary pre-\zs text makes the
" pattern's full (untrimmed) match start at the KEY's own opening quote,
" which loses the scan-position contest to ohhKeyMatch (defined above,
" also starting there) before \zs ever gets a chance to matter, the
" rule simply never fired, confirmed via synstack() showing an empty
" stack at the value's position. A zero-width lookbehind assertion does
" not own/consume that leading position the same way, so this version
" correctly starts its match at the value's own opening quote instead.
syn match ohhEnumValueString /\%("\%(game_type\|bet_type\|street\|action\)"[[:blank:]\r\n]*:[[:blank:]\r\n]*\)\@<="\%([^"\\]\|\\.\)*"\ze[[:blank:]\r\n]*[,}\]]/ contains=ohhEscape

" Ordinary value strings: a quoted string immediately followed by `,`,
" `}` or `]`, NOT immediately preceded by one of the four enum keys above.
syn match ohhStringMatch /\%("\%(game_type\|bet_type\|street\|action\)"[[:blank:]\r\n]*:[[:blank:]\r\n]*\)\@<!"\%([^"\\]\|\\.\)*"\ze[[:blank:]\r\n]*[,}\]]/ contains=ohhString
syn region ohhString oneline matchgroup=ohhQuote start=/"/ skip=/\\\\\|\\"/ end=/"/ contains=ohhEscape contained

syn match ohhEscape "\\[\"\\/bfnrt]" contained
syn match ohhEscape "\\u\x\{4}" contained

syn match ohhNumber "-\=\<\%(0\|[1-9]\d*\)\%(\.\d\+\)\=\%([eE][-+]\=\d\+\)\=\>\ze[[:blank:]\r\n]*[,}\]]"

" Boolean/null: same trailing-lookahead discipline as ohhNumber/ohhStringMatch
" above, and for the same reason, not primarily to detect malformed JSON,
" but because a bare \<true\>-style keyword with no such lookahead is
" "ambient" : it would
" incorrectly fire on the literal substring "true" inside an unrelated
" quoted string. Requiring what follows to be (only whitespace then)
" `,`/`}`/`]`, never a bare `"`, means a `true` appearing mid-string
" (always followed by more string content or a closing quote first) can
" never satisfy this lookahead, so no exclusion rule is needed here the
" way ohhStringMatch needed one for the enum keys.
syn match ohhBoolean "\<\%(true\|false\)\>\ze[[:blank:]\r\n]*[,}\]]"
syn match ohhNull "\<null\>\ze[[:blank:]\r\n]*[,}\]]"

syn region ohhFold matchgroup=ohhBraces start="{" end="}" transparent fold
syn region ohhFold matchgroup=ohhBraces start="\[" end="\]" transparent fold

hi def link ohhKey              Label
hi def link ohhQuote            Quote
hi def link ohhString           String
hi def link ohhEnumValueString  Special
hi def link ohhEscape           Special
hi def link ohhNumber           Number
hi def link ohhBoolean          Boolean
hi def link ohhNull             Function
hi def link ohhBraces           Delimiter
hi def link ohhNoise            Delimiter

let b:current_syntax = "ohh"
