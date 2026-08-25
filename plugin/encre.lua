if vim.g.loaded_encre then
  return
end
vim.g.loaded_encre = true

local subcommands = { "attach", "detach", "toggle", "reload" }

vim.api.nvim_create_user_command("Encre", function(args)
  local encre = require "encre"
  local sub = args.fargs[1] or "toggle"

  if not vim.tbl_contains(subcommands, sub) then
    vim.notify(
      ("encre: unknown subcommand %q (expected one of: %s)"):format(sub, table.concat(subcommands, ", ")),
      vim.log.levels.ERROR
    )
    return
  end

  encre[sub]()
end, {
  nargs = "?",
  desc = "Toggle, attach, detach or reload encre colour highlighting",
  complete = function(lead)
    return vim.tbl_filter(function(sub)
      return sub:find(lead, 1, true) == 1
    end, subcommands)
  end,
})
