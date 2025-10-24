-- Single-file Neovim setup
-- Keep all configuration here to avoid scattered files.

local nerd_font = "JetBrainsMono Nerd Font Mono"
vim.opt.guifont = nerd_font .. ":h14"     -- pick whatever size you like


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

-- pick up your shell’s OPENAI_API_KEY in Neovim’s env (no secrets in repo)
-- vim.env.OPENAI_API_KEY = vim.fn.getenv("OPENAI_API_KEY")

-- Plugins
require("packer").startup(function(use)
  use "wbthomason/packer.nvim"
  

--  -- Avante.nvim (AI-driven code suggestions)
--  use {
--      "yetone/avante.nvim",
--      branch = "main",
--      requires = {
--          -- required
--          "nvim-treesitter/nvim-treesitter",
--          "stevearc/dressing.nvim",
--          "nvim-lua/plenary.nvim",
--          "MunifTanjim/nui.nvim",
--          {
--              "MeanderingProgrammer/render-markdown.nvim",
--              opts = { file_types = { "markdown", "Avante" } },
--              ft   = { "markdown", "Avante" },
--          },
--          -- optional
--          "hrsh7th/nvim-cmp",
--          "nvim-tree/nvim-web-devicons",
--          "HakonHarnes/img-clip.nvim",
--          "zbirenbaum/copilot.lua",
--      },
--      run = "make",
--      config = function()
--          require("avante").setup({
--              provider = "openai",
--              openai = {
--                  endpoint    = "https://api.openai.com/v1",
--                  model       = "gpt-4o",
--                  timeout     = 60000,
--                  temperature =   0,
--                  max_tokens  = 4096,
--              },
--          })
--      end,
--  }

  -- Telescope
  use {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    requires = { "nvim-lua/plenary.nvim" }
  }

  -- Harpoon (v1)
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

-- Leader and basic mappings
vim.g.mapleader = " "
vim.keymap.set("n", "<leader>v", vim.cmd.Ex)

-- Telescope keymaps
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})

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

-- cmp.setup({
--   mapping = {
--     ['<Tab>'] = cmp.mapping.select_next_item(),
--     ['<S-Tab>'] = cmp.mapping.select_prev_item(),
--     ['<S-Space>'] = cmp.mapping.complete(),
--     ['<S-Space>'] = cmp.mapping.confirm({ select = true }),  -- Shift+Enter to confirm
--     -- Remove or disable the Enter mapping:
--     -- ['<CR>'] = cmp.mapping(function(fallback) fallback() end),
--   },
--   sources = {
--     { name = 'nvim_lsp' },
--     { name = 'luasnip' },
--     { name = 'buffer' },
--     { name = 'path' },
--   }
-- })
 
cmp.setup({
  mapping = {
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    -- ['<CR>'] = cmp.mapping.confirm({ select = true }),
    -- ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-Space>'] = cmp.mapping.confirm({ select = true }),
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

-- Harpoon keymaps (v1)
-- local mark = require("harpoon.mark")
-- local ui = require("harpoon.ui")
-- vim.keymap.set("n", "<leader>a", mark.add_file)
-- vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
-- vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
-- vim.keymap.set("n", "<C-j>", function() ui.nav_file(2) end)
-- vim.keymap.set("n", "<C-k>", function() ui.nav_file(3) end)
-- vim.keymap.set("n", "<C-l>", function() ui.nav_file(4) end)

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

-- Disable default vimtex mappings
vim.g.vimtex_mappings_enabled = 0

-- Map <Space>ll to start compilation
vim.api.nvim_set_keymap("n", "<Space>ll", ":VimtexCompile<CR>", { noremap = true, silent = true })

-- Map <Space>lv to open the PDF viewer
vim.api.nvim_set_keymap("n", "<Space>lv", ":VimtexView<CR>", { noremap = true, silent = true })

vim.g.vimtex_quickfix_ignore_filters = { "Underfull", "Overfull", "Warning:" }

vim.api.nvim_set_keymap('v', '&', '"+y:let @* = getreg("+")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '&', '"+y:let @* = getreg("+")<CR>', { noremap = true, silent = true })


local function log_var()
  -- yank visual selection into "z
  vim.cmd('silent! normal! "zy')

  -- get the text
  local var = vim.fn.getreg('z')
  if var == '' then
    vim.notify('No selection to log', vim.log.levels.WARN)
    return
  end

  -- choose template by filetype
  local ft = vim.bo.filetype
  local stmt
  if ft == 'c' then
    stmt = string.format('printf("%s: %%s\\n", %s);', var, var)
  elseif ft:match('^js') or ft:match('^javascript') or ft:match('^typescript') then
    stmt = string.format('console.log("%s: " + JSON.stringify(%s));', var, var)
  else
    vim.notify('LogVar: unsupported filetype ' .. ft, vim.log.levels.WARN)
    return
  end

  -- append the statement below the current line
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, { stmt })
end

-- map <leader>l in visual mode
vim.keymap.set('v', '<leader>l', log_var, { silent = true, desc = 'Log variable/value' })

-- make it so that pressing 'o' or 'O' from a comment doesn't insert comment text like "//"
local no_comment_o = vim.api.nvim_create_augroup("NoCommentO", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = no_comment_o,
  pattern = "*",
  callback = function()
    -- remove 'o' (and optional 'r') from the local formatoptions
    vim.bo.formatoptions = vim.bo.formatoptions:gsub("o", "")
    vim.bo.formatoptions = vim.bo.formatoptions:gsub("r", "")
  end,
})

vim.keymap.set('n','S',function()
  local c = vim.fn.nr2char(vim.fn.getchar())
  vim.api.nvim_feedkeys('i'..c..vim.api.nvim_replace_termcodes('<Esc>','',true,true),'n',false)
end,{noremap=true})

vim.keymap.set('n','s',function()
  local c = vim.fn.nr2char(vim.fn.getchar())
  vim.api.nvim_feedkeys('a'..c..vim.api.nvim_replace_termcodes('<Esc>','',true,true),'n',false)
end,{noremap=true})
