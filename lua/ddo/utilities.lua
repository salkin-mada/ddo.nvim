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
U = {}
local name = 'ddo.nvim'
U.path_sep = vim.loop.os_uname().sysname:match('Windows') and '\\' or '/'

U.anyof = function(element, table)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function U.get_len(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function U.get_plugin_root_dir()
	local package_path = debug.getinfo(1).source:gsub('@', '')
	package_path = vim.split(package_path, U.path_sep, true)
	-- find index of plugin root dir
	local index = 1
	for i, v in ipairs(package_path) do
		if v == name then
			index = i
			break
		end
	end
	local path_len = U.get_len(package_path)
	if index == 1 or index == path_len then
		error('['..name..'] could not find plugin root dir')
	end
	local path = {}
	for i, v in ipairs(package_path) do
		if i > index then
			break
		end
		path[i] = v
	end
	local dir = ''
	for _, v in ipairs(path) do
		-- first element is empty on unix
		if v == '' then
			dir = U.path_sep
		else
			dir = dir .. v .. U.path_sep
		end
	end
	assert(dir ~= '', '['..name..'] Could not get plugin root path')
	dir = dir:sub(1, -2) -- delete trailing slash
	return dir
end

return U
