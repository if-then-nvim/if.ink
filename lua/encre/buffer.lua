local parser = require "encre.parser"
local highlight = require "encre.highlight"
local lsp = require "encre.lsp"

local M = {}

local ns = vim.api.nvim_create_namespace "encre"
local augroup = vim.api.nvim_create_augroup("encre_buffer", { clear = true })

---@type encre.AttachedMap
local attached = {}

---@param mode encre.Mode|encre.Mode[]
---@return encre.Mode[]
local function normalize_modes(mode)
  if type(mode) == "table" then
    return mode
  end
  return { mode or "background" }
end

---@param buf integer
---@return integer min, integer max
local function visible_range(buf)
  local min, max
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local info = vim.fn.getwininfo(win)[1]
    if info then
      local lo, hi = info.topline - 1, info.botline
      min = min and math.min(min, lo) or lo
      max = max and math.max(max, hi) or hi
    end
  end
  if not min or not max then
    return 0, vim.api.nvim_buf_line_count(buf)
  end
  return min, max
end

---@param buf integer
---@param row integer
---@param options encre.Options
local function highlight_line(buf, row, options)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  if not line then
    return
  end

  local modes = normalize_modes(options.mode)
  local glyph = options.virtualtext or "██"
  local matches = parser.scan_line(line, options)

  if options.lsp then
    for _, color in ipairs(lsp.get_colors(buf, row)) do
      if not parser.overlaps(color.col_start, color.col_end, matches) then
        color.virtualtext_only = true
        matches[#matches + 1] = color
      end
    end
  end

  local line_len = #line
  for _, m in ipairs(matches) do
    local col_start = math.min(m.col_start - 1, line_len)
    local col_end = math.min(m.col_end, line_len)
    if col_start < col_end then
      local effective_modes = m.virtualtext_only and { "virtualtext" } or modes
      for _, mode in ipairs(effective_modes) do
        local hl_group = highlight.ensure(m.rgb_hex, mode, m.alpha)
        if mode == "virtualtext" then
          vim.api.nvim_buf_set_extmark(buf, ns, row, col_start, {
            virt_text = { { glyph, hl_group } },
            virt_text_pos = "inline",
          })
        else
          vim.api.nvim_buf_set_extmark(buf, ns, row, col_start, {
            end_col = col_end,
            hl_group = hl_group,
          })
        end
      end
    end
  end
end

---@param buf integer
---@return boolean
local function is_live(buf)
  return attached[buf] ~= nil and vim.api.nvim_buf_is_valid(buf)
end

---@param buf integer
local function refresh_visible(buf)
  if not is_live(buf) then
    return
  end
  local options = attached[buf]
  local min, max = visible_range(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, min, max)
  for row = min, max - 1 do
    highlight_line(buf, row, options)
  end
end

---@param buf integer
local function refresh_all(buf)
  if not is_live(buf) then
    return
  end
  local options = attached[buf]
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for row = 0, vim.api.nvim_buf_line_count(buf) - 1 do
    highlight_line(buf, row, options)
  end
end

---@param buf integer
---@param options encre.Options
function M.attach(buf, options)
  if attached[buf] then
    return
  end
  attached[buf] = options

  refresh_all(buf)

  if options.lsp then
    lsp.attach(buf, function()
      refresh_visible(buf)
    end)
    if vim.lsp.document_color then
      vim.lsp.document_color.enable(false, { bufnr = buf })
    end
  end

  vim.api.nvim_buf_attach(buf, false, {
    on_detach = function(_, b)
      attached[b] = nil
      lsp.detach(b)
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = augroup,
    buffer = buf,
    callback = function()
      local options_now = attached[buf]
      if not options_now then
        return
      end
      if options_now.lsp then
        lsp.trigger(buf, function()
          refresh_visible(buf)
        end)
      end
      if vim.fn.mode() == "i" then
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        vim.api.nvim_buf_clear_namespace(buf, ns, row, row + 1)
        highlight_line(buf, row, options_now)
      else
        refresh_visible(buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "WinScrolled", "BufEnter" }, {
    group = augroup,
    buffer = buf,
    callback = function()
      refresh_visible(buf)
    end,
  })
end

---@param buf integer
function M.detach(buf)
  if not attached[buf] then
    return
  end
  attached[buf] = nil
  lsp.detach(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_clear_autocmds { group = augroup, buffer = buf }
end

---@param buf integer
---@param options encre.Options
function M.toggle(buf, options)
  if attached[buf] then
    M.detach(buf)
  else
    M.attach(buf, options)
  end
end

---@param buf? integer
---@param options encre.Options
function M.reload(buf, options)
  local targets = {}
  if buf then
    targets[1] = buf
  else
    for b in pairs(attached) do
      targets[#targets + 1] = b
    end
  end

  for _, b in ipairs(targets) do
    if attached[b] then
      if vim.api.nvim_buf_is_valid(b) then
        attached[b] = options
        refresh_all(b)
      else
        attached[b] = nil
      end
    end
  end
end

---@param buf integer
---@return boolean
function M.is_attached(buf)
  return attached[buf] ~= nil
end

return M
