-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local fsfcg, sway, flow = fsfcg, sway, flow
local gui = flow.widgets

-- BUG: this code has a race condition. If two mods replace a widget, there needs to be a way to ensure they both play
-- nice.
local OldSwayForm = sway.Form
function sway.Form(fields)
	if not fsfcg.enabled then
		sway.Form = OldSwayForm
		return OldSwayForm(fields)
	end
	fields.expand = true
	return gui.HBox{
		spacing = 0.25,
		OldSwayForm(fields),
		gui.VBox{
			bgimg = "sway_bg_full.png",
			bgimg_middle = 12,
			padding = 0.4,
			fsfcg.form:embed{ name = "fsfcg" }
		}
	}
end
