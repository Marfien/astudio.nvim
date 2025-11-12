local M = {
  win_id = nil,
  buf = nil,
}

local function create_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd><cr>", { callback = M.close, desc = "Close Output" })

  return buf
end

local function create_window()
  return vim.api.nvim_open_win(create_buf(), true, {
    relative = "editor",
    anchor = "SW",
    width = vim.o.columns,
    height = 10,
    col = 0,
    row = vim.o.lines,
    style = "minimal",
  })
end

---Returns the output window. Creates a new one if invalid
---@return integer
function M.get_win()
  if not M.is_visible() then
    pcall(vim.api.nvim_win_close, M.win_id)

    M.win_id = create_window()
  end

  return M.win_id
end

---Creates a new output buffer
---@param title string
---@return integer buf_id
function M.new_buf(title)
  if M.buf ~= nil and vim.api.nvim_buf_is_valid(M.buf) then
    vim.api.nvim_buf_delete(M.buf, { force = true })
  end

  M.buf = create_buf()
  vim.api.nvim_win_set_buf(M.win_id, M.buf)
  vim.api.nvim_win_set_config(M.win_id, { title = " " .. title .. " " })
  return M.buf
end

---Check if output window is visible and optionally displays the given buffer
---@param buf? integer
---@return boolean
function M.is_visible(buf)
  return M.win_id ~= nil
    and vim.api.nvim_win_is_valid(M.win_id)
    and (buf == nil or vim.api.nvim_win_get_buf(M.win_id) == buf)
end

function M.focus()
  if M.is_visible() then
    vim.api.nvim_set_current_win(M.win_id)
  end
end

function M.close()
  if M.is_visible() then
    vim.api.nvim_win_close(M.win_id, true)
    M.win_id = nil
  end

  pcall(vim.api.nvim_buf_delete, M.buf, { force = true })
end

return M
