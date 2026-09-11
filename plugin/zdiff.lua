-- zdiff.nvim - A minimal git diff viewer for Neovim
-- This file provides commands without requiring explicit setup()

if vim.g.loaded_zdiff then
  return
end
vim.g.loaded_zdiff = true

require("zdiff.highlight").setup()

-- Git ref completion function
local function complete_git_refs(arg_lead, _, _)
  -- Get branches and tags
  local refs = {}

  -- Local branches
  local branches = vim.fn.systemlist("git branch --format='%(refname:short)' 2>/dev/null")
  if vim.v.shell_error == 0 then
    for _, branch in ipairs(branches) do
      if branch:find(arg_lead, 1, true) == 1 then
        table.insert(refs, branch)
      end
    end
  end

  -- Remote branches (without origin/ prefix for convenience)
  local remote_branches =
    vim.fn.systemlist("git branch -r --format='%(refname:short)' 2>/dev/null")
  if vim.v.shell_error == 0 then
    for _, branch in ipairs(remote_branches) do
      -- Strip origin/ prefix for easier typing
      local short = branch:gsub("^origin/", "")
      if short:find(arg_lead, 1, true) == 1 and not vim.tbl_contains(refs, short) then
        table.insert(refs, short)
      end
      -- Also include full ref
      if branch:find(arg_lead, 1, true) == 1 then
        table.insert(refs, branch)
      end
    end
  end

  -- Tags
  local tags = vim.fn.systemlist("git tag 2>/dev/null")
  if vim.v.shell_error == 0 then
    for _, tag in ipairs(tags) do
      if tag:find(arg_lead, 1, true) == 1 then
        table.insert(refs, tag)
      end
    end
  end

  return refs
end

local open_modes = { replace = true, borrow = true, tab = true }

-- Directory, open mode and git ref completion
local function complete_zdiff(arg_lead, cmd_line, cursor_pos)
  local candidates = complete_git_refs(arg_lead, cmd_line, cursor_pos)
  for mode in pairs(open_modes) do
    if mode:find(arg_lead, 1, true) == 1 then
      table.insert(candidates, mode)
    end
  end
  vim.list_extend(candidates, vim.fn.getcompletion(arg_lead, "dir"))
  return candidates
end

-- Create user command
vim.api.nvim_create_user_command("Zdiff", function(opts)
  local ref = nil
  local dir = nil
  local mode = nil

  -- Arguments are order independent: an existing directory sets the scope, an
  -- open mode name sets the window handling, anything else is a git ref.
  for _, arg in ipairs(opts.fargs) do
    if vim.fn.isdirectory(vim.fs.normalize(arg)) == 1 then
      if dir then
        vim.notify("[zdiff] Only one directory argument is supported", vim.log.levels.ERROR)
        return
      end
      dir = arg
    elseif open_modes[arg] then
      if mode then
        vim.notify("[zdiff] Only one open mode argument is supported", vim.log.levels.ERROR)
        return
      end
      mode = arg
    else
      if ref then
        vim.notify("[zdiff] Only one git ref argument is supported", vim.log.levels.ERROR)
        return
      end
      ref = arg
    end
  end

  -- `:Zdiff!` widens back to the whole repository regardless of the scope config.
  if not dir and opts.bang then
    dir = false
  end

  require("zdiff").open(ref, dir, mode)
end, {
  nargs = "*",
  bang = true,
  complete = complete_zdiff,
  desc = "Open zdiff (optionally against a git ref, a directory and/or an open mode)",
})

vim.api.nvim_create_user_command("ZdiffFocus", function()
  require("zdiff").focus()
end, {
  desc = "Show the current zdiff session again",
})
