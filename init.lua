-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2016-2019
-- SPDX-FileContributor: Jean-Patrick Guerrero and contributors
-- SPDX-FileCopyrightText: 2020-2022
-- SPDX-FileContributor: pauloue
-- SPDX-FileCopyrightText: 2022-2023
-- SPDX-FileContributor: dacmot
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local minetest = _G.minetest
local S = minetest.get_translator(minetest.get_current_modname())
local modpath = minetest.get_modpath(minetest.get_current_modname())

_G.fsfcg = {
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

if minetest.get_modpath"sway" and minetest.global_exists"sway" then
	local sway = _G.sway
	if sway.enabled then
		dofile(modpath.."/sway.lua")
	end
elseif minetest.get_modpath"flinv" and minetest.global_exists"flinv" then
	dofile(modpath.."/flinv.lua")
end

minetest.register_on_mods_loaded(function()
	if minetest.get_modpath"sfinv" and minetest.global_exists"sfinv" then
		local sfinv = _G.sfinv
		if sfinv.enabled then
			for mod, page in pairs{
				sfcraftguide = "sfcraftguide:craftguide",
				mtg_craftguide = "mtg_craftguide:craftguide"
			} do
				if minetest.get_modpath(mod) then
					sfinv.override_page(page, {
						is_in_nav = function()
							return false
						end
					})
				end
			end
		end
	end
end)
