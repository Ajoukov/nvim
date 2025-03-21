vim.g.mapleader = " "
vim.keymap.set("n", "<leader>v", vim.cmd.Ex)

local opts = { noremap = true, silent = false }

-- Normal mode mappings
vim.api.nvim_set_keymap('n', '<Up>',    ':lua print("arrows disabled")<CR>', opts)
vim.api.nvim_set_keymap('n', '<Down>',  ':lua print("arrows disabled")<CR>', opts)
vim.api.nvim_set_keymap('n', '<Left>',  ':lua print("arrows disabled")<CR>', opts)
vim.api.nvim_set_keymap('n', '<Right>', ':lua print("arrows disabled")<CR>', opts)


