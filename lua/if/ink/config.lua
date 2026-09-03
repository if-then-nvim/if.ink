local M = {}

---@type IfInk.Options
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

---@type IfInk.Options
M.options = vim.deepcopy(M.defaults)

---@param opts? IfInk.Options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

---@return IfInk.Options
function M.get()
  return M.options
end

return M
