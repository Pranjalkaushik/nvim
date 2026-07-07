# Neovim Config

A single-file Neovim setup (`init.lua`) built around [lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management. VS Code-style fuzzy finding, git diffing, completion, LSP, and AI code review.

## Plugins

| Plugin | Purpose |
| --- | --- |
| [folke/lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager (bootstraps itself on first launch). |
| [vossenwout/guts.nvim](https://github.com/vossenwout/guts.nvim) | Berserk-inspired muted colorscheme (truecolor; transparent background kept). |
| [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Language-aware syntax highlighting + treesitter-based folding. |
| [nvim-tree/nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | File explorer sidebar. |
| [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | File-type icons (used by nvim-tree & diffview). |
| [folke/snacks.nvim](https://github.com/folke/snacks.nvim) | Fuzzy finder / picker (`Ctrl+P`, ripgrep), indent guides + scope highlight, and smooth scrolling. |
| [nemanjamalesija/smart-paste.nvim](https://github.com/nemanjamalesija/smart-paste.nvim) | Re-indents pasted code to the cursor's context automatically. |
| [j-hui/fidget.nvim](https://github.com/j-hui/fidget.nvim) | LSP progress spinner in the bottom-right corner. |
| [tamton-aquib/duck.nvim](https://github.com/tamton-aquib/duck.nvim) | A 🦆 that waddles across the buffer. Purely for fun. |
| [lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Inline git signs, hunk staging/preview/reset, single-line blame popup. |
| [FabijanZulj/blame.nvim](https://github.com/FabijanZulj/blame.nvim) | VS Code GitLens-style toggleable blame panel (author + date per line, scroll-synced). |
| [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive) | Full git command surface (`:Git`, `:Gdiffsplit`, `:Gblame`, …). |
| [sindrets/diffview.nvim](https://github.com/sindrets/diffview.nvim) | VS Code-style side-by-side git diff & review UI. |
| [saghen/blink.cmp](https://github.com/saghen/blink.cmp) | As-you-type completion popup with fuzzy matching. |
| [rafamadriz/friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | Snippet collection for blink.cmp. |
| [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP configuration (go-to-definition, hover, references, rename, …). |
| [mason-org/mason.nvim](https://github.com/mason-org/mason.nvim) | Installs language servers (`pyright`, `lua_ls`, …). |
| [mason-org/mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | Bridges mason ↔ lspconfig; auto-enables installed servers. |
| [r4ppz/lspeek.nvim](https://github.com/r4ppz/lspeek.nvim) | Peek LSP definitions in a floating window (`gd`); press `gd` again to open at the far edge. |
| [smnatale/coderabbit.nvim](https://github.com/smnatale/coderabbit.nvim) | AI code review via the CodeRabbit CLI; findings surface as diagnostics. |
| [kopecmaciej/vi-sql.nvim](https://github.com/kopecmaciej/vi-sql.nvim) | SQL database TUI in a floating terminal (`:ViSQL`). |


## Shortcuts

> Leader key is `<Space>`. Anything starting with the `Space` leader is a chord sequence by
> nature — press the keys one after another (tap and release, then the next), *not* held down
> together. (See the **Git** section for the `Ctrl`+`g` chords, marked **†**.)

| Keys | Action |
| --- | --- |
| `Space` `c` `r` | CodeRabbit code review |
| `Ctrl` `p` | Open file (fuzzy finder) |
| `Alt` `i` | Toggle ignored/hidden files in the file search |
| `Ctrl` `b` | Toggle file tree side panel |
| `Space` `f` `g` | Search in repo (live grep) |
| `z` `M` | Fold all |
| `z` `R` | Unfold all |
| `Ctrl` `v` | Open in vertical split (in picker) |
| `Ctrl` `x` | Open in horizontal split (in picker) |
| `Ctrl` `Space` | Autocomplete (open completion menu / show docs) |
| `Ctrl` `w` `d` | Show full diagnostic (LSP error/warning) for the current line in a float |
| `Space` `d` `d` | Hatch a duck 🦆 (press a few times for a flock) |
| `Space` `d` `k` | Cook (remove) the most recent duck |
| `Space` `v` `s` | Open the vi-sql database TUI |

### Git

> Rows marked **†** are **chord sequences**: press `Ctrl`+`g` (tap and release), *then* the
> following key — *not* held down together.

| Keys | Action |
| --- | --- |
| `Ctrl` `g` `g` † | Git diff (VS Code-style diffview, toggle open/close) |
| `Ctrl` `g` `↓` † | Jump to next git hunk (diff line below) |
| `Ctrl` `g` `↑` † | Jump to previous git hunk (diff line above) |
| `Space` `g` `b` | Toggle git blame panel (author + date per line; `Enter` in the panel opens the commit) |
| `Space` `g` `l` | Blame the current line in a popup (full commit) |
| `Space` `g` `p` | Preview the git hunk under the cursor |
| `Space` `g` `s` | Stage the hunk under the cursor |
| `Space` `g` `r` | Reset the hunk under the cursor |
| `Space` `g` `d` | Diff the current file |
| `]` `c` / `[` `c` | Jump to next / previous git hunk |

### LSP (code navigation)

> These attach per-buffer only once a language server is serving the file, so they exist exactly where LSP is available.

| Keys | Action |
| --- | --- |
| `g` `d` | Peek definition in a float (lspeek); press `g` `d` again to open it at the far edge |
| `q` | Close the floating peek window (lspeek default; works for free, no mapping needed) |
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
| `p` | Paste (re-indented to context by smart-paste) |
| `]` `p` / `[` `p` | Paste charwise content onto a new, indented line |

## vi-sql (SQL TUI)

Open with `Space` `v` `s` (`:ViSQL`). Once it's up you're inside the vi-sql TUI, so
its **own** keys apply — not Neovim's. The bindings below are versioned in this repo at
[`vi-sql/keybindings-vim.yaml`](vi-sql/keybindings-vim.yaml) and symlinked into vi-sql's
config dir (`$XDG_CONFIG_HOME/vi-sql`) automatically on startup, so any machine that
clones this config gets the same keys. `config.yaml` (DB connections + passwords) is
deliberately **not** versioned — vi-sql generates it locally on first run.

> Rows marked ✎ are customizations on top of vi-sql's vim defaults.

| Keys | Action |
| --- | --- |
| `h` `j` `k` `l` / arrows | Move within the focused pane |
| `Ctrl` + `h/j/k/l` **or `Ctrl`+arrows** ✎ | Move focus between panes |
| `Ctrl` `p` ✎ / `g` `t` | Go to / search for a table (then `Enter` to open) |
| `Enter` / `Space` | Select table / peek row |
| `/` | Filter the current list |
| `g` `e` | Focus the schema tree |
| `e` / `s` / `i` | Expand table / open structure / open indexes |
| `g` `d` / `g` `r` | Follow foreign key / find references |
| `Ctrl` `t` / `Ctrl` `x` | New tab / close tab |
| `Ctrl` `s` | Confirm / run query |
| `Ctrl` `r` | Refresh |
| `Ctrl` `o` | Open connections page |
| `Esc` | Close / back |
| `F1` | Full-screen help |
| `Ctrl` `q` | Hide vi-sql back to Neovim (process keeps running) |
| `Ctrl` `c` | Quit vi-sql |

> `Ctrl`+arrow keys depend on your terminal emitting distinct codes for them; if they
> don't register, the `Ctrl`+`h/j/k/l` equivalents always work. Autocomplete-up in the
> query editor moved from `Ctrl`+`p` to the `Up` arrow (since `Ctrl`+`p` now jumps to a table).
