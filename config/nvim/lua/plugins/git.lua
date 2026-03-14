return {
    {
        "rhysd/committia.vim",
        config = function()
            vim.cmd([[
                let g:committia_hooks = {}
                let g:committia_edit_window_width = 60
                let g:committia_min_window_width = 100
                function! g:committia_hooks.edit_open(info)
                    imap <buffer><C-n> <Plug>(committia-scroll-diff-down-half)
                    nmap <buffer><C-n> <Plug>(committia-scroll-diff-down-half)
                    imap <buffer><C-p> <Plug>(committia-scroll-diff-up-half)
                    nmap <buffer><C-p> <Plug>(committia-scroll-diff-up-half)
                endfunction
            ]])
        end,
    },
}
