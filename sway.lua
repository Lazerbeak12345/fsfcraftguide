-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local fsfcg, minetest, sway, flow = fsfcg, minetest, sway, flow
local S = fsfcg.get_translator
local gui = flow.widgets

local Form = fsfcg.Form

-- BUG: this code has a race condition. If two mods replace a widget, there needs to be a way to ensure they both play
-- nice.
local OldSwayForm = sway.Form
function sway.Form(fields)
	fields.expand = true
	return gui.HBox{
		spacing = 0.25,
		OldSwayForm(fields),
		gui.VBox{
			bgimg = "sway_bg_full.png",
			bgimg_middle = 12,
			padding = 0.4,
			Form{}
		}
	}
end
sway.register_page("fsfcraftguide:craftguide", {
	title = S"Recipes",
	get = function(_--[[self]], _--[[player]], _--[[context]])
		return sway.Form{ Form{} }
	end
})
