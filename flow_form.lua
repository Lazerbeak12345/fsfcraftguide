-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local fsfcg, minetest, flow, flow_extras = fsfcg, minetest, flow, flow_extras
local S = fsfcg._translator
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

local function Recipes(_--[[fields]])
	local function recipe_cb(_--[[player]], context)
		if not context.recipes then return true end
		if context.rnum > #context.recipes then
			context.rnum = 1
		elseif context.rnum == 0 then
			context.rnum = #context.recipes
		end
		return true
	end
	local context = flow_extras.get_context()
	local recipe = context.recipes[context.rnum]
	return gui.HBox{
		Recipe{
			width = recipe.width,
			method = recipe.method,
			items = recipe.items,
			output = recipe.output
		},
		gui.Spacer{},
		gui.VBox{
			-- TODO: add better current item identification
			gui.Label{ label = context.prev_item },
			gui.Label{
				label = context.show_usages
					and S("Usage @1 of @2", context.rnum, #context.recipes)
					or S("Recipe @1 of @2", context.rnum, #context.recipes)
			},
			#context.recipes > 1 and gui.HBox{
				CraftguideImageButton{
					name = "recipe_prev", texture_name = "prev",
					tooltip = S("Previous recipe"), on_event = function (player, context)
						context.rnum = context.rnum + -1
						return recipe_cb(player, context)
					end
				},
				CraftguideImageButton{
					name = "recipe_next", texture_name = "next",
					tooltip =  S("Next recipe"), on_event = function (player, context)
						context.rnum = context.rnum + 1
						return recipe_cb(player, context)
					end
				}
			} or gui.Nil{},
			context.has_usages and context.has_recipes
			and gui.Button{
				label = context.show_usages
					and S"Show recipes"
					or S"Show usages",
				on_event = function (player, context)
					context.rnum = 1
					context.show_usages = not context.show_usages
					return recipe_cb(player, context)
				end
			}
			or gui.Label{
				label = context.has_recipes
					and S"No usages."
					or S"No recipes."
			},
		}
	}
end

function fsfcg.Form(_--[[fields]])
	local context = flow_extras.get_context()
	if not context.items then
		context.items = fsfcg.init_items
	end
	local w = 8
	local items = context.items

	local function filter_cb(_, context)
		local new = context.form.filter:lower()
		if context.filter == new then
			return
		end
		context.filter = new
		return true
	end

	local items_rendered
	if #items ~= 0 then
		items_rendered = { w = w * (FLOW_SPACING + FLOW_SIZE), spacing = FLOW_SPACING }
		local ItemButton = fsfcg.ItemButton

		for _, item in ipairs(context.items) do
			items_rendered[#items_rendered+1] = ItemButton{ item = item, element_name = item }
		end
		items_rendered = gui.Flow(items_rendered)
		items_rendered.name = "craftguide_items"
		items_rendered.h = context.prev_item and 4 or 7
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
				default = context.filter,
				on_event = filter_cb
			},
			CraftguideImageButton{ name = "search", tooltip = S("Search"), on_event = filter_cb },
			CraftguideImageButton{
				name = "clear", tooltip = S("Reset"),
				on_event = function(_, context)
					context.filter = ""
					context.form.filter = context.filter
					context.prev_item = nil
					context.recipes = nil
					context.items = fsfcg.init_items
					return true
				end
			},
		},
		items_rendered or gui.VBox{
			align_v = "center", align_h = "center",
			expand = true,
			gui.Label{ label = S("No items to show.") }
		},
		context.prev_item and Recipes{} or gui.Nil{},
	}
end

fsfcg.form = flow.make_gui(function (player, context)
	if context.filter == nil then
		context.filter = ""
	end
	if context.pagenum == nil then
		context.pagenum = 1
	end
	if context.items == nil then
		context.items = fsfcg.init_items
	end
	if context.lang_code == nil then
		local player_name = player:get_player_name()
		local info = minetest.get_player_information(player_name)
		context.lang_code = info.lang_code
	end
	if context.show_usages == nil then
		context.show_usages = false
	end
	local item = context.prev_item
	if item then
		local recipes = fsfcg.recipes_cache[item]
		local usages = fsfcg.usages_cache[item]
		context.has_recipes = recipes ~= nil
		context.has_usages = usages ~= nil
		context.show_usages = context.show_usages and context.has_usages
		if (not context.has_recipes) and (not context.show_usages) then
			context.show_usages = true
		end
		if context.show_usages then
			context.recipes = usages
		else
			context.recipes = recipes
		end
	end
	fsfcg.execute_search()
	return fsfcg.Form{}
end)
