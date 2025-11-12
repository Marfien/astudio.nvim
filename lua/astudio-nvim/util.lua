local M = {}

local output = require('astudio-nvim.output')
local highlight_group = vim.api.nvim_create_namespace('android')

---Wraps around vim.system to continues write into a buffer
---@param cmd string[]
---@param title string output key
---@param opts? vim.SystemOpts
---@param callback? fun(out: vim.SystemCompleted)
---@return vim.SystemObj
function M.exec_out(cmd, title, opts, callback)
  local win = output.get_win()
  local buf = output.new_buf(title)

  local function apply(data)
    if data == nil or vim.api.nvim_buf_is_valid(buf) then
      return 0, 0
    end

    local new_lines = vim.fn.split(data, '\n')
    local buffer_lines = vim.api.nvim_buf_line_count(buf) or 0

    local first = buffer_lines
    local last = buffer_lines + #new_lines

    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, first, last, false, new_lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_win_set_cursor(win, { last, 0 })
    end

    return first, last
  end
  return vim.system(
    cmd,
    vim.tbl_extend('force', opts or {}, {
      text = true,
      stdout = vim.schedule_wrap(function(_, data)
        apply(data)
      end),
      stderr = vim.schedule_wrap(function(_, data)
        local first, last = apply(data)
        vim.hl.range(buf, highlight_group, 'Error', { first, 0 }, { last + 1, 0 })
      end),
    }),
    vim.schedule_wrap(function(data)
      if data.code == 0 and output.is_visible(buf) then
        output.close()
      end

      if callback then
        callback(data)
      end
    end) or nil
  )
end

---Wraps the async result into a vim.ui.select
---@param prompt string
---@param error string
---@param callback fun(out: any)
---@param format_item? fun(item: any): string
---@return function
function M.wrap_select(prompt, error, callback, format_item)
  return vim.schedule_wrap(function(out, result)
    if result == nil then
      vim.notify(error .. ': \n' .. out.stderr, vim.log.levels.ERROR)
      return
    end

    if #result == 1 then
      callback(result[1])
      return
    end

    vim.ui.select(result, {
      prompt = prompt,
      format_item = format_item,
    }, function(item)
      if item == nil then
        vim.notify('Abording', vim.log.levels.WARN)
        return
      else
        callback(item)
      end
    end)
  end)
end

function M.table_contains(tbl, x)
  for _, v in pairs(tbl) do
    if v == x then
      return true
    end
  end
  return false
end

return M
