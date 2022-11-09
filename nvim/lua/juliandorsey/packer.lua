-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    -- Install Packer
    
    use { 'wbthomason/packer.nvim' }
    -- Install plugins
    use { 'nvim-telescope/telescope.nvim',
    requires = { { 'nvim-lua/plenary.nvim' } }
    }

    use { 'neovim/nvim-lspconfig' }
    use { 'nvim-treesitter/nvim-treesitter' }

    use { 'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
    }
    use { 'akinsho/bufferline.nvim', requires = 'nvim-tree/nvim-web-devicons' }

    -- Install themes
    use { 'catppuccin/nvim' }
end)
