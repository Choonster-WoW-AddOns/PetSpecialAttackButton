local locale = GetLocale()
if locale ~= "$(LOCALE)" then return end

local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

ns.PET_ABILITIES = $(ABILITIES)