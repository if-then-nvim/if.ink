---@alias IfInk.Mode

---@class IfInk.Options
---@field RGB? boolean highlight three-digit hex literals (`#f00`)
---@field RRGGBB? boolean highlight six-digit hex literals (`#ff0000`)
---@field names? boolean highlight colour names inside string literals (`"red"`)
---@field css_fn? boolean highlight `rgb()` / `rgba()` calls
---@field lsp? boolean render colours reported via `textDocument/documentColor`
---@field mode? IfInk.Mode|IfInk.Mode[] how to render a match; a list applies several at once
---@field virtualtext? string glyph used by the `virtualtext` mode
---@field editor_bg? string `#rrggbb` background used for contrast and alpha maths; defaults to `Normal`
---@field filetypes? string[] filetypes to attach to; `{ "*" }` for all
---@field exclusions? string[] filetypes never attached to, even when listed above

---@class IfInk.Match
---@field col_start integer
---@field col_end integer
---@field rgb_hex string six hex digits, without a leading `#`
---@field alpha? number 0-1, blended against the editor background
---@field virtualtext_only? boolean render as a swatch even when another mode is configured

---@class IfInk.RGB
---@field r number
---@field g number
---@field b number

---@alias IfInk.HighlightCache table<string, string> cache key -> highlight group name
---@alias IfInk.ColorMap table<string, string> lowercased colour name -> six hex digits
---@alias IfInk.AttachedMap table<integer, IfInk.Options> buffer -> options it was attached with
---@alias IfInk.LspColorCache table<integer, table<integer, IfInk.Match[]>> buffer -> row -> matches
---@alias IfInk.TimerMap table<integer, uv.uv_timer_t> buffer -> debounce timer
---@alias IfInk.AutocmdMap table<integer, integer[]> buffer -> autocmd ids
