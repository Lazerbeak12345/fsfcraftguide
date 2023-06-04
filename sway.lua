local fsfcg, minetest, sway = fsfcg, minetest, sway
local S = fsfcg.get_translator
local esc = minetest.formspec_escape
local gui = sway.widgets


local function coords(i, cols)
	return i % cols, math.floor(i / cols)
end


local function Recipe(fs, data)
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

	table.insert(fs, ("label[5.5,1;%s]"):format(esc(data.show_usages
		and S("Usage @1 of @2", data.rnum, #data.recipes)
		or S("Recipe @1 of @2", data.rnum, #data.recipes))))

	if #data.recipes > 1 then
		table.insert(fs,
			"image_button[5.5,1.6;0.8,0.8;craftguide_prev_icon.png;recipe_prev;]"..
			"image_button[6.2,1.6;0.8,0.8;craftguide_next_icon.png;recipe_next;]"..
			"tooltip[recipe_prev;"..esc(S("Previous recipe")).."]"..
			"tooltip[recipe_next;"..esc(S("Next recipe")).."]")
	end

	local rows = math.ceil(table.maxn(recipe.items) / width)
	if width > 3 or rows > 3 then
		table.insert(fs, ("label[0,1;%s]")
			:format(esc(S("Recipe is too big to be displayed."))))
		return
	end

	local base_x = 3 - width
	local base_y = rows == 1 and 1 or 0

  -- Use local variables for faster execution in loop
	local ItemButton = fsfcg.ItemButton
  local extract_groups = fsfcg.extract_groups
  local groups_to_item = fsfcg.groups_to_item

	for i, item in pairs(recipe.items) do
		local x, y = coords(i - 1, width)

		local elem_name = item
		local groups = extract_groups(item)
		if groups then
			item = groups_to_item(groups)
			elem_name = esc(item.."."..table.concat(groups, "+"))
		end
		ItemButton(fs, base_x + x, base_y + y, item, elem_name, groups)
	end

	if shapeless or recipe.method == "cooking" then
		table.insert(fs, ("image[3.2,0.5;0.5,0.5;craftguide_%s.png]")
			:format(shapeless and "shapeless" or "furnace"))
		local tooltip = shapeless and S("Shapeless") or
			S("Cooking time: @1", minetest.colorize("yellow", cooktime))
		table.insert(fs, "tooltip[3.2,0.5;0.5,0.5;"..esc(tooltip).."]")
	end
	table.insert(fs, "image[3,1;1,1;sfinv_crafting_arrow.png]")

	ItemButton(fs, 4, 1, recipe.output, recipe.output:match("%S*"))
end

local function CraftguideImageButton(name, tooltip)
	return gui.VBox{
		gui.ImageButton{
			w = 0.8, h = 0.8,
			texture_name = "craftguide_" .. name .. "_icon.png",
			name = name,
			label = "",
		},
		gui.Tooltip{ tooltip_text = tooltip, gui_element_name = name }
	}
end

local function get_formspec(player, context)
	print("fsfcg get_formspec", dump(fsfcg.player_data))
	local name = player:get_player_name()
	local data = fsfcg.player_data[name] or { items = {}, pagenum = 1 }
	local w = 8

	local fs = {
		expand = true,
		gui.StyleType{
			selectors = { "item_image_button" },
			props = { padding = 2 }
		},
		gui.HBox{
			gui.Field{ name = "filter", default = data.filter },
			CraftguideImageButton("search", S("Search")),
			CraftguideImageButton("clear", S("Reset")),
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
	end

	--table.insert(fs, "container[0,5.6]")
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
