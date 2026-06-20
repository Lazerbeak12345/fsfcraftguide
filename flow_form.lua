-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local fsfcg, minetest, flow, flow_extras = fsfcg, minetest, flow, flow_extras
local S = fsfcg.get_translator
local gui = flow.widgets

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

local function RightArrow(_--[[fields]])
	local texture_name
	if minetest.global_exists"sway" then
		texture_name = "sway_crafting_arrow.png"
	elseif minetest.global_exists"sfinv" then
		texture_name = "sfinv_crafting_arrow.png"
	else
		-- This image name is a placeholder, and does not exist.
		texture_name = "fsfcraftguide_crafting_arrow.png"
	end
	return gui.Image{
		w = 1,
		h = 1,
		texture_name = texture_name
	}
end

local function Recipe(fields)
	local width = fields.width
	local cooktime, shapeless

	if fields.method == "cooking" then
		cooktime, width = width, 1
	elseif width == 0 then
		shapeless = true
		if #fields.items == 1 then
			width = 1
		elseif #fields.items <= 4 then
			width = 2
		else
			width = 3
		end
	end
	local rows = math.ceil(table.maxn(fields.items) / width)

	if width > 3 or rows > 3 then
		return gui.Label{ label = S("Recipe is too big to be displayed.") }
	end

	local recipe_parts = { spacing = FLOW_SPACING, w = width * (FLOW_SPACING + FLOW_SIZE) }
	for index=1,math.max(width * width, #fields.items) do
		local item = fields.items[index]
		if item then
			local elem_name = item
			local groups = fsfcg.extract_groups(item)
			if groups then
				item = fsfcg.groups_to_item(groups)
				elem_name = item.."."..table.concat(groups, "+")
			end
			recipe_parts[#recipe_parts+1] = fsfcg.ItemButton{ item = item, element_name = elem_name, groups = groups }
		else
			recipe_parts[#recipe_parts+1] = gui.Box{ color = "grey", w = FLOW_SIZE, h = FLOW_SIZE }
		end
	end

	return gui.HBox{
		gui.Flow(recipe_parts),
		(shapeless or fields.method == "cooking") and gui.VBox{
			align_v = "center",
			gui.Image{
				w = 0.5, h = 0.5,
				texture_name = shapeless and "craftguide_shapeless.png" or "craftguide_furnace.png",
				name = "cooking_type"
			},
			gui.Tooltip{
				gui_element_name = "cooking_type",
				tooltip_text = shapeless and S("Shapeless") or S("Cooking time: @1", minetest.colorize("yellow", cooktime))
			},
			RightArrow{},
			gui.Spacer{ expand = false, w = 0.5, h = 0.5 },
		} or gui.VBox{
			align_v = "center",
			RightArrow{}
		},
		gui.VBox{
			align_v = "center",
			fsfcg.ItemButton{ item = fields.output, element_name = fields.output:match"%S*" }
		}
	}
end

local function Recipes(fields)
	local data = fields.data
	local recipe = data.recipes[data.rnum]
	if not recipe then return gui.Nil{} end
	local function recipe_cb(_, c)
		local data = assert(c.fsfcg, "fsfcg data must be present in context")
		if data.rnum > #data.recipes then
			data.rnum = 1
		elseif data.rnum == 0 then
			data.rnum = #data.recipes
		end
		return true
	end
	return gui.HBox{
		Recipe{
			width = recipe.width,
			method = recipe.method,
			items = recipe.items,
			output = recipe.output
		},
		gui.Spacer{},
		gui.VBox{
			gui.Label{
				label = data.show_usages
					and S("Usage @1 of @2", data.rnum, #data.recipes)
					or S("Recipe @1 of @2", data.rnum, #data.recipes)
			},
			#data.recipes > 1 and gui.HBox{
				CraftguideImageButton{
					name = "recipe_prev", texture_name = "prev",
					tooltip = S"Previous recipe", on_event = function (...)
						data.rnum = data.rnum + -1
						return recipe_cb(...)
					end
				},
				CraftguideImageButton{
					name = "recipe_next", texture_name = "next",
					tooltip =  S"Next recipe", on_event = function (...)
						data.rnum = data.rnum + 1
						return recipe_cb(...)
					end
				}
			} or gui.Nil{},
			(data.has_recipes and data.has_usages)
			and CraftguideImageButton{
				name = "recipe_toggle", texture_name = "toggle",
				tooltip = data.show_usages
					and S"Show usages"
					or S"Show recipes",
				on_event = function (_, _--[[context]])
					data.show_usages = not data.show_usages
					fsfcg.set_recipes_on_data(data)
					return true
				end
			} or gui.Nil{}
		}
	}
end

function fsfcg.Form(_--[[fields]])
	local context = flow_extras.get_context()
	local name = context.player_name
	local data = fsfcg.player_data[name] or { items = fsfcg.init_items }
	context.fsfcg = data
	local w = 8
	local items = data.items

	local function filter_cb(_, c)
		local new = c.form.filter:lower()
		if data.filter == new then
			return
		end
		data.filter = new
		fsfcg.execute_search(data)
		return true
	end

	local items_rendered
	if #items ~= 0 then
		items_rendered = { w = w * (FLOW_SPACING + FLOW_SIZE), spacing = FLOW_SPACING }
		local ItemButton = fsfcg.ItemButton

		for _, item in ipairs(data.items) do
			items_rendered[#items_rendered+1] = ItemButton{ item = item, element_name = item }
		end
		items_rendered = gui.Flow(items_rendered)
		items_rendered.name = "craftguide_items"
		items_rendered.h = 4
		items_rendered = gui.ScrollableVBox(items_rendered)
	end

	return gui.VBox{
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
		items_rendered or gui.VBox{
			align_v = "center", align_h = "center",
			expand = true,
			gui.Label{ label = S("No items to show.") }
		},
		(data.has_recipes or data.has_usages)
		and Recipes{data = data}
		or gui.Label{ label = S"No usages or recipes." }
	}
end

local orig_update_for_player = fsfcg.update_for_player
function fsfcg.update_for_player(playername)
	local player = orig_update_for_player(playername)
	-- TODO: this is incorrect
	if player and minetest.global_exists"sway" and sway.enabled then
		sway.set_player_inventory_formspec(player)
	end
	return player
end
