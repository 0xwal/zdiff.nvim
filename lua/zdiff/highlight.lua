local M = {}

-- Every component falls back to ZDiffHeader, which falls back to Comment.
-- All links are `default`, so a colorscheme or user definition wins.
M.links = {
  ZDiffHeader = "Comment",
  ZDiffHeaderText = "ZDiffHeader",
  ZDiffHeaderSeparator = "ZDiffHeader",
  ZDiffHeaderBranch = "ZDiffHeader",
  ZDiffHeaderPath = "ZDiffHeader",
  ZDiffHeaderScope = "ZDiffHeader",
  ZDiffHeaderRoot = "ZDiffHeader",
  ZDiffHeaderRef = "ZDiffHeader",
  ZDiffHeaderMode = "ZDiffHeader",
  ZDiffHeaderDesc = "ZDiffHeader",
  ZDiffHeaderLoading = "ZDiffHeader",

  ZDiffIcon = "Directory",
  ZDiffIconAdd = "DiffAdd",
  ZDiffIconDelete = "DiffDelete",
  ZDiffIconChange = "DiffChange",
  ZDiffFileName = "Directory",
  ZDiffFileExpanded = "ZDiffFileName",
  ZDiffAddCount = "DiffAdd",
  ZDiffRemoveCount = "DiffDelete",
}

function M.apply()
  for group, link in pairs(M.links) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
  end
end

local registered = false

function M.setup()
  M.apply()
  if registered then
    return
  end
  registered = true

  -- :colorscheme clears the default links.
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("ZdiffHighlight", { clear = true }),
    callback = M.apply,
  })
end

return M
