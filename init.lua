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

  -- ===================== Autocomplete / LSP stack =====================
  -- Everything below is new. It adds real code intelligence (go-to-def,
  -- diagnostics, hover docs) and completion popups for popular languages:
  -- Lua, Python, JavaScript/TypeScript, C/C++, Bash, HTML/CSS, and JSON.

  -- Mason: installs and manages language servers for you (no manual setup).
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- Mason-lspconfig: bridges Mason with nvim-lspconfig so servers below
  -- get auto-installed the first time Neovim starts.
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",     -- Lua
          "pyright",    -- Python
          "ts_ls",      -- JavaScript / TypeScript
          "clangd",     -- C / C++
          "bashls",     -- Bash
          "html",       -- HTML
          "cssls",      -- CSS
          "jsonls",     -- JSON
        },
      })
    end,
  },

  -- nvim-lspconfig: ships the default server configs (cmd, filetypes, root
  -- markers) that vim.lsp.config() below builds on top of. We no longer
  -- call require('lspconfig')[server].setup() directly — that path is
  -- deprecated as of nvim-lspconfig + Neovim 0.11 and will be removed in
  -- nvim-lspconfig v3.0.0. The new built-in API is vim.lsp.config / vim.lsp.enable.
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      -- Tell language servers the editor can render completion items with
      -- extra info (snippets, docs, etc.) — cmp-nvim-lsp adds this.
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Keymaps that apply only in buffers where an LSP has attached.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local map = function(mode, lhs, rhs)
            vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, silent = true })
          end
          map("n", "gd", vim.lsp.buf.definition)       -- go to definition
          map("n", "K", vim.lsp.buf.hover)              -- hover docs
          map("n", "gr", vim.lsp.buf.references)        -- find references
          map("n", "<leader>rn", vim.lsp.buf.rename)    -- rename symbol
          map("n", "<leader>ca", vim.lsp.buf.code_action)
          map("n", "[d", vim.diagnostic.goto_prev)
          map("n", "]d", vim.diagnostic.goto_next)
        end,
      })

      -- vim.lsp.config("*", ...) applies these defaults to every server
      -- configured below, so we don't have to repeat `capabilities` each time.
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- lua_ls needs to know Neovim ships its own Lua globals (vim.*),
      -- otherwise it flags them as "undefined global" everywhere.
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      -- Turn on every server. mason-lspconfig already installed the
      -- binaries; this just tells Neovim's built-in LSP client to start
      -- them for matching filetypes.
      vim.lsp.enable({
        "lua_ls", "pyright", "ts_ls", "clangd", "bashls", "html", "cssls", "jsonls",
      })
    end,
  },

  -- LuaSnip: snippet engine used by nvim-cmp to expand snippets
  -- (e.g. typing "for" + Tab in Python expands a full for-loop).
  { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },

  -- nvim-cmp: the actual autocomplete popup/engine, wired up to
  -- LSP, the current buffer, file paths, and snippets.
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",   -- completions from the language server
      "hrsh7th/cmp-buffer",     -- completions from words in open buffers
      "hrsh7th/cmp-path",       -- completions from filesystem paths
      "saadparwaiz1/cmp_luasnip", -- completions from snippets
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),   -- manually trigger completion
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- accept selected item
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
})