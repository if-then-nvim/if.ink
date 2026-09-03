if vim.g.loaded_ifink then
  return
end
vim.g.loaded_ifink = true

local subcommands = { "attach", "detach", "toggle", "reload" }

vim.api.nvim_create_user_command("IfInk", function(args)
  local ink = require "if.ink"
  local sub = args.fargs[1] or "toggle"

  if not vim.tbl_contains(subcommands, sub) then
    vim.notify(
      ("if.ink: unknown subcommand %q (expected one of: %s)"):format(sub, table.concat(subcommands, ", ")),
      vim.log.levels.ERROR
    )
    return
  end

  ink[sub]()
end, {
  nargs = "?",
  desc = "Toggle, attach, detach or reload if.ink colour highlighting",
  complete = function(lead)
    return vim.tbl_filter(function(sub)
      return sub:find(lead, 1, true) == 1
    end, subcommands)
  end,
})
