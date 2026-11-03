-- lsp.lua – LSP is OFF until you ask for it (see REVIEW.md).
--   :LspStart        → attach a server matching the current filetype
--   :LspStart <name> → attach a specific server (clangd, ltex, julials, pyright, …)
--   :LspStop         → detach and stop
-- Only nvim-lspconfig + mason get loaded when the command is first used.
local M = {}

-- filetype → server(s), same setup as the old config (mason ensure_installed)
local ft_servers = {
  c = { "clangd" }, cpp = { "clangd" },
  julia = { "julials" },
  python = { "pyright" },
  tex = { "ltex" }, plaintex = { "ltex" }, markdown = { "ltex" }, text = { "ltex" },
}

local servers_configured = false

local function configure_servers()
  if servers_configured then return end
  require("lazy").load({ plugins = { "nvim-lspconfig" } })
  -- nvim-lspconfig defines commands of its own while loading. Keep ours for
  -- subsequent calls too, rather than silently changing behaviour after first use.
  M.commands()

  -- mason installs/updates the LSP binaries locally (~/.local/share/nvim/mason)
  -- Mason adds its bin directory to PATH. Server configs are discovered from
  -- nvim-lspconfig's lsp/ directory by Neovim; the deprecated require isn't needed.
  require("mason").setup({ ui = { icons = {
    package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } } })
  require("mason-lspconfig").setup({
    ensure_installed = { "ltex", "clangd", "julials" },
    automatic_enable = false,   -- manual only, per user request
  })

  -- ltex: same settings as the old config
  vim.lsp.config("ltex", {
    cmd = { "ltex-ls" },
    filetypes = { "tex", "plaintex", "text", "markdown" },
    settings = {
      ltex = {
        configurationTarget = "workspace",
        language = "de-DE",
        disabledRules = {
          ["de-DE"] = {
            "LEERZEICHEN_VOR_AUSRUFEZEICHEN_ETC",
            "LEERZEICHEN_HINTER_DOPPELPUNKT",
          },
        },
      },
    },
  })
  servers_configured = true
end

-- on_attach: same keymaps as the old config
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("ConfigLsp", { clear = true }),
  callback = function(args)
    local buf = args.buf
    local function map(lhs, fn, desc)
      vim.keymap.set("n", lhs, fn, { buffer = buf, desc = "lsp: " .. desc })
    end
    map("gD", vim.lsp.buf.declaration, "goto declaration")
    map("gd", vim.lsp.buf.definition, "goto definition")
    map("K",  vim.lsp.buf.hover, "show hover info")
    map("gi", vim.lsp.buf.implementation, "show implementations")
    map("<C-k>", vim.lsp.buf.signature_help, "show signature")
    map("gy", vim.lsp.buf.type_definition, "show type definition")
    map("<leader>er", vim.lsp.buf.rename, "rename symbol")
    map("<C-,>", vim.lsp.buf.code_action, "apply code action")
    map("gr", vim.lsp.buf.references, "show references")
    map("<leader>ef", function() vim.lsp.buf.format({ async = true }) end, "format using lsp")
    map("<leader>bo", vim.diagnostic.open_float, "open diagnostics in float")
    map("<leader>ld", vim.diagnostic.setloclist, "populate location list with diagnostics")
    map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "previous diagnostic")
    map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "next diagnostic")

    -- highlight occurrences of the symbol under the cursor (as before)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/documentHighlight") then
      vim.api.nvim_set_hl(0, "LspReferenceRead",  { bg = "#6565cf" })
      vim.api.nvim_set_hl(0, "LspReferenceText",  { bg = "#6565cf" })
      vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#6565cf" })
      local group = vim.api.nvim_create_augroup("lsp_document_highlight_" .. buf, { clear = true })
      vim.api.nvim_create_autocmd("CursorHold", {
        group = group, buffer = buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd("CursorMoved", {
        group = group, buffer = buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

function M.commands()
  vim.api.nvim_create_user_command("LspStart", function(o)
    local configured, err = pcall(configure_servers)
    if not configured then
      vim.notify("LspStart: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    local names = #o.args > 0 and { o.args }
      or (ft_servers[vim.bo.filetype] or {})
    if #names == 0 then
      vim.notify("LspStart: no server configured for filetype '" .. vim.bo.filetype ..
        "'. Use :LspStart <server>.", vim.log.levels.WARN)
      return
    end
    for _, n in ipairs(names) do
      local ok, err = pcall(vim.lsp.enable, n)
      if not ok then vim.notify("LspStart: could not enable " .. n .. " (" .. tostring(err) .. ")") end
    end
    -- vim.lsp.enable handles existing buffers itself. Replaying all FileType
    -- autocommands also reruns unrelated ftplugins and can reset local options.
  end, { nargs = "?", complete = function()
    return { "clangd", "ltex", "julials", "pyright", "rust_analyzer", "bashls", "vimls" }
  end })

  vim.api.nvim_create_user_command("LspStop", function(o)
    if #o.args > 0 then
      vim.lsp.enable(o.args, false)
    else
      for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        vim.lsp.enable(c.name, false)
      end
    end
  end, { nargs = "?" })
end

return M
