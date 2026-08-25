local M = {}

---@type encre.HighlightCache
local CACHE = {}

local CONTRAST_THRESHOLD = 1.3
local GAMMA = 1.5

---@type string?
local user_editor_bg = nil

---@type encre.RGB?
local editor_bg = nil

---@param hex string
---@return encre.RGB
local function parse_hex(hex)
  hex = hex:gsub("^#", "")
  return {
    r = tonumber(hex:sub(1, 2), 16) or 0,
    g = tonumber(hex:sub(3, 4), 16) or 0,
    b = tonumber(hex:sub(5, 6), 16) or 0,
  }
end

---@return encre.RGB?
local function get_editor_bg()
  if editor_bg then
    return editor_bg
  end
  if user_editor_bg then
    editor_bg = parse_hex(user_editor_bg)
    return editor_bg
  end
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  if normal.bg then
    editor_bg = parse_hex(string.format("%06x", normal.bg))
  end
  return editor_bg
end

---@param channel number 0-255
---@return number
local function linearize(channel)
  local c = channel / 255
  return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

---@return number
local function relative_luminance(r, g, b)
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
end

---@return number
local function contrast_ratio(l1, l2)
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05)
end

---@return boolean
local function is_low_contrast(r, g, b)
  local bg = get_editor_bg()
  if not bg then
    return false
  end
  local against = relative_luminance(bg.r, bg.g, bg.b)
  return contrast_ratio(relative_luminance(r, g, b), against) < CONTRAST_THRESHOLD
end

---@return integer, integer, integer
local function lighten(r, g, b)
  return math.floor(255 * (r / 255) ^ (1 / GAMMA)),
    math.floor(255 * (g / 255) ^ (1 / GAMMA)),
    math.floor(255 * (b / 255) ^ (1 / GAMMA))
end

---@param fg encre.RGB
---@param bg encre.RGB
---@param alpha number
---@return integer, integer, integer
local function alpha_blend(fg, bg, alpha)
  return math.floor(fg.r * alpha + bg.r * (1 - alpha) + 0.5),
    math.floor(fg.g * alpha + bg.g * (1 - alpha) + 0.5),
    math.floor(fg.b * alpha + bg.b * (1 - alpha) + 0.5)
end

---@return string
local function readable_fg(r, g, b)
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5 and "#000000" or "#ffffff"
end

---@param rgb_hex string six hex digits, without a leading `#`
---@param mode encre.Mode
---@param alpha? number 0-1, blended against the editor background
---@return string hl_group
function M.ensure(rgb_hex, mode, alpha)
  local alpha_key = alpha and string.format("_a%.2f", alpha) or ""
  local key = mode .. "_" .. rgb_hex .. alpha_key
  if CACHE[key] then
    return CACHE[key]
  end

  local name = "encre_" .. key:gsub("%.", "d")
  local r = tonumber(rgb_hex:sub(1, 2), 16) or 0
  local g = tonumber(rgb_hex:sub(3, 4), 16) or 0
  local b = tonumber(rgb_hex:sub(5, 6), 16) or 0

  if alpha and alpha < 1 then
    local bg = get_editor_bg()
    if bg then
      r, g, b = alpha_blend({ r = r, g = g, b = b }, bg, alpha)
    end
  end

  if is_low_contrast(r, g, b) then
    r, g, b = lighten(r, g, b)
  end

  local hex = string.format("#%02x%02x%02x", r, g, b)
  if mode == "background" then
    vim.api.nvim_set_hl(0, name, { fg = readable_fg(r, g, b), bg = hex })
  else
    vim.api.nvim_set_hl(0, name, { fg = hex })
  end

  CACHE[key] = name
  return name
end

---@param bg? string
function M.set_editor_bg(bg)
  user_editor_bg = bg
  editor_bg = nil
end

function M.clear_cache()
  CACHE = {}
  editor_bg = nil
end

return M
