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

local U = require'ddo.utilities'
local api = vim.api
local UI = {}
local win_id
local win_id_
local buf_nr
local buf_nr_
local filetype = 'ddo'

UI.height_proportion = 2/3
UI.max_height = 30

local function create_windows(self)
    -- result
	self.bufnr = api.nvim_create_buf(false, true)
    buf_nr = self.bufnr
	vim.bo[self.bufnr].buftype = 'nowrite'
	api.nvim_buf_set_name(self.bufnr, '[ddo]')
    -- prompt
	self.bufnr_ = api.nvim_create_buf(false, true)
    buf_nr_ = self.bufnr_
	vim.bo[self.bufnr_].buftype = 'nowrite' -- type -> 'prompt'
	api.nvim_buf_set_name(self.bufnr_, '[ddo-prompt]')
end

-- function string:firstword()
--     return self:match("^([%w]+)");
-- end
local function firstword(inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
   end
   return t[1]
end

-- move into own @class .. so lazy
local query = function()
    vim.cmd('stopinsert')
    local query = vim.api.nvim_get_current_line()
    close(win_id_)
    vim.api.nvim_set_current_win(win_id)
    -- vim.api.nvim_input(query..'<Esc>')
    vim.api.nvim_buf_set_lines(buf_nr, 0, -1, true, {""}) -- clear
    query = string.gsub(query,"> ","")
    query = string.gsub(query,">","")
    query = firstword(query)
    vim.api.nvim_buf_set_lines(buf_nr, 0, 0, false, {query})
    vim.api.nvim_buf_set_lines(buf_nr, 1, 1, false, {"~~~~~~~"})

    -- print(vim.inspect.inspect())
    --
    function tablelength(T)
        local count = 0
        for _ in pairs(T) do count = count + 1 end
        return count
    end

    local handle = io.popen(U.get_plugin_root_dir().."/ddo.sh "..query)
    if handle then
        local result = handle:read("*a")
        -- if vim.g.ddo_sed_style == 'gnu'  then
        --     -- ERE with gnu sed:
        --     handle_ = io.popen("echo ".."\""..result.."\"".." | sed -r '/^\\s*$/d'")
        -- else
            -- posix
            handle_ = io.popen("echo ".."\""..result.."\"".." | sed '/^[[:space:]]*$/d'")
        -- end

        if handle_ then squeeze = handle_:read("*a") handle_:close() end
        i = 2
        for s in squeeze:gmatch("[^\r\n]+") do
            vim.api.nvim_buf_set_lines(buf_nr,i,i,false,{s})
            i = i + 1
        end
        handle:close()
    end
    -- reposition cursor
    api.nvim_win_set_cursor(win_id, {1, 1})
end

local abort = function()
    vim.cmd('stopinsert')
    close(win_id)
    close(win_id_)
end

function UI:new()
	tbl = {}
	setmetatable(tbl, self)
	self.__index = self

    create_windows(self)

    vim.keymap.set('n', vim.g.ddo_toggle_key or '<leader>å', function() closeui(true) end, { silent = true, buffer = self.bufnr })
    vim.keymap.set('n', 'q', function() closeui() end, { silent = true, buffer = self.bufnr })
    vim.keymap.set('n', '<Esc>', function() closeui() end, { silent = true, buffer = self.bufnr })

    vim.keymap.set('n', '<Esc>', abort, { silent = true, buffer = self.bufnr_ })
    vim.keymap.set('i', '<Esc>', abort, { silent = true, buffer = self.bufnr_ })
    vim.keymap.set('n', '<Enter>', query, { silent = true, buffer = self.bufnr_ })
    vim.keymap.set('i', '<Enter>', query, { silent = true, buffer = self.bufnr_ })
	return tbl
end

function UI:is_open()
    -- print(self.bufnr)
    --
	return self:is_valid() and vim.fn.bufwinnr(self.bufnr) > 0
	-- return self:is_valid() and vim.fn.bufwinnr(self.bufnr) > 0 and vim.fn.bufwinnr(self.bufnr_) > 0
end

function UI:is_valid()
	return self.bufnr and api.nvim_buf_is_loaded(self.bufnr) or false
end

function UI:set_lines(data)
	if self:is_valid() then
		api.nvim_buf_set_lines(self.bufnr, -1, -1, true, {data})
		if self:is_open() then
			local num_lines = api.nvim_buf_line_count(self.bufnr)
			api.nvim_win_set_cursor(self.winnr, {num_lines, 0})
		end
	end
end


function UI:open_prompt()

	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")
    local win_height = math.min(math.ceil(height * UI.height_proportion), UI.max_height)
    local win_width
        if (width >= 15 and height >= 15) then
            -- brute scale to width
            if (width < 100) then
                win_width = math.ceil(width * 0.7)
            else
                win_width = math.ceil(width * 0.5)
            end
            local opts_ = {
                relative = 'editor',
                style = 'minimal',
                width = win_width,
                height = 1,
                row =  math.ceil((height - win_height) / 2)-1,
                col = math.ceil((width - win_width) / 2)
            }
            self.winnr_ = api.nvim_open_win(self.bufnr_, true, opts_)
            win_id_ = self.winnr_
            api.nvim_win_set_option(self.winnr_, 'winhl', 'Normal:Floating')
            api.nvim_win_set_option(self.winnr_, 'winblend', vim.g.ddo_window_blend)
            api.nvim_buf_set_option(self.bufnr_, 'filetype', filetype)
            vim.cmd('startinsert')
            vim.api.nvim_input("> ")
    end
end

function UI:open(with_prompt)
    -- if vim.api.nvim_win_get_config(0).zindex then
	-- self:load_cursor_pos()
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")
    -- the window height is "height_proportion" of the max height, but not more than max_height
    local win_height = math.min(math.ceil(height * UI.height_proportion), UI.max_height)
    local win_width


    -- if the editor is big enough
    if (width >= 15 and height >= 15) then
        -- only open if a query result has been dumped
        -- if (vim.api.nvim_buf_line_count(buf_nr) > 1) then
            -- brute scale to width
            if (width < 100) then
                win_width = math.ceil(width * 0.7)
            else
                win_width = math.ceil(width * 0.5)
            end
            local opts = {
                relative = 'editor',
                style = 'minimal',
                width = win_width,
                height = win_height,
                row = math.ceil((height - win_height) / 2),
                col = math.ceil((width - win_width) / 2)
            }
            -- local border_options = self:create_border(opts)
            -- self.winnr = api.nvim_open_win(self.bufnr, false, opts)
            self.winnr = api.nvim_open_win(self.bufnr, true, opts)
            win_id = self.winnr
            api.nvim_win_set_option(self.winnr, 'winhl', 'Normal:Floating')
            api.nvim_win_set_option(self.winnr, 'winblend', vim.g.ddo_window_blend)
            api.nvim_buf_set_option(self.bufnr, 'filetype', filetype)
        -- end

        if with_prompt then
            UI:open_prompt()
        end
    else
        print("w:", width, "h:", height, "term window is too small")
    end

    -- end
end

function UI:close(with_prompt)
    closeui(with_prompt)
end

function close(winid)
    if api.nvim_win_is_valid(winid) then
        api.nvim_win_close(winid, true)
        if winid == win_id_ then
            api.nvim_buf_delete(buf_nr_, { unload = true })
        end
    end
end

function closeui(check_buf)
    if check_buf then
        -- if api.nvim_get_current_win() == win_id then
        if api.nvim_get_current_buf() == buf_nr then
            UI:open_prompt()
        else
            close(win_id)
            close(win_id_)
        end
    else
        close(win_id)
        close(win_id_)
    end
end

-- function UI:destroy()
-- 	-- self.save_cursor_pos()
-- 	api.nvim_buf_delete(self.bufnr, { force = true })
-- 	api.nvim_buf_delete(self.bufnr_, { force = true })
-- end

function UI:unload()
	-- self.save_cursor_pos()
	api.nvim_buf_delete(self.bufnr, { unload = true })
	api.nvim_buf_delete(self.bufnr_, { unload = true })
end

-- function UI:create_border(options, margin)
-- 	vim.validate {
-- 		options = {options, 'table'}
-- 	}
-- 	margin = margin or 2
-- 	local opts = {
-- 		width = options.width + margin,
-- 		height = options.height + margin,
-- 		col = options.col - (margin / 2),
-- 		row = options.row - (margin / 2),
-- 		focusable = false,
-- 	}
-- 	local border = {}
-- 	local t = '╔' .. string.rep('═', opts.width - margin) .. '╗'
-- 	local s = '║' .. string.rep(' ', opts.width - margin) .. '║'
-- 	local b = '╚' .. string.rep('═', opts.width - margin) .. '╝'
-- 	table.insert(border, t);
-- 	for _=1, opts.height - margin do
-- 		table.insert(border, s);
-- 	end
-- 	table.insert(border, b);
-- 	api.nvim_buf_set_lines(self.border_bufnr, 0, -1, true, border)
-- 	return vim.tbl_extend('keep', opts, options)
-- end

-- function UI:store(name, win, buf)
-- 	self.wins[name] = win
-- 	self.bufs[name] = buf
-- end

-- function UI:place_cursor()
-- 	local pos = UI.last_cursor_pos or {1,0}
-- 	api.nvim_win_set_cursor(0,pos)
-- end

-- function UI:save_cursor_pos()
-- 	-- buggy..
-- 	if fn.win_getid() == win_id then
-- 		UI.last_cursor_pos = api.nvim_win_get_cursor(win_id)
-- 	end
-- 	-- print("O",win_id,"current", fn.win_getid())
-- 	-- self.last_win = fn.winnr()
-- 	-- self.last_pos = fn.getpos('.')
-- end

-- function UI:read_file()
-- 	-- local path = U.ddo_nvim_root_dir .. U.path_sep .. "help_source" .. U.path_sep .. "ddo_cheatsheet.scadhelp"
-- 	-- api.nvim_command('silent read '  .. path)
--     -- print("read file.. empty")
-- end

-- function UI:load_cursor_pos()
-- 	if self.last_win and next(self.last_pos) then
-- 		cmd(self.last_win.." wincmd w")
-- 		fn.setpos('.', self.last_pos)
-- 		self.last_win = nil
-- 		self.last_pos = nil
-- 	end
-- end

return UI
