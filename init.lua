-- ===================== Basic options =====================
-- vim.opt is Neovim's Lua interface to normal Vim settings (like :set in Vimscript).
local opt = vim.opt

opt.number = true          -- show absolute line numbers in the left column
opt.relativenumber = true  -- also show relative distance from the cursor line
opt.cursorline = true      -- highlight the screen line the cursor is on
opt.termguicolors = true   -- enable 24-bit RGB colors in the terminal UI;
                            -- required for most modern colorschemes to look right

opt.expandtab = true       -- pressing Tab inserts spaces instead of a tab character
opt.shiftwidth = 4         -- number of spaces used for each step of (auto)indent
opt.tabstop = 4            -- number of spaces a <Tab> character is displayed as
opt.softtabstop = 4        -- number of spaces the Tab key inserts/removes when editing
opt.smartindent = true     -- smarter auto-indenting for C-like code (braces, etc.)
opt.autoindent = true      -- copy indent from the current line when starting a new line

opt.scrolloff = 8          -- keep at least 8 lines visible above/below the cursor
opt.sidescrolloff = 8      -- same idea, but horizontally (columns left/right)

opt.showmode = false       -- don't use Vim's built-in "-- INSERT --" text;
                            -- the mode is shown in the lualine statusline instead
opt.signcolumn = "yes"     -- always reserve a column on the left for git signs
opt.clipboard = "unnamedplus" -- use the system clipboard for all yank/delete/paste,
                               -- so anything you yank in nvim can be pasted anywhere
                               -- else (and vice versa). Requires 'xclip' (X11) or
                               -- 'wl-clipboard' (Wayland) installed on the system.

-- ===================== Plugin manager (lazy.nvim) =====================
-- Path where lazy.nvim (the plugin manager) will live on disk.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Clone lazy.nvim automatically the first time, if it isn't installed yet.
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end

-- Add lazy.nvim to Neovim's runtimepath so `require("lazy")` below works.
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- Colorscheme: nightfox's "carbonfox" variant is a true black theme
  -- (designed for OLED-style pure black backgrounds).
  {
    "EdenEast/nightfox.nvim",
    priority = 1000,              -- load this before other plugins (colors first)
    config = function()
      vim.cmd("colorscheme carbonfox")
    end,
  },

  -- Statusline: shows current mode (INSERT/NORMAL/VISUAL) and a clock.
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "carbonfox" },
        sections = {
          lualine_a = { "mode" },          -- shows current mode
          lualine_c = { "filename" },
          lualine_x = { "filetype" },
          lualine_y = { "progress" },
          lualine_z = {
            function() return os.date("%H:%M") end,  -- clock
          },
        },
      })
    end,
  },

  -- Syntax highlighting via Treesitter.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",     -- pin to the legacy stable API (has nvim-treesitter.configs)
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "bash", "python", "c", "javascript", "vim", "vimdoc" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Git integration: shows added/changed/removed markers in the sign column.
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Autopairs: auto-closes brackets/quotes.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
})