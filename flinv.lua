-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2016-2019
-- SPDX-FileContributor: Jean-Patrick Guerrero and contributors
-- SPDX-FileCopyrightText: 2020-2022
-- SPDX-FileContributor: pauloue
-- SPDX-FileCopyrightText: 2022-2023
-- SPDX-FileContributor: dacmot
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local fsfcg, flinv, flow, core, sway, sfinv = fsfcg, flinv, flow, core, sway, sfinv

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
	show_inventory = false,
	-- TODO: flinv may have a bug, smart_inventory didn't work (at all)
	-- 		 This was while unified_inventory was also present.
	show = function (player)
		-- Opt-in to inventory systems that don't already come with a craftguide
		-- This still isn't ideal, thanks to the above bug.
		return (core.get_modpath"sway" and sway.enabled)
			or (core.get_modpath"sfinv" and sfinv.enabled)
			-- TODO: send them code for an enablement flag?
			-- TODO: this inventory needs a back button
			or (core.get_modpath"inventory_plus" --[[has no enablement flag]])
	end
})
