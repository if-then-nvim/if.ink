local M = {}

local MIN_VERSION = { 0, 11, 0 }

---@return boolean
local function version_ok()
  local v = vim.version()
  return vim.version.ge({ v.major, v.minor, v.patch }, MIN_VERSION)
end

function M.check()
  vim.health.start "encre.nvim"

  if version_ok() then
    vim.health.ok("Neovim " .. tostring(vim.version()))
  else
    vim.health.error(
      ("Neovim >= %s required, found %s"):format(table.concat(MIN_VERSION, "."), tostring(vim.version()))
    )
  end

  if vim.o.termguicolors then
    vim.health.ok "'termguicolors' is set"
  else
    vim.health.warn("'termguicolors' is off; colours fall back to the 256-colour palette", {
      "Add `vim.o.termguicolors = true` to your config.",
    })
  end

  local options = require("encre.config").get()

  if options.lsp then
    local clients = vim.lsp.get_clients { method = "textDocument/documentColor" }
    if #clients > 0 then
      local names = vim.tbl_map(function(c)
        return c.name
      end, clients)
      vim.health.ok("LSP documentColor available from: " .. table.concat(names, ", "))
    else
      vim.health.info "No attached language server provides textDocument/documentColor"
    end
  else
    vim.health.info "LSP colours disabled (`lsp = false`)"
  end

  local buf = vim.api.nvim_get_current_buf()
  if require("encre").is_attached(buf) then
    vim.health.ok "Attached to the current buffer"
  else
    vim.health.info "Not attached to the current buffer; run `:Encre attach` to enable it here"
  end
end

return M
