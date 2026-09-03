# if.ink

Inline colour highlighting for Neovim. Paints hex literals, CSS colour
functions, named colours and LSP-reported colours where they appear in your
buffer.

## Requirements

- Neovim >= 0.11
- `termguicolors` enabled

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "if-then-nvim/if.ink",
  main = "if.ink",
  event = "BufReadPre",
  opts = {},
}
```

`main` is not optional. Without it lazy.nvim infers `if` from the
directory layout, and if.nvim ships `lua/if/init.lua`.

## Usage

Buffers matching `filetypes` are attached automatically. To control it by hand:

| Command          | Description                                        |
| ---------------- | -------------------------------------------------- |
| `:IfInk`         | Toggle highlighting in the current buffer          |
| `:IfInk toggle`  | Same as above                                      |
| `:IfInk attach`  | Start highlighting the current buffer              |
| `:IfInk detach`  | Stop highlighting and clear the current buffer     |
| `:IfInk reload`  | Repaint every attached buffer with current options |

The same actions are available from Lua:

```lua
require("if.ink").attach()
require("if.ink").detach()
require("if.ink").toggle()
require("if.ink").reload()
require("if.ink").is_attached()
```

Run `:checkhealth if.ink` to verify your setup.

## Configuration

Defaults:

```lua
require("if.ink").setup({
  RGB = true,               -- #f00
  RRGGBB = true,            -- #ff0000
  names = true,             -- "red" inside string literals
  css_fn = true,            -- rgb() / rgba()
  lsp = true,               -- textDocument/documentColor
  mode = "background",      -- "background" | "foreground" | "virtualtext"
  virtualtext = "██",       -- glyph used by virtualtext mode
  editor_bg = nil,          -- "#1e1e28"; defaults to the Normal highlight
  filetypes = { "*" },
  exclusions = {},
})
```

### mode

`mode` takes one render mode or a list of them:

```lua
mode = { "background", "virtualtext" }
```

A colour wrapped in square brackets — `[#ff0000]` — is always rendered as a
swatch only, leaving the literal itself readable. Colours reported by a
language server behave the same way, since there is no literal to paint over.

### filetypes and exclusions

```lua
filetypes = { "css", "scss", "lua" },  -- only these; { "*" } for every buffer
exclusions = { "markdown" },           -- never attach, even if listed above
```

### editor_bg

Contrast checks and alpha blending read the background of the `Normal`
highlight. Set `editor_bg` when your terminal background differs from what
Neovim reports:

```lua
editor_bg = "#1e1e28"
```

## blink.cmp integration

Paint the completion kind icon of a `Color` item with the colour it represents:

```lua
require("blink.cmp").setup({
  completion = {
    menu = {
      draw = {
        components = {
          kind_icon = require("if.ink.blink").kind_icon(),
        },
      },
    },
  },
})
```

`kind_icon` accepts `icon` to change the glyph, and `fallback` to delegate
non-colour items to another component:

```lua
require("if.ink.blink").kind_icon({
  icon = "󱓻",
  fallback = require("blink.cmp.completion.windows.render.tailwind"),
})
```

## Highlight groups

Groups are created on demand and named `ifink_<mode>_<rrggbb>`, with an
`_a<alpha>` suffix when a colour carries transparency. They are cached and
rebuilt when the colorscheme changes.

## Development

```sh
make test          # plenary test suite
make lint          # stylua --check + selene
make format        # stylua
make check         # lint + test
```

## License

MIT
