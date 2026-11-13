# vim-ohh

Plain-Vim (not Neovim) support for OHH (.ohh), same L0-only scope as `vim-phh`:
plain Vim has no tree-sitter and no built-in LSP client, so L1 comes from
`ohh-ls` through a general-purpose LSP plugin, documented below, not a
bespoke plugin shipped here.

## Install

Add this directory to `'runtimepath'` before `filetype on`/`syntax on`
run (e.g. `set runtimepath+=/path/to/vim-ohh` in your `vimrc`). Needs
`:filetype on` and `:syntax on` enabled.

## What's implemented (L0)

- **Filetype detection** (`ftdetect/ohh.vim`): `.ohh` → `ohh`.
- **Syntax highlighting** (`syntax/ohh.vim`): structurally adapted from
  Vim's own bundled MIT-licensed `$VIMRUNTIME/syntax/json.vim`, keys, strings, numbers, booleans,
  `null`, braces/brackets. One OHH-specific addition: the *value* string
  of the four registry-enum-valued keys (`game_type`, `bet_type`,
  `street`, `action`) gets its own highlight group
  (`ohhEnumValueString`), mirroring `tree-sitter-ohh/queries/highlights.scm`
  and `vscode-ohh/syntaxes/ohh.tmLanguage.json`'s own special-casing of
  the same four keys.
- **ftplugin** (`ftplugin/ohh.vim`): deliberately near-empty, OHH has no
  comment syntax to configure (confirmed, not assumed: JSON itself has
  none), unlike `vim-phh`'s `#`-comment setup.

## L1: diagnostics and hover via ohh-ls

No bespoke plugin here, same reasoning as `vim-phh`. Point any general
LSP client at `../ohh-ls/build/ohh-ls ../ohh/registry` for filetype
`ohh`. For [vim-lsp](https://github.com/prabirshrestha/vim-lsp):

```vim
if executable('ohh-ls')
  au User lsp_setup call lsp#register_server({
      \ 'name': 'ohh-ls',
      \ 'cmd': {server_info->['/path/to/ohh-ls/build/ohh-ls', '/path/to/ohh/registry']},
      \ 'allowlist': ['ohh'],
      \ 'root_uri': {server_info->lsp#utils#path_to_uri(fnamemodify(lsp#utils#get_buffer_path(), ':p:h'))},
      \ })
endif
```

**`root_uri` is included from the start here**, `vim-phh/README.md`
already paid the cost of discovering it's required (without it, vim-lsp
silently skips initialization); no need to rediscover that for OHH.
This snippet has the same "not independently re-verified end-to-end"
status `vim-phh`'s does, see that package's README for exactly what was
and wasn't confirmed about vim-lsp's full handshake in this project's
test harness.

For [coc.nvim](https://github.com/neoclient/coc.nvim):

```json
{
  "languageserver": {
    "ohh": {
      "command": "/path/to/ohh-ls/build/ohh-ls",
      "args": ["/path/to/ohh/registry"],
      "filetypes": ["ohh"]
    }
  }
}
```

## How this was verified, and two real things testing caught

`test/synid_test.vim` drives real Vim (`vim -N -u NONE -es`) against the
real corpus (`../ohh/corpus/`), reading back the actual resolved
highlight group at specific positions via `synID()`/`synstack()`, same
discipline as `vim-phh`. **19/19 checks pass.**

Writing this file deliberately probed two risks before trusting them,
rather than assuming either a problem or its absence:

1. **A real bug, found and fixed.** The enum-value rule
   (`ohhEnumValueString`) was first written with its key/colon context
   as ordinary text *before* `\zs`, the same general shape as reaching
   for a lookahead/lookbehind. Testing showed it never matched at all, `synstack()` came back completely empty at the value's position.
   The cause: the pattern's *full* (untrimmed) match starts at the key's
   own opening quote, where it loses the scan-position contest to
   `ohhKeyMatch` (which also starts there) before `\zs` ever gets a
   chance to matter. Fixed by rewriting the context as a genuine
   zero-width lookbehind (`\@<=`) instead, the same technique already
   used (and already working, confirmed by the same test) for
   `ohhStringMatch`'s *exclusion* of these same four keys via `\@<!`.
2. **A real worry, tested and found not to apply.** `vim-phh/README.md`
   documents Vim's syntax engine treating a plain (non-`contained`)
   match as "ambient" inside an unrelated region, regardless of that
   region's own `contains=` list. `ohhNoise`'s `:` match is exactly such
   an item, so a colon inside an ISO-8601 timestamp *value* (inside the
   `oneline` `ohhString` region) seemed like a plausible place for the
   same quirk to resurface in this package. It does not, confirmed via
   `synstack()` that the position resolves to `ohhString`, not
   `ohhNoise`. Recorded as a verified negative result, not assumed safe
   because it compiled.

Also confirmed empirically rather than assumed: the trailing
comma/brace/bracket lookahead on `ohhNumber`/`ohhBoolean` correctly
spans a real line break (e.g. `"amount": 0.77` as the last field in its
object, with the closing `}` on the following, indented line), and a
digit-only or keyword-shaped *string value* (e.g. `"game_number":
"226935652098"`) is never mistaken for a bare number by an ambient
match, both risks that bit, or could plausibly have bitten, other
grammars in this project.

## What's NOT attempted here, and why

Unlike `vim-phh`, **no feature was dropped due to a genuine Vim
syntax-engine limit**, OHH's flat key/value shape doesn't need the kind
of nested-region exclusivity (one region's `contains=` trying to
*forbid* an ambient generic rule from firing inside it) that caused
`vim-phh` to drop its action-notation sub-grammar and dedicated
variant-value highlights. Every feature attempted here shipped.
