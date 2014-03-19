--[[
	Lua log mod_mam reader (Prosody)
	Alexandre Espinosa Menor <aemenor@gmail.com>
	
	To use: lua arg[0] [FILE | LOG_DIR]
	
	Note: LOG_DIR usually is /var/lib/prosody/VIRTUALHOST/archive2
--]]

require 'lfs'

local files = {};

-- read files from directory
function read_files(dir)
	local files = {};
	
	for file in lfs.dir(dir) do
		if lfs.attributes(file,"mode") == "file" then
			table.insert(files, dir..'/'..file)
		end
	end
	
	return files
end


-- parsea items para devolver log em formato legivel
function parse_item(item)
	local return_log;
	local msg = '';
		
	local from = string.gsub(item['stanza']['attr']['from'], '/.*$', '')
	local to = string.gsub(item['stanza']['attr']['to'], '/.*$', '')
	
	-- se som iguais from e to, sera que esta numha sala, colhemos resource do root
	if from == to then
		from = item['resource']
	end

	-- buscamos onde esta ['name'] = body para saber onde esta a mensagem ([1] dessa table)
	for key, value in pairs(item['stanza']) do
		if value['name'] == "body" and type(value['attr']) == "table" then
			if value[1] then
				msg = value[1];
			else
				msg = '';
			end
		elseif value['name'] == "subject" and type(value['attr']) == "table" and value[1] ~= nil then
			msg = '[TOPIC NOVO] '..value[1];
			-- local inspect = require('lib/inspect')
			-- print(inspect(value))
			-- os.exit()
		end
	end

	return_log = '['..os.date("%Y-%m-%d %H:%M:%S", item['when'])..'] '..from..' > '..to..' : '..msg
	
	return return_log
end


-- le ficheiros e carga items
function read_items(file)
	local file = assert(io.open(file, "r"))
	local str = file:read("*a")
	
	local items = {}
	for i in string.gmatch(str, '(item%({.-\n}%);%s)') do
		-- if string.find(i, 'atopado string que peta') then
		-- 	print('i: '..i);
		-- 	return 
		-- end

		table.insert(items, i)
	end
	return items
end




-- main
if arg[1] then 
	if lfs.attributes(arg[1],"mode")== "directory" then
		files = read_files(arg[1])
	else
		table.insert(files, arg[1])
	end
else
	print('Uso: lua '..arg[0]..' [FILE|LOG_DIR]')
end



for i = 1, #files do
	items = read_items(files[i])

	for i = 1,#items do
		item = items[i]
		item = string.gsub(item, '^item%({', '({')
		
		item = loadstring("return "..item)()
		print(parse_item(item))
	end
end
