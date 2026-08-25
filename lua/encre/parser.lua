local M = {}

local HEX6 = "#(%x%x%x%x%x%x)"
local HEX3 = "#(%x%x%x)"
local WORD = "()(%a+)()"
local RGBA_PAT = "rgba?%s*%((.-)%)"

---@type encre.ColorMap?
local COLOR_MAP = nil

local function init_colors()
  COLOR_MAP = {}
  for name, rgb in pairs(vim.api.nvim_get_color_map()) do
    COLOR_MAP[name:lower()] = string.format("%06x", rgb)
  end
end

---@param col_start integer
---@param col_end integer
---@param matches encre.Match[]
---@return boolean
function M.overlaps(col_start, col_end, matches)
  for _, m in ipairs(matches) do
    if col_start <= m.col_end and col_end >= m.col_start then
      return true
    end
  end
  return false
end

---@param line string
---@param init integer
---@param pattern string
---@param skip_numeric boolean reject all-digit matches such as issue refs (#123)
---@return integer? col_start, integer? col_end, string? hex, boolean? bracketed
local function find_hex(line, init, pattern, skip_numeric)
  local pos = init
  while pos <= #line do
    local s, e, hex = line:find(pattern, pos)
    if not s then
      return nil
    end
    local before = s > 1 and line:sub(s - 1, s - 1) or ""
    local after = e < #line and line:sub(e + 1, e + 1) or ""
    local embedded = before:find "%w" or after:find "%x"
    if not embedded and not (skip_numeric and hex:find "^%d+$") then
      return s, e, hex, before == "["
    end
    pos = e + 1
  end
  return nil
end

---@param hex3 string
---@return string
local function expand_hex3(hex3)
  local r, g, b = hex3:sub(1, 1), hex3:sub(2, 2), hex3:sub(3, 3)
  return r .. r .. g .. g .. b .. b
end

---@param line string
---@return {[1]: integer, [2]: integer}[]
local function find_string_regions(line)
  local regions = {}
  local i = 1
  while i <= #line do
    local b = line:byte(i)
    if b == 34 or b == 39 or b == 96 then
      local quote = b
      local start = i
      i = i + 1
      while i <= #line and line:byte(i) ~= quote do
        if line:byte(i) == 92 then
          i = i + 1
        end
        i = i + 1
      end
      if i <= #line then
        regions[#regions + 1] = { start + 1, i - 1 }
      end
    end
    i = i + 1
  end
  return regions
end

---@param pos integer
---@param regions {[1]: integer, [2]: integer}[]
---@return boolean
local function in_string(pos, regions)
  for _, r in ipairs(regions) do
    if pos >= r[1] and pos <= r[2] then
      return true
    end
  end
  return false
end

---@param value string
---@return integer
local function channel(value)
  local n = math.floor(tonumber(value) or 0)
  return math.max(0, math.min(255, n))
end

---@param line string
---@return encre.Match[]
local function find_rgba(line)
  local results = {}
  local pos = 1
  while pos <= #line do
    local s, e, inner = line:find(RGBA_PAT, pos)
    if not s then
      break
    end
    local parts = {}
    for part in inner:gmatch "[^,%s]+" do
      parts[#parts + 1] = part
    end
    if #parts >= 3 then
      local alpha = #parts >= 4 and tonumber(parts[4]) or nil
      if alpha then
        alpha = math.max(0, math.min(1, alpha))
      end
      results[#results + 1] = {
        col_start = s,
        col_end = e,
        rgb_hex = string.format("%02x%02x%02x", channel(parts[1]), channel(parts[2]), channel(parts[3])),
        alpha = alpha,
      }
    end
    pos = e + 1
  end
  return results
end

---@param line string
---@param options encre.Options
---@param matches encre.Match[]
local function scan_hex(line, options, matches)
  ---@type {pattern: string, skip_numeric: boolean, expand: boolean}[]
  local passes = {}
  if options.RRGGBB then
    passes[#passes + 1] = { pattern = HEX6, skip_numeric = false, expand = false }
  end
  if options.RGB then
    passes[#passes + 1] = { pattern = HEX3, skip_numeric = true, expand = true }
  end

  for _, pass in ipairs(passes) do
    local init = 1
    while init <= #line do
      local s, e, hex, bracketed = find_hex(line, init, pass.pattern, pass.skip_numeric)
      if not s or not e or not hex then
        break
      end
      if not M.overlaps(s, e, matches) then
        hex = hex:lower()
        matches[#matches + 1] = {
          col_start = s,
          col_end = e,
          rgb_hex = pass.expand and expand_hex3(hex) or hex,
          virtualtext_only = bracketed or nil,
        }
      end
      init = e + 1
    end
  end
end

---@param line string
---@param matches encre.Match[]
local function scan_names(line, matches)
  if not COLOR_MAP then
    init_colors()
  end
  ---@cast COLOR_MAP encre.ColorMap

  local regions = find_string_regions(line)
  local init = 1
  while init <= #line do
    local ws, word, we = line:match(WORD, init)
    if not ws then
      break
    end
    ---@cast ws integer
    ---@cast we integer
    ---@cast word string
    local rgb = COLOR_MAP[word:lower()]
    if rgb and in_string(ws, regions) then
      local before = ws > 1 and line:byte(ws - 1) or 0
      local after = we <= #line and line:byte(we) or 0
      local joined = before == 45 or before == 95 or before == 46 or after == 45 or after == 95 or after == 46
      if not joined then
        matches[#matches + 1] = { col_start = ws, col_end = we - 1, rgb_hex = rgb }
      end
    end
    init = we
  end
end

---@param line string
---@param options encre.Options
---@return encre.Match[]
function M.scan_line(line, options)
  ---@type encre.Match[]
  local matches = {}

  scan_hex(line, options, matches)

  if options.css_fn then
    for _, m in ipairs(find_rgba(line)) do
      if not M.overlaps(m.col_start, m.col_end, matches) then
        matches[#matches + 1] = m
      end
    end
  end

  if options.names then
    scan_names(line, matches)
  end

  return matches
end

function M.clear_cache()
  COLOR_MAP = nil
end

return M
