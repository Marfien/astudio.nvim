local M = {}

local adb = vim.env.ANDROID_HOME .. '/platform-tools/adb'

---Installs the apk on the given device
---@param device_id string
---@param apk string path to the apk
---@return boolean successful
function M.install(device_id, apk)
  local data = vim.system({ adb, '-s', device_id, 'install', apk }):wait()
  return data.code == 0
end

---Runs the application on device
---@param device_id string
---@param main_activity? string
---@return boolean successful
function M.run(device_id, main_activity)
  -- adb -s <device-id> shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n <main-activity>
  local data = vim
    .system({
      adb,
      '-s',
      device_id,
      'shell',
      'start',
      '-a',
      'android.intent.action.MAIN',
      '-c',
      'android.intent.category.LAUNCHER',
      '-n',
      main_activity,
    })
    :wait()
  return data.code == 0
end

---Removes the binary from the device
---@param device_id string
---@param application_id string
---@return boolean successful
function M.uninstall(device_id, application_id)
  local data = vim.system({ adb, '-s', device_id, 'uninstall', application_id }):wait()
  return data.code == 0
end

---Returns a stream of log messages from the device
---@param device util.android.adb.DeviceData
---@param debug_tags? string[]
function M.logcat(device, debug_tags)
  local cmd = {
    adb,
    '-s',
    device.id,
    'logcat',
  }

  local filter = {
    'ActivityManager:I',
    '*:S',
  }

  for _, tag in ipairs(debug_tags or {}) do
    table.insert(filter, tag .. ':D')
  end

  for _, x in ipairs(filter) do
    table.insert(cmd, x)
  end

  require('astudio-nvim.android.util').exec_out(
    cmd,
    'Logcat: ' .. device.name .. ' (' .. vim.fn.join(filter) .. ')'
  )
end

---Resolved the main activity from the application_id
---@param device_id string
---@param application_id string
---@return nil | string
function M.resolve_main(device_id, application_id)
  local data = vim
    .system({
      adb,
      '-s',
      device_id,
      'shell',
      'cmd',
      'package',
      'resolve-activity',
      '--brief',
      application_id,
    }, { text = true })
    :wait()

  if data.code ~= 0 or data.stdout == 'No activity found\n' then
    return nil
  end

  return vim.fn.trim(data.stdout)
end

local function get_adb_devices()
  local data = vim.system({ adb, 'devices' }):wait()
  if data.code ~= 0 then
    error('Could not get devices:\n' .. data.stderr)
  end

  local lines = vim.fn.split(data.stdout, '\n')

  local ids = {}
  for i = 2, #lines do
    local id = vim.fn.split(lines[i], '')[1]
    table.insert(ids, id)
  end

  return ids
end

---Looks up the name of devices by their id
---@param ids string[]
---@return table[]
local function get_device_names(ids)
  local devices = {}

  for _, id in ipairs(ids) do
    local cmd = vim.startswith(id, 'emulator') and { adb, '-s', id, 'emu', 'avd', 'name' }
      or { adb, '-s', id, 'shell', 'getprop', 'ro.product.model' }

    local data = vim.system(cmd, { text = true }):wait()
    if data.code == 0 then
      local device_name = vim.fn.split(data.stdout, '\n')[1]
      table.insert(devices, { id = id, name = device_name })
    else
      vim.notify('Could not get device name for ' .. id .. ':\n' .. data.stderr)
    end
  end

  return devices
end

---@class util.android.adb.DeviceData
---@field id string
---@field name string

---Gets the currently running devices from adb
---@return util.android.adb.DeviceData[]
function M.get_running_devices()
  local devices = get_adb_devices()
  local names = get_device_names(devices)
  return names
end

return M
