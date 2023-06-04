local fsfcg = fsfcg
local S = fsfcg.get_translator
local esc = minetest.formspec_escape
local gui = sway.widgets


local group_stereotypes = {
	dye = "dye:white",
	wool = "wool:white",
	coal = "default:coal_lump",
	vessel = "vessels:glass_bottle",
	flower = "flowers:dandelion_yellow"
}


local group_names = {
	coal = S("Any coal"),
	sand = S("Any sand"),
	wool = S("Any wool"),
	stick = S("Any stick"),
	vessel = S("Any vessel"),
	wood = S("Any wood planks"),
	stone = S("Any kind of stone block"),

	["color_red,flower"] = S("Any red flower"),
	["color_blue,flower"] = S("Any blue flower"),
	["color_black,flower"] = S("Any black flower"),
	["color_green,flower"] = S("Any green flower"),
	["color_white,flower"] = S("Any white flower"),
	["color_orange,flower"] = S("Any orange flower"),
	["color_violet,flower"] = S("Any violet flower"),
	["color_yellow,flower"] = S("Any yellow flower"),

	["color_red,dye"] = S("Any red dye"),
	["color_blue,dye"] = S("Any blue dye"),
	["color_cyan,dye"] = S("Any cyan dye"),
	["color_grey,dye"] = S("Any grey dye"),
	["color_pink,dye"] = S("Any pink dye"),
	["color_black,dye"] = S("Any black dye"),
	["color_brown,dye"] = S("Any brown dye"),
	["color_green,dye"] = S("Any green dye"),
	["color_white,dye"] = S("Any white dye"),
	["color_orange,dye"] = S("Any orange dye"),
	["color_violet,dye"] = S("Any violet dye"),
	["color_yellow,dye"] = S("Any yellow dye"),
	["color_magenta,dye"] = S("Any magenta dye"),
	["color_dark_grey,dye"] = S("Any dark grey dye"),
	["color_dark_green,dye"] = S("Any dark green dye")
}


function fsfcg.extract_groups(str)
	if str:sub(1, 6) == "group:" then
		return str:sub(7):split()
	end
	return nil
end
local extract_groups = fsfcg.extract_groups


local function imatch(str, filter)
	return str:lower():find(filter, 1, true) ~= nil
end


function fsfcg.execute_search(data)
  local init_items = fsfcg.init_items
	local filter = data.filter
	if filter == "" then
		data.items = init_items
		return
	end
	data.items = {}

  local reg_items = minetest.registered_items
	for _, item in ipairs(init_items) do
    if imatch(item, filter) then
      table.insert(data.items, item)
    else
      local def = reg_items[item]
      local desc = def and def.description
      if desc then
        if imatch(desc, filter) then
          table.insert(data.items, item)
        else
          local tr_desc = minetest.get_translated_string(data.lang_code, desc)
          if tr_desc and imatch(tr_desc, filter) then
            table.insert(data.items, item)
          end
        end
      end
		end
	end
end


local function table_replace(t, val, new)
	for k, v in pairs(t) do
		if v == val then
			t[k] = new
		end
	end
end


function fsfcg.item_has_groups(item_groups, groups)
	for _, group in ipairs(groups) do
		if not item_groups[group] then
			return false
		end
	end
	return true
end
local item_has_groups = fsfcg.item_has_groups


function fsfcg.groups_to_item(groups)
	if #groups == 1 then
		local group = groups[1]
		if group_stereotypes[group] then
			return group_stereotypes[group]
		elseif minetest.registered_items["default:"..group] then
			return "default:"..group
		end
	end

	for name, def in pairs(minetest.registered_items) do
		if item_has_groups(def.groups, groups) then
			return name
		end
	end

	return ":unknown"
end


local function get_craftable_recipes(output)
	local recipes = minetest.get_all_craft_recipes(output)
	if not recipes then
		return nil
	end

  local groups_to_item = fsfcg.groups_to_item
  local reg_items = minetest.registered_items
	for i = #recipes, 1, -1 do
		for _, item in pairs(recipes[i].items) do
			local groups = extract_groups(item)
			if groups then
				item = groups_to_item(groups)
			end
			if not reg_items[item] then
				table.remove(recipes, i)
				break
			end
		end
	end

	if #recipes > 0 then
		return recipes
	end
end


local function show_item(def)
	return def and def.groups and def.groups.not_in_craft_guide ~= 1 and def.description ~= ""
end


local function cache_usages(recipe)

	local added = {}
  local usages_cache = fsfcg.usages_cache
  local reg_items = minetest.registered_items

	for _, item in pairs(recipe.items) do
		if not added[item] then
			local groups = extract_groups(item)
			if groups then

				for name, def in pairs(reg_items) do
					if not added[name] and show_item(def)
							and item_has_groups(def.groups, groups) then
						local usage = table.copy(recipe)
						table_replace(usage.items, item, name)
						usages_cache[name] = usages_cache[name] or {}
						table.insert(usages_cache[name], usage)
						added[name] = true
					end
				end

			elseif show_item(reg_items[item]) then
				usages_cache[item] = usages_cache[item] or {}
				table.insert(usages_cache[item], recipe)
			end

			added[item] = true
		end
	end
end


local function is_fuel(item)
	return minetest.get_craft_result({method="fuel", items={item}}).time > 0
end


function fsfcg.ItemButton(fields)
	local item, element_name, groups = fields.item, fields.element_name, fields.groups
	local fs = {
		gui.ItemImageButton{
			w = 1.05, h = 1.05,
			item_name = item,
			name = element_name,
			groups and "\n" .. S("G") or ""
		}
	}

	local tooltip
	if groups then
		table.sort(groups)
		tooltip = group_names[table.concat(groups, ",")]
		if not tooltip then
			local groupstr = {}
			for _, group in ipairs(groups) do
				table.insert(groupstr, minetest.colorize("yellow", group))
			end
			groupstr = table.concat(groupstr, ", ")
			tooltip = S("Any item belonging to the group(s): @1", groupstr)
		end
	elseif is_fuel(item) then
		local itemdef = minetest.registered_items[item:match("%S*")]
		local desc = itemdef and itemdef.description or S("Unknown Item")
		tooltip = desc.."\n"..minetest.colorize("orange", S("Fuel"))
	end
	if tooltip then
		fs[#fs+1] = gui.Tooltip{ tooltip_text = tooltip, gui_element_name = element_name }
	end
	return gui.VBox(fs)
end


function fsfcg.on_receive_fields(player, fields)
	local name = player:get_player_name()
	local data = fsfcg.player_data[name]

	if fields.clear then
		data.filter = ""
		data.pagenum = 1
		data.prev_item = nil
		data.recipes = nil
		data.items = fsfcg.init_items
		return true

	elseif fields.key_enter_field == "filter" or fields.search then
		local new = fields.filter:lower()
		if data.filter == new then
			return
		end
		data.filter = new
		data.pagenum = 1
		fsfcg.execute_search(data)
		return true

	elseif fields.prev or fields.next then
		if data.pagemax == 1 then
			return
		end
		data.pagenum = data.pagenum + (fields.next and 1 or -1)
		if data.pagenum > data.pagemax then
			data.pagenum = 1
		elseif data.pagenum == 0 then
			data.pagenum = data.pagemax
		end
		return true

	elseif fields.recipe_next or fields.recipe_prev then
		data.rnum = data.rnum + (fields.recipe_next and 1 or -1)
		if data.rnum > #data.recipes then
			data.rnum = 1
		elseif data.rnum == 0 then
			data.rnum = #data.recipes
		end
		return true

	else
		local item
		for field in pairs(fields) do
			if field:find(":") then
				item = field:match("[%w_:]+")
				break
			end
		end
		if not item then
			return
		end

		if item == data.prev_item then
			data.show_usages = not data.show_usages
		else
			data.show_usages = nil
		end
		if data.show_usages then
			data.recipes = fsfcg.usages_cache[item]
		else
			data.recipes = fsfcg.recipes_cache[item]
		end
		data.prev_item = item
		data.rnum = 1
		return true
	end
end


function fsfcg.update_for_player(playername)
	local player = minetest.get_player_by_name(playername)
	if player then
		fsfcg.execute_search(fsfcg.player_data[playername])
	end
  return player
end


minetest.register_on_mods_loaded(function()

  local recipes_cache = fsfcg.recipes_cache
  local usages_cache = fsfcg.usages_cache
  local init_items = fsfcg.init_items
	for name, def in pairs(minetest.registered_items) do
		if show_item(def) then
			local recipes = get_craftable_recipes(name)
			if recipes then
				recipes_cache[name] = recipes
				for _, recipe in ipairs(recipes) do
					cache_usages(recipe)
				end
			end
		end
	end

	for name, def in pairs(minetest.registered_items) do
		if recipes_cache[name] or usages_cache[name] then
			table.insert(init_items, name)
		end
	end
	table.sort(init_items)

end)


minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local info = minetest.get_player_information(name)

	local data = {
		playername = name,
		filter = "",
		pagenum = 1,
		items = fsfcg.init_items,
		lang_code = info.lang_code
	}
	fsfcg.player_data[name] = data
	fsfcg.execute_search(data)
end)


minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	fsfcg.player_data[name] = nil
end)
