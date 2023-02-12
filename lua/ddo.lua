-- This file is part of ddo.nvim
--
-- ddo.nvim is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- ddo.nvim is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with ddo.nvim.  If not, see <http://www.gnu.org/licenses/>.
--
--
-- Maintainer: Niklas Adam <adam@oddodd.org>
-- Version:	0.1
-- Modified: 2023-02-07T09:10:57 CET
--

local M = {}
-- local S = require'ddo.shell'
local UI = require'ddo.ui'
-- local U = require'ddo.utilities'
-- local autocmd = vim.api.nvim_create_autocmd
-- local augroup = vim.api.nvim_create_augroup

vim.g.loaded_ddo = false

function M.setup()
    vim.g.ddo_default_mappings = vim.g.ddo_default_mappings or false
    vim.g.ddo_window_blend = vim.g.ddo_window_blend or 0 -- %
    -- vim.g.ddo_excludes = vim.g.ddo_excludes or {}
    vim.g.ddo_always_load = vim.g.ddo_always_load or false
    -- table.insert(vim.g.ddo_excludes, 'ddo') -- or {'ddo'}

    if vim.g.ddo_always_load then
        -- vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
        --     pattern = "*",
        --     callback = function ()
        --         if not U.anyof(vim.bo.filetype, vim.g.ddo_excludes) then
                    require'ddo'.load()
        --         end
        --     end
        -- })
    else
        vim.cmd("command! DDOLoad lua require('ddo').load()")
        -- autocmd({"FileType"}, {
        --     pattern = vim.g.ddo_filetypes or {'text', 'markdown'},
        --     callback = function ()
        --         if vim.bo.filetype ~= 'ddo' then
        --             require'ddo'.load()
        --         end
        --     end
        -- })
    end

end

function M.load()
    if vim.g.loaded_ddo == false then
        M.windows = UI:new()
        vim.cmd("command! DDO lua require('ddo').toggle(true)")
        vim.cmd("command! DDORead lua require('ddo').toggle()")
    end
    if vim.g.ddo_default_mappings then
        M.default_mappings()
        M.set_mappings()
    else
        M.set_user_mappings()
    end
    vim.g.loaded_ddo = true
end

function M.self_close()
    M.windows:unload()
    -- M.windows:close()
    -- print("self close ddo ui")
end

function M.toggle(with_prompt)
    if M.windows:is_open() then
        M.windows:close(with_prompt)
    else
        M.windows:open(with_prompt)
    end
end

function M.default_mappings()
    vim.g.ddo_toggle_key = vim.g.ddo_toggle_key or '<leader>å'
    vim.g.ddo_read_key = vim.g.ddo_read_key or '<leader>ø'
end

function M.set_mappings()
    vim.keymap.set('n', vim.g.ddo_toggle_key, function() require"ddo".toggle(true) end, { silent = true })
    vim.keymap.set('n', vim.g.ddo_read_key, function() require"ddo".toggle() end, { silent = true })
end

function M.set_user_mappings()
    if vim.g.ddo_toggle_key then
        vim.keymap.set('n', vim.g.ddo_toggle_key, function() require"ddo".toggle(true) end, { silent = true })
    end
    if vim.g.ddo_read_key then
        vim.keymap.set('n', vim.g.ddo_read_key, function() require"ddo".toggle() end, { silent = true })
    end
end

return M
