-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2016-2019
-- SPDX-FileContributor: Jean-Patrick Guerrero and contributors
-- SPDX-FileCopyrightText: 2020-2022
-- SPDX-FileContributor: pauloue
-- SPDX-FileCopyrightText: 2022-2023
-- SPDX-FileContributor: dacmot
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local fsfcg, flinv, flow, minetest = fsfcg, flinv, flow, minetest

local S = fsfcg.get_translator
local Form = fsfcg.Form

minetest.register_on_mods_loaded(function ()
	if not flinv.enabled then return end
	local inventory_mod = flinv.inventory_mod
	local supported_mod_list = { "sway", "sfinv", "inventory_plus" }
	local supported_mod_set = {}
	local supported_mod_string = ""
	for _, inventory_mod in ipairs(supported_mod_list) do
		supported_mod_set[inventory_mod] = true
		supported_mod_string = supported_mod_string.."\n\t"..inventory_mod
	end
	-- Note that all of the asserts I've made are _after_ we check `flinv.enabled`. This is because I'm nice.
	if not inventory_mod then
		assert(false, "\n\n[fsfcraftguide]: requires an inventory mod. Try one of these: "..supported_mod_string.."\n")
	end
	if not supported_mod_set[inventory_mod] then
		assert(false, "\n\n[fsfcraftguide]: only supports these inventories: "..supported_mod_string.."\nbut the inventory '"..inventory_mod.."' was found\n")
	end
end)

flinv.register_tab("fsfcraftguide:craftguide", {
	title = S"Recipes",
	-- TODO: icon
	icon = "craftguide_inventory_icon.png",
	form = flow.make_gui(function (player, context)
		context.player_name = player:get_player_name()
		return Form{}
	end),
	show_inventory = false,
	-- TODO: flinv may have a bug, smart_inventory didn't work (at all)
	-- 		 This was while unified_inventory was also present. (to test this modernly, you'd have to disable the assert above)
	show = function ()
		return fsfcg.enabled
	end
})
