local opt = vim.opt

-- line numbers
opt.number = true
opt.relativenumber = true

-- tabs & indentation
opt.tabstop = 4
opt.shiftwidth = 4
-- タブキーで半角スペースを挿入する
opt.expandtab = true
opt.autoindent = true

-- line wrapping
opt.wrap = false

-- search settings
opt.ignorecase = true
opt.smartcase = true
opt.iskeyword:append("-")

-- cousor line
opt.cursorline = true
opt.startofline = true

-- appearance
opt.signcolumn = "yes"

-- clipboard
opt.clipboard:append("unnamedplus")
-- vim.g.clipboard = {
--     name = "xclip",
--     copy = {
--         ["+"] = { "xclip", "-quiet", "-i", "-selection", "clipboard" },
--         ["*"] = { "xclip", "-quiet", "-i", "-selection", "primary" },
--     },
--     paste = {
--         ["+"] = { "xclip", "-o", "-selection", "clipboard" },
--         ["*"] = { "xclip", "-o", "-selection", "primary" },
--     },
--     cache_enabled = 1
-- }

-- fold
opt.foldenable = false

-- switch options by file type
local my_filetype = require("core.filetype")
vim.api.nvim_create_augroup("vimrc_augroup", {})
vim.api.nvim_create_autocmd("FileType", {
	group = "vimrc_augroup",
	pattern = "*",
	callback = function(args)
		-- args.match に対応するファイルタイプ関数が存在するか確認
		local filetype_func = my_filetype[args.match]
		if filetype_func then
			filetype_func()
		else
			-- デフォルトのインデント設定（例: 4スペース）を設定
			my_filetype.default()
		end
	end,
})
