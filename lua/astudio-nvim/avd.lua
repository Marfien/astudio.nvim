local M = {}

local emulator = vim.env.ANDROID_HOME .. '/emulator/emulator'

---@param name string
---@param callback fun(out: vim.SystemCompleted)
function M.launch(name, callback)
  vim.system({
    emulator,
    '-avd',
    name,
  }, {}, callback)
end

---@param callback fun(data: vim.SystemCompleted, avds: string[]|nil)
function M.list(callback)
  vim.system(
    {
      emulator,
      '-list-avds',
    },
    {},
    vim.schedule_wrap(function(data)
      callback(data, data.code == 0 and vim.fn.split(data.stdout, '\n', false) or nil)
    end)
  )
end

---@param name string
---@param callback fun(out: vim.SystemCompleted)
function M.delete(name, callback)
  vim.system({
    'avdmanager',
    'delete',
    'avd',
    '--name',
    name,
  }, {}, callback)
end

---Creates a new AVD
---@param name string
---@param image string
---@param device string
---@param callback fun(out: vim.SystemCompleted)
function M.create(name, image, device, callback)
  vim.system({
    'sdkmanager',
    image,
  }, {}, function(data)
    if data.code ~= 0 then
      callback(data)
    end

    vim.system({
      'avdmanager',
      'create',
      'avd',
      '--name',
      name,
      '--package',
      image,
      '--device',
      device,
    }, {}, callback)
  end)
end

---Lists all system images avaiable
---@param callback fun(out: vim.SystemCompleted, packages: string[]|nil)
function M.list_images(callback)
  vim.system(
    {
      'sdkmanager',
      '--list',
    },
    {},
    vim.schedule_wrap(function(data)
      if data.code ~= 0 then
        callback(data, nil)
      end

      local packages = {}
      for image in data.stdout:gmatch('(system%-images;.-)%s') do
        if not require('astudio-nvim.util').table_contains(packages, image) then
          table.insert(packages, image)
        end
      end

      ---@diagnostic disable-next-line: param-type-mismatch
      callback(data, packages)
    end)
  )
end

---Lists all avaiable avd devices
---@param callback fun(out: vim.SystemCompleted, devices: string[]|nil)
function M.list_devices(callback)
  vim.system({ 'avdmanager', 'list', 'device' }, {}, function(data)
    if data.code ~= 0 then
      callback(data, nil)
    end

    local devices = {}
    for id, name in data.stdout:gmatch('id: %d+ or "(.-)"%s+Name: (.-)\n') do
      table.insert(devices, { name = name, id = id })
    end

    callback(data, devices)
  end)
end

return M
