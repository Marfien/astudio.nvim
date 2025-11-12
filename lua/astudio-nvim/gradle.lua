local M = {}

local function exec_task(self, task, callback)
  local executable = self.project_root .. '/gradlew'
  if jit.os == 'Windows' then
    executable = executable .. '.bat'
  end

  require('astudio-nvim.util').exec_out(
    {
      executable,
      self.module_id .. ':' .. task,
    },
    'Build Log',
    { cwd = self.project_root },
    function(data)
      if data.code ~= 0 then
        vim.notify('Gradle Task (' .. task .. ') unsuccessfull')
        return
      else
        callback(data)
      end
    end
  )
end

local function application_id(self)
  if self._application_id then
    return self._application_id
  end

  local build_script = self.module_root .. '/build.gradle.kts'

  for line in io.lines(build_script, '*a') do
    if line:find('applicationId') then
      local app_id = line:match('.*["\']([^"\']+)["\']')
      return app_id
    end
  end

  return nil
end

---@class astudio-nvim.GradleContext
---@field project_root string
---@field module_root string
---@field module_id string
---@field exec_task fun(self, task: string, callback: fun(out: vim.SystemCompleted))
---@field application_id fun(self): string

---@return astudio-nvim.GradleContext
function M.find()
  local buf_name = vim.api.nvim_buf_get_name(0)
  local gradlew = vim.fs.find('gradlew', { upward = true, path = buf_name })[1]
  local project_root = vim.fn.fnamemodify(gradlew, ':h')
  local build_script = vim.fs.find('build.gradle.kts', { upward = true, path = buf_name })[1]
  local module_root = vim.fn.fnamemodify(build_script, ':h')

  local module_id = module_root:sub(#project_root + 1, #module_root):gsub('/', ':')

  return {
    project_root = project_root,
    module_root = module_root,
    module_id = module_id,
    exec_task = exec_task,
    application_id = application_id,
  }
end

return M
