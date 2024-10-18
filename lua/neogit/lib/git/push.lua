local git = require("neogit.lib.git")
local util = require("neogit.lib.util")

---@class NeogitGitPush
local M = {}

---Pushes to the remote and handles password questions
---@param remote string
---@param branch string
---@param args string[]
---@return ProcessResult
function M.push_interactive(remote, branch, args)
  return git.cli.push.args(remote or "", branch or "").arg_list(args).call { pty = true }
end

---@param branch string
---@return boolean
function M.auto_setup_remote(branch)
  local push_autoSetupRemote = git.config.get("push.autoSetupRemote"):read()
    or git.config.get_global("push.autoSetupRemote"):read()

  local push_default = git.config.get("push.default"):read() or git.config.get_global("push.default"):read()

  local branch_remote = git.config.get("branch." .. branch .. ".remote"):read()

  return (
    push_autoSetupRemote
    and (push_default == "current" or push_default == "simple" or push_default == "upstream")
    and not branch_remote
  ) == true
end

local function update_unmerged(state)
  local status = git.branch.status()

  state.upstream.unmerged.items = {}
  state.pushRemote.unmerged.items = {}

  if status.detached then
    return
  end

  if status.upstream then
    state.upstream.unmerged.items =
      util.filter_map(git.log.list({ "@{upstream}.." }, nil, {}, true), git.log.present_commit)
  end

  local pushRemote = require("neogit.lib.git").branch.pushRemote_ref()
  if pushRemote then
    state.pushRemote.unmerged.items =
      util.filter_map(git.log.list({ pushRemote .. ".." }, nil, {}, true), git.log.present_commit)
  end
end

function M.register(meta)
  meta.update_unmerged = update_unmerged
end

return M
