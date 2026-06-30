-- True color: required by the guts.nvim colorscheme, which defines only GUI
-- (hex) colors and no 256-color/cterm fallbacks. Your terminal (Windows
-- Terminal under WSL) supports truecolor, so syntax renders with guts' palette.
vim.opt.termguicolors = true
vim.opt.mouse = "a"

-- Insert mode uses a blinking block cursor (default is a vertical bar).
vim.opt.guicursor = "n-v-c:block,i-ci-ve:block-blinkwait350-blinkoff200-blinkon125,r-cr:hor20,o:hor50"

-- Transparent background: let the terminal's own background show through instead
-- of nvim (or the colorscheme) painting its own. We clear BOTH bg (guibg, the
-- attribute that matters now that termguicolors is on) and ctermbg, so the editor,
-- gutters, and floating windows stay transparent regardless. This runs on a
-- ColorScheme autocmd so it re-applies after guts (below) loads — meaning guts'
-- syntax colors show over a transparent background. To instead use guts' own dark
-- background, drop "Normal"/"NormalNC"/"NormalFloat" from the list below.
local function make_transparent()
  for _, group in ipairs({
    "Normal", "NormalNC", "NormalFloat", "FloatBorder", "SignColumn",
    "LineNr", "FoldColumn", "EndOfBuffer", "NonText",
  }) do
    -- Resolve the group's real attributes (link = false follows any link) so we
    -- keep guts' foreground color and only strip the background. Plain set_hl
    -- with just bg would replace the whole group and discard the fg.
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg = "NONE"
    hl.ctermbg = "NONE"
    vim.api.nvim_set_hl(0, group, hl)
  end
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = make_transparent })
make_transparent()

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

-- Show the full diagnostic message (the E/W sign in the gutter) for the current
-- line in a floating window. Default config shows only the sign + underline, not
-- the text; this pops the message on demand. Use ]d / [d to jump between them.
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic message" })

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

-- Guard the actual frame that throws "attempt to call method 'range' (a nil value)"
-- at runtime/lua/vim/treesitter.lua:197, where vim.treesitter.get_range() does
-- `node:range(true)`. Several callers hand it a nil node when a tree is parsed
-- against a buffer that changed underneath them: the blink.cmp documentation popup
-- as you type (auto_show), get_node_text, and the snacks picker highlighter. The
-- sync-parsing flag above only covers the core highlighter, not these paths.
-- Wrapping get_range so a nil node yields an empty range (Range6 of zeros) makes
-- that frame render nothing instead of crashing, for every caller at once.
do
  local get_range = vim.treesitter.get_range
  local logged = false
  vim.treesitter.get_range = function(node, source, metadata)
    if node == nil then
      -- One-shot: dump the call stack of the first nil-node hit so we can find the
      -- exact caller. Remove this block once the path is identified.
      if not logged then
        logged = true
        local f = io.open(vim.fn.stdpath("cache") .. "/ts_nil_node.log", "w")
        if f then f:write(debug.traceback("get_range got nil node", 2)); f:close() end
      end
      return { 0, 0, 0, 0, 0, 0 }
    end
    return get_range(node, source, metadata)
  end
end

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
  -- Window separators. With laststatus=3 (below) there is no per-window
  -- statusline to act as the divider between stacked windows, so draw an
  -- explicit horizontal line (horiz) and the matching T/cross junctions where
  -- it meets vertical splits. All use the WinSeparator highlight.
  horiz     = "─",
  horizup   = "┴",
  horizdown = "┬",
  vert      = "│",
  vertleft  = "┤",
  vertright = "├",
  verthoriz = "┼",
})

-- One global statusline at the very bottom instead of one per window. This frees
-- the row between horizontally-stacked windows for a real WinSeparator line, so
-- horizontal splits get a visible divider matching the vertical ones (the old
-- per-window statuslines were invisible here because the transparent theme
-- leaves StatusLine with no background).
vim.opt.laststatus = 3

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
  -- guts.nvim: Berserk-inspired muted colorscheme. Truecolor only (needs the
  -- termguicolors=true set at the top of this file). Loaded eagerly at startup
  -- with a high priority so the colors are applied before other UI plugins draw.
  -- Applying it fires the ColorScheme autocmd above, which re-asserts the
  -- transparent background over guts' palette.
  {
    "vossenwout/guts.nvim",
    lazy = false,
    priority = 1100,
    config = function()
      vim.cmd.colorscheme("guts")
    end,
  },

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

  -- smart-paste: pasted code lands at the correct indent level automatically.
  -- Wraps p/P/gp/gP (and visual-line paste) so linewise registers are re-indented
  -- to the cursor's context; adds ]p/[p to drop charwise content onto a new
  -- indented line. Indent is detected via indentexpr -> treesitter -> heuristics
  -- (treesitter is already loaded above), and registers are read without being
  -- clobbered, so it composes with clipboard=unnamedplus. Loads on VeryLazy so the
  -- p/P remaps are in place before you paste. Escape hatches:
  -- <Plug>(smart-paste-raw-p) / <Plug>(smart-paste-raw-P) for a raw paste.
  {
    "nemanjamalesija/smart-paste.nvim",
    event = "VeryLazy",
    opts = {
      exclude_filetypes = {},  -- filetypes that skip smart indent (e.g. "markdown")
    },
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

      -- Toggle the file tree side panel (VS Code-style sidebar).
      vim.keymap.set("n", "<C-b>", "<cmd>NvimTreeToggle<cr>",
        { silent = true, desc = "Toggle file tree" })
    end,
  },

  -- Fuzzy finder: VS Code-style file picker (Ctrl+P) and project-wide grep.
  -- Uses the snacks.nvim picker + ripgrep.
  {
    "folke/snacks.nvim",
    -- Load at startup (not lazily on a keypress) so the indent guides and smooth
    -- scroll below are active the moment a file opens. priority puts it before
    -- other start plugins. The picker keymaps still work the same.
    lazy = false,
    priority = 1000,
    opts = {
      -- Indent guides: subtle vertical lines per indent level, with the current
      -- scope (the block the cursor is in) drawn brighter and animated as you move.
      indent = {
        enabled = true,
        animate = { enabled = true },   -- the scope underline grows in
      },
      -- Smooth scroll: <C-d>/<C-u>/<C-f> and friends glide instead of jumping,
      -- so it's easy to keep your place. Short duration keeps it snappy.
      scroll = {
        enabled = true,
        animate = { duration = { step = 10, total = 150 } },
      },
      picker = {
        enabled = true,
        -- Show every file in the pickers: hidden = dotfiles (.github/, .gitignore),
        -- ignored = gitignored files (node_modules/, build artifacts). snacks
        -- filters both out by default; turn them on so nothing is hidden.
        sources = {
          files = { hidden = true, ignored = true },
          smart = { hidden = true, ignored = true },
        },
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
    config = function(_, opts)
      require("snacks").setup(opts)
      -- Guard snacks' picker treesitter highlighter against a transient nil node.
      -- The picker reuses one scratch buffer and stop/restarts treesitter on it as
      -- you scroll, so query:iter_captures can yield a stale (nil) node. snacks then
      -- feeds it to vim.treesitter.get_node_text -> get_range -> node:range(), which
      -- crashes at runtime/lua/vim/treesitter.lua:197. This path runs its own
      -- parser:parse(true), so vim.g._ts_force_sync_parsing (set above, for the core
      -- highlighter) doesn't cover it, and upstream is unguarded. Wrap the public
      -- entry point: a transient bad frame renders without TS highlights instead of
      -- erroring. Override the module-table field so every require() call site sees it.
      local hl = require("snacks.picker.util.highlight")
      local get_highlights = hl.get_highlights
      hl.get_highlights = function(...)
        local ok, ret = pcall(get_highlights, ...)
        return ok and ret or {}
      end
    end,
    keys = {
      -- Open any file, fuzzy, with recent/buffer recommendations (like VS Code Ctrl+P).
      { "<C-p>", function() require("snacks").picker.smart() end, desc = "Find files (smart)" },
      { "<leader>ff", function() require("snacks").picker.files() end, desc = "Find files" },
      -- Search for a term across the project directory (live grep via ripgrep).
      -- In-prompt filtering (snacks parses everything after " -- " as raw rg flags):
      --   foo -- -g=*.lua            only .lua files
      --   foo -- -t py               only Python (rg filetype; see `rg --type-list`)
      --   foo -- -g=!*.test.js       exclude test files
      --   foo -- db/                 restrict to a folder (positional path — simplest)
      --   foo -- -g=db/**            restrict to a folder via glob (note: -g=db/ alone matches nothing)
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
        map("<C-g><Down>", gs.next_hunk, "Jump to git diff line below")
        map("<C-g><Up>", gs.prev_hunk, "Jump to git diff line above")
        map("<leader>gp", gs.preview_hunk, "Preview hunk")
        map("<leader>gs", gs.stage_hunk, "Stage hunk")
        map("<leader>gr", gs.reset_hunk, "Reset hunk")
        -- Note: <leader>gb is the full blame panel (blame.nvim, below). The
        -- single-line popup lives on <leader>gl to avoid clashing with it.
        map("<leader>gl", function() gs.blame_line({ full = true }) end, "Blame line (popup)")
        map("<leader>gd", gs.diffthis, "Diff this")
      end,
    },
  },

  -- Git blame: VS Code GitLens-style toggleable side panel. Opens a column to
  -- the left of the buffer where every line shows the commit that last touched
  -- it (author + date), scroll-synced with the file. <leader>gt toggles it;
  -- inside the panel <CR> opens the commit, and the usual close keys dismiss it.
  {
    "FabijanZulj/blame.nvim",
    cmd = { "BlameToggle" },
    keys = {
      { "<leader>gb", "<cmd>BlameToggle<cr>", desc = "Toggle git blame panel" },
    },
    opts = {
      -- "window" = the left-hand panel (the VS Code look). ("virtual" would
      -- instead overlay end-of-line virtual text, which you didn't want.)
      blame_options = { "-w" },           -- ignore whitespace-only changes
      date_format = "%Y-%m-%d %H:%M",
      merge_consecutive = false,          -- show the date on every line, not just hunk starts
      max_summary_width = 30,
      commit_detail_view = "vsplit",      -- <CR> opens the full commit beside the file
      focus_blame = true,                 -- move the cursor into the panel on open
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
      -- Keymap preset 'super-tab': <Tab> accepts the selected entry, or selects
      -- and accepts the first one when nothing is highlighted yet (VS Code style);
      -- <Tab>/<S-Tab> also navigate. <C-y> accepts, <C-n>/<C-p> (or <Up>/<Down>)
      -- navigate, <C-space> opens the menu / shows docs, <C-e> hides it.
      keymap = { preset = "super-tab" },
      -- Show the documentation popup beside the menu automatically.
      -- treesitter_highlighting = false: blink's doc-popup highlighter parses the
      -- code in the doc against a scratch buffer that changes as you keep typing,
      -- and hands a stale (nil) node to vim.treesitter -> node:range(), crashing with
      -- "attempt to call method 'range' (a nil value)" (.../vim/treesitter.lua:197).
      -- Turning it off drops only syntax coloring inside the doc popup; the text and
      -- markdown still render. This is the path that survived the get_range guard.
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          treesitter_highlighting = false,
        },
      },
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
          -- gd is defined GLOBALLY in the lspeek spec (peek definition / open at
          -- the far edge when already peeking), so it isn't mapped here. The
          -- Ctrl+Click mapping below still does a direct jump.
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

  -- lspeek: preview LSP definitions in a read-only floating window instead of
  -- jumping straight there. Wired into `gd` below (in the LspAttach block): the
  -- first `gd` opens the float; pressing `gd` again inside the float opens the
  -- target in a split of the CURRENT window (the one gd was invoked from), not
  -- pushed out to the far edge of the layout. The orientation of that split is
  -- chosen to balance the current layout: a HORIZONTAL split only when there are fewer
  -- horizontal splits than vertical ones, otherwise a VERTICAL split (so a tie
  -- or a single unsplit window opens vertically). Other in-float keys keep their
  -- defaults: s = split, v = vsplit, t = tab, <CR> = open in the current window,
  -- q = close, [ / ] = cycle stacked previews. Loads on LspAttach so setup() and
  -- the gd override are ready before you ever press gd.
  {
    "r4ppz/lspeek.nvim",
    event = "LspAttach",
    config = function()
      require("lspeek").setup({})  -- defaults; in-float split=s, vsplit=v

      -- Only real editor windows should influence the orientation. Side panels
      -- (nvim-tree, the blame panel, quickfix, help, terminals) are themselves
      -- splits and would otherwise skew the count — e.g. an open nvim-tree is a
      -- vertical split, which alone would force the first jump to go horizontal.
      local function is_editor_win(winid)
        if not vim.api.nvim_win_is_valid(winid) then return false end
        if vim.api.nvim_win_get_config(winid).relative ~= "" then return false end -- float
        return vim.bo[vim.api.nvim_win_get_buf(winid)].buftype == ""
      end

      -- Count existing splits from the window-layout tree, ignoring non-editor
      -- windows. winlayout() nests windows as 'col' (stacked = horizontal splits)
      -- and 'row' (side-by-side = vertical splits). We first prune leaves that
      -- aren't editor windows, collapsing single-child containers, then count what
      -- remains — so the counts describe just the file windows the jump splits.
      local function count_splits()
        local function prune(node)
          if node[1] == "leaf" then
            return is_editor_win(node[2]) and node or nil
          end
          local kept = {}
          for _, child in ipairs(node[2]) do
            local p = prune(child)
            if p then kept[#kept + 1] = p end
          end
          if #kept == 0 then return nil end
          if #kept == 1 then return kept[1] end  -- collapse away the divider
          return { node[1], kept }
        end

        local h, v = 0, 0
        local function walk(node)
          if not node or node[1] == "leaf" then return end
          if node[1] == "col" then
            h = h + (#node[2] - 1)
          elseif node[1] == "row" then
            v = v + (#node[2] - 1)
          end
          for _, child in ipairs(node[2]) do walk(child) end
        end
        walk(prune(vim.fn.winlayout()))
        return h, v
      end

      -- Track which floating windows are lspeek previews. lspeek shows the real
      -- file buffer in its float, so we must NOT add buffer-local keymaps to it
      -- (they would linger on the actual file after the preview closes). Instead
      -- we wrap the preview constructor only to record the float's window id, and
      -- drive everything from a single global gd that checks this set.
      local preview_wins = {}
      local window = require("lspeek.window")
      local create_preview = window.create_preview_floating_window
      window.create_preview_floating_window = function(source, target)
        local preview = create_preview(source, target)
        if preview and preview.win then
          preview_wins[preview.win] = true
          vim.api.nvim_create_autocmd("WinClosed", {
            pattern = tostring(preview.win),
            once = true,
            callback = function() preview_wins[preview.win] = nil end,
          })
        end
        return preview
      end

      -- One GLOBAL gd, so it never sticks to a file buffer:
      --   * inside a lspeek preview float -> open the target in a layout-balanced
      --     split of the CURRENT window. We delegate to lspeek's own split (s) /
      --     vsplit (v) action (its buffer-local keymaps are live while the float
      --     is up); lspeek closes the float first, so the split lands on the
      --     source window rather than spanning the whole layout.
      --   * anywhere else -> peek the definition in the float.
      vim.keymap.set("n", "gd", function()
        if preview_wins[vim.api.nvim_get_current_win()] then
          local h, v = count_splits()
          local km = require("lspeek.config").options.keymaps
          local horizontal = h < v
          local keys = horizontal and km.split or km.vsplit
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes(keys, true, false, true), "m", false)
        else
          require("lspeek").peek_definition()
        end
      end, { desc = "Peek definition (lspeek) / open in a split of the current window while peeking" })
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

  -- vi-sql: a TUI for managing SQL databases, run inside a floating terminal.
  -- setup() registers :ViSQL (open/toggle the window — the process keeps running
  -- in the background when hidden) and :ViSQLJump schema/table (open and jump
  -- straight to a table). The vi-sql binary isn't bundled: on first :ViSQL it
  -- prompts to auto-install via `curl | sh` (curl is present on this machine).
  -- hide_key works because `stty -ixon` above frees <C-q> from flow control.
  {
    "kopecmaciej/vi-sql.nvim",
    cmd = { "ViSQL", "ViSQLJump" },
    keys = {
      { "<leader>vs", "<cmd>ViSQL<cr>", desc = "Open vi-sql (SQL TUI)" },
    },
    -- Portable keybindings: vi-sql reads $XDG_CONFIG_HOME/vi-sql (default
    -- ~/.config/vi-sql). We keep our customized keybindings-vim.yaml versioned in
    -- this repo (nvim/vi-sql/) and symlink it into that dir on startup, so cloning
    -- this config to any PC gets the same vi-sql bindings. config.yaml (DB
    -- connections + plaintext passwords) is deliberately NOT versioned — it stays
    -- a local, per-machine file that vi-sql generates on first run.
    init = function()
      local src = vim.fn.stdpath("config") .. "/vi-sql/keybindings-vim.yaml"
      if not vim.uv.fs_stat(src) then return end
      local dir = (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")) .. "/vi-sql"
      local dst = dir .. "/keybindings-vim.yaml"
      if vim.uv.fs_readlink(dst) == src then return end  -- already linked
      vim.fn.mkdir(dir, "p")
      vim.fn.delete(dst)  -- drop a stale file/symlink if one exists
      vim.uv.fs_symlink(src, dst)
    end,
    opts = {
      hide_key = "<C-q>",  -- press in the vi-sql terminal to hide it back to nvim
      width = 0.9,         -- floating window size as a fraction of the editor
      height = 0.9,
      -- connection = "mydb",  -- optional: passed to vi-sql as --connection-name
    },
  },

  -- fidget: a small spinner/notification in the bottom-right showing LSP progress
  -- (e.g. pyright indexing) so long operations aren't silent. Loads with the LSP.
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {},
  },

  -- duck: pure whimsy. <leader>dd hatches a duck that waddles across the buffer;
  -- <leader>dk cooks (removes) the most recent one. Does nothing useful — that's
  -- the point. Press dd a few times for a flock.
  {
    "tamton-aquib/duck.nvim",
    keys = {
      { "<leader>dd", function() require("duck").hatch() end, desc = "Hatch a duck 🦆" },
      { "<leader>dk", function() require("duck").cook() end, desc = "Cook a duck" },
    },
  },
})
