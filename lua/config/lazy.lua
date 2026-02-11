-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.runtimepath:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.number = true
vim.opt.relativenumber = true

-- SEARCHING CONFIG
vim.opt.incsearch = false
local search_match_id = nil

-- Function to clean up the "fake" highlights
local function clear_live_highlight()
    if search_match_id then
        pcall(vim.fn.matchdelete, search_match_id)
        search_match_id = nil
        vim.cmd("redraw")
    end
end

-- Create the autocommand group
local group = vim.api.nvim_create_augroup("LiveSearchNoJump", { clear = true })

-- Event: Runs every time you type in the command line (/ or ?)
vim.api.nvim_create_autocmd("CmdlineChanged", {
    group = group,
    callback = function()
        local cmd_type = vim.fn.getcmdtype()
        -- Only run for search commands
        if cmd_type == "/" or cmd_type == "?" then
            local pattern = vim.fn.getcmdline()

            -- Clear previous highlights to avoid stacking them
            if search_match_id then
                pcall(vim.fn.matchdelete, search_match_id)
                search_match_id = nil
            end

            -- If pattern is empty, stop here
            if pattern == "" then
                vim.cmd("redraw")
                return
            end

            -- Manually highlight matches using 'Search' group
            -- Priority 101 ensures it sits on top of other highlights
            local ok, id = pcall(vim.fn.matchadd, "Search", pattern, 101)
            if ok then
                search_match_id = id
                vim.cmd("redraw")
            end
        end
    end,
})

-- Event: Clear highlights when you press Enter or Esc
vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = clear_live_highlight,
})


-- =============================================================================
-- 2. STANDARD SETTINGS & KEYMAPS
-- =============================================================================

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Clear search highlights with Esc
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Easy terminal exit
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Search for the word under the cursor without jumping
vim.keymap.set("n", "*", function()
    vim.fn.setreg("/", "\\<" .. vim.fn.expand("<cword>") .. "\\>")
    vim.opt.hlsearch = true
end, { desc = "Search for word under cursor (no jump)" })

-- Search for SELECTED text without jumping
vim.keymap.set("x", "*", function()
  -- 1. Yank the current selection into the 'v' register
  vim.cmd('noau normal! "vy')
  local text = vim.fn.getreg('v')

  -- 2. Escape special regex characters (like . * [ ] \ /)
  -- This ensures "core.dpath" matches literally, not as a regex wildcards
  local escaped = vim.fn.escape(text, "\\/.*$^~[]")

  -- 3. Set the search register manually
  vim.fn.setreg("/", escaped)

  -- 4. Enable highlighting
  vim.opt.hlsearch = true
end, { desc = "Search for selection (no jump)" })

vim.opt.undofile = true

vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", "<C-W>d", function()
	vim.diagnostic.open_float()
end, { desc = "Show diagnostics under the cursor" })

-- Map `>` in Visual Mode to indent and reselect
vim.api.nvim_set_keymap("v", ">", ">gv", { noremap = true, silent = true })

-- Map `<` in Visual Mode to dedent and reselect
vim.api.nvim_set_keymap("v", "<", "<gv", { noremap = true, silent = true })

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	change_detection = {
		notify = false,
	},
})
