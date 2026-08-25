local config = require "encre.config"

describe("config", function()
  before_each(function()
    config.setup()
  end)

  it("has correct defaults", function()
    assert.is_true(config.defaults.RRGGBB)
    assert.is_true(config.defaults.RGB)
    assert.is_true(config.defaults.names)
    assert.is_true(config.defaults.lsp)
    assert.are.equal("background", config.defaults.mode)
  end)

  it("merges user options", function()
    config.setup { RRGGBB = false, lsp = false }
    local opts = config.get()
    assert.is_false(opts.RRGGBB)
    assert.is_true(opts.RGB)
    assert.is_false(opts.lsp)
  end)

  it("resets with empty table", function()
    config.setup { RRGGBB = false }
    config.setup {}
    local opts = config.get()
    assert.is_true(opts.RRGGBB)
    assert.is_true(opts.lsp)
  end)

  it("uses defaults with nil", function()
    config.setup()
    local opts = config.get()
    assert.is_true(opts.RRGGBB)
    assert.is_true(opts.lsp)
  end)

  it("is usable before setup runs", function()
    local original = package.loaded["encre.config"]
    package.loaded["encre.config"] = nil
    local fresh = require "encre.config"
    local opts = fresh.get()
    assert.is_true(opts.RRGGBB)
    assert.is_true(opts.lsp)
    assert.are.equal("background", opts.mode)
    package.loaded["encre.config"] = original
  end)

  it("does not mutate defaults", function()
    config.setup { filetypes = { "lua" } }
    assert.are.same({ "*" }, config.defaults.filetypes)
  end)
end)
