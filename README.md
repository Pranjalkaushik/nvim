# Neovim Config

A single-file Neovim setup (`init.lua`) built around [lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management. VS Code-style fuzzy finding, git diffing, completion, LSP, and AI code review.

## Plugins

| Plugin | Purpose |
| --- | --- |
| [folke/lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager (bootstraps itself on first launch). |
| [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Language-aware syntax highlighting + treesitter-based folding. |
| [nvim-tree/nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | File explorer sidebar. |
| [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | File-type icons (used by nvim-tree & diffview). |
| [folke/snacks.nvim](https://github.com/folke/snacks.nvim) | Fuzzy finder / picker — file search (`Ctrl+P`) and project-wide grep (ripgrep). |
| [lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Inline git signs, hunk staging/preview/reset, line blame. |
| [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive) | Full git command surface (`:Git`, `:Gdiffsplit`, `:Gblame`, …). |
| [sindrets/diffview.nvim](https://github.com/sindrets/diffview.nvim) | VS Code-style side-by-side git diff & review UI. |
| [saghen/blink.cmp](https://github.com/saghen/blink.cmp) | As-you-type completion popup with fuzzy matching. |
| [rafamadriz/friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | Snippet collection for blink.cmp. |
| [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP configuration (go-to-definition, hover, references, rename, …). |
| [mason-org/mason.nvim](https://github.com/mason-org/mason.nvim) | Installs language servers (`pyright`, `lua_ls`, …). |
| [mason-org/mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | Bridges mason ↔ lspconfig; auto-enables installed servers. |
| [smnatale/coderabbit.nvim](https://github.com/smnatale/coderabbit.nvim) | AI code review via the CodeRabbit CLI; findings surface as diagnostics. |


## Shortcuts

> Leader key is `<Space>`.

| Keys | Action |
| --- | --- |
| `Space` `c` `r` | CodeRabbit code review |
| `Ctrl` `g` `g` | Git diff (VS Code-style diffview, toggle open/close) |
| `Ctrl` `p` | Open file (fuzzy finder) |
| `Ctrl` `b` | Toggle file tree side panel |
| `Space` `f` `g` | Search in repo (live grep) |
| `z` `M` | Fold all |
| `z` `R` | Unfold all |
| `Ctrl` `v` | Open in vertical split (in picker) |
| `Ctrl` `x` | Open in horizontal split (in picker) |
| `Ctrl` `Space` | Autocomplete (open completion menu / show docs) |
| `Ctrl` `w` `d` | Show full diagnostic (LSP error/warning) for the current line in a float |

### LSP (code navigation)

> These attach per-buffer only once a language server is serving the file, so they exist exactly where LSP is available.

| Keys | Action |
| --- | --- |
| `g` `d` | Go to definition |
| `g` `D` | Go to declaration |
| `g` `i` | Go to implementation |
| `g` `y` | Go to type definition |
| `g` `r` | List references |
| `K` | Hover docs |
| `Space` `r` `n` | Rename symbol |
| `Space` `c` `a` | Code action |
| `Ctrl` `LeftClick` | Go to definition (mouse) |
| `Ctrl` `RightClick` | Jump back |
| `Ctrl` `o` | Jump back (keyboard) |
| `Ctrl` `i` | Jump forward |

### Search filters (`Space` `f` `g`)

Everything typed after ` -- ` is passed to ripgrep as raw flags:

| Type this | Effect |
| --- | --- |
| `foo -- -g=*.lua` | Only `.lua` files |
| `foo -- -t py` | Only Python (rg filetype; see `rg --type-list`) |
| `foo -- -g=!*.test.js` | Exclude test files |
| `foo -- db/` | Restrict to a folder (positional path — simplest) |
| `foo -- -g=db/**` | Restrict to a folder via glob |
| `foo -- -g=*.{ts,tsx} src/` | Combine extension + folder |

> **Folder filters:** the easy way is a positional path with a trailing slash (`foo -- db/`). If you reach for a glob instead, remember `-g=db/` matches the *directory entry only* and finds nothing — you need the recursive `-g=db/**` to match files inside it.

## Copying within Neovim

Yank/cut into the clipboard, then paste back later. (`clipboard=unnamedplus` is set, so these also sync with the system clipboard — including the Windows clipboard under WSL.)

| Keys | Action |
| --- | --- |
| `d` | Cut |
| `yy` | Copy the current whole line |
| `yw` | Copy from cursor to the start of the next word |
| `y$` | Copy to end of line |
| `p` | Paste |
