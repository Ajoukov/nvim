-- Bootstrap Packer
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({
      "git",
      "clone",
      "--depth",
      "1",
      "https://github.com/wbthomason/packer.nvim",
      install_path,
    })
    vim.cmd([[packadd packer.nvim]])
    return true
  end
  return false
end
ensure_packer()

-- Auto-sync on save
vim.cmd([[ 
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost init.lua source <afile> | PackerSync
  augroup end
]])

-- Plugins
require("packer").startup(function(use)
  use "wbthomason/packer.nvim"

  -- Telescope
  use {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    requires = { "nvim-lua/plenary.nvim" }
  }

  -- Harpoon
  use "ThePrimeagen/harpoon"

  -- LSP
  use "neovim/nvim-lspconfig"
  use { "williamboman/mason.nvim", run = ":MasonUpdate" }
  use "williamboman/mason-lspconfig.nvim"

  -- Autocompletion
  use "hrsh7th/nvim-cmp"
  use "hrsh7th/cmp-nvim-lsp"
  use "L3MON4D3/LuaSnip"
  use "saadparwaiz1/cmp_luasnip"
  use "hrsh7th/cmp-buffer"
  use "hrsh7th/cmp-path"

  use { 'lervag/vimtex', tag = 'v2.15' }

end)

-- Telescope keymaps
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})

-- Harpoon keymaps
local harpoon = require("harpoon")
vim.keymap.set("n", "<leader>a", function() harpoon:list():append() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<C-j>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<C-k>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<C-l>", function() harpoon:list():select(4) end)

-- LSP Setup
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "clangd",
  },
  automatic_installation = true,
})

local lspconfig = require("lspconfig")
require("mason-lspconfig").setup_handlers({
  function(server_name)
    lspconfig[server_name].setup({})
  end,
})

-- Lua-specific LSP tweaks
lspconfig.lua_ls.setup({
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" }
      }
    }
  }
})

-- LSP Keymaps (on_attach)
local lsp = require("lspconfig")

lsp.on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, remap = false }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
  vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
end

-- Autocompletion setup
local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
  mapping = {
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
  }
})

vim.diagnostic.config({
  virtual_text = false,
  signs = false,
  underline = false,
  update_in_insert = false,
})
vim.opt.signcolumn = "no"

vim.diagnostic.config({
  virtual_text = false,
  signs = false,
  underline = false,
  update_in_insert = false,
})
vim.opt.signcolumn = "no"

local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.g.mapleader = " "

vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)
vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>f', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>s', function()
        builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)


vim.keymap.set("n", "<leader>v", vim.cmd.Ex)

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 5

-- Set your preferred PDF viewer. For example, if you are on Linux:
vim.g.vimtex_view_method = "zathura"
-- If you are on macOS, you might use:
-- vim.g.vimtex_view_method = "skim"

-- vimtex uses latexmk by default. You can customize its options:
vim.g.vimtex_compiler_latexmk = {
  options = {
    "-pdf",               -- compile to PDF
    "-pvc",               -- preview continuously (auto-update)
    "-interaction=nonstopmode",
    "-synctex=1",
  },
}

vim.g.vimtex_mappings_enabled = 0
-- Set leader to space (if not already set)
vim.g.mapleader = " "

-- Disable default vimtex mappings
vim.g.vimtex_mappings_enabled = 0

-- Map <Space>ll to start compilation
vim.api.nvim_set_keymap("n", "<Space>ll", ":VimtexCompile<CR>", { noremap = true, silent = true })

-- Map <Space>lv to open the PDF viewer
vim.api.nvim_set_keymap("n", "<Space>lv", ":VimtexView<CR>", { noremap = true, silent = true })

vim.g.vimtex_quickfix_ignore_filters = { "Underfull", "Overfull", "Warning:" }

