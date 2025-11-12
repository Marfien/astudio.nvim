local M = {}

local avd = require('astudio-nvim.avd')
local util = require('astudio-nvim.util')
local gradle = require('astudio-nvim.gradle')
local adb = require('astudio-nvim.adb')

local function avd_create_cmd()
  vim.ui.input({ prompt = 'Create AVD - Name:' }, function(name)
    if not name then
      return
    end

    vim.notify('Create AVD - Fetching system images...')
    avd.list_images(
      util.wrap_select(
        'Create AVD - Select Image:',
        'Could not retrive system images',
        function(image)
          vim.notify('Create AVD - Fetching devices...')
          avd.list_devices(
            util.wrap_select(
              'Create AVD - Select Device: ',
              'Cloud not retrive device list',
              function(device)
                avd.create(name, image, device.id, function(out)
                  if out.code ~= 0 then
                    vim.notify('Error while creating device: \n' .. out.stderr)
                  else
                    vim.notify('Succesfully created device: ' .. name .. ' (' .. image .. ')')
                  end
                end)
              end,
              function(item)
                return item.name
              end
            )
          )
        end
      )
    )
  end)
end

local function avd_launch_cmd()
  avd.list(util.wrap_select('Select AVD:', 'Could not retieve list of AVDs', function(selected)
    avd.launch(selected, function(out)
      if out.code ~= 0 then
        vim.notify('Error launching AVD: \n' .. out.stderr)
      end
    end)
  end))
end

local function avd_delete_cmd()
  avd.list(util.wrap_select('Select AVD:', 'Could not retieve list of AVDs', function(selected)
    avd.delete(selected, function(out)
      if out.code == 0 then
        vim.notify('Succesfully deleted ' .. selected)
      else
        vim.notify('Error launching AVD: \n' .. out.stderr)
      end
    end)
  end))
end

local function avd_help()
  vim.notify('Usage: Android avd <create|launch|delete>', vim.log.levels.ERROR)
end

local function avd_cmd(args)
  local sub_cmds = {
    ['create'] = avd_create_cmd,
    ['launch'] = avd_launch_cmd,
    ['delete'] = avd_delete_cmd,
    ['*'] = avd_help,
  }
  (sub_cmds[args[2]] or sub_cmds['*'])()
end

local function install_cmd()
  local gradlew_ctx = gradle.find()
  gradlew_ctx:exec_task('assembleDebug', function()
    local apk = gradlew_ctx.module_root
      .. '/build/outputs/apk/debug/'
      .. vim.fn.fnamemodify(gradlew_ctx.module_root, ':t')
      .. '-debug.apk'

    local devices = adb.get_running_devices()
    vim.ui.select(devices, {
      prompt = 'Install - Select Device:',
      format_item = function(item)
        return item.name
      end,
    }, function(dev)
      if dev == nil then
        vim.notify('Aboarding...', vim.log.levels.WARN)
        return
      end

      if not adb.install(dev.id, apk) then
        vim.notify(
          'Could not install apk on device ' .. dev.name .. ': ' .. apk,
          vim.log.levels.ERROR
        )
        return
      else
        vim.notify('Succesfully installed on ' .. dev.name)
      end

      -- TODO: why is main activity not detected?
      --
      -- local main = adb.resolve_main(dev.id, gradlew_ctx:application_id())
      -- if main == nil then
      --   vim.notify("Could not determine main activity"), vim.log.levels.ERROR)
      --   return
      -- end

      -- if adb.run(dev.id, main) then
      --   vim.notify("Succesfully installed and launched " .. main .. " on " .. dev.name)
      -- else
      --   vim.notify("Error launching " .. main .. " on " .. dev.name)
      -- end
      vim.notify('Cannot launch Activity, yet', vim.log.levels.WARN)
    end)
  end)
end

local function uninstall_cmd()
  -- select device
  -- adb -s <device-id> uninstall <app_id>
  vim.notify('Not implemented, yet', vim.log.levels.WARN)
end

local function logcat_cmd()
  vim.ui.select(adb.get_running_devices(), {
    prompt = 'Logcat - Select Device:',
    format_item = function(item)
      return item.name
    end,
  }, function(selected)
    if selected ~= nil then
      vim.ui.input({ prompt = 'Logcat - Add Tags:' }, function(input)
        adb.logcat(selected, input == nil and nil or vim.fn.split(input, '', false))
      end)
    else
      vim.notify('Aboarding', vim.log.levels.WARN)
    end
  end)
end

local function help()
  vim.notify('Usage: Android <avd|install|uninstall|logcat|focus> [...]', vim.log.levels.ERROR)
end

function M.register()
  vim.api.nvim_create_user_command('Android', function(args)
    local fargs = args.fargs

    if #fargs < 1 then
      help()
      return
    end

    local sub_cmds = {
      ['avd'] = avd_cmd,
      ['install'] = install_cmd,
      ['uninstall'] = uninstall_cmd,
      ['logcat'] = logcat_cmd,
      ['focus'] = require('astudio-nvim.output').focus,
      ['*'] = help,
    }
    local cmd = sub_cmds[fargs[1]] or sub_cmds['*']
    cmd(fargs)
  end, { nargs = '*' })
end

return M
