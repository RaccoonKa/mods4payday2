local text_original = LocalizationManager.text
local testAllStrings = false

function LocalizationManager:text(string_id, ...)
return string_id == "menu_difficulty_sm_wish" and "ADSKAYA DROCHILNYA"

or string_id == "menu_risk_sm_wish" and "ADSKAYA DROCHILNYA"

or string_id == "bm_sm_wish" and "ADSKAYA DROCHILNYA"

or testAllStrings == true and string_id
or text_original(self, string_id, ...)
end