#!/usr/bin/env lua

--[==[
This script requires an installation of Lua with the following libraries:
	* LuaSocket (https://github.com/diegonehab/luasocket)
	* Penlight (with or without LuaFileSystem) (https://github.com/stevedonovan/Penlight)
	* LuaJSON (https://github.com/harningt/luajson)
	
These can all be installed with LuaRocks (http://www.luarocks.org/) if you don't want to install them manually.

Before running this script, you should set the configuration variables below to the appropriate values.

To run this script on Windows, open a command prompt and enter the following command (you can also create a batch file from it):

	lua "C:\Users\Public\Games\World of Warcraft\Interface\AddOns\PetSpecialAttackButton\generate_abilities.lua"

This assumes that Lua is in your PATH. If it isn't, you can either edit your PATH environment variable
to include the directory with Lua's executable in it or replace `lua` with the full path to the executable.
It also assumes that WoW is installed in C:\Users\Public\Games, which it may not be.

On Unix, you can make this script executable with `chmod +x` and then double click to run it.
You can also manually enter the command in your terminal like on Windows.

You may need to configure your terminal to use UTF-8 output if the pet/ability names aren't printed correctly.
Even if they're not printed correctly, the abilities file should still be generated properly.
]==]

---------------------
-- START OF CONFIG --
---------------------

-- Set this to your locale code. See Wowpedia for a list of locale codes:
-- http://www.wowpedia.org/API_GetLocale
local LOCALE = "enUS"

-- Set this to whatever the subtext for special abilities is in your locale
local SPECIAL_ABILITY = "Special Ability"

-- Se this to whatever the subtext for exotic abilities is in your locale
local EXOTIC_ABILITY = "Exotic Ability"

-- If true, use exotic abilities instead of special abilities where possible. If false, only use special abilities.
local USE_EXOTIC = true

-- Set this to the address of your locale's Battle.net site.
-- For every region except China, this is "http://<region>.battle.net/". For China, this is "http://www.battlenet.com.cn/"
local BNET = "http://us.battle.net/"

-- Set this to the address of your locale's Wowhead site
local WOWHEAD = "http://www.wowhead.com/"

-- Set this to the location of your WoW folder (using forward slashes as directory separators)
local WOW_DIR = "C:/Users/Public/Games/World of Warcraft/"

-- A list of pet families and the ability to use for each one. This overrides the automatically-generated ability for the families.
-- Format is ["Family Name"] = "Ability Name", (note the comma after the closing quotation mark)
local OVERRIDES = {
	["Cat"] = "Prowl",
	["Shale Spider"] = "Web Wrap",
	["Silithid"] = "Venom Web Spray",
	["Water Strider"] = "Surface Trot",
}

---------------------
--  END OF CONFIG  --
---------------------
-- Do not change anything below here!

local http = require("socket.http")
local pretty = require("pl.pretty")
local json = require("json")

if package.config:sub(1, 1) == "\\" then -- If we're on Windows, set the code page to UTF-8
	os.execute("chcp 65001")
end

local function request(url)
	local result, code, headers, status = assert(http.request(url))
	if code ~= 200 then
		error(("ERROR: Request to %q failed with status %q"):format(url, status), 2)
	end
	
	return result
end

local function fopen(file, mode)
	return assert(io.open(file, mode))
end

local function printf(f, ...)
	print(f:format(...))
end

printf(
	"Generating abilities file.\nConfig:\n\tLocale code = %q\n\tSpecial ability text = %q\n\tBattle.net address = %q\n\tWowhead address = %q\n\tWoW directory = %q\n",
	LOCALE, SPECIAL_ABILITY, BNET, WOWHEAD, WOW_DIR
)

local ADDON_DIR = WOW_DIR .. "Interface/AddOns/PetSpecialAttackButton"
local SPELL_URL = BNET .. "api/wow/spell/%d?locale=" .. LOCALE
local WOWHEAD_PATTERN = "new Listview%({template: 'pet', id: 'hunter%-pets', computeDataFunc: _, visibleCols: %['abilities'%], data: (%[.+%])}%);"
local TEMPLATE = fopen(ADDON_DIR .. "/abilities_template.lua"):read("*a")

local wowheadHTML = request(WOWHEAD .. "pets")
print("Retrieved Wowhead pets page")

local petsJSON = assert(wowheadHTML:match(WOWHEAD_PATTERN), "ERROR: Failed to extract pet data from Wowhead page") -- Extract the pet data JSON from the page
local pets = json.decode(petsJSON)
local numPets = #pets
printf("Extracted pet data for %d pets", numPets)

local abilities = {}
local blacklist = {} -- Keep a record of spells that aren't special abilities so we don't send a request for every occurrence of a shared basic ability.
local numErrors = 0

for i, petData in ipairs(pets) do
	local family = petData.name
	local isExotic = false
	local isOveride = false
	printf("\nProcessing family: %q (%d of %d)", family, i, numPets)
	
	local override = OVERRIDES[family]
	if override then -- Use a hardcoded ability name if we have one for this family
		abilities[family] = override
		isOveride = true
	else
		for i, spellID in ipairs(petData.spells) do
			if not blacklist[spellID] then
				local spellJSON = request(SPELL_URL:format(spellID))
				local spellData = json.decode(spellJSON)
				local subtext = spellData.subtext
				
				if USE_EXOTIC and subtext == EXOTIC_ABILITY then -- If we're using exotic abilities and this ability is exotic, use it and break now.
					abilities[family] = spellData.name
					isExotic = true
					break
				elseif spellData.subtext == SPECIAL_ABILITY then -- This ability is special, use it for now. If we're not using exotic abilities, break now.
					abilities[family] = spellData.name
					if not USE_EXOTIC then break end
				else -- This isn't an ability we want, blacklist it.
					blacklist[spellID] = true
				end
			end
		end
	end
	
	local spellName = abilities[family]
	if spellName then
		printf("Family %q has %s ability %q%s", family, isExotic and "exotic" or "special", spellName, isOveride and " (override)" or "")
	else
		printf("ERROR: Couldn't find special ability for family %q", family)
		numErrors = numErrors + 1
		abilities[family] = "<ERROR>"
	end
end

print() -- Print a newline

local abilitiesStr = pretty.write(abilities, "\t", true)

local abilitiesFileName = "abilities_" .. LOCALE .. ".lua"
local abilitiesFile = fopen(ADDON_DIR .. "/" .. abilitiesFileName, "w")

local finalString = TEMPLATE:gsub("$%((%a+)%)", function(var)
	if var == "ABILITIES" then
		return abilitiesStr
	elseif var == "LOCALE" then
		return LOCALE
	else
		abilitiesFile:close()
		error(("ERROR: Unknown variable name %q"):format(var))
	end
end)

abilitiesFile:write(finalString)
abilitiesFile:close()

local tocFileName = ADDON_DIR .. "/PetSpecialAttackButton.toc"

local tocFile = fopen(tocFileName, "r+") -- Open the file in update mode so the existing text is preserved.

if not tocFile:read("*a"):find(abilitiesFileName, 1, true) then -- The new abilities file isn't in the TOC yet, add it now
	tocFile:seek("end", -8) -- Move to the beginning of "core.lua" (8 characters from the end of the file)
	tocFile:write(abilitiesFileName, "\ncore.lua") -- Write the abilities file name to the TOC. This overwrites "core.lua", so we rewrite it as well.
end

tocFile:close()

if numErrors == 0 then
	printf("Successfully generated abilities_%s.lua", LOCALE)
else
	printf("Encountered %d errors while generating abilities_%s.lua", numErrors, LOCALE)
end