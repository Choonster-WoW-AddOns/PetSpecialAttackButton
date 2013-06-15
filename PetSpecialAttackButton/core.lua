---------------------
-- START OF CONFIG --
---------------------

-- Set this to the name of the macro you're using /click PetSpecialAttackButton in.
-- The macro's icon and tooltip will be automatically updated to your current pet's spell.
-- Leave it blank if you don't want this behaviour
local MACRO_NAME = "PET"

---------------------
--  END OF CONFIG  --
---------------------

local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

local addon, ns = ...
local PET_ABILITIES = ns.PET_ABILITIES

local button = CreateFrame("Button", "PetSpecialAttackButton", UIParent, "SecureActionButtonTemplate")
button:SetAttribute("type", "macro")

local function UpdateMacro()
	if MACRO_NAME == "" then return end
	
	local family = UnitCreatureFamily("pet")
	local ability = PET_ABILITIES[family]
	SetMacroSpell(MACRO_NAME, ability or "")
end

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
	
	UpdateMacro()
	
	return macrotext ~= ""
end

button:RegisterEvent("PLAYER_ENTERING_WORLD")
button:RegisterEvent("PET_STABLE_CLOSED")
button:RegisterUnitEvent("UNIT_PET", "player")
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

function button:UNIT_PET(unit) -- unit will always be "player"
	UpdateMacro()
end

SlashCmdList.PSAB_UPDATE = UpdateMacro
SLASH_PSAB_UPDATE1, SLASH_PSAB_UPDATE2 = "/psab_update", "/psabu"