local blink = require "encre.blink"

describe("blink", function()
  local function ctx(kind, item)
    return { kind = kind, item = item, icon_gap = " ", kind_icon = "?", kind_hl = "Normal" }
  end

  describe("get_hl", function()
    it("resolves a colour from documentation", function()
      assert.are.equal("encre_virtualtext_ff0000", blink.get_hl { documentation = "#ff0000" })
    end)

    it("resolves a colour from a documentation table", function()
      assert.are.equal("encre_virtualtext_00ff00", blink.get_hl { documentation = { value = "swatch #00ff00" } })
    end)

    it("resolves a colour from detail", function()
      assert.are.equal("encre_virtualtext_0000ff", blink.get_hl { detail = "#0000ff" })
    end)

    it("returns nil without a colour", function()
      assert.is_nil(blink.get_hl { detail = "no colour here" })
    end)

    it("returns nil for a non-table item", function()
      assert.is_nil(blink.get_hl "nope")
    end)
  end)

  describe("kind_icon", function()
    it("uses the configured icon for colour items", function()
      local component = blink.kind_icon { icon = "@" }
      assert.are.equal("@ ", component.text(ctx("Color", { detail = "#ff0000" })))
    end)

    it("highlights colour items with the item's own colour", function()
      local component = blink.kind_icon()
      assert.are.equal("encre_virtualtext_ff0000", component.highlight(ctx("Color", { detail = "#ff0000" })))
    end)

    it("falls back for non-colour kinds", function()
      local component = blink.kind_icon()
      assert.are.equal("? ", component.text(ctx("Function", {})))
      assert.are.equal("Normal", component.highlight(ctx("Function", {})))
    end)

    it("falls back for colour items with no resolvable colour", function()
      local component = blink.kind_icon()
      assert.are.equal("? ", component.text(ctx("Color", { detail = "none" })))
    end)

    it("delegates to a fallback component when given", function()
      local component = blink.kind_icon {
        fallback = {
          text = function()
            return "fb"
          end,
          highlight = function()
            return "FbHl"
          end,
        },
      }
      assert.are.equal("fb", component.text(ctx("Function", {})))
      assert.are.equal("FbHl", component.highlight(ctx("Function", {})))
    end)
  end)
end)
