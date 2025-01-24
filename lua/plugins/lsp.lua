return {
	{
		-- Tell Nvim more about lua configuration files (Get rid of some warnings)
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			-- We use mason to manage LSP for a specific language.
			{ "williamboman/mason.nvim", config = true },
			-- We use mason-lspconfig to tell nvim more capabilities.
			"williamboman/mason-lspconfig.nvim",
			-- We use mason-tool-installer to install LSP for a specific language
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			-- Allows extra capabilities provided by nvim-cmp
			"hrsh7th/cmp-nvim-lsp",

			-- Useful status updates for LSP.
			-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
			{ "j-hui/fidget.nvim", opts = {} },
		},
		config = function()
			--  This function gets run when an LSP attaches to a particular buffer.
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- Jump to the definition of the word under your cursor.
					--  This is where a variable was first declared, or where a function is defined, etc.
					--  To jump back, press <C-t>.
					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

					-- Find references for the word under your cursor.
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

					-- Jump to the implementation of the word under your cursor.
					--  Useful when your language has ways of declaring types without an actual implementation.
					map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

					-- Jump to the type of the word under your cursor.
					--  Useful when you're not sure what type a variable is and you want to see
					--  the definition of its *type*, not where it was *defined*.
					map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

					-- Fuzzy find all the symbols in your current document.
					--  Symbols are things like variables, functions, types, etc.
					map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

					-- Fuzzy find all the symbols in your current workspace.
					--  Similar to document symbols, except searches over your entire project.
					map(
						"<leader>ws",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[W]orkspace [S]ymbols"
					)

					-- Rename the variable under your cursor.
					--  Most Language Servers support renaming across files, etc.
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

					-- Execute a code action, usually your cursor needs to be on top of an error
					-- or a suggestion from your LSP for this to activate.
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

					-- WARN: This is not Goto Definition, this is Goto Declaration.
					--  For example, in C this would take you to the header.
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					-- Toggle Hints
					map("<leader>th", function()
						local currently_enabled = vim.lsp.inlay_hint.is_enabled({})
						vim.lsp.inlay_hint.enable(not currently_enabled, {})
					end, "[T]oggle [H]ints")
				end,
			})

			-- LSP servers and clients are able to communicate to each other what features they support.
			--  By default, Neovim doesn't support everything that is in the LSP specification.
			--  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
			--  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			-- Enable the following language servers
			local servers = {
				clangd = {},
				-- gopls = {},
				pyright = {},
				lua_ls = {},
				rust_analyzer = {},
				verible = {
					cmd = { "verible-verilog-ls", "--rules=-line-length,-no-tabs" },
				},
			}
			-- Ensure the servers and tools above are installed
			require("mason").setup()

			-- You can add other tools here that you want Mason to install
			-- for you, so that they are available from within Neovim.
			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"stylua", -- Used to format Lua code
				"isort", -- Used to format python code
				"black", -- Used to format python code
				"clang-format", -- Used to format c code
				"verible", -- Used to format verilog and systemverilog code
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			---@diagnostic disable-next-line: missing-fields
			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},
	{
		"scalameta/nvim-metals",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		ft = { "scala", "sbt", "java" },
		opts = function()
			local metals_config = require("metals").bare_config()
			metals_config.init_options = {
				statusBarProvider = "on",
			}
			return metals_config
		end,
		config = function(self, metals_config)
			require("metals").initialize_or_attach(metals_config)
			local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = self.ft,
				callback = function()
					require("metals").initialize_or_attach(metals_config)
				end,
				group = nvim_metals_group,
			})
			-- vim.api.nvim_create_autocmd("FileType", {
			-- 	pattern = self.ft,
			-- 	callback = function()
			-- 		vim.keymap.set("n", "<leader>m", function()
			-- 			vim.lsp.buf.format({ async = true })
			-- 		end, { buffer = true, desc = "Format Scala/SBT/Java" })
			-- 	end,
			-- 	group = nvim_metals_group,
			-- })
		end,
	},
	{
		-- Auto formatting
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				rust = { "rustfmt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				verilog = { "verible" },
				systemverilog = { "verible" },
			},
			-- format_on_save = {
			-- 	timeout_ms = 500,
			-- 	lsp_format = "fallback",
			-- },
		},
		config = function(_, opts)
			require("conform").setup(opts)
			-- In your conform.nvim config:
			vim.keymap.set("n", "<leader>f", function()
				local filetype = vim.bo.filetype
				-- Use LSP formatting for Metals-supported filetypes
				if vim.tbl_contains({ "scala", "sbt", "java" }, filetype) then
					vim.lsp.buf.format({ async = true })
				else
					require("conform").format()
				end
			end, { desc = "[F]ormat" })
		end,
	},
	{
		-- Auto completion
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",

			-- Use LuaSnip as the completion window
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			-- See `:help cmp`
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },

				mapping = cmp.mapping.preset.insert({
					-- Select the [n]ext item
					["<C-n>"] = cmp.mapping.select_next_item(),
					-- Select the [p]revious item
					["<C-p>"] = cmp.mapping.select_prev_item(),

					-- Scroll the documentation window [b]ack / [f]orward
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),

					-- Accept ([y]es) the completion.
					["<C-y>"] = cmp.mapping.confirm({ select = true }),
				}),
				sources = {
					{ name = "nvim_lsp" },
					{ name = "path" },
					-- { name = "luasnip" },
					-- { name = "buffer" },
					-- { name = "cmdline" },
				},
			})
		end,
	},
}
