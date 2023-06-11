local fsfcg, minetest, sway = fsfcg, minetest, sway
local S = fsfcg.get_translator
local gui = sway.widgets

local FLOW_SPACING = 0.25
local FLOW_SIZE = 1.05

local function CraftguideImageButton(fields)
	local name = fields.name
	return gui.VBox{
		gui.ImageButton{
			w = 0.8, h = 0.8,
			texture_name = "craftguide_" .. (fields.texture_name or name) .. "_icon.png",
			name = name,
			label = "",
			on_event = fields.on_event
		},
		gui.Tooltip{ tooltip_text = fields.tooltip, gui_element_name = name }
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

	local function recipe_cb()
		if data.rnum > #data.recipes then
			data.rnum = 1
		elseif data.rnum == 0 then
			data.rnum = #data.recipes
		end
		return true
	end

	local fs = {
		gui.Label{
			label = data.show_usages
				and S("Usage @1 of @2", data.rnum, #data.recipes)
				or S("Recipe @1 of @2", data.rnum, #data.recipes)
		},
		#data.recipes > 1 and gui.HBox{
			CraftguideImageButton{
				name = "recipe_prev", texture_name = "prev",
				tooltip = S("Previous recipe"), on_event = function ()
					data.rnum = data.rnum + -1
					return recipe_cb()
				end
			},
			CraftguideImageButton{
				name = "recipe_next", texture_name = "next",
				tooltip =  S("Next recipe"), on_event = function ()
					data.rnum = data.rnum + 1
					return recipe_cb()
				end
			}
		} or gui.Nil{},
		(width > 3 or rows > 3) and gui.Label{ label = S("Recipe is too big to be displayed.") } or gui.Nil{}
	}

	-- Use local variables for faster execution in loop
	local ItemButton = fsfcg.ItemButton
	local extract_groups = fsfcg.extract_groups
	local groups_to_item = fsfcg.groups_to_item

	local recipe_parts = { spacing = FLOW_SPACING, w = width * (FLOW_SPACING + FLOW_SIZE) }
	for index=1,math.max(width * width, #recipe.items) do
		local item = recipe.items[index]
		if item then
			local elem_name = item
			local groups = extract_groups(item)
			if groups then
				item = groups_to_item(groups)
				elem_name = item.."."..table.concat(groups, "+")
			end
			recipe_parts[#recipe_parts+1] = ItemButton{ item = item, element_name = elem_name, groups = groups }
		else
			recipe_parts[#recipe_parts+1] = gui.Box{ color = "grey", w = FLOW_SIZE, h = FLOW_SIZE }
		end
	end
	local expanded_craft_info = shapeless or recipe.method == "cooking"
	fs[#fs+1] = gui.HBox{
		gui.Flow(recipe_parts),
		gui.VBox{
			align_v = "center",
			expanded_craft_info and gui.Spacer{ expand = false, w = 0.5, h = 0.5 } or gui.Nil{},
			gui.Image{ w = 1, h = 1, texture_name = "sway_crafting_arrow.png" },
			expanded_craft_info and gui.Image{
				w = 0.5, h = 0.5,
				texture_name = shapeless and "craftguide_shapeless.png" or "craftguide_furnace.png",
				name = "cooking_type"
			} or gui.Nil{},
			expanded_craft_info and gui.Tooltip{
				gui_element_name = "cooking_type",
				tooltip_text = shapeless and S("Shapeless") or S("Cooking time: @1", minetest.colorize("yellow", cooktime))
			} or gui.Nil{}
		},
		gui.VBox{
			align_v = "center",
			ItemButton{ item = recipe.output, element_name = recipe.output:match"%S*" }
		}
	}
	return gui.VBox(fs)
end

local function Form(fields)
	local player, context = fields.player, fields.context
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
			CraftguideImageButton{ name = "search", tooltip = S("Search"), on_event = filter_cb },
			CraftguideImageButton{
				name = "clear", tooltip = S("Reset"),
				on_event = function(_, c)
					data.filter = ""
					c.form.filter = data.filter
					data.prev_item = nil
					data.recipes = nil
					data.items = fsfcg.init_items
					return true
				end
			},
		},
	}

	if #data.items == 0 then
		fs[#fs+1] = gui.VBox{
			align_v = "center", align_h = "center",
			expand = true,
			gui.Label{ label = S("No items to show.") }
		}
	else
		local items_rendered = { w = w * (FLOW_SPACING + FLOW_SIZE), spacing = FLOW_SPACING }
		local ItemButton = fsfcg.ItemButton

		for _, item in ipairs(data.items) do
			items_rendered[#items_rendered+1] = ItemButton{ item = item, element_name = item }
		end
		items_rendered = gui.Flow(items_rendered)
		items_rendered.name = "craftguide_items"
		items_rendered.h = 8
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
			Form{ player = player, context = context }
		} or gui.Nil{}
	}
end
sway.register_page("fsfcraftguide:craftguide", {
	title = S("Recipes"),
	get = function(self, player, context)
		return gui.sway.Form{
			player = player,
			context = context,
			Form{ player = player, context = context }
		}
	end
})
