return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",

				-- `cond` is a condition used to determine whether this plugin should be
				-- installed and loaded.
				-- Some server might not have the make installed.
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
		},
		config = function()
			require("telescope").setup({
				extensions = {
					-- FZF makes Telescope searching faster
					fzf = {},
				},
			})

			require("telescope").load_extension("fzf")

			-- TODO: Need to set up more shortcurts
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "Telescope find files" })
			-- NOTE: Fuzzy find a word in the current file
			vim.keymap.set("n", "<leader>g", function()
				builtin.grep_string({
					shorten_path = true,
					word_match = "-w",
					only_sort_text = true,
					search = "", -- You can specify a default search string here if desired
				})
			end, { desc = "Telescope: Search Current Word" })
			vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "[ ] Find existing buffers" })
		end,
	},
}
