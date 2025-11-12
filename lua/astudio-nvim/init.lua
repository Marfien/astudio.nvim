local M = {}

function M.setup()
  if vim.env.ANDROID_USER_HOME and not vim.env.ANDROID_AVD_HOME then
    vim.env.ANDROID_AVD_HOME = vim.env.ANDROID_USER_HOME .. '/avd'
  end

  require('astudio-nvim.command').register()
end

return M
