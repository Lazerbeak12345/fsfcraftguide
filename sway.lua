-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023-2026
-- SPDX-FileContributor: Lazerbeak12345

local fsfcg, sway, flow = fsfcg, sway, flow
local gui = flow.widgets

local OldSwayForm = sway.Form
function sway.Form(fields)
	if not fsfcg.enabled then
		return OldSwayForm(fields)
	end
	fields.expand = true
	return gui.HBox{
		spacing = 0.25,
		name = "fsfcg_sway_form_wrapper",
		OldSwayForm(fields),
		gui.VBox{
			bgimg = "sway_bg_full.png",
			bgimg_middle = 12,
			padding = 0.4,
			fsfcg.form:embed{ name = "fsfcg" }
		}
	}
end
