-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2016-2019
-- SPDX-FileContributor: Jean-Patrick Guerrero and contributors
-- SPDX-FileCopyrightText: 2020-2022
-- SPDX-FileContributor: pauloue
-- SPDX-FileCopyrightText: 2022-2023
-- SPDX-FileContributor: dacmot
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local S = minetest.get_translator(minetest.get_current_modname())
local modpath = minetest.get_modpath(minetest.get_current_modname())

fsfcg = {
	modpath = modpath,
	get_translator = S,
	player_data = {},
	init_items = {},
	recipes_cache = {},
	usages_cache = {},
}

function fsfcg.get_usages(data, item)
	return fsfcg.usages_cache[item]
end

function fsfcg.get_recipes(data, item)
	return fsfcg.recipes_cache[item]
end

-- Loading components

dofile(modpath.."/craftguide.lua")
dofile(modpath.."/flow_form.lua")

if minetest.get_modpath"doc" and minetest.get_modpath"doc_items" then
	dofile(modpath.."/reveal.lua")
end

if minetest.get_modpath"sway" and minetest.global_exists"sway" and sway.enabled then
	dofile(modpath.."/sway.lua")
elseif minetest.get_modpath"flinv" and minetest.global_exists"flinv" then
	dofile(modpath.."/flinv.lua")
end

if minetest.get_modpath"mtg_craftguide" and minetest.get_modpath"sfinv" and minetest.global_exists"sfinv" then
	-- Disable mtg_craftguide
	sfinv.override_page("mtg_craftguide:craftguide", {
		is_in_nav = function () return false end
	})
end
