local highlight = require "if.ink.highlight"

local M = {}

---@param item table blink.cmp completion item
---@return string? rgb_hex
local function extract_color(item)
  if type(item) ~= "table" then
    return nil
  end

  local doc = item.documentation
  if type(doc) == "table" then
    doc = doc.value
  end

  local candidates = {}
  for _, text in ipairs { doc or false, item.detail or false } do
    if type(text) == "string" then
      candidates[#candidates + 1] = text
    end
  end

  for _, text in ipairs(candidates) do
    local hex = text:match "#(%x%x%x%x%x%x)"
    if hex then
      return hex:lower()
    end
  end

  return nil
end

---@class IfInk.BlinkOpts
---@field icon? string glyph drawn for colour items
---@field fallback? table component delegated to for non-colour items

---@param opts? IfInk.BlinkOpts
---@return table
function M.kind_icon(opts)
  opts = opts or {}
  local icon = opts.icon or "󱓻"
  local fallback = opts.fallback

  return {
    text = function(ctx)
      if ctx.kind == "Color" and extract_color(ctx.item) then
        return icon .. ctx.icon_gap
      end
      if fallback and fallback.text then
        return fallback.text(ctx)
      end
      return ctx.kind_icon .. ctx.icon_gap
    end,
    highlight = function(ctx)
      if ctx.kind == "Color" then
        local rgb = extract_color(ctx.item)
        if rgb then
          return highlight.ensure(rgb, "virtualtext")
        end
      end
      if fallback and fallback.highlight then
        return fallback.highlight(ctx)
      end
      return ctx.kind_hl
    end,
  }
end

---@param item table
---@return string?
function M.get_hl(item)
  local rgb = extract_color(item)
  return rgb and highlight.ensure(rgb, "virtualtext") or nil
end

return M
