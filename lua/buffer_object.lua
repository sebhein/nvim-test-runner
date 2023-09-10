local ts_utils = require 'nvim-treesitter.ts_utils'
local api = vim.api
local BufferObject = {}

function BufferObject:new(bufnr)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  self._filename = api.nvim_buf_get_name(bufnr)
  self._bufnr = bufnr
  self._scratch_bufnr = api.nvim_create_buf(false, true)
  self._test_names = {}
  return o
end

function BufferObject:get_path()
  return self._filename
end

function BufferObject:write_to_scratch(content)
  vim.schedule(function()
    api.nvim_buf_set_lines(self._scratch_bufnr, 0, -1, false, content)
  end)
end

function BufferObject:open_scratch()
  api.nvim_buf_call(self._scratch_bufnr, function()
    vim.cmd('botright vsplit')
    vim.cmd('vertical resize 120')
  end)
end

function BufferObject:collect_function_nodes(node, result)
    if node:type() == 'function_definition' then
      result[vim.treesitter.get_node_text(node:named_child(0), self._bufnr)] = node
    end

    for child in node:iter_children() do
        self:collect_function_nodes(child, result)
    end
end

function BufferObject:place_sign(type, function_name)
  vim.schedule(function()
    -- TODO: this seems pretty expensive to do for every sign
    local root = ts_utils.get_root_for_position(0, 0)
    local test_to_node = {}
    self:collect_function_nodes(root, test_to_node)
    -- this block
    local row, _, _ = test_to_node[function_name]:start()
    vim.fn.sign_place(0, 'TronSigns', type, self._bufnr, {lnum=row + 1, priority=10}) 
  end)
end

return BufferObject
