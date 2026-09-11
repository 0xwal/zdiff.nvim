# zdiff.nvim

A minimal, fast git diff viewer for Neovim with treesitter syntax highlighting.

Inspired by [Zed's](https://zed.dev) multi-buffer diff view - a clean, collapsible interface for reviewing changes across multiple files in a single view.

<img width="50%" height="50%" alt="image" src="https://github.com/user-attachments/assets/cb03976a-3d0c-4554-8d05-f712e030c52c" /><img width="50%" height="50%" alt="image" src="https://github.com/user-attachments/assets/f38c871a-3ca6-490a-8727-26f8275a0bf1" />

Easily yank changes without including git markers or hunk headers

<img width="50%" height="50%" alt="image" src="https://github.com/user-attachments/assets/7b274b5d-db18-4e02-b277-03b633bf9d04" />

## Features

- View uncommitted changes or changes compared to any git ref
- Expand/collapse files to see inline diffs
- Treesitter syntax highlighting in diff views
- Sticky file headers while scrolling expanded diffs
- Jump directly to source files at the correct line
- Auto-refresh when returning to zdiff buffer
- Tab completion for branch/tag names
- Configurable keymaps and icons

## Requirements

- Neovim >= 0.9.0
- git
- (Optional) nvim-treesitter for syntax highlighting in diffs

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "martindur/zdiff.nvim",
  cmd = "Zdiff",
  keys = {
    { "<leader>zd", "<cmd>Zdiff<cr>", desc = "Zdiff (uncommitted)" },
    { "<leader>zD", "<cmd>Zdiff main<cr>", desc = "Zdiff (vs main)" },
  },
  opts = {},
}
```

Or with lua function keymaps:

```lua
{
  "martindur/zdiff.nvim",
  cmd = "Zdiff",
  keys = {
    { "<leader>zd", function() require("zdiff").open() end, desc = "Zdiff (uncommitted)" },
    { "<leader>zD", function() require("zdiff").open("main") end, desc = "Zdiff (vs main)" },
  },
  opts = {},
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "martindur/zdiff.nvim",
  config = function()
    require("zdiff").setup()

    vim.keymap.set("n", "<leader>zd", function() require("zdiff").open() end, { desc = "Zdiff (uncommitted)" })
    vim.keymap.set("n", "<leader>zD", function() require("zdiff").open("main") end, { desc = "Zdiff (vs main)" })
  end,
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'martindur/zdiff.nvim'
```

```lua
-- In your init.lua or after/plugin/zdiff.lua:
require("zdiff").setup()

vim.keymap.set("n", "<leader>zd", function() require("zdiff").open() end, { desc = "Zdiff (uncommitted)" })
vim.keymap.set("n", "<leader>zD", function() require("zdiff").open("main") end, { desc = "Zdiff (vs main)" })
```

## Usage

### Command

```vim
:Zdiff [ref]
```

| Example | Description |
|---------|-------------|
| `:Zdiff` | Uncommitted changes (diff vs HEAD) below the current directory |
| `:Zdiff!` | Uncommitted changes in the whole repository |
| `:Zdiff main` | Changes compared to `main` branch |
| `:Zdiff develop` | Changes compared to `develop` branch |
| `:Zdiff v1.0.0` | Changes compared to tag `v1.0.0` |
| `:Zdiff HEAD~5` | Changes compared to 5 commits ago |
| `:Zdiff origin/feature` | Changes compared to remote branch |
| `:Zdiff lua` | Uncommitted changes under `lua/` |
| `:Zdiff main lua` | Changes vs `main` under `lua/` (same as `:Zdiff lua main`) |
| `:Zdiff tab` | Uncommitted changes in a new tab page |
| `:Zdiff main lua tab` | All three at once |
| `:ZdiffFocus` | Return to the current session (e.g. after `<CR>` opened a file) |
| `:ZdiffClose` | Close the current session, same as `q` |

Arguments are order independent: an argument naming an existing directory sets the scope, `replace`/`borrow`/`tab` set the open mode (see `open_mode`), anything else is treated as a git ref.

By default the listing is limited to the current working directory, so opening Neovim in a subdirectory of a large repository does not show changes in sibling directories. Set `scope = "root"` to list the whole repository instead.

Tab completion is available for branch names, tag names and directories.

### Keymaps (in zdiff buffer)

| Key | Action |
|-----|--------|
| `<CR>` | Go to file/line under cursor |
| `<Tab>` | Toggle expand/collapse file |
| `zR` | Expand all files |
| `zM` | Collapse all files |
| `]f` | Jump to next file header |
| `[f` | Jump to previous file header |
| `]h` | Jump to next hunk, within the current file |
| `[h` | Jump to previous hunk, within the current file |
| `m` | Toggle between uncommitted and branch mode |
| `R` | Refresh diff |
| `q` | Close zdiff |
| `gy` | Yank file:line reference |
| `?` | Show help |

`gy` works in both normal mode (current line) and visual mode (selection). Outputs file:line or file:start-end for ranges. Deletion lines are ignored; selections spanning multiple hunks produce multiple ranges (e.g., `path:10-15, 1020-1025`).

Press `?` while in zdiff to see all available keymaps.

## Configuration

```lua
require("zdiff").setup({
  -- Whether files are expanded by default
  default_expanded = false,

  -- Default branch for toggle_mode (m key)
  default_branch = "main",

  -- Where the zdiff buffer is shown, and what closing it leaves behind:
  --   "replace" focused window, closing deletes the buffer (window
  --             usually closes with it)
  --   "borrow"  focused window, closing puts the previous buffer back
  --   "tab"     a new tab page, closing closes that tab
  -- `:Zdiff replace|borrow|tab` overrides this per invocation.
  open_mode = "replace",

  -- Name for the zdiff buffer. nil leaves it unnamed, which keeps
  -- `:mksession` clean: a named scratch buffer is written to the session
  -- as `enew` + `file <name>` and restores as a phantom buffer. Match on
  -- the `zdiff` filetype in statusline/bufferline config instead.
  buffer_name = nil,

  -- Header line template. Placeholders:
  --   <branch>  git branch, or jj bookmarks at @ (comma separated),
  --             falling back to the short change id
  --   <path>    active scope directory, or the repository directory name
  --   <scope>   active scope directory, empty for the whole repository
  --   <root>    repository directory name
  --   <ref>     base ref being diffed against, empty in uncommitted mode
  --   <mode>    "Uncommitted changes" or "Changes vs <ref>"
  --   <desc>    first line of the jj description of @ (jj_header only)
  -- Literal text may sit inside the brackets, around the name: it takes
  -- the placeholder's highlight and is dropped when the value is empty,
  -- so `<"desc">` renders "some description" or nothing at all.
  -- An unknown placeholder is reported once and the template falls back.
  header = "diffs(<branch>): <path>",

  -- Optional per VCS templates. Each wins over `header` in its own
  -- repository kind; only `jj_header` may use <desc>.
  git_header = nil,
  jj_header = nil,

  -- A colocated repository has both .jj and .git. This picks which
  -- template and which <branch> lookup wins there.
  header_priority = "git",

  -- Which changes are listed when no directory argument is given:
  -- "cwd" limits the listing to the current working directory,
  -- "root" lists the whole repository.
  scope = "cwd",

  -- Paths shown in the file list and winbar:
  -- "root" keeps them relative to the repository root (w/y/z/a.lua),
  -- "scope" strips the active scope prefix (a.lua).
  path_display = "root",

  -- Paths written by yank_ref (gy): "root" or "scope", as above.
  yank_path = "root",

  -- Keymap bindings (defaults)
  keymaps = {
    goto_file = "<CR>",
    toggle = "<Tab>",
    close = "q",
    refresh = "R",
    toggle_mode = "m",
    next_file = "]f",
    prev_file = "[f",
    next_hunk = "]h",
    prev_hunk = "[h",
    expand_all = "zR",
    collapse_all = "zM",
    help = "?",
    yank_ref = "gy",
  },

  -- Icons for UI elements
  icons = {
    collapsed = "",
    expanded = "",
    added = "+",
    deleted = "-",
    modified = "~",
  },

  -- Syntax highlighting strategy
  syntax = {
    -- "projection" parses old/new full-file snapshots and projects
    -- captures onto unified diff lines. "hunk" keeps legacy behavior.
    mode = "projection",
    -- Skip projection when either old/new source exceeds this many lines.
    -- 0 means unlimited.
    max_lines = 8000,
  },
})
```

### Examples

#### Set default branch to develop

```lua
require("zdiff").setup({
  default_branch = "develop",
})
```

#### Custom keymaps

All keymaps can be customized or disabled (set to `false`).

```lua
require("zdiff").setup({
  keymaps = {
    goto_file = "o",
    toggle = "<Space>",
    yank_ref = "Y",  -- or false to disable
  },
})
```

#### Limit projection on very large files

```lua
require("zdiff").setup({
  syntax = {
    -- Files above this line count skip projection and use
    -- hunk-based syntax highlighting for performance.
    max_lines = 12000,
  },
})
```

## Highlights

The header is highlighted per component, one group per header placeholder:

| Group | Covers |
|-------|--------|
| `ZDiffHeader` | Whole header line. Links to `Comment` by default |
| `ZDiffHeaderText` | Literal text between placeholders |
| `ZDiffHeaderSeparator` | Dashed line below the header |
| `ZDiffHeaderBranch` | `<branch>` |
| `ZDiffHeaderPath` | `<path>` |
| `ZDiffHeaderScope` | `<scope>` |
| `ZDiffHeaderRoot` | `<root>` |
| `ZDiffHeaderRef` | `<ref>` |
| `ZDiffHeaderMode` | `<mode>` |
| `ZDiffHeaderDesc` | `<desc>` |
| `ZDiffHeaderLoading` | ` (loading...)` suffix |

File header lines:

```
  ~ lua/zdiff/git.lua  +104 -0
 ^ ^        ^            ^    ^
 | |        |            |    ZDiffRemoveCount
 | |        |            ZDiffAddCount
 | |        ZDiffFileName / ZDiffFileExpanded
 | ZDiffIconAdd / ZDiffIconDelete / ZDiffIconChange
 ZDiffIcon
```

| Group | Covers | Default link |
|-------|--------|--------------|
| `ZDiffIcon` | Expand/collapse indicator | `Directory` |
| `ZDiffIconAdd` | Status icon, added or untracked file | `DiffAdd` |
| `ZDiffIconDelete` | Status icon, deleted file | `DiffDelete` |
| `ZDiffIconChange` | Status icon, any other file | `DiffChange` |
| `ZDiffFileName` | File path, collapsed file | `Directory` |
| `ZDiffFileExpanded` | File path, expanded file | `ZDiffFileName` |
| `ZDiffAddCount` | `+N` count | `DiffAdd` |
| `ZDiffRemoveCount` | `-N` count | `DiffDelete` |

The same groups are used in the window's winbar.

Each component links to `ZDiffHeader` unless you define it, so styling `ZDiffHeader` alone restyles the whole header:

```lua
vim.api.nvim_set_hl(0, "ZDiffHeader", { link = "Title" })
vim.api.nvim_set_hl(0, "ZDiffHeaderBranch", { fg = "#a6e3a1", bold = true })
```

Defaults use `default = true`, so a colorscheme wins over them, and they are reapplied on `ColorScheme`.

## Health Check

Run `:checkhealth zdiff` to verify your setup.

## Development

### Running Tests

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim):

```bash
make test
```

Stress test (async refresh + repeated open/close memory baseline check + open-time load benchmark):

```bash
make stress-test
```

Open a generated fixture repo with many file types and expanded diffs for manual syntax highlighting checks. The default target uses your normal Neovim config and installed parsers, while the clean target uses `tests/minimal_init.lua`:

```bash
make syntax-gallery
make syntax-gallery-clean
```

Format tracked Lua files with `stylua`:

```bash
make format
```

Lint Lua sources with `luacheck`:

```bash
make lint
```

## License

MIT
