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
  org = true, asciidoc = true, mail = true, nroff = true,plaintex = true,
}

local function git_branch()
  -- gitsigns keeps this up to date; empty when no git repo / no gitsigns
  local g = vim.b.gitsigns_status_dict
  if g and g.head and g.head ~= "" then return " ⎇ " .. g.head end
  return ""
end

local function diagnostics()
  if not vim.diagnostic.is_enabled or not vim.diagnostic.is_enabled() then return "" end
  local c = vim.diagnostic.count(0)
  local s = {}
  if (c.error or 0) > 0 then s[#s + 1] = "E:" .. c.error end
  if (c.warn or 0) > 0 then s[#s + 1] = "W:" .. c.warn end
  if #s == 0 then return "" end
  return " [" .. table.concat(s, " ") .. "]"
end

local function encoding()
  local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
  local ff = vim.bo.fileformat
  if enc == "utf-8" and ff == "unix" then return "" end
  return " " .. enc .. "[" .. ff .. "]"
end

function M.statusline()
  local mode = modes[vim.fn.mode()] or vim.fn.mode():upper()

  local spell = vim.wo.spell and (" SPELL:" .. vim.o.spelllang) or ""
  local tablemode = vim.g.table_mode_enabled and " TABLE" or ""

  local fname = "%f%m%r"
  local branch = git_branch()
  local diag = diagnostics()

  local right = {}
  right[#right + 1] = vim.bo.filetype ~= "" and vim.bo.filetype or "no ft"
  right[#right + 1] = encoding()
  right[#right + 1] = "%=%l:%c/%L %p%%"
  if prose[vim.bo.filetype] then
    local ok, wc = pcall(vim.fn.wordcount)
    if ok and wc and wc.words then right[#right + 1] = wc.words .. "w" end
  end

  return table.concat({
    "%#StatusLine#", mode, spell, tablemode,
    "%#StatusLineNC#  ", fname, branch, diag,
    "%#StatusLine#  ", table.concat(right, "  "),
  })
end

-- =============================================================================
--  Tabline: buffer list, like the old airline tabline
-- =============================================================================
function M.tabline()
  local s = {}
  local cur = vim.api.nvim_get_current_buf()
  local n = 0
  for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    n = n + 1
    if n > 15 then break end   -- keep it cheap with many buffers
    local name = vim.fn.fnamemodify(b.name, ":t")
    if name == "" then name = "[No Name]" end
    local hl = (b.bufnr == cur) and "%#TabLineSel#" or "%#TabLine#"
    s[#s + 1] = hl .. " " .. b.bufnr .. ":" .. name
    if b.changed == 1 then s[#s + 1] = " ⚡" end
    s[#s + 1] = "%T"   -- click target
  end
  if #s == 0 then s[#s + 1] = "%#TabLine# [No Name]" end
  s[#s + 1] = "%#TabLineFill#%=%#TabLine# " .. #vim.fn.getbufinfo({ buflisted = 1 }) .. " buf"
  return table.concat(s)
end

return M
