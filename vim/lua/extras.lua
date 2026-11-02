-- extras.lua – small utilities ported from the old vimrc, no plugin needed
local M = {}

-- =============================================================================
--  Resize mode (same interface as the old vimscript ResizeModeStart)
--  <C-w>. grow height, <C-w>, shrink height, <C-w>> grow width, <C-w>< shrink width
--  while in mode: same key repeats, h/j/k/l = factor 3, 1-9 sets count,
--  ; decrements count, : increments count, any other key exits and is replayed
-- =============================================================================
function M.ResizeModeStart(direction, count)
  local action_map = { ["."] = "+", [","] = "-", ["<"] = "<", [">"] = ">" }
  local triple_map = { k = "+", j = "-", h = "<", l = ">" }
  local full_map = vim.tbl_extend("force", action_map, triple_map)
  local c = direction
  count = count or 1
  local factor = 1
  while true do
    if factor > 0 then
      vim.cmd(count * factor .. "wincmd " .. full_map[c])
    end
    vim.cmd("redraw")
    vim.api.nvim_echo({ { "-- RESIZE(f=" .. count .. ") --", "ModeMsg" } }, false, {})
    local ok, raw = pcall(vim.fn.getchar)
    if not ok then break end
    factor = 0
    local key = type(raw) == "number" and vim.fn.nr2char(raw) or raw
    if full_map[key] then
      c = key
      factor = triple_map[key] and 3 or 1
    elseif key:match("^%d$") then
      count = tonumber(key)
    elseif key == ";" and count >= 2 then
      count = count - 1
    elseif key == ":" then
      count = count + 1
    else
      -- exit: clear the echo, replay the terminating keypress
      vim.api.nvim_echo({}, false, {})
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(key, true, false, true), "mt", false)
      break
    end
  end
end

-- =============================================================================
--  Floating terminals (replacement for vim-floaterm; F8 new, F9/F10 cycle,
--  F12 toggle)
-- =============================================================================
local terms = {}   -- list of { buf = bufnr, win = nil }
local cur = 0

local function win_opts()
  return {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.9),
    height = math.floor(vim.o.lines * 0.9),
    col = math.floor(vim.o.columns * 0.05),
    row = math.floor(vim.o.lines * 0.05),
    border = "rounded",
  }
end

local function show(t)
  t.win = vim.api.nvim_open_win(t.buf, true, win_opts())
  vim.cmd("startinsert")
end

function M.floatterm_new()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  local t = { buf = buf, win = nil }
  terms[#terms + 1] = t
  cur = #terms
  show(t)
  vim.fn.termopen(vim.env.SHELL or "sh", { on_exit = function()
    if t.win and vim.api.nvim_win_is_valid(t.win) then vim.api.nvim_win_close(t.win, true) end
    t.win = nil
  end })
end

function M.floatterm_toggle()
  if cur == 0 or not terms[cur] then return M.floatterm_new() end
  local t = terms[cur]
  if t.win and vim.api.nvim_win_is_valid(t.win) then
    vim.api.nvim_win_hide(t.win)
    t.win = nil
  else
    show(t)
  end
end

function M.floatterm_cycle(step)
  if #terms == 0 then return M.floatterm_new() end
  if cur == 0 then cur = 1 else cur = ((cur - 1 + step) % #terms) + 1 end
  local t = terms[cur]
  if t.win and vim.api.nvim_win_is_valid(t.win) then
    vim.api.nvim_set_current_win(t.win)
  else
    show(t)
  end
end

-- =============================================================================
--  Move single character left/right (replacement for vim-move MoveChar*)
-- =============================================================================
function M.move_char(dir)
  if dir < 0 and vim.fn.col(".") <= 1 then return end
  if dir > 0 and vim.fn.col(".") >= vim.fn.col("$") - 1 then return end
  -- swap char under cursor with the one left/right of it
  vim.cmd(dir < 0 and "silent! normal! Xp" or "silent! normal! xp")
end

-- =============================================================================
--  ExecuteInShell – run a shell command, show output in a split window
-- =============================================================================
function M.execute_in_shell(command)
  -- expand % like the old version did
  command = command:gsub("%%", function() return vim.fn.expand("%") end)
  local winnr = vim.fn.bufwinnr("^" .. command .. "$")
  if winnr < 0 then
    vim.cmd("botright new | resize 15")
    vim.api.nvim_buf_set_name(0, command)
    vim.bo.buftype = "nowrite"
    vim.bo.bufhidden = "wipe"
    vim.bo.noswapfile = true
    vim.bo.buflisted = false
    vim.opt_local.wrap = false
    vim.bo.filetype = "output"
  else
    vim.cmd(winnr .. "wincmd w")
  end
  vim.fn.setline(1, vim.fn.systemlist(command))
  vim.keymap.set("n", "r", function() M.execute_in_shell(command) end, { buffer = true, desc = "rerun command" })
end

-- =============================================================================
--  Matlab helpers (kept from old config; output via ExecuteInShell)
-- =============================================================================
function M.matlab_run(cmd)
  local j = "jupyter console --existing=nvim-connection-imatlab.json --kernel imatlab --no-confirm-exit --simple-promp"
  local filter = "tail -n +4 | head -n -2 | sed -E '1 s/^In \\[[0-9]*\\]: //'"
  M.execute_in_shell('echo "' .. cmd .. '" | ' .. j .. " | " .. filter)
end

-- =============================================================================
--  Digraphs (ported from old config: custom digraphs + greek.sty)
-- =============================================================================
function M.digraphs()
  -- combining characters
  vim.fn.digraph_set("--", vim.fn.nr2char(772))   -- combining overbar      a̅
  vim.fn.digraph_set("__", vim.fn.nr2char(818))   -- combining underline    a̲
  vim.fn.digraph_set("^^", vim.fn.nr2char(769))   -- combining caret above  â
  vim.fn.digraph_set("^.", vim.fn.nr2char(775))   -- combining dot above    ȧ
  vim.fn.digraph_set("::", vim.fn.nr2char(776))   -- combining double dots  ä
  vim.fn.digraph_set("\\>", vim.fn.nr2char(8407)) -- combining arrow above  a⃗
  vim.fn.digraph_set("^~", vim.fn.nr2char(771))   -- combining tilde above  ã

  local path = vim.env.HOME .. "/conf/tex/greek.sty"
  if vim.fn.filereadable(path) == 0 then return end
  for _, line in ipairs(vim.fn.readfile(path)) do
    if line:match("\\newunicodechar{.}") and line:match("§..") then
      local chr = line:match("\\newunicodechar{(.)}")
      local dig = line:match("§(..)")
      if chr and dig then pcall(vim.fn.digraph_set, dig, chr) end
    end
  end
end

return M
