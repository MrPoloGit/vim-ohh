# vim-ohh

Vim support for OHH (.ohh).

## Install

Add this directory to `'runtimepath'` before `filetype on`/`syntax on`
run (e.g. `set runtimepath+=/path/to/vim-ohh` in your `vimrc`). Needs
`:filetype on` and `:syntax on` enabled.

**Not listed anywhere.** This repo is pushed to
`github.com/MrPoloGit/vim-ohh`, usable today by any plugin manager that
takes a plain git URL, but it isn't listed on vim.org, vimawesome, or
any other curated index, nothing has been submitted anywhere.

No bespoke plugin here, same reasoning as `vim-phh`. Point any general
LSP client at `../ohh-ls/build/ohh-ls ../ohh-data/registry` for filetype
`ohh`. For [vim-lsp](https://github.com/prabirshrestha/vim-lsp):

```vim
if executable('ohh-ls')
  au User lsp_setup call lsp#register_server({
      \ 'name': 'ohh-ls',
      \ 'cmd': {server_info->['/path/to/ohh-ls/build/ohh-ls', '/path/to/ohh-data/registry']},
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
      "args": ["/path/to/ohh-data/registry"],
      "filetypes": ["ohh"]
    }
  }
}
```
