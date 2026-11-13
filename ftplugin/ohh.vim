" Buffer-local settings for OHH files. OHH has no comment syntax at all
" (confirmed, not assumed, JSON itself has none), so unlike
" vim-phh/ftplugin/phh.vim there is no commentstring/comments to set here.
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1
