return {
	-- dracula
	{
		"Mofiqul/dracula.nvim",
		config = function()
			require("dracula").setup({
				colors = {
					comment = "#FFB86C",
				},
				transparent_bg = true,
			})
			vim.cmd("colorscheme dracula")
		end,
	},
}
