local M = {}

----------
-- CONFIG
----------

M.ignored_buftypes = {
  'nofile',
  'quickfix',
  'prompt',
}

M.ignored_filetypes = {
  'NvimTree',
}

----------
-- PLUGIN
----------

local win_pos = {
  start = 0,
  middle = 1,
  middle_middle = 2,
  last = 3,
}

local function is_full_height(winnr)
  -- for vertical height account for tabline, status line, and cmd line
  local window_height = vim.o.lines - 1 - vim.o.cmdheight
  if (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1) or vim.o.showtabline == 2 then
    window_height = window_height - 1
  end
  return vim.api.nvim_win_get_height(winnr or 0) == window_height
end

local function is_full_width(winnr)
  return vim.api.nvim_win_get_width(winnr or 0) == vim.o.columns
end

local function move_win(direction)
  if direction == 'j' or direction == 'k' then
    vim.cmd('wincmd ' .. direction)
    return
  end

  local offset = vim.fn.winline() + vim.api.nvim_win_get_position(0)[1]
  vim.cmd('wincmd ' .. direction)
  offset = offset - vim.api.nvim_win_get_position(0)[1]
  vim.cmd('normal! ' .. offset .. 'H')
end

local function at_top_edge()
  local cur_win = vim.api.nvim_get_current_win()
  move_win('k')
  local is_at_top = vim.api.nvim_get_current_win() == cur_win
  vim.api.nvim_set_current_win(cur_win)
  return is_at_top
end

local function at_bottom_edge()
  local cur_win = vim.api.nvim_get_current_win()
  move_win('j')
  local is_at_bottom = vim.api.nvim_get_current_win() == cur_win
  vim.api.nvim_set_current_win(cur_win)
  return is_at_bottom
end

local function at_left_edge()
  local cur_win = vim.api.nvim_get_current_win()
  move_win('h')
  local is_at_left = vim.api.nvim_get_current_win() == cur_win
  vim.api.nvim_set_current_win(cur_win)
  return is_at_left
end

local function at_right_edge()
  local cur_win = vim.api.nvim_get_current_win()
  move_win('l')
  local is_at_right = vim.api.nvim_get_current_win() == cur_win
  vim.api.nvim_set_current_win(cur_win)
  return is_at_right
end

function M.win_position(direction)
  if direction == 'left' or direction == 'right' then
    if at_left_edge() then
      return win_pos.start
    end

    if at_right_edge() then
      return win_pos.last
    end

    if at_top_edge() or at_bottom_edge() then
      return win_pos.middle_middle
    end

    return win_pos.middle
  end

  if at_top_edge() then
    return win_pos.start
  end

  if at_bottom_edge() then
    return win_pos.last
  end

  return win_pos.middle
end

local function compute_direction_vertical(direction)
  local current_pos = M.win_position(direction)
  if current_pos == win_pos.start or current_pos == win_pos.middle then
    return direction == 'down' and '+' or '-'
  end

  return direction == 'down' and '-' or '+'
end

local function compute_direction_horizontal(direction)
  local current_pos = M.win_position(direction)
  if current_pos == win_pos.start or current_pos == win_pos.middle then
    return direction == 'right' and '+' or '-'
  end

  return direction == 'right' and '-' or '+'
end

local function resize(direction, amount)
  amount = amount or 3

  -- don't try to horizontally resize a full width window
  if (direction == 'left' or direction == 'right') and is_full_width() then
    return
  end

  -- don't try to vertically resize a full height window
  if (direction == 'down' or direction == 'up') and is_full_height() then
    return
  end

  -- vertically
  if direction == 'down' or direction == 'up' then
    local plus_minus = compute_direction_vertical(direction)
    vim.cmd(string.format('resize %s%s', plus_minus, amount))
    return
  end

  -- horizontally
  local plus_minus = compute_direction_horizontal(direction)
  vim.cmd(string.format('vertical resize %s%s', plus_minus, amount))
end

local function move_cursor(direction)
  if direction == 'left' then
    if at_left_edge() then
      for _ = 0, #vim.api.nvim_tabpage_list_wins(0), 1 do
        vim.cmd('wincmd l')
      end
    else
      vim.cmd('wincmd h')
    end
  elseif direction == 'right' then
    if at_right_edge() then
      for _ = 0, #vim.api.nvim_tabpage_list_wins(0), 1 do
        vim.cmd('wincmd h')
      end
    else
      vim.cmd('wincmd l')
    end
  elseif direction == 'up' then
    if at_top_edge() then
      for _ = 0, #vim.api.nvim_tabpage_list_wins(0), 1 do
        vim.cmd('wincmd j')
      end
    else
      vim.cmd('wincmd k')
    end
  elseif at_bottom_edge() then
    for _ = 0, #vim.api.nvim_tabpage_list_wins(0), 1 do
      vim.cmd('wincmd k')
    end
  else
    vim.cmd('wincmd j')
  end
end

vim.tbl_map(function(direction)
  M[string.format('resize_%s', direction)] = function(amount)
    resize(direction, amount)
  end
  M[string.format('move_cursor_%s', direction)] = function()
    move_cursor(direction)
  end
end, {
  'left',
  'right',
  'up',
  'down',
})

return M
