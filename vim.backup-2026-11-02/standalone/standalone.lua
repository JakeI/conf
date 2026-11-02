-- TODO: checkout how `vim-pandoc/autoload/markdown/tex.vim` works this might 
--       be a lot smarter than this mess right here
--       or maybe use treesitter supposedly that is possible some how
--       
--       used `nmap g1 :lua print(require('nvim-treesitter.ts_utils').get_node_at_cursor(nil))<CR>`
--       This seams to work in e.g. *.c files but doesn't in markdown files
--       In Buffer with Filetype Pandoc the output is just nil   not sure why
--       In Buffer with Filetype Markdown this works but math isn't
--       standardized/recognized so math just gives node_paragraph just like
--       everything else around it
--       also see here: https://www.reddit.com/r/neovim/comments/pjgn7n/how_to_check_if_youre_in_markdown_math/
--
--       if this would be expanded to deal with tex some day
--       `vimtex#syntax#in_mathzone()` might be useful

-- TODO Considere using vim builtin searchpair({start}, {middle}, {end}) or similar

-- TODO: This keeps failing if there are only very view lines in the files

local BLOCK_GROUP   = "pandocLaTeXMathBlock"
local INLINE_GROUP  = "pandocLaTeXInlineMath"
local LATEX_BLOCK   = "pandocLaTeXRegion"
local MAX_MATH_SIZE = 50  -- TODO: Increase for production
local TMP_FILE_NAME = "/tmp/nvim-preview.tex"
-- used gm alias with courser above those file names to find those

-- TODO: figer out how to display images wiht that
--local REFERENCE_DEFINE = "pandocReferenceDefinition"

local filetype_match = function()
    if vim.bo == nil then
        return false  -- for some reason kitty conf buffers don't have this value
    end
    return vim.bo.filetype == "pandoc"
end

local block_type = function(lne, col)
    local lst = vim.fn.synstack(lne, col)
    for k, i1 in pairs(lst) do
        local i2 = vim.fn.synIDtrans(i1)
        local n1 = vim.fn.synIDattr(i1, 'name')
        local n2 = vim.fn.synIDattr(i2, 'name')
        if n1 == BLOCK_GROUP or n2 == BLOCK_GROUP then
            return 2
        elseif n1 == INLINE_GROUP or n2 == INLINE_GROUP then
            return 1
        elseif n1 == LATEX_BLOCK or n2 == LATEX_BLOCK then
            return 3
        end
    end
    return nil
end

local max = function(a, b)
    if a > b then
        return a
    else
        return b
    end
end

local gen_search_chunk = function(lne)
    local start = lne - MAX_MATH_SIZE - 1
    local first = max(start, 0)
    local finish = lne + MAX_MATH_SIZE  -- TODO: maybe add minimum
    local lines = vim.api.nvim_buf_get_lines(0, first, finish, false)
    for i=1,first-start do
        table.insert(lines, 0, nil)
    end
    -- print(start .. "," .. first .. "," .. finish .. "," .. #lines)
    return lines
end

local cut_at_block_end = function(col, marker, chunk)
    -- if chunk == nil then
    --     return nil
    -- end
    local found = false
    for i = MAX_MATH_SIZE+1, #chunk, 1 do
        if found then
            chunk[i] = ""
        else
            local s, e = string.find(chunk[i], marker, col)
            col = 0
            if e then
                chunk[i] = string.sub(chunk[i], 0, e)
                found = true
            end
        end
    end
    if found then
        return chunk
    end
    return nil
end

local rfind = function(str, src, idx)
    local a = -1 
    local b
    local s
    local e
    if str == nil or src == nil or idx == nil then
        return nil, nil
    end
    while a ~= nil do
        a, b = string.find(str, src, idx + a + 1)
        if not a then
            return s, e
        else
            s = a
            e = b
        end
    end
    return nil, nil
end

local cut_at_block_start = function(col, marker, chunk)
    if chunk == nil then
        return nil
    end
    local found = false
    local first = true  -- technically unnecessary because this is always called after cut_at_block_end
    local marker = marker
    for i = MAX_MATH_SIZE+1, 0, -1 do
        if found then
            chunk[i] = ""
        else
            local str = first and string.sub(chunk[i], 0, col) or chunk[i]
            local s, e = rfind(str, marker, 0)
            first = false
            if s then
                chunk[i] = string.sub(chunk[i], s, string.len(chunk[i]))
                found = true
            end
        end
    end
    if found then
        return chunk
    end
    return nil
end

local concat = function(lines)
    -- different from table.concat(chunk, "\n") because this
    -- will also filter nil values instead of printing empty lines
    -- TODO: make this Funktion redundant by optimizing the cut_at_block_*
    --       Funktion so the won't produce nil in chunk
    local agg = ""
    for i, l in pairs(lines) do
        if string.len(l) > 0 then
            agg = agg .. l .. "\n"
        end
    end
    return agg
end

local extract_math_block = function(lne, col, tpy)
    local marker_start
    local marker_end
    if tpy == 2 then
        marker_start = '[^\\]?%$%$'
        marker_end = marker_start
    elseif tpy == 1 then
        marker_start = '[^\\]?%$'
        marker_end = marker_start
    elseif tpy == 3 then
        marker_start = '\\begin%{tikzpicture%}'
        marker_end = '\\end%{tikzpicture%}'
    else
        return nil
    end
    local chunk = gen_search_chunk(lne)
    local c = chunk[MAX_MATH_SIZE+1]  -- TODO: handle case when min function in gen_search_chunk is used
    if c then
        local current_char = string.sub(c, col, col)
        if current_char == '$' and (tpy == 1 or typ == 2) then  -- unclear weather this is the start or end of a maths block (be save and don't do anything)
            return nil
        end
    else
        return nil
    end
    chunk = cut_at_block_end(col, marker_end, chunk)
    chunk = cut_at_block_start(col, marker_start, chunk)
    if chunk then
        return concat(chunk)
    else
        return nil
    end
end

local update_needed = function(math)
    if math and math ~= vim.g.currently_displayed then
        vim.g.currently_displayed = math
        return math
    end
    return nil
end

local apply_filters = function(math)
    if not math then
        return nil
    end
    return vim.fn.system("/home/ji/conf/tex/replace-combining.sh", math)
    -- return math
end

local write_tex_code = function(math)
    if not math then
        return nil
    end
    local extras = "\\usepackage{greek}\n\\usepackage{upgreek}"
    local opts = "preview,varwidth"
    if string.find(math, "tikzpicture") then
        extras = extras .. "\n\\input{/home/ji/conf/tex/tikz.tex}"
        opts = "crop,tikz"
    end
    local s = table.concat({
        "\\documentclass[" .. opts .."]{standalone}",
        "\\usepackage{amsmath}",
        extras,
        "\\begin{document}",
        math,
        "\\end{document}"
    }, "\n")
    local f = io.open(TMP_FILE_NAME, 'w')
    f:write(s)
    io.close(f)
    return true
end

local run_latex = function()
    local cmd = table.concat({
        'xelatex',
        '-interaction=batchmode', 
        '-output-directory=/tmp', 
        '-output-comment=nvim-preview',
        TMP_FILE_NAME
    }, " ")
    if vim.g.handle then  -- kill there should only ever by one preview
        vim.fn.jobstop(vim.g.handle)
    end
    vim.g.handle = vim.fn.jobstart(cmd)
end

local lne = vim.fn.line('.')
local col = vim.fn.col('.')
if filetype_match() then
    local tpy = block_type(lne, col)
    local tmp = extract_math_block(lne, col, tpy)
    tmp = update_needed(tmp)
    tmp = apply_filters(tmp)
    tmp = write_tex_code(tmp) 
    if tmp then
        run_latex()
    end
end
