return {
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  {
    'tpope/vim-vinegar',
  },
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {},
  },
}
