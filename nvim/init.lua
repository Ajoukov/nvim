-- Single-file Neovim setup
-- Keep all configuration here to avoid scattered files.

local nerd_font = "JetBrainsMono Nerd Font Mono"
vim.opt.guifont = nerd_font .. ":h14"

-- Silence 0.10+ deprecation notices for tbl_islist
if vim.fn.has("nvim-0.10") == 1 and vim.islist and vim.tbl_islist then
  vim.tbl_islist = function(t) return vim.islist(t) end
end

-- Bootstrap Packer
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
    vim.cmd([[packadd packer.nvim]])
    return true
  end
  return false
end
local packer_bootstrap = ensure_packer()

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
  use { "nvim-telescope/telescope.nvim", tag = "0.1.6", requires = { "nvim-lua/plenary.nvim" } }

  -- Harpoon (v1)
  use "ThePrimeagen/harpoon"

  -- Tools (no nvim-lspconfig; use core vim.lsp.start)
  use { "williamboman/mason.nvim", run = ":MasonUpdate" }

  -- Autocompletion
  use "hrsh7th/nvim-cmp"
  use "hrsh7th/cmp-nvim-lsp"
  use "L3MON4D3/LuaSnip"
  use "saadparwaiz1/cmp_luasnip"
  use "hrsh7th/cmp-buffer"
  use "hrsh7th/cmp-path"

  -- LaTeX
  use { "lervag/vimtex", tag = "v2.15" }

  if packer_bootstrap then require("packer").sync() end
end)

if packer_bootstrap then return end

-- Leader and basic mappings
vim.g.mapleader = " "
vim.keymap.set("n", "<leader>v", vim.cmd.Ex)

-- Telescope keymaps
local ok_tbuiltin, tbuiltin = pcall(require, "telescope.builtin")
if ok_tbuiltin then
  vim.keymap.set("n", "<leader>ff", tbuiltin.find_files, {})
  vim.keymap.set("n", "<leader>fg", tbuiltin.live_grep, {})
  vim.keymap.set("n", "<leader>fb", tbuiltin.buffers, {})
end

-- Mason UI (optional)
local ok_mason, mason = pcall(require, "mason")
if ok_mason then mason.setup() end

-- LSP via core (no nvim-lspconfig)
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmpcap, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmpcap then capabilities = cmp_nvim_lsp.default_capabilities(capabilities) end

local function on_attach(_, bufnr)
  local opts = { buffer = bufnr, remap = false }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K",  vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
  vim.keymap.set("n", "<leader>vd",  vim.diagnostic.open_float, opts)
end

local function buf_dir(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return vim.loop.cwd() end
  return vim.fn.fnamemodify(name, ":p:h")
end

local function find_root(start_dir)
  local found = vim.fs.find({ "compile_commands.json", "compile_flags.txt", ".git" }, { upward = true, path = start_dir })[1]
  return (found and vim.fs.dirname(found)) or start_dir
end

-- clangd (C/C++)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "objc", "objcpp" },
  callback = function(args)
    local root = find_root(buf_dir(args.buf))
    vim.lsp.start({
      name = "clangd",
      cmd = { "clangd" },
      root_dir = root,
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end,
})

-- lua-language-server (Lua)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua" },
  callback = function(args)
    local root = find_root(buf_dir(args.buf))
    vim.lsp.start({
      name = "lua_ls",
      cmd = { "lua-language-server" },
      root_dir = root,
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = { checkThirdParty = false },
        },
      },
    })
  end,
})

-- Autocompletion setup
local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  cmp.setup({
    mapping = {
      ["<Tab>"]   = cmp.mapping.select_next_item(),
      ["<S-Tab>"] = cmp.mapping.select_prev_item(),
      ["<C-Space>"] = cmp.mapping.confirm({ select = true }),
    },
    sources = {
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "buffer" },
      { name = "path" },
    },
  })
end

-- Diagnostics minimal
vim.diagnostic.config({
  virtual_text = false,
  signs = false,
  underline = false,
  update_in_insert = false,
})
vim.opt.signcolumn = "no"

-- Indentation and timeouts
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 5

-- VimTeX
vim.g.vimtex_view_method = "zathura"
vim.g.vimtex_compiler_latexmk = {
  options = {
    "-pdf",
    "-pvc",
    "-interaction=nonstopmode",
    "-synctex=1",
  },
}
vim.g.vimtex_mappings_enabled = 0
vim.api.nvim_set_keymap("n", "<Space>ll", ":VimtexCompile<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<Space>lv", ":VimtexView<CR>", { noremap = true, silent = true })
vim.g.vimtex_quickfix_ignore_filters = { "Underfull", "Overfull", "Warning:" }

-- Yank to system clipboard helpers on &
vim.api.nvim_set_keymap("v", "&", '"+y:let @* = getreg("+")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "&", '"+y:let @* = getreg("+")<CR>', { noremap = true, silent = true })

-- Quick log of selected var/value
local function log_var()
  vim.cmd('silent! normal! "zy')
  local var = vim.fn.getreg("z")
  if var == "" then
    vim.notify("No selection to log", vim.log.levels.WARN)
    return
  end
  local ft = vim.bo.filetype
  local stmt
  if ft == "c" then
    stmt = string.format('printf("%s: %%s\\n", %s);', var, var)
  elseif ft:match("^js") or ft:match("^javascript") or ft:match("^typescript") then
    stmt = string.format('console.log("%s: " + JSON.stringify(%s));', var, var)
  else
    vim.notify("LogVar: unsupported filetype " .. ft, vim.log.levels.WARN)
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, { stmt })
end
vim.keymap.set("v", "<leader>l", log_var, { silent = true, desc = "Log variable/value" })

-- Don't continue comments on o/O
local no_comment_o = vim.api.nvim_create_augroup("NoCommentO", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = no_comment_o,
  pattern = "*",
  callback = function()
    vim.bo.formatoptions = vim.bo.formatoptions:gsub("o", "")
    vim.bo.formatoptions = vim.bo.formatoptions:gsub("r", "")
  end,
})

-- Insert single char before/after cursor with S/s
vim.keymap.set("n", "S", function()
  local c = vim.fn.nr2char(vim.fn.getchar())
  vim.api.nvim_feedkeys("i" .. c .. vim.api.nvim_replace_termcodes("<Esc>", "", true, true), "n", false)
end, { noremap = true })
vim.keymap.set("n", "s", function()
  local c = vim.fn.nr2char(vim.fn.getchar())
  vim.api.nvim_feedkeys("a" .. c .. vim.api.nvim_replace_termcodes("<Esc>", "", true, true), "n", false)
end, { noremap = true })

