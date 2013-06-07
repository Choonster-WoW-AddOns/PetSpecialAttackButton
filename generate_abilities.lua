#!/usr/bin/env lua

--[==[
This script requires an installation of Lua with the following libraries:
	* LuaSocket (https://github.com/diegonehab/luasocket)
	* Penlight (with or without LuaFileSystem) (https://github.com/stevedonovan/Penlight)
	* LuaJSON (https://github.com/harningt/luajson)
	
These can all be installed with LuaRocks (http://www.luarocks.org/) if you don't want to install them manually.
]==]

-- Set this to your locale code. See Wowpedia for a list of locale codes:
-- http://www.wowpedia.org/API_GetLocale
local LOCALE = "enUS"

-- Set this to whatever the subtext for special abilities is in your locale
local SPECIAL_ABILITY = "Special Ability"

-- Set this to the address of your locale's Battle.net site. For every region except China, this is "http://<region>.battle.net/". For China, this is "http://www.battlenet.com.cn/"
local BNET = "http://us.battle.net/"

-- Set this to the address of your locale's Wowhead site
local WOWHEAD = "http://www.wowhead.com/"

-- Set this to the location of your WoW folder (using forward slashes as directory separators)
local WOW_DIR = "C:/Users/Public/Games/World of Warcraft/"

-------------------
-- END OF CONFIG --
-------------------

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
local TEMPLATE = assert(io.open(ADDON_DIR .. "/abilities_template.lua")):read("*a")

local wowheadHTML, whCode, whHeaders, whStatus = request(WOWHEAD .. "pets")

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
	printf("\nProcessing family: %q (%d of %d)", family, i, numPets)
	
	for i, spellID in ipairs(petData.spells) do
		if not blacklist[spellID] then
			local spellJSON = request(SPELL_URL:format(spellID))
			local spellData = json.decode(spellJSON)
			if spellData.subtext == SPECIAL_ABILITY then
				local spellName = spellData.name
				abilities[family] = spellName
				printf("Family %q has special ability %q", family, spellName)
				break
			else
				blacklist[spellID] = true
			end
		end
	end
	
	if not abilities[family] then
		printf("ERROR: Couldn't find special ability for family %q", family)
		numErrors = numErrors + 1
		abilities[family] = "<ERROR>"
	end
end

print() -- Print a newline

local abilitiesStr = pretty.write(abilities, "\t", true)

local file = assert(io.open(ADDON_DIR .. "/abilities_" .. LOCALE .. ".lua", "w"))

local str = TEMPLATE:gsub("$%((%a+)%)", function(var)
	if var == "ABILITIES" then
		return abilitiesStr
	elseif var == "LOCALE" then
		return LOCALE
	else
		file:close()
		error(("ERROR: Unknown variable name %q"):format(var))
	end
end)

file:write(str)
file:close()

if numErrors == 0 then
	printf("Successfully generated abilities_%s.lua", LOCALE)
else
	printf("Encountered %d errors while generating abilities_%s.lua", numErrors, LOCALE)
end