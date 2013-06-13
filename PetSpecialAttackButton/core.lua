local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

local addon, ns = ...
local PET_ABILITIES = ns.PET_ABILITIES

local button = CreateFrame("Button", "PetSpecialAttackButton", UIParent, "SecureActionButtonTemplate")
button:SetAttribute("type", "macro")

local function UpdatePets()
	if InCombatLockdown() then return end
	
	local macrotext = ""
	for petSlot = 1, NUM_PET_ACTIVE_SLOTS do
		local icon, name, level, family, talent = GetStablePetInfo(petSlot)
		local ability = PET_ABILITIES[family]
		if ability then
			macrotext = macrotext .. ("/use %s\n"):format(ability)
		end
	end
	button:SetAttribute("macrotext", macrotext)
	
	return macrotext ~= ""
end

button:RegisterEvent("PLAYER_ENTERING_WORLD")
button:RegisterEvent("PET_STABLE_CLOSED")
button:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

local THROTTLE = 0.5
local timer = THROTTLE

local function OnUpdate(self, elapsed)
	timer = timer - elapsed

	if timer < 0 then
		timer = THROTTLE
		if UpdatePets() then
			self:SetScript("OnUpdate", nil)
		end
	end
end

function button:PLAYER_ENTERING_WORLD()	
	-- We only care about this event the first time it fires, so we unregister the event and nil out this method
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self.PLAYER_ENTERING_WORLD = nil
	
	if not UpdatePets() then -- If we don't have pet data, start the OnUpdate script to try again every 0.5 seconds
		self:SetScript("OnUpdate", OnUpdate)
	end
end

function button:PET_STABLE_CLOSED()
	UpdatePets()
end