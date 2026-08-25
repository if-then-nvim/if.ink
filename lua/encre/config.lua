local M = {}

---@type encre.Options
M.defaults = {
  RGB = true,
  RRGGBB = true,
  names = true,
  css_fn = true,
  mode = "background",
  virtualtext = "██",
  filetypes = { "*" },
  exclusions = {},
  lsp = true,
}

---@type encre.Options
M.options = vim.deepcopy(M.defaults)

---@param opts? encre.Options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

---@return encre.Options
function M.get()
  return M.options
end

return M
