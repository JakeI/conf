-- plugins.lua – lazy.nvim spec. Everything is lazy-loaded:
--   * nothing loads for a plain markdown/text file except the statusline
--   * picker/pickers load on first <leader>f keypress
--   * LSP stack loads only via :LspStart
--   * tex/csv/… load only for those filetypes
return {
  ---------------------------------------------------------------------------
  -- Picker: Telescope (replaces fzf.vim; same <leader>f* keys)
  ---------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      "<leader>ff", "<leader>fg", "<leader>fG", "<leader>fb", "<leader>fS",
      "<leader>fl", "<leader>fL", "<leader>ft", "<leader>fT", "<leader>fm",
      "<leader>fw", "<leader>fh", "<leader>f:", "<leader>f/", "<leader>fc",
      "<leader>fC", "<leader>fM", "<leader>fH", "<leader>fF",
      "<leader>bf", "<leader>nr", "<leader>nf", "gz", "<leader>gs",
      { "<C-x><C-r>", mode = "i" },
    },
    config = function()
      local actions = require("telescope.actions")
      require("telescope").setup({
        defaults = {
          mappings = {
            i = { ["<C-t>"] = actions.select_tab },  -- like old fzf_action
            n = { ["<C-t>"] = actions.select_tab },
          },
        },
      })
      local tb = require("telescope.builtin")
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
      end

      -- custom "Windows" picker (fzf's :Windows equivalent; removed from telescope 0.2)
      local windows_picker = function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local sorters = require("telescope.config").values
        local state = require("telescope.actions.state")
        local wins = {}
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local b = vim.api.nvim_win_get_buf(w)
          local name = vim.api.nvim_buf_get_name(b)
          name = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or ("[No Name] " .. b)
          wins[#wins + 1] = {
            win = w,
            text = string.format("win %d: %s%s", w, name,
              w == vim.api.nvim_get_current_win() and " (current)" or ""),
          }
        end
        pickers.new({}, {
          prompt_title = "Windows",
          finder = finders.new_table({
            results = wins,
            entry_maker = function(e)
              return { value = e, display = e.text, ordinal = e.text }
            end,
          }),
          sorter = sorters.generic_sorter({}),
          attach_mappings = function(buf)
            actions.select_default:replace(function()
              local e = state.get_selected_entry()
              actions.close(buf)
              if e then vim.api.nvim_set_current_win(e.value.win) end
            end)
            return true
          end,
        }):find()
      end

      map("<leader>ff", tb.find_files,                "Find files")
      map("<leader>fg", tb.git_files,                 "Git files (git ls-files)")
      map("<leader>fG", tb.git_status,                "Git files git status")
      map("<leader>gs", tb.git_status,                "Git files git status")
      map("<leader>fb", tb.buffers,                   "Open buffers")
      map("<leader>bf", tb.buffers,                   "Find buffers")
      map("<leader>fS", tb.colorscheme,               "Color schemes")
      map("<leader>fl", tb.live_grep,                 "Lines (was: open buffers, now project-wide)")
      map("<leader>fL", tb.current_buffer_fuzzy_find, "Lines in current buffer")
      map("<leader>ft", tb.tags,                      "Tags")
      map("<leader>fT", tb.current_buffer_tags,       "Tags in current buffer")
      map("<leader>fm", tb.marks,                     "Marks")
      map("<leader>fw", windows_picker,               "Windows")
      map("<leader>fh", tb.oldfiles,                  "History")
      map("<leader>f:", tb.command_history,           "Command history")
      map("<leader>f/", tb.search_history,            "Search history")
      map("<leader>fs", "<Cmd>Snippets<CR>",          "Snippets")
      map("<leader>fc", tb.git_commits,               "Commits")
      map("<leader>fC", tb.git_bcommits,              "Commits for current buffer")
      map("<leader>fM", tb.keymaps,                   "Keyboard mappings")
      map("<leader>fH", tb.help_tags,                 "Helptags")
      map("<leader>fF", tb.filetypes,                 "Filetypes")
      map("<leader>nr", function() tb.live_grep({ default_text = vim.fn.expand("<cword>") }) end,
        "search for current word")
      map("<leader>nf", function() tb.tags({ default_text = vim.fn.expand("<cword>") }) end,
        "find tags for word under cursor")
      map("gz", function() tb.tags({ default_text = vim.fn.expand("<cword>") }) end,
        "find tags for word under cursor")

      -- insert-mode completion via <C-x>… (kept from old fzf config)
      vim.keymap.set("i", "<C-x><C-p>", "<C-x><C-f>", { desc = "path completion" })
      vim.keymap.set("i", "<C-x><C-s>", "<Cmd>Snippets<CR>", { desc = "snippet completion" })
      vim.keymap.set("i", "<C-w>", "<C-x><C-k>", { desc = "dictionary word completion" })

      -- bibtex completion (was fzf grep over *.bib)
      vim.keymap.set("i", "<C-x><C-r>", function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local sorters = require("telescope.config").values
        local act_state = require("telescope.actions.state")
        local entries = vim.fn.systemlist(
          "grep -o '^@.*{.*' *.bib 2>/dev/null | sed -e 's/^@.*{/@/;s/,$//'")
        pickers.new({}, {
          prompt_title = "BibTeX",
          finder = finders.new_table({ results = entries }),
          sorter = sorters.generic_sorter({}),
          attach_mappings = function(buf)
            actions.select_default:replace(function()
              local entry = act_state.get_selected_entry()
              actions.close(buf)
              if entry then vim.api.nvim_put({ entry.value }, "", true, true) end
            end)
            return true
          end,
        }):find()
      end, { desc = "bibtex completion" })
    end,
  },

  ---------------------------------------------------------------------------
  -- which-key: same popup UX as vim-which-key, descriptions come from
  -- the `desc` field of every mapping in init.lua
  ---------------------------------------------------------------------------
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").add({
        { "<leader>",  group = "general commands: general commands" },
        { "<leader>a", group = "OpenCode" },
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Configuration" },
        { "<leader>d", group = "Boxdraw" },
        { "<leader>e", group = "Edit" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "Location" },
        { "<leader>n", group = "Navigation" },
        { "<leader>q", group = "Quickfix" },
        { "<leader>r", group = "Run" },
        { "<leader>s", group = "Specific" },
        { "<leader>S", group = "Spectre" },
        { "<leader>t", group = "Table" },
        { "<leader>v", group = "csv" },
        { "<leader>w", group = "Window" },
        { "<leader>x", group = "VimTeX" },
        { "<C-w>",     group = "window commands" },
        { "z",         group = "z key" },
        { "zZ",        desc = "center current line in screen (zz)" },
        { "za",        desc = "open/close current fold" },
        { "zg",        desc = "add current word to dictionary" },
        { "zG",        desc = "add current word to internal wordlist" },
        { "zw",        desc = "mark current word as wrong" },
        { "zu",        group = "undo zg/zw" },
        { "]c",        desc = "next git hunk" },
        { "[c",        desc = "previous git hunk" },
        { "]d",        desc = "next lsp diagnostic (when LSP is running)" },
        { "[d",        desc = "previous lsp diagnostic (when LSP is running)" },
        { "ic",        desc = "git hunk text object (inner)" },
        { "ac",        desc = "git hunk text object (outer)" },
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- git signs (replaces vim-gitgutter, same hunk keys)
  ---------------------------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function()
      local gs = require("gitsigns")
      gs.setup({
        signs = { add = { text = "+" }, change = { text = "~" }, delete = { text = "_" } },
        on_attach = function(bufnr)
          local m = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end
          m("n", "]c", function() gs.nav_hunk("next") end, "next git hunk")
          m("n", "[c", function() gs.nav_hunk("prev") end, "previous git hunk")
          m("n", "<leader>gG", gs.toggle_current_line_highlights, "toggle git gutter visibility")
          m("n", "<leader>gu", gs.reset_hunk,        "git undo current hunk")
          m("v", "<leader>gu", function() gs.reset_hunk({}) end, "git undo selected hunks")
          m("n", "<leader>gp", gs.preview_hunk,      "git preview current hunk")
          m({ "o", "x" }, "ic", gs.select_hunk, "git hunk text object (inner)")
          m({ "o", "x" }, "ac", gs.select_hunk, "git hunk text object (outer)")
        end,
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- core editing helpers (tiny, vimscript)
  ---------------------------------------------------------------------------
  { "tpope/vim-sleuth",        event = "VeryLazy" },          -- tab size detection
  { "tpope/vim-commentary",    keys = { "gc", "gcc", "gcu" }, cmd = "Commentary" },
  { "tpope/vim-surround",      keys = { "ys", "yS", "cs", "ds", "S" } },
  { "andymass/vim-matchup",    keys = { "%", "g%", "[%", "]%" } },

  -- EasyAlign (ga, same custom delimiters as before)
  {
    "junegunn/vim-easy-align",
    keys = { "ga", { "ga", mode = "x" } },
    init = function()
      vim.g.easy_align_delimiters = {
        [">"] = { pattern = ">>\\|=>\\|>" },
        ["/"] = { pattern = "//\\+\\|/\\*\\|\\*/", delimiter_align = "l", ignore_groups = { "!Comment" } },
        ["]"] = { pattern = "[\\[\\]]", left_margin = 0, right_margin = 0, stick_to_left = 0 },
        [")"] = { pattern = "[()]", left_margin = 0, right_margin = 0, stick_to_left = 0 },
        ["r"] = { pattern = " \\(\\S\\+\\s*[;=]\\)@=", left_margin = 0, right_margin = 0 },
        ["d"] = { pattern = " \\ze\\S\\+\\s*[;=]", left_margin = 0, right_margin = 0 },
        ["m"] = { pattern = "\\.\\.\\.$", left_margin = 1, right_margin = 0 },
        ["\\"] = { pattern = "\\\\$", left_margin = 1, right_margin = 0 },
        ["%"] = { pattern = "%", left_margin = 1, right_margin = 1 },
      }
    end,
    config = function()
      vim.keymap.set({ "n", "x" }, "ga", "<Plug>(EasyAlign)", { desc = "align selection" })
    end,
  },

  ---------------------------------------------------------------------------
  -- treesitter (syntax highlighting)
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    event = "VeryLazy",
    build = ":TSUpdate",
    config = function()
      -- highlight any filetype that has a parser installed
      vim.api.nvim_create_autocmd("FileType", {
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- snippets: UltiSnips (kept; uses ~/.venvs/nvim python + conf/vim/UltiSnips)
  ---------------------------------------------------------------------------
  {
    "SirVer/ultisnips",
    keys = { { "<C-j>", mode = "i" }, { "<C-j>", mode = "s" } },
    cmd = { "Snippets", "UltiSnipsEdit" },
    config = function()
      vim.keymap.set("n", "<leader>cs", function() vim.call("UltiSnips#RefreshSnippets") end,
        { desc = "reload snippets" })
    end,
  },

  ---------------------------------------------------------------------------
  -- markdown (only for markdown buffers)
  ---------------------------------------------------------------------------
  {
    "preservim/vim-markdown",
    ft = "markdown",
    dependencies = { "godlygeek/tabular" },
    config = function()
      local m = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
      end
      m("<leader>nt", "<Cmd>Toc<CR>", "open markdown TOC in vsplit")
      m("<leader>nT", "<Cmd>InsertToc 6<CR>", "write markdown TOC until h6 into buffer")
      m("<leader>e<", "<Cmd>HeaderDecrease<CR>", "decrease markdown header")
      m("<leader>e>", "<Cmd>HeaderIncrease<CR>", "increase markdown header")
      m("<leader>nF", "<Cmd>setlocal foldmethod=syntax<CR>", "fold markdown document")
    end,
  },
  {
    "dkarter/bullets.vim",
    ft = { "markdown", "text", "gitcommit" },
    config = function()
      vim.keymap.set({ "n", "x" }, "<leader>e<C-a>", "<Plug>(bullets-renumber)",
        { desc = "renumber list or selection" })
    end,
  },
  {
    "dhruvasagar/vim-table-mode",
    ft = "markdown",
    cmd = { "TableModeEnable", "TableModeToggle", "TableModeRealign" },
    init = function()
      vim.g.table_mode_disable_mappings = 0
      vim.g.table_mode_syntax = 1
      vim.g.table_mode_motion_up_map    = "<up>"
      vim.g.table_mode_motion_down_map  = "<down>"
      vim.g.table_mode_motion_left_map  = "<left>"
      vim.g.table_mode_motion_right_map = "<right>"
      vim.g.table_mode_cell_text_object_a_map = "a<Bar>"
      vim.g.table_mode_cell_text_object_i_map = "i<Bar>"
      vim.g.table_mode_realign_map            = "<Leader>tr"
      vim.g.table_mode_delete_row_map         = "<Leader>tdd"
      vim.g.table_mode_delete_column_map      = "<Leader>tdc"
      vim.g.table_mode_insert_column_before_map = "<Leader>tiC"
      vim.g.table_mode_insert_column_after_map  = "<Leader>tic"
      vim.g.table_mode_add_formula_map          = "<Leader>tfa"
      vim.g.table_mode_eval_formula_map         = "<Leader>tfe"
      vim.g.table_mode_echo_cell_map            = "<Leader>t?"
      vim.g.table_mode_sort_map                 = "<Leader>ts"
      vim.g.table_mode_tableize_map             = "<Leader>tt"
      vim.g.table_mode_tableize_d_map           = "<Leader>tT"
      vim.g.table_mode_align_char = ":"
    end,
    config = function()
      local function grid()
        vim.g.table_mode_corner = "+"
        vim.g.table_mode_corner_corner = "+"
        vim.g.table_mode_header_fillchar = "="
        vim.cmd("TableModeEnable")
      end
      local function pipe()
        vim.g.table_mode_corner = "|"
        vim.g.table_mode_corner_corner = "|"
        vim.g.table_mode_header_fillchar = "-"
        vim.cmd("TableModeEnable")
      end
      vim.api.nvim_create_user_command("TableModeGridTable", function()
        vim.g.table_mode_corner = "+"
        vim.g.table_mode_corner_corner = "+"
        vim.g.table_mode_header_fillchar = "="
        vim.cmd("TableModeEnable")
      end, {})
      vim.api.nvim_create_user_command("TableModePipeTable", function()
        vim.g.table_mode_corner = "|"
        vim.g.table_mode_corner_corner = "|"
        vim.g.table_mode_header_fillchar = "-"
        vim.cmd("TableModeEnable")
      end, {})
      local m = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
      end
      m("<leader>tg", "<Cmd>TableModeGridTable<CR>", "format grid table")
      m("<leader>tp", "<Cmd>TableModePipeTable<CR>", "format pipe table")
      m("<leader>tr", "<Cmd>TableModeRealign<CR>", "realign table")
      m("<leader>te", "<Cmd>OpenInScim<CR>", "open markdown table in sc-im")
    end,
  },
  { "mipmip/vim-scimark", ft = "markdown", cmd = "OpenInScim" },
  {
    "img-paste-devs/img-paste.vim",
    ft = "markdown",
    cmd = "MarkdownClipboardImagePaste",
    init = function()
      vim.g.mdip_imgdir = "img"
      vim.g.mdip_imgname = "image"
    end,
    config = function()
      vim.cmd([[command! MarkdownClipboardImagePaste call mdip#MarkdownClipboardImage()]])
      vim.keymap.set("n", "<leader>ep", "<Cmd>MarkdownClipboardImagePaste<CR>",
        { buffer = true, silent = true, desc = "paste image from clipboard as markdown" })
    end,
  },
  {
    "gpanders/vim-medieval",
    ft = "markdown",
    config = function()
      vim.keymap.set("n", "!", "<Plug>(medieval-eval)", { buffer = true, desc = "evaluate code block" })
    end,
  },

  ---------------------------------------------------------------------------
  -- LaTeX (only for tex buffers)
  ---------------------------------------------------------------------------
  {
    "lervag/vimtex",
    ft = { "tex", "bib" },
    -- nvim 0.12.0-dev is newer than what the version gate knows about;
    -- see :h vimtex_version_check
    init = function()
      vim.g.vimtex_version_check = 0
    end,
    config = function()
      local map = function(lhs, plug, desc)
        vim.keymap.set("n", lhs, plug, { buffer = true, silent = true, desc = desc })
      end
      map("<leader>xi", "<plug>(vimtex-info)", "vimtex-info")
      map("<leader>xI", "<plug>(vimtex-info-full)", "vimtex-info-full")
      map("<leader>xt", "<plug>(vimtex-toc-open)", "vimtex-toc-open")
      map("<leader>xT", "<plug>(vimtex-toc-toggle)", "vimtex-toc-toggle")
      map("<leader>xq", "<plug>(vimtex-log)", "vimtex-log")
      map("<leader>xv", "<plug>(vimtex-view)", "vimtex-view")
      map("<leader>xr", "<plug>(vimtex-reverse-search)", "vimtex-reverse-search")
      map("<leader>xl", "<plug>(vimtex-compile)", "vimtex-compile")
      map("<leader>xL", "<plug>(vimtex-compile-selected)", "vimtex-compile-selected")
      map("<leader>xk", "<plug>(vimtex-stop)", "vimtex-stop")
      map("<leader>xK", "<plug>(vimtex-stop-all)", "vimtex-stop-all")
      map("<leader>xe", "<plug>(vimtex-errors)", "vimtex-errors")
      map("<leader>xo", "<plug>(vimtex-compile-output)", "vimtex-compile-output")
      map("<leader>xg", "<plug>(vimtex-status)", "vimtex-status")
      map("<leader>xG", "<plug>(vimtex-status-all)", "vimtex-status-all")
      map("<leader>xc", "<plug>(vimtex-clean)", "vimtex-clean")
      map("<leader>xC", "<plug>(vimtex-clean-full)", "vimtex-clean-full")
      map("<leader>xm", "<plug>(vimtex-imaps-list)", "vimtex-imaps-list")
      map("<leader>xx", "<plug>(vimtex-reload)", "vimtex-reload")
      map("<leader>xX", "<plug>(vimtex-reload-state)", "vimtex-reload-state")
      map("<leader>xs", "<plug>(vimtex-toggle-main)", "vimtex-toggle-main")
      map("<leader>xa", "<plug>(vimtex-context-menu)", "vimtex-context-menu")
    end,
  },
  { "chomosuke/typst-preview.nvim", ft = "typst", version = "v1.*" },

  ---------------------------------------------------------------------------
  -- LSP stack: loads ONLY when you call :LspStart (see lua/lsp.lua)
  ---------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    cmd = { "LspStart", "LspStop" },
    dependencies = {
      { "mason-org/mason.nvim" },
      { "mason-org/mason-lspconfig.nvim" },
      { "p00f/clangd_extensions.nvim", config = function() require("clangd_extensions").setup() end },
    },
  },

  ---------------------------------------------------------------------------
  -- search & replace across the project (same keys as before)
  ---------------------------------------------------------------------------
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>SS", function() require("spectre").open() end, desc = "open spectre" },
      { "<leader>Sw", function() require("spectre").open_visual({ select_word = true }) end, desc = "search current word" },
      { "<leader>SS", mode = "v", function() require("spectre").open_visual() end, desc = "open spectre with selection" },
      { "<leader>Sp", function() require("spectre").open_file_search() end, desc = "open file search" },
    },
    config = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "spectre_panel",
        callback = function()
          vim.opt_local.spell = false
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
        end,
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- todo comments → quickfix/location list (same keys as before)
  ---------------------------------------------------------------------------
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>qt", "<Cmd>TodoQuickFix<CR>", desc = "populate quickfix list with todo comments" },
      { "<leader>lt", "<Cmd>TodoLocList<CR>",  desc = "populate location list with todo comments" },
    },
    cmd = { "TodoQuickFix", "TodoLocList" },
  },

  ---------------------------------------------------------------------------
  -- spelling errors → quickfix/location list (same keys as before)
  ---------------------------------------------------------------------------
  {
    "inkarkat/vim-SpellCheck",
    dependencies = { "inkarkat/vim-ingo-library" },
    keys = { "<leader>qs", "<leader>ls" },
  },

  ---------------------------------------------------------------------------
  -- vim-slime: send code to terminal REPLs (default <C-c><C-c>)
  ---------------------------------------------------------------------------
  {
    "jpalardy/vim-slime",
    keys = "<C-c><C-c>",
    init = function() vim.g.slime_target = "neovim" end,
  },

  ---------------------------------------------------------------------------
  -- OpenCode integration (local CLI; same agent you use in the terminal)
  ---------------------------------------------------------------------------
  {
    "nickjvandyke/opencode.nvim",
    keys = {
      { "<leader>aa", desc = "toggle OpenCode TUI" },
      { "<leader>ai", desc = "ask OpenCode about selection/cursor" },
      { "<leader>ab", desc = "ask OpenCode about buffer" },
      { "<leader>ad", desc = "ask OpenCode about diagnostics" },
      { "<leader>as", desc = "select OpenCode action" },
      { "<leader>ac", desc = "run OpenCode command" },
      { "<leader>ap", mode = "x", desc = "send selection to OpenCode" },
      { "<leader>ao", desc = "send range to OpenCode (operator)" },
    },
    config = function()
      -- configuration via vim.g.opencode_opts (no setup() call in this plugin)
      -- toggle the opencode TUI in a vertical split (same split you'd get
      -- from the plugin's default server start, but closable from both sides)
      local function opencode_toggle()
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local buf = vim.api.nvim_win_get_buf(w)
          if vim.api.nvim_buf_get_name(buf):match("^term://.*opencode") then
            vim.api.nvim_win_close(w, true)
            return
          end
        end
        vim.cmd("vsplit term://opencode")
      end

      local oc = function(fn) return function() require("opencode")[fn]() end end
      vim.keymap.set({ "n", "t" }, "<leader>aa", opencode_toggle, { desc = "toggle OpenCode TUI" })
      vim.keymap.set({ "n", "x" }, "<leader>ai", function() require("opencode").ask("@this: ") end,
        { desc = "ask OpenCode about selection/cursor" })
      vim.keymap.set({ "n", "x" }, "<leader>ab", function() require("opencode").ask("@buffer: ") end,
        { desc = "ask OpenCode about buffer" })
      vim.keymap.set({ "n", "x" }, "<leader>ad", function() require("opencode").ask("@diagnostics: ") end,
        { desc = "ask OpenCode about diagnostics" })
      vim.keymap.set({ "n", "x" }, "<leader>as", oc("select"), { desc = "select OpenCode action" })
      vim.keymap.set({ "n", "x" }, "<leader>ac", function() require("opencode").select({ prompts = false }) end,
        { desc = "run OpenCode command" })
      vim.keymap.set("x", "<leader>ap", function() require("opencode").prompt("@this ") end,
        { desc = "send selection to OpenCode" })
      vim.keymap.set("n", "<leader>ao", function() return require("opencode").operator("@this") .. "_" end,
        { expr = true, desc = "send range to OpenCode (operator, dot-repeat)" })
    end,
  },

  ---------------------------------------------------------------------------
  -- misc / niche filetypes (all lazy by filetype or command)
  ---------------------------------------------------------------------------
  { "NoahTheDuke/vim-just",           ft = "just" },
  { "JuliaEditorSupport/julia-vim",   event = "VeryLazy" },
  { "andymass/vim-matlab",            ft = "matlab" },
  { "justin2004/vim-apl",             ft = "apl" },
  { "mlochbaum/BQN",                  ft = "bqn", rtp = "editors/vim" },
  { "chrisbra/csv.vim",               ft = "csv" },
  { "powerman/vim-plugin-AnsiEsc",    cmd = "AnsiEsc" },
}
