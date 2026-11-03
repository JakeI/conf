# Neovim Config Rewrite — Review Notes (2026-11-02)

The old 2,678-line `vimrc` (Vim/Neovim dual config, vimscript, vim-plug) was replaced by a
minimal, lazy-loading, Neovim-only Lua config.

**Backup:** full copy at `~/conf/vim.backup-2026-11-02/` and git commit `488c1fc`
("backup: old vim config before neovim rewrite (2026-11-02)") in the `~/conf` repo.
The old files (`vim/vimrc`, `vim/init.vim`, `vim/simple_vimrc`, …) were not modified.

## New layout

| File | Purpose |
|---|---|
| `vim/init.lua` | Entry point: options, global keymaps, autocmds, lazy.nvim setup |
| `vim/lua/plugins.lua` | All plugin specs (38 plugins) + plugin keymaps |
| `vim/lua/lsp.lua` | Manual LSP: `:LspStart` / `:LspStop`, mason, on-attach maps |
| `vim/lua/statusline.lua` | Built-in statusline + tabline (no plugin) |
| `vim/lua/extras.lua` | Resize mode, digraph helpers, ExecuteInShell, matlab_run, move_char |
| `vim/lazy-lock.json` | Snapshot of existing plugin revisions; no upgrades made during review |
| `vim/tests/check.lua` | Regression checks using the real config and installed plugins |

Entry: `~/.config/nvim/init.lua` is a symlink to `~/conf/vim/init.lua`. The old
`~/.config/nvim/init.vim` symlink was **removed** (Neovim aborts with "E5422: Conflicting
configs" when both `init.lua` and `init.vim` exist). The runtime path prepend of `~/conf/vim`
keeps the existing `UltiSnips/`, `colors/atom.vim`, `syntax/`, `ftdetect/` assets working.

## Startup performance (measured 2026-11-02, headless, same session)

| Config | Empty file | Single markdown file |
|---|---|---|
| Old `vimrc` | ~600 ms | ~730–800 ms |
| New config | **127–157 ms** | **213–353 ms** |

Roughly 4–5× faster. Lazy loading: Telescope/GitSigns/etc. load on first use or on `VeryLazy`;
filetype plugins (vimtex, matlab, csv, APL, BQN, just) load only for those buffers.
Julia currently loads on `VeryLazy` because of its global Unicode-completion hooks.

## LSP: manual only

LSP never starts automatically. Per file type, `:LspStart` (no argument) starts the
configured server, or `:LspStart clangd` names one:

| File type | Server (via mason) |
|---|---|
| c / cpp | clangd (+ clangd_extensions) |
| julia | julials |
| python | pyright |
| tex / markdown / text | ltex |

`gd` and other LSP navigation maps are installed on attachment (they currently remain in
that buffer after stopping the server). Mason binaries live in
`~/.local/share/nvim/mason/bin`; Mason adds this to `PATH` at `:LspStart` time.
Starting a server enables it for matching buffers until `:LspStop`; it is not per-buffer.

## OpenCode integration (opencode v2.2.1)

Via `nickjvandyke/opencode.nvim` (`~/.opencode/bin/opencode` on `PATH`), fitting the existing
leader scheme:

| Key | Action |
|---|---|
| `<leader>aa` | toggle OpenCode TUI (vertical split terminal) |
| `<leader>ai` | ask about cursor position (`@this:`) |
| `<leader>ab` | ask about buffer (`@buffer:`) |
| `<leader>ad` | ask about diagnostics (`@diagnostics:`) |
| `<leader>as` | pick OpenCode action (prompts + commands) |
| `<leader>ac` | pick OpenCode command |
| `<leader>ap` (visual) | send selection as prompt (`@this`) |
| `<leader>ao` | operator: apply prompt over motion / `.`-repeatable |

---

# Removed (candidates you may want to skim)

## Removed in second pass (2026-11-02, after your review)
- **Floating terminals (F8/F9/F10/F12)** — the floaterm replacement was removed entirely;
  you no longer use float terms. Split terminals remain: `<leader>bt` / `<leader>bT`.

## Dead weight / was already commented out
- **coc.nvim**, **coq_nvim** (+ coq.artifacts, coq.thirdparty) — completion/LSP blocks were
  commented out. LSP is now manual (`:LspStart`), no completion engine installed.
- **AutomaticLaTexPlugin** — obsolete with vimtex.
- Netrw junk comment blocks and the `t_UT`/`t_SI` terminal escape hacks — obsolete on modern
  Neovim.
- Host-name gating (`IRS-Illerhaus` `fullconfigs` checks) — config now host-independent.

## Replaced by built-in Neovim features
- **vim-airline** (+ themes, airline-tablemode) → built-in `statusline`/`tabline`
  (`lua/statusline.lua`). No plugin at all.
- **vim-floaterm** (+ fzf-floaterm) → built-in floating terminals (`lua/extras.lua`,
  F8/F9/F10/F12) — **removed again in second pass** (unused).
- **vim-which-key / WhichKey** → `folke/which-key.nvim` (already maintained for Neovim,
  loaded lazy; `<leader>sh` opens the hint popup).
- **vim-sensible**, **vim-vinegar** — sensible defaults are in `init.lua`; vinegar folded
  into kept netrw.
- **vim-expand-region** → removed; no replacement incremental-selection mapping is
  currently configured (`gnn` was incorrectly listed here previously).
- **vim-json**, **haskell-vim**, **vim-glsl**, **julia-syntax.vim**, **vim-pandoc(-syntax)** →
  Treesitter parsers / existing ftplugins cover highlighting.
- **suda.vim** → built-in `<leader>bw` (`:w !sudo tee`) kept from old config.

## Replaced by a better/maintained plugin
- **fzf + fzf.vim + coc-fzf** → **telescope.nvim** (+ plenary). Same leader groups; see
  changed keys below.
- **vim-gitgutter / git-blame.nvim / nerdtree-git-plugin** → **gitsigns.nvim** (lazy, on
  git buffer).
- **vim-matchit** → **vim-matchup** (already kept).
- **tcomment_vim** → **tpope/vim-commentary** (kept).
- **bqf** (quickfix preview) → removed; `[q`/`]q` and quickfix kept, preview dropped.
- **vim-nerdtree-syntax-highlight / fern-renderer-nerdfont / fern-renderer-devicons** →
  dropped with their file managers.

## File managers consolidated to netrw
- **nerdtree**, **fern** (+ fern-mapping-fzf, fern-hijack, fern-preview), **nvim-tree**,
  **chadtree**, **broot.nvim**, **vifm.vim**, **vim-vinegar** — all removed. Netrw is kept:
  `<leader>nn` = `:Lexplore 30` sidebar toggle. Icons/dirs plugins (vim-devicons, nvim-web-devicons) dropped
  with them.

## UI chrome / appearance
- **minimap.vim**, **indentLine**, **vim-cursorword**, **vimade**, **SimpleSmoothScroll**,
  **folddigest.vim**, **tagbar**, **calendar.vim** (both itchyny & mattn), **catppuccin**,
  **space-vim-theme** — removed; `colors/atom.vim` stays as colorscheme.
  (tagbar: `<leader>nB`/`<leader>nb` now unbound — treesitter symbols via LSP if wanted.)

## Other removed integrations
- **firenvim** — browser/editor bridge, no longer part of this setup.
- **YouCompleteMe** — compilation and a local ycmd server no longer needed.
- **vimspeak**, **klog**, **kmonad-vim** — omitted niche integrations.

These removals are not evidence that those plugins contain telemetry. Background update
checks are disabled; explicit installs/updates, language-server installation and OpenCode
can use the network. This configuration review is not a full security audit of dependencies.

## Misc
- **vim-move** → custom `<A-J/K/H/L>` move maps kept in `init.lua` (same keys).
- **hologram.nvim** (markdown image preview) → removed; `<leader>ep` img-paste kept.
- **mdnav** → removed (vim-markdown follows links with `Enter` reasonably).
- **unicode.vim / vim-isotope** → removed; custom digraph helpers kept in `init.lua`.
- **vim-renumber, vis, vim-addon-qf-layout, vim-pursuit, vim-boxdraw/boxdraw** → removed;
  the `ascii2box.pl` map `<leader>db` is preserved.
- **honza/vim-snippets** → removed; your own `vim/UltiSnips/` snippets remain via UltiSnips.
- **ltex_extra.nvim** → removed (commented out before; ltex-ls works without it).
- Updated org name: **williamboman/mason** → **mason-org/mason** (GitHub org moved).

---

# Changed shortcuts (everything else kept identical)

Kept exactly as before: `<space>` leader groups `f`/`s`/`g`/`n`/`c`/`b`/`e`/`r`/`w`/`d`/`t`/
`x`/`l`/`q`/`v`/`F`/`S` (minus items below), `ü`=z=, `s`=update, `<A-h/j/k/l>` window
navigation, `<A-n/p>`/`<A-N/P>` tabs & buffers, `<A-J/K/H/L>` line/char move, resize mode
`<C-w>. , > <`, `gs`, `go`=xdg-open, `gA`, `gm`, `gZ`, `gz` (tags picker), quickfix/location
`[q ]q [l ]l` groups, `K` matlab help, UltiSnips keybinds, vimtex `<leader>x*` family
(extended), markdown `!`=medieval, `ga`=EasyAlign, comment/surround keys.

| Key | Old | New |
|---|---|---|
| `<leader>fl` | fzf `:Lines` (open buffers) | Telescope live_grep (project-wide) |
| `<leader>fL` | — | lines in current buffer (new) |
| `<leader>nB` | `:TagbarToggle` | unbound (tagbar removed) |
| `<leader>nb` | `:TagbarOpen j` | unbound |
| `<leader>nj` | echo b:terminal_job_id | unbound (floaterm gone) |
| `<leader>fx` | vimtex fzf `ctli` picker | unbound (vimtex has richer `<leader>x*` maps) |
| `<leader>gF` | `:GitGutterFold` | unbound (gitgutter removed) |
| `<leader>gG` | `:GitGutterToggle` | gitsigns `toggle_signs` (same semantics) |
| `<leader>nn` | fern | netrw **sidebar** (`:Lex 30`, 30-col left panel, toggle) |
| `<leader>sh` | WhichKey popup | which-key.nvim hint loop (same purpose) |
| `<F8>` | floaterm new/cycle (`:Floaterms`) | **removed** (unused) |
| `<F9>` / `<F10>` | floaterm prev / next | **removed** (unused) |
| `<F12>` | floaterm toggle | **removed** (unused) |
| `Plug*` commands | `:PlugInstall` etc. | `:Lazy` (`:Lazy install`, `:Lazy update`, `:Lazy sync`) |
| (new) | — | `<leader>aa/ai/ab/ad/as/ac/ap/ao` OpenCode |
| (new) | — | `<leader>bf`, `<leader>gs` aliases for buffer/git pickers |

## Color schemes

The old `:Colors` command came from a removed picker plugin. Options now:

- `:colorscheme atom` — set a scheme at runtime (replace `atom` with any installed scheme;
  your `colors/atom.vim` still loads). Same interactive picker still exists as
  `<leader>fS` (Telescope colorscheme), though you don't need it.
- To change the default permanently, edit `init.lua` line ~114:
  `pcall(vim.cmd.colorscheme, "atom")` — built-in fallbacks like `habamax`, `vim`, `quiet`
  also work.

## Second-pass fixes (2026-11-02, after your review)

- **gitsigns attach error fixed** (`rhs: expected string|function, got nil` on open/save):
  `<leader>gG` now maps `gitsigns.toggle_signs` (the function `toggle_current_line_highlights`
  does not exist in gitsigns).
- **OpenCode TUI crash fixed** (`Unknown option 'nonumber'`): the `TermOpen` autocmd used
  `vim.opt_local.nonumber = true` — the `no`-prefixed names aren't valid option keys in Lua;
  it now sets `number = false` etc. `<leader>aa` works.
- **Statusline spell indicator compacted**: ` SPELL:en_us,de_de` → emoji flags with no
  punctuation, e.g. ` 🇬🇧🇩🇪` (`en→🇬🇧, de→🇩🇪, fr→🇫🇷 …`; unknown langs fall back to the
  plain code). Still on the left, right after the mode.
- **Tabline adaptive**: with one tab open it lists buffers (as before); as soon as more
  than one tab exists it shows tabs only (name of first non-netrw buffer per tab).
- **which-key modernized**: `preset = "helix"` — compact bottom panel like Helix editor /
  LunarVim instead of the floating classic popup. (No plugin switch needed; alternatives
  like mini.clue or hydra.nvim were considered but which-key's helix preset is exactly
  that look.)
- **which-key spec curated**: groups plus a meaningful set of leaf mappings added for
  Telescope find keys, OpenCode, gitsigns, buffer/window/config/edit/misc groups —
  deliberately not exhaustive.
- **`<leader>nn` opens a netrw sidebar** (`:Lex 30`, left, 30 columns, toggles) instead of
  replacing the whole window.
- **Floating terminals removed** (F8/F9/F10/F12 + `lua/extras.lua` implementation).

# Known limitations

- **LaTeX treesitter parser skipped**: the `latex` parser build fails against the system
  tree-sitter CLI (ABI mismatch on this 0.12.0-dev build). vimtex's own syntax highlighting
  covers tex files; revisit after the next nvim stable update.
- **vimtex version gate**: the installed VimTeX requires nvim ≥ 0.12.4 (or Vim 9.2).
  This 0.12.0-dev build is **below** that minimum. `g:vimtex_version_check = 0` bypasses
  the check, but doesn't guarantee compatibility. Upgrade Neovim, or pin a supported
  VimTeX release; no dependency upgrades/downgrades were made during this review.
- **vimtex inverse search**: upstream advises against filetype-only lazy loading because
  the global inverse-search command may be needed before a TeX buffer is open. This
  loading policy is unchanged; revisit if you use PDF-to-editor inverse search.
- **julia-vim** loads on `VeryLazy` rather than on `ft=julia` because its ftdetect registers
  global `BufEnter *` autocmds that error when the plugin is ft-gated.
- Old `~/.local/share/nvim` still contains leftover `tree-sitter-*` plugin dirs from the old
  setup — safe to delete manually.
- The first `:LspStart` explicitly loads/configures the LSP stack; later calls reuse it.
- `<leader>cl` reapplies main options/mappings/autocommands. Plugin configuration/module
  changes still require a fresh Neovim instance; it is not a full plugin hot-reloader.

## Performance / code-quality review (2026-11-04)

The current architecture is worth keeping. There is no justification for replacing the
plugin stack or changing shortcuts just to chase startup milliseconds. The useful gains
were in frequently executed rendering code and fixing lazy-loading/reload correctness.

### Applied

- **Word-count cache:** `wordcount()` scans the entire buffer on every invocation. Cache
  the total by buffer + changedtick, invalidate after edits, and release on buffer wipe.
  In a 50,000-line / 500,000-word stress test, unchanged redraws went from about **12.3 ms
  to 0.07 ms**. The first count after an edit still scans the buffer.
- **Cheaper tabline:** avoid `getbufinfo()`/`gettabinfo()` copying all buffer/tab variables
  on every redraw. Use focused APIs, keep the existing 15-buffer display limit, and count
  listed buffers in one pass. Stress test with 202 buffers (200 with 10 KB metadata): about
  **3.13 ms → 0.65 ms** per render; two buffers: **0.034 ms → 0.010 ms**.
- **Correct rendering:** diagnostic counts use numeric severity keys, inactive windows
  show their own metadata, literal `%` in names/branches is escaped, tab labels have
  proper click targets, and TABLE reflects the displayed buffer's actual table mode.
- **Filetype mappings:** Markdown/table/image/medieval/VimTeX shortcuts now apply to every
  matching buffer, not just whichever buffer triggered the plugin's one-time `config()`.
- **Safe reload:** named autocommand groups avoid accumulating duplicate callbacks;
  don't rerun `lazy.setup()` after initial setup. Removed unused helpers.
- **Mapping maintenance:** which-key reads actual mapping descriptions and lazy key
  stubs rather than a second, easily-stale copy. Telescope keys/descriptions live together;
  plugin functionality is still lazy. Existing snippet-list keys now call UltiSnips's
  actual list function instead of the removed fzf `:Snippets` command.
- **Manual LSP:** explicitly load the stack, preserve our commands after lspconfig loads,
  surface setup failures, avoid deprecated `require('lspconfig')`, and avoid replaying
  unrelated FileType hooks on every start. Start/stop and repeated start tested with clangd.
- **Other small fixes:** preserve OpenCode's terminal job across toggles; register visual
  lazy triggers; pass the visual range when resetting Git hunks; fix the Shell output
  buffer's invalid `noswapfile` Lua option, refresh/reuse it correctly, and parse UTF-8
  digraph characters correctly. Quote/pass filenames literally in chmod/open/sudo-write
  helpers (sudo itself was not invoked during testing).
- **Reproducibility:** `lazy-lock.json` is now beside the config. It is an exact copy of
  the previous lockfile; plugin revisions were not changed. Keep it in version control
  and use `:Lazy restore` if needed, rather than blindly updating dependencies.

### Startup measurements

Five same-machine headless samples per case; median through `NVIM STARTED`:

| Case | Before review | After review |
|---|---:|---:|
| Empty | 135 ms | 131 ms |
| `REVIEW.md` | 220 ms | 237 ms |

Treat startup as essentially unchanged, not a claimed speedup; the samples vary. These
headless timings exclude deferred UI work. An attached-UI smoke test separately checked
Telescope, the Helix-style which-key panel, Git attachment, initial Treesitter highlighting
and OpenCode terminal reuse. OpenCode used a local fake executable for that test, so no
model request was sent.

### Deliberately left alone

- Keep the existing shortcuts, theme, sidebar, tab/buffer policy, spell flags and manual LSP.
- Leave spelling/syntax/highlighting enabled as requested. Disabling them, or loading fewer
  Markdown helpers, could save more time but would be a feature/behaviour tradeoff.
- `:Shell`/Matlab helpers still run synchronously. Making them asynchronous is worthwhile
  only if you use slow commands there; it needs cancellation/lifecycle handling, not just
  a mechanical substitution.
- Avoid broad caching and extra abstraction elsewhere: most remaining setup code runs
  once, not per redraw. No additional plugins or background workers were introduced.

### Repeatable checks

From `~/conf/vim`, with plugins/parsers already installed:

```sh
nvim --headless -n "+lua dofile('tests/check.lua')"
# Also exercise installed clangd (starts a real local language server):
NVIM_TEST_LSP=1 nvim --headless -n "+lua dofile('tests/check.lua')"
```

The extended run passes 16 checks, including multi-buffer mappings, cache invalidation,
inactive-window metadata, tabline escaping/targets, real Git attachment, sidebar/terminals,
literal shell filenames, repeat reloads, snippet precedence and manual LSP. No plugin update
or model completion is part of these checks.

### TeX snippet-priority fix

The `bar`/`hat` overrides left `priority 100` active for later TeX snippets. This let the
derivative regex `([^dn])d` beat the global `fold` snippet (priority 10), producing
`fol{𝒹÷𝒹}`. Reset priority after the math overrides, keeping the fold definition unchanged.
Actual insert-mode tests checked `fold`, indented `fold`, `foldo`, `foldc` and the existing
` d`/`dd`/`nd` derivative expansions with Ctrl-J, including first-use lazy loading.

# Rollback

```sh
# restore the old config
rm ~/.config/nvim/init.lua
ln -s ~/conf/vim.backup-2026-11-02/init.vim ~/.config/nvim/init.vim
# plugins were never touched; vim-plug setup inside old init.vim will handle itself
```

(The backup dir is a full copy of `vim/` from 2026-11-02, including `vimrc`, `init.vim`,
`UltiSnips/`, `colors/`, `syntax/`, `ftdetect/`.)
