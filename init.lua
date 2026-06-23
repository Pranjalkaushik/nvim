vim.opt.termguicolors = false
vim.opt.mouse = "a"

-- Leader must be set before plugins load so <leader>-based keymaps register correctly.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- System clipboard: yanks/deletes/pastes use the OS clipboard, so anything copied
-- in nvim can be pasted into other apps (and vice versa).
vim.opt.clipboard = "unnamedplus"
-- WSL has no native clipboard tool; bridge to the Windows clipboard via clip.exe
-- (copy) and powershell Get-Clipboard (paste). Skipped on non-WSL systems.
if vim.fn.has("wsl") == 1 then
  local ps_paste = 'powershell.exe -NoLogo -NoProfile -c '
    .. '[Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
    paste = { ["+"] = ps_paste, ["*"] = ps_paste },
    cache_enabled = 0,
  }
end

-- Completion popup behaviour: always show the menu (even for one match), don't
-- auto-select an entry, fuzzy-match the typed text, and show a doc popup beside it.
vim.opt.completeopt = { "menuone", "noselect", "fuzzy", "popup" }

vim.keymap.set("n", "<C-Up>",    "<C-w>k", { silent = true })  -- up
vim.keymap.set("n", "<C-Down>",  "<C-w>j", { silent = true })  -- down
vim.keymap.set("n", "<C-Left>",  "<C-w>h", { silent = true })  -- left
vim.keymap.set("n", "<C-Right>", "<C-w>l", { silent = true })  -- right

vim.keymap.set("n", "<C-s>",    "<C-w>s", { silent = true })  -- Horizontal split
-- <C-s> is often swallowed by terminal flow control (XOFF); disable it so the
-- key reaches Neovim (and nvim-tree's buffer-local <C-s> mapping below).
vim.cmd("silent !stty -ixon")

-- Force synchronous treesitter parsing. By default core parses asynchronously
-- with a timeout; the snacks picker preview reuses one scratch buffer and
-- stop/restarts treesitter on it as you scroll grep results (<leader>fg), so a
-- half-finished async parse resumes against the swapped buffer and dereferences
-- a stale (nil) injection node -> "attempt to call method 'range' (a nil value)"
-- from the treesitter highlighter. Parsing synchronously removes that race.
-- Preview files are capped (~1MB) so the cost is imperceptible.
vim.g._ts_force_sync_parsing = true

-- Folding: visuals + sensible defaults so `zM` folds functions/classes nicely.
-- Treesitter-based folds follow real syntax (functions/classes), set up per-buffer
-- by the nvim-treesitter spec below. These are the global fallbacks/visuals.
vim.opt.foldmethod = "expr"                            -- fold via expression (treesitter)
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"   -- language-aware fold regions
vim.opt.foldnestmax = 4         -- allow nesting (e.g. methods inside a class)
vim.opt.foldlevelstart = 99     -- open everything on file load; press zM to collapse
vim.opt.foldcolumn = "1"        -- gutter showing fold arrows (clickable with the mouse)
vim.opt.foldtext = ""           -- keep the folded line's real syntax highlighting (no "····")
vim.opt.fillchars:append({
  foldopen  = "▾",  -- shown in the gutter when a fold is open
  foldclose = "▸",  -- shown in the gutter when a fold is closed
  fold      = " ",  -- trailing fill on a folded line
  foldsep   = " ",  -- foldcolumn separator
})

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
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Treesitter: language-aware syntax tree used for highlighting and, here,
  -- for folding (`foldexpr = vim.treesitter.foldexpr`). `zM`/`zR` then fold
  -- and unfold real functions/classes rather than indentation guesses.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",   -- classic API (ensure_installed/highlight); `main` is a breaking rewrite
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        -- Parsers compiled with the system C compiler via :TSInstall. We list them
        -- explicitly because `auto_install` would need the tree-sitter CLI, which
        -- isn't installed; add languages here as you need them.
        ensure_installed = {
          "lua", "vim", "vimdoc", "python", "javascript", "typescript",
          "tsx", "json", "yaml", "bash", "markdown", "c",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local function my_on_attach(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)
        local function opts(desc)
          return { desc = desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end
        vim.keymap.set("n", "o", api.node.open.horizontal, opts("Open: Horizontal Split"))
        vim.keymap.set("n", "<C-s>", api.node.open.horizontal, opts("Open: Horizontal Split"))
      end

      require("nvim-tree").setup({
        on_attach = my_on_attach,
        view = { width = 30, side = "left" },
        actions = { open_file = { quit_on_open = false } },
      })
    end,
  },

  -- Fuzzy finder: VS Code-style file picker (Ctrl+P) and project-wide grep.
  -- Uses the snacks.nvim picker + ripgrep.
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        enabled = true,
        -- snacks opens splits with <C-s> (horizontal) / <C-v> (vertical) by
        -- default. Add <C-x> -> horizontal split too (Telescope/VS Code muscle
        -- memory). Bound in both the input and list windows so it works whether
        -- you're typing or navigating results.
        win = {
          input = { keys = { ["<c-x>"] = { "edit_split", mode = { "i", "n" } } } },
          list  = { keys = { ["<c-x>"] = "edit_split" } },
        },
      },
    },
    keys = {
      -- Open any file, fuzzy, with recent/buffer recommendations (like VS Code Ctrl+P).
      { "<C-p>", function() require("snacks").picker.smart() end, desc = "Find files (smart)" },
      { "<leader>ff", function() require("snacks").picker.files() end, desc = "Find files" },
      -- Search for a term across the project directory (live grep via ripgrep).
      -- In-prompt filtering (snacks parses everything after " -- " as raw rg flags):
      --   foo -- -g=*.lua            only .lua files
      --   foo -- -t py               only Python (rg filetype; see `rg --type-list`)
      --   foo -- -g=!*.test.js       exclude test files
      --   foo -- src/components/     restrict to a folder
      --   foo -- -g=*.{ts,tsx} src/  combine extension + folder
      { "<leader>fg", function() require("snacks").picker.grep() end, desc = "Grep in project" },
      { "<leader>/", function() require("snacks").picker.grep() end, desc = "Grep in project" },
      -- Grep scoped to the current file's directory (handy quick folder filter).
      { "<leader>fG", function() require("snacks").picker.grep({ dirs = { vim.fn.expand("%:p:h") } }) end, desc = "Grep in current file's folder" },
      -- Grep the word/selection under the cursor.
      { "<leader>fw", function() require("snacks").picker.grep_word() end, mode = { "n", "x" }, desc = "Grep word under cursor" },
      -- Handy extras.
      { "<leader>fb", function() require("snacks").picker.buffers() end, desc = "Find buffers" },
      { "<leader>fr", function() require("snacks").picker.recent() end, desc = "Recent files" },
    },
  },

  -- Git: inline signs / hunk staging / blame in the gutter.
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(l, r, desc)
          vim.keymap.set("n", l, r, { buffer = bufnr, desc = desc })
        end
        map("]c", gs.next_hunk, "Next git hunk")
        map("[c", gs.prev_hunk, "Prev git hunk")
        map("<leader>gp", gs.preview_hunk, "Preview hunk")
        map("<leader>gs", gs.stage_hunk, "Stage hunk")
        map("<leader>gr", gs.reset_hunk, "Reset hunk")
        map("<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("<leader>gd", gs.diffthis, "Diff this")
      end,
    },
  },

  -- Git: full command surface (:Git, :Gdiffsplit, :Gblame, ...).
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gblame", "Gread", "Gwrite", "Gedit" },
    keys = {
      { "<leader>gg", "<cmd>Git<cr>", desc = "Git status (fugitive)" },
    },
  },

  -- Git diff: VS Code-style review UI. A changed-files panel on the left and a
  -- side-by-side (old | new) diff of the selected file, like VS Code's Source
  -- Control diff editor. <C-g><C-g> toggles it open/closed on the working tree.
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = {
      "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles",
      "DiffviewFocusFiles", "DiffviewRefresh", "DiffviewFileHistory",
    },
    opts = {
      -- Default args ensure LSP/treesitter work in the diff buffers.
      default_args = { DiffviewOpen = { "--imply-local" } },
      file_panel = {
        listing_style = "tree",
        win_config = { position = "left", width = 35 },  -- like VS Code's left panel
      },
    },
    keys = {
      {
        "<C-g><C-g>",
        function()
          -- Toggle: close if a Diffview tab is already open, otherwise open.
          if next(require("diffview.lib").views) ~= nil then
            vim.cmd("DiffviewClose")
          else
            vim.cmd("DiffviewOpen")
          end
        end,
        desc = "Git diff (VS Code-style)",
      },
    },
  },

  -- Completion engine: VS Code-style, as-you-type popup with fuzzy matching.
  -- Pops suggestions on every keystroke (e.g. `dev` -> `developer`/`developer_vector`),
  -- backed by the LSP. `version` pulls a prebuilt fuzzy-matcher binary, so no
  -- Rust/cargo toolchain is required to build it.
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- Keymap preset 'default': <C-y> accepts, <C-n>/<C-p> (or <Up>/<Down>)
      -- navigate, <C-space> opens the menu / shows docs, <C-e> hides it.
      -- Swap to 'super-tab' for Tab-to-accept (VS Code style) or 'enter' for <CR>.
      keymap = { preset = "default" },
      -- Show the documentation popup beside the menu automatically.
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 200 } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      -- Use the prebuilt Rust matcher; fall back to the Lua one (with a warning)
      -- if the binary is unavailable.
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },

  -- LSP: language servers power "go to definition", hover docs, references, etc.
  -- mason.nvim installs the servers; mason-lspconfig auto-enables each installed
  -- server via Neovim 0.11+'s built-in vim.lsp.enable (no manual setup per server).
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", config = true },
      "mason-org/mason-lspconfig.nvim",
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("mason").setup()

      -- Advertise blink.cmp's richer completion capabilities (snippets,
      -- auto-import text edits, etc.) to every server. vim.lsp.config('*')
      -- sets defaults merged into all servers enabled by mason-lspconfig.
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      require("mason-lspconfig").setup({
        -- pyright for this Python project; lua_ls for editing this config.
        -- Add more here as needed: ts_ls, bashls, jsonls, yamlls, ...
        ensure_installed = { "pyright", "lua_ls" },
        -- automatic_enable is on by default: installed servers are enabled
        -- automatically, so no require("lspconfig").<server>.setup{} needed.
      })

      -- Keymaps attach per-buffer only once a server is actually serving it,
      -- so `gd` etc. exist exactly where LSP is available.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs,
              { buffer = bufnr, desc = desc, silent = true })
          end

          -- Keyboard navigation.
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("gy", vim.lsp.buf.type_definition, "Go to type definition")
          map("gr", vim.lsp.buf.references, "List references")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")

          -- Mouse: Ctrl+Click a symbol to jump to its definition. The leading
          -- <LeftMouse> lets the click position the cursor first, then the
          -- command runs against the symbol now under the cursor.
          map("<C-LeftMouse>",
            "<LeftMouse><cmd>lua vim.lsp.buf.definition()<cr>",
            "Go to definition (Ctrl+Click)")
          -- Mouse: Ctrl+Right-Click to jump back to where you came from.
          map("<C-RightMouse>", "<C-o>", "Jump back")

          -- Completion is handled by the blink.cmp plugin (see its spec below):
          -- it shows the as-you-type popup and owns its own insert-mode keymaps.
        end,
      })
    end,
  },

  -- CodeRabbit: AI code review via the CodeRabbit CLI; findings as diagnostics.
  {
    "smnatale/coderabbit.nvim",
    cmd = {
      "CodeRabbitReview", "CodeRabbitShow", "CodeRabbitHistory",
      "CodeRabbitStop", "CodeRabbitClear", "CodeRabbitQuickfix", "CodeRabbitRestore",
    },
    keys = {
      { "<leader>cr", "<cmd>CodeRabbitReview<cr>", desc = "CodeRabbit: review changes" },
      { "<leader>cs", "<cmd>CodeRabbitShow<cr>", desc = "CodeRabbit: show results" },
      { "<leader>ch", "<cmd>CodeRabbitHistory<cr>", desc = "CodeRabbit: history" },
      { "<leader>cx", "<cmd>CodeRabbitStop<cr>", desc = "CodeRabbit: stop review" },
    },
    opts = {
      review = {
        base = "master",     -- diff against master
        type = "committed",  -- only committed changes (HEAD vs master); ignores staged/working tree
      },
    },
  },
})
