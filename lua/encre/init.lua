local config = require "encre.config"
local buffer = require "encre.buffer"
local highlight = require "encre.highlight"
local parser = require "encre.parser"

local M = {}

local augroup = vim.api.nvim_create_augroup("encre", { clear = true })

---@param buf integer
---@return boolean
local function should_attach(buf)
  if vim.bo[buf].buftype ~= "" then
    return false
  end

  local opts = config.get()
  local ft = vim.bo[buf].filetype

  if vim.tbl_contains(opts.exclusions or {}, ft) then
    return false
  end

  local filetypes = opts.filetypes or { "*" }
  return vim.tbl_contains(filetypes, "*") or vim.tbl_contains(filetypes, ft)
end

---@param opts? encre.Options
function M.setup(opts)
  config.setup(opts)
  highlight.set_editor_bg(config.get().editor_bg)

  vim.api.nvim_clear_autocmds { group = augroup }

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    callback = function(ev)
      if should_attach(ev.buf) then
        buffer.attach(ev.buf, config.get())
      end
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = function()
      highlight.clear_cache()
      parser.clear_cache()
      buffer.reload(nil, config.get())
    end,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and should_attach(buf) then
      buffer.attach(buf, config.get())
    end
  end
end

---@param buf? integer
function M.attach(buf)
  buffer.attach(buf or vim.api.nvim_get_current_buf(), config.get())
end

---@param buf? integer
function M.detach(buf)
  buffer.detach(buf or vim.api.nvim_get_current_buf())
end

---@param buf? integer
function M.toggle(buf)
  buffer.toggle(buf or vim.api.nvim_get_current_buf(), config.get())
end

---@param buf? integer
function M.reload(buf)
  buffer.reload(buf, config.get())
end

---@param buf? integer
---@return boolean
function M.is_attached(buf)
  return buffer.is_attached(buf or vim.api.nvim_get_current_buf())
end

return M
