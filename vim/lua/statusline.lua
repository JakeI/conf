-- statusline.lua – built-in statusline/tabline, no plugin (replaces vim-airline)
local M = {}

local modes = {
  n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE",
  ["\22"] = "V-BLOCK", c = "COMMAND", t = "TERM", R = "REPLACE",
  s = "SELECT", S = "S-LINE", ["\19"] = "S-BLOCK",
}

-- filetypes where a word count is useful (same list as old airline config)
local prose = {
  markdown = true, pandoc = true, tex = true, text = true, rst = true,
  org = true, asciidoc = true, mail = true, nroff = true, plaintex = true,
}

local word_counts = {}
vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("ConfigStatusline", { clear = true }),
  callback = function(args) word_counts[args.buf] = nil end,
})

local function word_count(win, buf)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local cached = word_counts[buf]
  if not cached or cached.tick ~= tick then
    -- wordcount() scans the whole buffer, even on cursor-only redraws. The
    -- total (unlike cursor/visual counts) only needs updating after an edit.
    local wc = win == vim.api.nvim_get_current_win() and vim.fn.wordcount()
      or vim.api.nvim_win_call(win, vim.fn.wordcount)
    cached = { tick = tick, words = wc.words }
    word_counts[buf] = cached
  end
  return cached.words
end

local function escape(text)
  return (text:gsub("%%", "%%%%")) -- literal text must not become statusline syntax
end

local function git_branch(buf)
  -- gitsigns keeps this up to date; empty when no git repo / no gitsigns
  local g = vim.b[buf].gitsigns_status_dict
  if g and g.head and g.head ~= "" then return " ⎇ " .. escape(g.head) end
  return ""
end

local function diagnostics(buf)
  if not vim.diagnostic.is_enabled({ bufnr = buf }) then return "" end
  local c = vim.diagnostic.count(buf)
  local s = {}
  local errors, warnings = c[vim.diagnostic.severity.ERROR] or 0, c[vim.diagnostic.severity.WARN] or 0
  if errors > 0 then s[#s + 1] = "E:" .. errors end
  if warnings > 0 then s[#s + 1] = "W:" .. warnings end
  if #s == 0 then return "" end
  return " [" .. table.concat(s, " ") .. "]"
end

-- spell languages as compact emoji flags (en→🇬🇧, de→🇩🇪, …), plain code as fallback
local spell_flags = {
  en = "🇬🇧", de = "🇩🇪", fr = "🇫🇷", es = "🇪🇸", it = "🇮🇹", nl = "🇳🇱",
  ru = "🇷🇺", pt = "🇵🇹", sv = "🇸🇪", da = "🇩🇰", no = "🇳🇴", fi = "🇫🇮",
  pl = "🇵🇱", cs = "🇨🇿", hu = "🇭🇺", tr = "🇹🇷", ca = "🇨🇦", sl = "🇸🇮",
}
local spell_lang, spell_text
local function spell(win, buf)
  if not vim.wo[win].spell then return "" end
  local langs = vim.bo[buf].spelllang
  if langs == spell_lang then return spell_text end
  local out = {}
  for lang in vim.gsplit(langs, ",", { plain = true }) do
    if lang ~= "" then
      local code = lang:match("^(%a%a)")
      out[#out + 1] = spell_flags[code] or lang
    end
  end
  spell_lang, spell_text = langs, " " .. table.concat(out)
  return spell_text
end

local function encoding(buf)
  local enc = vim.bo[buf].fileencoding
  if enc == "" then enc = vim.o.encoding end
  local ff = vim.bo[buf].fileformat
  if enc == "utf-8" and ff == "unix" then return "" end
  return " " .. enc .. "[" .. ff .. "]"
end

function M.statusline()
  -- %! expressions run in the focused window, not necessarily the window being drawn.
  local win = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local ft = vim.bo[buf].filetype
  local mode = modes[vim.fn.mode()] or vim.fn.mode():upper()

  local spell_txt = spell(win, buf)
  local tablemode = vim.b[buf].table_mode_active == 1 and " TABLE" or ""

  local fname = "%f%m%r"
  local branch = git_branch(buf)
  local diag = diagnostics(buf)

  local right = {}
  right[#right + 1] = ft ~= "" and escape(ft) or "no ft"
  right[#right + 1] = encoding(buf)
  right[#right + 1] = "%=%l:%c/%L %p%%"
  if prose[ft] then
    right[#right + 1] = word_count(win, buf) .. "w"
  end

  return table.concat({
    "%#StatusLine#", mode, spell_txt, tablemode,
    "%#StatusLineNC#  ", fname, branch, diag,
    "%#StatusLine#  ", table.concat(right, "  "),
  })
end

-- =============================================================================
--  Tabline: buffers when a single tab is open, tabs when multiple tabs exist
-- =============================================================================
function M.tabline()
  local s = {}
  local tabs = vim.api.nvim_list_tabpages()
  if #tabs > 1 then
    -- multiple tabs: show tabs only
    local current = vim.api.nvim_get_current_tabpage()
    for i, tab in ipairs(tabs) do
      local cur = tab == current
      local name = ""
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local b = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[b].filetype
        if ft ~= "netrw" then name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t") break end
      end
      if name == "" then name = "[No Name]" end
      local hl = cur and "%#TabLineSel#" or "%#TabLine#"
      s[#s + 1] = "%" .. i .. "T" .. hl .. " " .. i .. ":" .. escape(name)
      s[#s + 1] = "%T"
    end
    s[#s + 1] = "%#TabLineFill#%=%#TabLine# " .. #tabs .. " tabs"
    return table.concat(s)
  end
  -- single tab: show buffers (like the old airline tabline)
  local cur = vim.api.nvim_get_current_buf()
  local n = 0
  -- getbufinfo() also copies every buffer's variables; only request the fields we use.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_get_option_value("buflisted", { buf = buf }) then
      n = n + 1
      if n <= 15 then
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
        if name == "" then name = "[No Name]" end
        local hl = (buf == cur) and "%#TabLineSel#" or "%#TabLine#"
        s[#s + 1] = hl .. " " .. buf .. ":" .. escape(name)
        if vim.bo[buf].modified then s[#s + 1] = " ⚡" end
      end
    end
  end
  if #s == 0 then s[#s + 1] = "%#TabLine# [No Name]" end
  s[#s + 1] = "%#TabLineFill#%=%#TabLine# " .. n .. " buf"
  return table.concat(s)
end

return M
