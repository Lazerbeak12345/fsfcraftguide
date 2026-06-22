-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2016-2019
-- SPDX-FileContributor: Jean-Patrick Guerrero and contributors
-- SPDX-FileCopyrightText: 2020-2022
-- SPDX-FileContributor: pauloue
-- SPDX-FileCopyrightText: 2022-2023
-- SPDX-FileContributor: dacmot
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local fsfcg, flinv, minetest = fsfcg, flinv, minetest

local S = fsfcg._translator

minetest.register_on_mods_loaded(function ()
	if not fsfcg.enabled then return end
	local inventory_mod = flinv.inventory_mod
	local supported_mod_list = { "sway", "sfinv", "inventory_plus" }
	local supported_mod_set = {}
	local supported_mod_string = ""
	for _, other_inventory_mod in ipairs(supported_mod_list) do
		supported_mod_set[other_inventory_mod] = true
		supported_mod_string = supported_mod_string.."\n\t"..other_inventory_mod
	end
	-- Note that all of the asserts I've made are _after_ we check `fsfcg.enabled`. This is because I'm nice.
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
	form = fsfcg.form,
	show_inventory = false,
	-- TODO: flinv may have a bug, smart_inventory didn't work (at all)
	-- 		 This was while unified_inventory was also present. (to test this modernly, you'd have to disable the assert above)
	show = function ()
		return fsfcg.enabled and flinv.inventory_mod ~= "sway"
	end
})

local orig_update_for_player = fsfcg.update_for_player
function fsfcg.update_for_player(playername)
	local player = orig_update_for_player(playername)
	if flinv.inventory_mod == "sway" and minetest.global_exists"sway" then
		_G.sway.set_player_inventory_formspec(player)
	elseif flinv.inventory_mod == "sfinv" and minetest.global_exists"sfinv" then
		_G.sfinv.set_player_inventory_formspec(player)
	elseif flinv.inventory_mod == "inventory_plus" and minetest.global_exists"inventory_plus" then
		local inventory_plus = _G.inventory_plus
		-- NOTE: The pagename is not persisted, so there's no way to tell what it was. This means that every update resets their page.
		inventory_plus.set_inventory_formspec(
			player,
			inventory_plus.get_formspec(player, inventory_plus.default))
	end
	return player
end

