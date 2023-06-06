local fsfcg, minetest, sway = fsfcg, minetest, sway
local S = fsfcg.get_translator
local gui = sway.widgets


local function CraftguideImageButton(name, tooltip, on_event)
	return gui.VBox{
		gui.ImageButton{
			w = 0.8, h = 0.8,
			texture_name = "craftguide_" .. name .. "_icon.png",
			name = name,
			label = "",
			on_event = on_event
		},
		gui.Tooltip{ tooltip_text = tooltip, gui_element_name = name }
	}
end


local function Recipe(fields)
	local data = fields.data
	local recipe = data.recipes[data.rnum]
	local width = recipe.width
	local cooktime, shapeless

	if recipe.method == "cooking" then
		cooktime, width = width, 1
	elseif width == 0 then
		shapeless = true
		if #recipe.items == 1 then
			width = 1
		elseif #recipe.items <= 4 then
			width = 2
		else
			width = 3
		end
	end
	local rows = math.ceil(table.maxn(recipe.items) / width)

	local fs = {
		gui.Label{
			label = data.show_usages
				and S("Usage @1 of @2", data.rnum, #data.recipes)
				or S("Recipe @1 of @2", data.rnum, #data.recipes)
		},
		#data.recipes > 1 and gui.HBox{
			-- TODO move callbacks to here
			CraftguideImageButton("prev", S("Previous recipe")),
			CraftguideImageButton("next", S("Next recipe"))
		} or gui.Nil{},
		(width > 3 or rows > 3) and gui.Label{ label = S("Recipe is too big to be displayed.") } or gui.Nil{}
	}

	-- Use local variables for faster execution in loop
	local ItemButton = fsfcg.ItemButton
	local extract_groups = fsfcg.extract_groups
	local groups_to_item = fsfcg.groups_to_item

	local recipe_info = {}
	local recipe_rows = {}
	local recipe_row = {}
	for _, item in pairs(recipe.items) do
		local elem_name = item
		local groups = extract_groups(item)
		if groups then
			item = groups_to_item(groups)
			elem_name = item.."."..table.concat(groups, "+")
		end
		recipe_row[#recipe_row+1] = ItemButton{ item = item, element_name = elem_name, groups = groups }
		if #recipe_row >= width then
			recipe_rows[#recipe_rows+1] = gui.HBox(recipe_row)
			recipe_row = {}
		end
	end
	if #recipe_row > 0 then
		recipe_rows[#recipe_rows+1] = gui.HBox(recipe_row)
	end
	recipe_info[#recipe_info+1] = gui.VBox(recipe_rows)

	if shapeless or recipe.method == "cooking" then
		recipe_info[#recipe_info+1] = gui.Image{
			w = 0.5, h = 0.5,
			texture_name = shapeless and "craftguide_shapeless.png" or "craftguide_furnace.png",
			name = "cooking_type"
		}
		recipe_info[#recipe_info+1] = gui.Tooltip{
			gui_element_name = "cooking_type",
			tooltip_text = shapeless and S("Shapeless") or S("Cooking time: @1", minetest.colorize("yellow", cooktime))
		}
	end
	recipe_info[#recipe_info+1] = gui.Image{ w = 1, h = 1, texture_name = "sway_crafting_arrow.png" }

	recipe_info[#recipe_info+1] = ItemButton{ item = recipe.output, element_name = recipe.output:match"%S*" }

	fs[#fs+1] = gui.HBox(recipe_info)
	return gui.VBox(fs)
end

local function get_formspec(player, context)
	local name = player:get_player_name()
	local data = fsfcg.player_data[name] or { items = fsfcg.init_items }
	context.fsfcg = data
	local w = 8

	local function filter_cb(_, c)
		local new = c.form.filter:lower()
		if data.filter == new then
			return
		end
		data.filter = new
		fsfcg.execute_search(data)
		return true
	end

	local fs = {
		expand = true,
		gui.StyleType{
			selectors = { "item_image_button" },
			props = { padding = 2 }
		},
		gui.HBox{
			gui.Field{
				name = "filter",
				default = data.filter,
				on_event = filter_cb
			},
			CraftguideImageButton("search", S("Search"), filter_cb),
			CraftguideImageButton("clear", S("Reset"), function(_, c)
				data.filter = ""
				c.form.filter = data.filter
				data.prev_item = nil
				data.recipes = nil
				data.items = fsfcg.init_items
				return true
			end),
		},
	}

	if #data.items == 0 then
		fs[#fs+1] = gui.VBox{
			align_v = "center", align_h = "center",
			expand = true,
			gui.Label{ label = S("No items to show.") }
		}
	else
		local items_rendered = { w = nil, h = 8, name = "pages" }
		local ItemButton = fsfcg.ItemButton

		-- TODO turn into a seperate function
		local row = {}
		for _, item in ipairs(data.items) do
			row[#row+1] = ItemButton{ item = item, element_name = item }
			if #row >= w then
				items_rendered[#items_rendered+1] = gui.HBox(row)
				row = {}
			end
		end
		if #row > 0 then
			items_rendered[#items_rendered+1] = gui.HBox(row)
		end
		fs[#fs+1] = gui.ScrollableVBox(items_rendered)
		--fs[#fs+1] = gui.PaginatedVBox(items_rendered)
	end

	if data.recipes then
		fs[#fs+1] = Recipe{data = data}
	elseif data.prev_item then
		fs[#fs+1] = gui.Label{
			label = data.show_usages
				and S("No usages.").."\n"..S("Click again to show recipes.")
				or S("No recipes.").."\n"..S("Click again to show usages.")
		}
	end

	return gui.VBox(fs)
end

local orig_update_for_player = fsfcg.update_for_player
function fsfcg.update_for_player(playername)
	local player = orig_update_for_player(playername)
	if player and sway.enabled then
		sway.set_player_inventory_formspec(player)
	end
	return player
end

-- BUG this code has a race condition. If two mods replace a widget, there needs to be a way to ensure they both play
-- nice.
local OldForm = gui.sway.Form
function gui.sway.Form(fields)
	local player = fields.player
	local context = fields.context
	return gui.HBox{
		spacing = 0.25,
		OldForm(fields),
		(player and context) and gui.VBox{
			bgimg = "sway_bg_full.png",
			bgimg_middle = 12,
			padding = 0.4,
			get_formspec(player, context)
		} or gui.Nil{}
	}
end
sway.register_page("fsfcraftguide:craftguide", {
	title = S("Recipes"),
	get = function(self, player, context)
		return gui.sway.Form{
			player = player,
			context = context,
			get_formspec(player, context)
		}
	end
})
