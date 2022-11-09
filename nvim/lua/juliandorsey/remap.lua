local nnoremap = require("juliandorsey.keymap").nnoremap
local telescope = require("telescope.builtin")

nnoremap("<leader>e", "<cmd>Ex<CR>")

nnoremap("<leader>ff", telescope.find_files) 
nnoremap("<leader>fg", telescope.live_grep) 
nnoremap("<leader>fb", telescope.buffers) 
nnoremap("<leader>fh", telescope.help_tags) 
