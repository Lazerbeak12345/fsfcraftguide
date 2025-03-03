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

if (minetest.get_modpath("doc") and minetest.get_modpath("doc_items")) then
	dofile(modpath.."/reveal.lua")
end

if (minetest.get_modpath("sway") and minetest.global_exists("sway")) and sway.enabled then
	dofile(modpath.."/sway.lua")
elseif (minetest.get_modpath("sfinv") and minetest.global_exists("sfinv")) and sfinv.enabled then
	dofile(modpath.."/sfinv.lua")
end

