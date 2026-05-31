-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2016-2019
-- SPDX-FileContributor: Jean-Patrick Guerrero and contributors
-- SPDX-FileCopyrightText: 2020-2022
-- SPDX-FileContributor: pauloue
-- SPDX-FileCopyrightText: 2022-2023
-- SPDX-FileContributor: dacmot
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local fsfcg, flinv, flow = fsfcg, flinv, flow

local S = fsfcg.get_translator
local Form = fsfcg.Form

assert(type(Form) == "function", "The form must be defined!"..type(Form))

flinv.register_tab("fsfcraftguide:craftguide", {
	title = S"Recipes",
	-- TODO: icon
	icon = "craftguide_inventory_icon.png",
	form = flow.make_gui(function (player, context)
		context.player_name = player:get_player_name()
		return Form{}
	end),
	show_inventory = false
	-- TODO: disable on
	--       - i3 (has builtin craftguide)
	--       - unified_inventory (has builtin craftguide)
	-- TODO: flinv may have a bug, smart_inventory didn't work (at all)
	-- 		 This was while unified_inventory was also present.
})
