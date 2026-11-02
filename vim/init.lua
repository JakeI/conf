-- =============================================================================
--  Neovim config  (Lua, Neovim-only — replaces vimrc/init.vim)
--  Design goals:
--    * fast startup: markdown / single files load almost nothing
--    * LSP, tex, csv, ... only load when explicitly asked for (:LspStart etc.)
--    * keyboard shortcuts preserved from the old vimrc (see REVIEW.md)
--    * no plugins with network/telemetry behaviour
-- =============================================================================

-- Bootstrap lazy.nvim ----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Runtime path: this repo holds colors/, syntax/, ftdetect/, UltiSnips/
vim.opt.rtp:prepend(vim.env.HOME .. "/conf/vim")
-- ~/.vim still holds the spell files (plus the old config, harmless)
vim.opt.rtp:prepend(vim.env.HOME .. "/.vim")

-- Python host (needed by UltiSnips) -------------------------------------------
vim.g.python3_host_prog = vim.env.HOME .. "/.venvs/nvim/bin/python"

-- Plugin-side globals (must be set before the plugin loads) --------------------
vim.g.mapleader = " "
vim.g.UltiSnipsExpandTrigger       = "<C-j>"
vim.g.UltiSnipsJumpForwardTrigger  = "<C-l>"
vim.g.UltiSnipsJumpBackwardTrigger = "<C-h>"
vim.g.UltiSnipsEditSplit           = "vertical"
vim.g.snips_author = "jochen.illerhaus@student.kit.edu"
-- vim-markdown
vim.g.vim_markdown_follow_anchor             = 1
vim.g.vim_markdown_math                      = 1
vim.g.vim_markdown_toc_autofit               = 1
vim.g.vim_markdown_frontmatter               = 1
vim.g.vim_markdown_no_extensions_in_markdown = 1
vim.g.vim_markdown_folding_style_pythonic    = 1
vim.g.vim_markdown_fenced_languages = { "c++=cpp", "ini=dosini", "viml=vim", "bash=sh" }
vim.g.vim_markdown_conceal_code_blocks       = 0
vim.g.tex_conceal = "式"
-- bullets
vim.g.bullets_set_mappings             = 1
vim.g.bullets_pad_right                = 1
vim.g.bullets_checkbox_markers         = "✗◐✓"
vim.g.bullets_checkbox_partials_toggle = 1
vim.g.bullets_outline_levels           = { "num", "std-" }
-- medieval (evaluate code blocks in markdown)
vim.g.medieval_langs = { "python=python3", "sh", "console=bash", "zsh", "julia", "R" }
-- netrw
vim.g.netrw_liststyle       = 3
vim.g.netrw_banner          = 0
vim.g.netrw_localcopydircmd = "cp -r"
-- pandoc leftovers must stay off (we use vim-markdown)
vim.g["pandoc#syntax#style#use_definition_lists"] = 0

-- Options ---------------------------------------------------------------------
vim.opt.encoding      = "utf-8"
vim.opt.fileencodings = "utf-8"
vim.opt.showbreak     = "↪\\ "
vim.opt.list          = true
vim.opt.listchars     = "tab:▶‒,nbsp:␣,eol:↲,trail:∙,extends:▶,precedes:◀"
vim.opt.showcmd       = true
vim.opt.mouse         = "a"
vim.opt.updatetime    = 100                -- fast git signs
vim.opt.termguicolors = true
vim.opt.background    = "dark"

vim.opt.textwidth  = 80
vim.opt.tabstop    = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab  = true
vim.opt.joinspaces = true

vim.opt.completeopt = "longest,menuone,preview"
vim.opt.wildmenu    = true
vim.opt.wildmode    = "list:longest,full"
vim.opt.wildignore:append({
  "*.o", "*.obj", ".git", ".hg", "*.rbc", "*.pyc", "*.zip", "*.gz", "*.bz",
  "*.tar", "*.jpg", "*.png", "*.gif", "*.avi", "*.wmv", "*.ogg", "*.mp3",
  "*.mov", "*~", "tags", "cscope.out", "*.db", "*.pdf", "GTAGS", "GRTAGS",
  "GPATH", ".tmp", "*.exe", "*.lst", "*.gdx",
})

vim.opt.foldmethod    = "marker"
vim.opt.virtualedit   = "all"
vim.opt.spellsuggest  = "fast,10"
vim.opt.spell         = true
vim.opt.spelllang     = "en_us,de_de"
vim.opt.spellfile     = vim.env.HOME .. "/.vim/spell/en.utf-8.add"
vim.opt.spellfile:append(vim.env.HOME .. "/.vim/spell/de.utf-8.add")
vim.opt.dictionary    = "/usr/share/dict/words,/usr/share/dict/ngerman"

vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.wrap           = false
vim.opt.linebreak      = true
vim.opt.cursorline     = true
vim.opt.hidden         = true
vim.opt.autoread       = true
vim.opt.conceallevel   = 2
vim.opt.concealcursor  = ""
vim.opt.path:append("**")

vim.opt.grepprg = "rg --color=never --vimgrep"

-- active window brighter than inactive ones (replaces vimade)
vim.api.nvim_set_hl(0, "MyNormalNC", { fg = "#b2b2b2", bg = "#2c2c2c" })
vim.api.nvim_set_hl(0, "Normal",     { fg = "#b2b2b2", bg = "#404040" })
vim.opt.winhighlight = "NormalNC:MyNormalNC"

-- Colorscheme (custom, lives in conf/vim/colors/atom.vim)
pcall(vim.cmd.colorscheme, "atom")
vim.api.nvim_set_hl(0, "texMathSuper", { fg = "#d78787", bg = "NONE", default = true })
-- transparent background variant (for tmux panel backgrounds, as in old config):
-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })

-- filetype / syntax machinery is enabled by Neovim's defaults

-- color column tied to 'textwidth' (ported from old config)
local function set_color_column()
  local tw = vim.opt_local.textwidth:get()
  local cols = {}
  if tw > 0 then
    cols = { tostring(tw) }
    for c = tw + 20, 2000, 20 do cols[#cols + 1] = tostring(c) end
    vim.opt_local.colorcolumn = table.concat(cols, ",")
  else
    vim.opt_local.colorcolumn = ""
  end
end
vim.api.nvim_create_autocmd("BufWinEnter", { callback = set_color_column })
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "textwidth",
  callback = function()
    if vim.v.option_new and tonumber(vim.v.option_new) then set_color_column() end
  end,
})

-- =============================================================================
--  Statusline + tabline: built-in, no plugin (see lua/statusline.lua)
-- =============================================================================
vim.opt.statusline  = "%!v:lua.require('statusline').statusline()"
vim.opt.showtabline = 2
vim.opt.tabline     = "%!v:lua.require('statusline').tabline()"

-- =============================================================================
--  Plugins (lazy-loaded, see lua/plugins.lua)
-- =============================================================================
require("lazy").setup("plugins", {
  root = vim.fn.stdpath("data") .. "/lazy",
  defaults = { lazy = true },
  ui = { border = "rounded" },
  checker = { enabled = false },   -- no phone-home
  change_detection = { notify = false },
  performance = {
    rtp = {
      reset = false,  -- keep conf/vim & ~/.vim on the runtimepath (UltiSnips, colors, syntax)
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
  install = { colorscheme = { "atom", "habamax" } },
})

-- =============================================================================
--  Mappings  (keys unchanged from the old vimrc)
-- =============================================================================

-- leader: don't move on space
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>")

-- quickly reload this config
vim.keymap.set("n", "<leader>cl", "<Cmd>source $MYVIMRC<CR>", { desc = "reload configuration [:source $MYVIMRC]" })
-- key hint popup (replaces <leader>sh WhichKey fallback)
vim.keymap.set("n", "<leader>sh", function() require("which-key").show({ mode = "n", loop = true }) end,
  { desc = "show help for leaderless keys" })

-- --- c: Configuration --------------------------------------------------------
vim.keymap.set("n", "<leader>cv", "<Cmd>setlocal cursorcolumn!<CR>",   { desc = "toggle column highlighting" })
vim.keymap.set("n", "<leader>co", "<Cmd>setlocal spell!<CR>",          { desc = "toggle spell checking" })
vim.keymap.set("n", "<leader>cr", "<Cmd>setlocal relativenumber!<CR>", { desc = "toggle relative line numbering" })
vim.keymap.set("n", "<leader>cw", "<Cmd>setlocal wrap!<CR>",           { desc = "toggle line wrapping" })
vim.keymap.set("n", "<leader>ch", "<Cmd>noh<CR>",                      { desc = "stop highlighting search results" })
vim.keymap.set("n", "<leader>cC", "<Cmd>set conceallevel=0<CR>",       { desc = "disable conceal" })

-- --- spelling / misc ----------------------------------------------------------
vim.keymap.set("n", "ü", "z=", { desc = "suggest spelling [z=]" })
vim.keymap.set("n", "s",  "<Cmd>update<CR>", { desc = "update current buffer from disk" })

-- --- b: Buffer ----------------------------------------------------------------
vim.keymap.set("n", "<leader>bp", "<Cmd>bp<CR>", { desc = "goto previous buffer [<A-P>]" })
vim.keymap.set("n", "<leader>bn", "<Cmd>bn<CR>", { desc = "goto next buffer [<A-N>]" })
vim.keymap.set("n", "<leader>bd", "<Cmd>bd<CR>", { desc = "delete buffer/close file" })
vim.keymap.set("n", "<leader>be", "<Cmd>edit<CR>", { desc = "reload buffer" })
vim.keymap.set("n", "<leader>bT", "<Cmd>vsplit<CR><C-w>w<Cmd>terminal<CR>", { desc = "open new terminal vertical split" })
vim.keymap.set("n", "<leader>bt", "<Cmd>terminal<CR>", { desc = "open new terminal" })
vim.keymap.set("n", "<A-P>", "<Cmd>bp<CR>", { desc = "goto previous buffer" })
vim.keymap.set("n", "<A-N>", "<Cmd>bn<CR>", { desc = "goto next buffer" })

-- --- windows / tabs (unchanged) ------------------------------------------------
for _, m in ipairs({
  { "n", "<A-h>", "<C-w>h", "focus window left" },
  { "n", "<A-j>", "<C-w>j", "focus window below" },
  { "n", "<A-k>", "<C-w>k", "focus window above" },
  { "n", "<A-l>", "<C-w>l", "focus window right" },
  { "t", "<A-h>", "<C-\\><C-n><C-w>h", "focus window left" },
  { "t", "<A-j>", "<C-\\><C-n><C-w>j", "focus window below" },
  { "t", "<A-k>", "<C-\\><C-n><C-w>k", "focus window above" },
  { "t", "<A-l>", "<C-\\><C-n><C-w>l", "focus window right" },
  { "n", "<A-n>", "gt", "next tab" },
  { "n", "<A-p>", "gT", "previous tab" },
  { "t", "<A-n>", "<C-\\><C-n>gt", "next tab" },
  { "t", "<A-p>", "<C-\\><C-n>gT", "previous tab" },
}) do
  vim.keymap.set(m[1], m[2], m[3], { desc = m[4], silent = true })
end
vim.keymap.set("n", "<C-w>N", "<Cmd>tabmove +1<CR>", { desc = "move tab right" })
vim.keymap.set("n", "<C-w>P", "<Cmd>tabmove -1<CR>", { desc = "move tab left" })
vim.keymap.set({ "n", "t" }, "<C-w>-", "<C-\\><C-n><Cmd>split<CR>", { desc = "split window" })
vim.keymap.set({ "n", "t" }, "<C-w>|", "<C-\\><C-n><Cmd>vsplit<CR>", { desc = "vertical split" })
vim.keymap.set("n", "<C-w><C-j>", "<Cmd>resize -10<CR>",  { desc = "shrink height" })
vim.keymap.set("n", "<C-w><C-k>", "<Cmd>resize +10<CR>",  { desc = "grow height" })
vim.keymap.set("n", "<C-w><C-h>", "<Cmd>vertical resize -10<CR>", { desc = "shrink width" })
vim.keymap.set("n", "<C-w><C-l>", "<Cmd>vertical resize +10<CR>", { desc = "grow width" })
vim.keymap.set("n", "<leader>wh", "<Cmd>set wfh<CR>", { desc = "keep window height constant" })
vim.keymap.set("n", "<leader>ww", "<Cmd>set wfw<CR>", { desc = "keep window width constant" })

-- interactive resize mode, same keys as the old ResizeModeStart()
local extras = require("extras")
vim.keymap.set("n", "<C-w>.", function() extras.ResizeModeStart(".", vim.v.count1) end, { desc = "resize mode: grow height" })
vim.keymap.set("n", "<C-w>,", function() extras.ResizeModeStart(",", vim.v.count1) end, { desc = "resize mode: shrink height" })
vim.keymap.set("n", "<C-w>>", function() extras.ResizeModeStart(">", vim.v.count1) end, { desc = "resize mode: grow width" })
vim.keymap.set("n", "<C-w><", function() extras.ResizeModeStart("<", vim.v.count1) end, { desc = "resize mode: shrink width" })

-- --- q: Quickfix ----------------------------------------------------------------
vim.keymap.set("n", "]q", "<Cmd>cn<CR>", { desc = "next quickfix entry" })
vim.keymap.set("n", "[q", "<Cmd>cp<CR>", { desc = "previous quickfix entry" })
vim.keymap.set("n", "<leader>qn", "<Cmd>cn<CR>", { desc = "next quickfix entry" })
vim.keymap.set("n", "<leader>qp", "<Cmd>cp<CR>", { desc = "previous quickfix entry" })
vim.keymap.set("n", "<leader>qo", "<Cmd>copen<CR>", { desc = "open quickfix list" })
vim.keymap.set("n", "<leader>qc", "<Cmd>cclose<CR>", { desc = "close quickfix list" })
vim.keymap.set("n", "<leader>qC", function() vim.fn.setqflist({}) end, { desc = "clear quickfix list" })
vim.keymap.set("n", "<leader>qm", "<Cmd>make<CR>", { desc = "run make" })

-- --- l: Location list ------------------------------------------------------------
vim.keymap.set("n", "]l", "<Cmd>lnext<CR>", { desc = "next location" })
vim.keymap.set("n", "[l", "<Cmd>lprevious<CR>", { desc = "previous location" })
vim.keymap.set("n", "<leader>ln", "<Cmd>lnext<CR>", { desc = "next location" })
vim.keymap.set("n", "<leader>lp", "<Cmd>lprevious<CR>", { desc = "previous location" })
vim.keymap.set("n", "<leader>lo", "<Cmd>lopen<CR>", { desc = "open location list" })
vim.keymap.set("n", "<leader>lc", "<Cmd>lclose<CR>", { desc = "close location list" })
vim.keymap.set("n", "<leader>lC", function() vim.fn.setloclist(0, {}) end, { desc = "clear location list" })

-- --- n: Navigation ----------------------------------------------------------------
vim.keymap.set("n", "<leader>nn", "<Cmd>Lex 30<CR>", { desc = "toggle netrw sidebar [:Lexplore]" })

-- --- git (searching; hunk navigation is set up by gitsigns) ------------------------
vim.keymap.set("n", "<leader>gg", [[/^[>=<][>=<][>=<][>=<][>=<][>=<][>=<]<CR>]],
  { desc = "search next merge conflict" })

-- --- misc editing -------------------------------------------------------------------
vim.keymap.set("n", "<leader>bw", "<Cmd>w !sudo tee > /dev/null %<CR>", { desc = "write buffer as sudo" })

local function preserve(cmd)
  local view = vim.fn.winsaveview()
  vim.cmd(cmd)
  vim.fn.winrestview(view)
end
vim.keymap.set("n", "<leader>rw", function() preserve([[silent! %s/\s\+$//e]]) end,
  { desc = "strip trailing whitespace from buffer" })
vim.keymap.set("x", "<leader>rw", function() preserve([[silent! '<,'>s/\s\+$//e]]) end,
  { desc = "strip trailing whitespace from selection" })
vim.keymap.set("x", "<leader>ri", function()
  preserve([[silent! '<,'>!awk '{ match($0, /^( *)([^ ].*)$/, arr); l=length(arr[1]); if(l%4==0){ print substr(arr[1], 1, l/2) arr[2] } else { print $0 }}']])
end, { desc = "visually go from 4 to 2 space indent" })
vim.cmd([[command! -nargs=1 Chmod call system('chmod ' . <args> . ' ' . expand('%'))]])
vim.keymap.set("n", "<leader>rx", "<Cmd>Chmod '+x'<CR>", { desc = "make current file executable" })

-- move lines / chars with Alt+HJKL (replaces vim-move plugin)
vim.keymap.set("n", "<A-J>", "<Cmd>m .+1<CR>==", { desc = "move line down", silent = true })
vim.keymap.set("n", "<A-K>", "<Cmd>m .-2<CR>==", { desc = "move line up", silent = true })
vim.keymap.set("n", "<A-H>", function() extras.move_char(-1) end, { desc = "move char left", silent = true })
vim.keymap.set("n", "<A-L>", function() extras.move_char(1) end,  { desc = "move char right", silent = true })
vim.keymap.set("x", "<A-J>", "<Cmd>m '>+1<CR>gv=gv", { desc = "move selection down", silent = true })
vim.keymap.set("x", "<A-K>", "<Cmd>m '<-2<CR>gv=gv", { desc = "move selection up", silent = true })
vim.keymap.set("x", "<A-H>", "<Cmd>silent '<,'>s/^ //<CR><Cmd>noh<CR>gv", { desc = "move selection left", silent = true })
vim.keymap.set("x", "<A-L>", "<Cmd>silent '<,'>s/^/ /<CR><Cmd>noh<CR>gv", { desc = "move selection right", silent = true })

-- dates and times
vim.keymap.set("n", "<leader>et", "a<C-r>=strftime('%H:%M')<CR><Esc>",  { desc = "print current time" })
vim.keymap.set("n", "<leader>ed", "a<C-r>=strftime('%Y-%m-%d')<CR><Esc>", { desc = "print current date" })
vim.keymap.set("n", "<leader>eD", "a<C-r>=strftime('%Y-%m-%d %H:%M')<CR><Esc>", { desc = "print current datetime" })

-- system clipboard helpers (kept from old config; native clipboard also works)
vim.keymap.set("x", "<leader>ec", "!xclip -f -sel clip<CR>", { desc = "copy selection to system clipboard via xclip" })
vim.keymap.set("n", "<leader>ep", ":-1r !xclip -o -sel clip<CR>", { desc = "paste from system clipboard via xclip" })
vim.keymap.set("i", "<S-D-Insert>", "<C-R>+", { desc = "insert from clipboard (handy voice-to-text)" })

-- character inspection / misc (g-prefixed, same as before)
vim.keymap.set("n", "gs", "vdp", { desc = "switch current with next character" })
vim.keymap.set("n", "go", "<Cmd>!xdg-open <cfile><CR>", { desc = "open path under cursor in default viewer" })
vim.keymap.set("n", "gA", "<Cmd>ascii<CR>", { desc = "print ascii of character under cursor" })
vim.keymap.set("n", "gm", function()
  for _, id in ipairs(vim.fn.synstack(vim.fn.line("."), vim.fn.col("."))) do
    print(vim.fn.synIDattr(id, "name") .. " -> " .. vim.fn.synIDattr(vim.fn.synIDtrans(id), "name"))
  end
end, { desc = "show highlighting groups under cursor" })
vim.keymap.set("n", "gZ", "<C-]>", { desc = "jump through ctags" })

-- box drawing / editing positions that don't exist yet
vim.keymap.set("x", "<leader>db", ":!ascii2box.pl<CR>", { desc = "convert selection to box drawing diagram" })
vim.keymap.set("n", "<leader>dv", "<Cmd>set virtualedit+=all<CR>", { desc = "allow editing beyond end of line" })

-- combining characters / digraphs (ported from old config)
extras.digraphs()

-- markdown -> pdf preview link (kept from old config)
local function link_pdf_preview()
  local name = vim.fn.expand("%:p:r") .. ".pdf"
  if vim.fn.filereadable(name) == 1 then
    vim.fn.system({ "ln", "-sf", name, "/tmp/nvim-current-md.pdf" })
  end
end
-- disabled for test
vim.keymap.set("n", "<leader>sP",
  function() vim.fn.system({ "zathura", "--fork", "/tmp/nvim-current-md.pdf" }) end,
  { desc = "open current markdown preview in zathura" })

-- Pons dictionary lookup
vim.keymap.set("n", "<leader>se",
  "<Cmd>execute '!xdg-open \"https://en.pons.com/translate/spanish-german/' . expand('<cword>') . '\"'<CR>",
  { desc = "lookup current word on Pons" })

-- GAMS -----------------------------------------------------------------------
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "*.gms", "*.lst" },
  callback = function(a)
    if a.match:match("%.gms$") then
      vim.opt_local.filetype = "gams"
      vim.opt_local.foldmethod = "marker"
      vim.opt_local.commentstring = "#%s"
      vim.opt_local.foldmarker = "$onFold,$offFold"
    else
      vim.opt_local.filetype = "gamslst"
      vim.opt_local.buftype = "nowrite"
      vim.opt_local.spell = false
      vim.opt_local.wrap = false
    end
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gams", "gamslst" },
  callback = function()
    vim.keymap.set("n", "<leader>se", [[/\*\*\*\*\s*\(\$[0-9,]*\s*\)\+\s*$<CR>]],
      { buffer = true, desc = "GAMS search for error" })
    vim.keymap.set("n", "<leader>ss", "<Cmd>edit %:r.lst<CR>", { buffer = true, desc = "edit lst/gms" })
  end,
})
vim.cmd([[command GamsMakeSetup set efm=%f;%l;%c;%n;%m makeprg=gamserror\ %:r.lst]])
vim.keymap.set("n", "<leader>sg", "<Cmd>GamsMakeSetup<CR>", { desc = "setup make for GAMS" })

-- Matlab ----------------------------------------------------------------------
vim.keymap.set("n", "<leader>rm", function() extras.matlab_run(vim.fn.expand("<cword>")) end,
  { desc = "run word under cursor in Matlab environment" })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "matlab",
  callback = function()
    vim.opt_local.commentstring = "%%%s"
    vim.keymap.set("n", "K", function() extras.matlab_run("help " .. vim.fn.expand("<cword>")) end,
      { buffer = true, desc = "Matlab help for word under cursor" })
  end,
})

-- :Shell – show command output in a new window (kept from old config)
vim.cmd([[command! -complete=shellcmd -nargs=+ Shell call v:lua.require('extras').execute_in_shell(<q-args>)]])

-- terminal buffers -------------------------------------------------------------
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.spell = false
    vim.opt_local.cursorline = false
    vim.opt_local.cursorcolumn = false
    vim.opt_local.scrolloff = 0
  end,
})
vim.api.nvim_create_autocmd("BufEnter", { pattern = "term://*", command = "startinsert" })
vim.keymap.set("t", "<C-g>", "<C-\\><C-n>", { desc = "leave terminal to normal mode" })
vim.keymap.set("t", "<C-e>", function()
  local c = vim.fn.nr2char(vim.fn.getchar())
  return "<C-\\><C-n>\"" .. c .. "pi"
end, { expr = true, desc = "paste register in terminal" })

-- (floating terminals removed — unused; use <leader>bt / <leader>bT for split terminals)

-- fold helper (treesitter folding, replaces old nvim_treesitter#foldexpr)
vim.keymap.set("n", "<leader>bs", function()
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
end, { desc = "fold based on treesitter" })

-- spell errors into quickfix/location list (via vim-SpellCheck, key-loaded)
vim.keymap.set("n", "<leader>qs", "<Cmd>SpellCheck<CR><Cmd>copen<CR>",   { desc = "quickfix list with spelling errors" })
vim.keymap.set("n", "<leader>ls", "<Cmd>SpellLCheck<CR><Cmd>lopen<CR>", { desc = "location list with spelling errors" })

-- Neovide-only cosmetics
if vim.g.neovide then
  vim.g.neovide_cursor_vfx_mode = "railgun"
end

-- =============================================================================
--  LSP: completely manual. Nothing attaches until you call
--      :LspStart            (picks a server based on the current filetype)
--      :LspStart clangd     (or any server name)
--      :LspStop
--  See lua/lsp.lua
-- =============================================================================
require("lsp").commands()

-- firenvim / neovide laststatus handling is gone; firenvim was removed (see REVIEW.md)
