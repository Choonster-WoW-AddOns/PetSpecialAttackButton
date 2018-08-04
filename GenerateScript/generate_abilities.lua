#!/usr/bin/env lua

--[==[
This script requires an installation of Lua with the following libraries:
	* LuaSocket (https://github.com/diegonehab/luasocket) [install the SCM version if using LuaRocks]
	* LuaSec (https://github.com/brunoos/luasec)
	* Penlight (https://github.com/stevedonovan/Penlight)
	* LuaJSON (https://github.com/harningt/luajson)
	
These can all be installed with LuaRocks (http://www.luarocks.org/) if you don't want to install them manually.

Before running this script, you should set the configuration variables below to the appropriate values.

To run this script on Windows, open a command prompt and enter the following command (you can also create a batch file from it):

	lua "C:\Users\Public\Games\World of Warcraft\Interface\AddOns\PetSpecialAttackButton\GenerateScript\generate_abilities.lua"

This assumes that Lua is in your PATH. If it isn't, you can either edit your PATH environment variable
to include the directory with Lua's executable in it or replace `lua` with the full path to the executable.
It also assumes that WoW is installed in C:\Users\Public\Games, which it may not be.

On Unix, you can make this script executable with `chmod +x` and then double click to run it.
You can also manually enter the command in your terminal like on Windows.

You may need to configure your terminal to use UTF-8 output if the pet/ability names aren't printed correctly.
Even if they're not printed correctly, the abilities file should still be generated properly.
]==]

local SPELLID_NO_ABILITY = -1
local SPELLID_ERROR = -2

-- Do not change anything above here!
---------------------
-- START OF CONFIG --
---------------------

-- If true, use exotic abilities instead of special abilities where possible. If false, only use special abilities.
local USE_EXOTIC = true

-- Set this to the location of your WoW folder (using forward slashes as directory separators)
local WOW_DIR = "C:/Users/Public/Games/World of Warcraft/"

-- A list of pet families and the ability to use for each one. This overrides the automatically-generated ability for the families.
-- Format is [familyID] = spellID, -- Family Name - Ability Name
-- Use the SPELLID_NO_ABILITY as the spellID if the family has no special ability
local OVERRIDES = {
	[130] = 159733, -- Basilisk - Stone Scales
	[2]   = 24450,  -- Cat - Prowl
	[34]  = 160452, -- Nether Ray - Netherwinds
	[149] = 160007, -- Rylak - Updraft
	[41]  = 160065, -- Silithid - Tendon Rip
}

---------------------
--  END OF CONFIG  --
---------------------
-- Do not change anything below here!

local http = require("socket.http")
local https = require("ssl.https")
local json = require("json")

require("pl.app").require_here() -- Search for modules in the script's directory
local PrettyPrint = require("PrettyPrint")
require("strict")

-- The Battle.net API key for this script
local API_KEY = "s37g43rgb9bchha8epjqbxn8wc9vj98r"

local BNET_URLS = {
	US = "https://us.api.battle.net/",
	EU = "https://eu.api.battle.net/",
	TW = "https://tw.api.battle.net/",
	CN = "https://api.battlenet.com.cn/",
}

local LOCALES = {
	-- US
	enUS = { wowhead = "http://www.wowhead.com/", bnet = BNET_URLS.US }, -- English (US) - Also used for English (UK)
	esMX = { wowhead = "http://es.wowhead.com/", bnet = BNET_URLS.US }, -- Spanish (Mexico)
	ptBR = { wowhead = "http://pt.wowhead.com/", bnet = BNET_URLS.US }, -- Brazilian Portuguese
	
	-- Europe
	-- English (UK) returns enUS in-game
	-- Neither WoW or its API are available in Polish
	-- WoW isn't available in European Portuguese
	deDE = { wowhead = "http://de.wowhead.com/", bnet = BNET_URLS.EU }, -- German
	esES = { wowhead = "http://es.wowhead.com/", bnet = BNET_URLS.EU }, -- Spanish (Spain)
	frFR = { wowhead = "http://fr.wowhead.com/", bnet = BNET_URLS.EU }, -- French
	itIT = { wowhead = "http://it.wowhead.com/", bnet = BNET_URLS.EU }, -- Italian
	ruRU = { wowhead = "http://ru.wowhead.com/", bnet = BNET_URLS.EU }, -- Russian
	
	-- Korea
	-- Wowhead isn't available in Korean
	
	-- Taiwan
	zhTW = { wowhead = "http://cn.wowhead.com/", bnet = BNET_URLS.TW }, -- Traditional Chinese - Pet family names may not be accurate, Wowhead is only available in Simplified Chinese
	
	-- China
	zhCN = { wowhead = "http://cn.wowhead.com/", bnet = BNET_URLS.CN }, -- Simplified Chinese
}

local petFamilies = {} -- [locale] = { count = N, data = { [familiyID] = familyData } }
local abilitySpellData = {} -- [locale] = { [spellID] = spellData }

for locale, localeData in pairs(LOCALES) do
	localeData.apiLocale = locale:sub(1, 2) .. "_" .. locale:sub(3, 4) -- GetLocale() returns enUS but the API uses en_US
	localeData.petsURL = localeData.wowhead .. "pets"
	localeData.spellURL = localeData.bnet .. "wow/spell/%d?locale=" .. localeData.apiLocale .. "&apikey=" .. API_KEY
	
	abilitySpellData[locale] = {
		[SPELLID_NO_ABILITY] = { id = SPELLID_NO_ABILITY, name = "No Special Ability" },
		[SPELLID_ERROR] = { id = SPELLID_ERROR, name = "<ERROR>" },
	}
end

local DEFAULT_LOCALE = "enUS"

-- The subtext for special abilities
local SPECIAL_ABILITY = "Special Ability"

-- The subtext for exotic abilities
local EXOTIC_ABILITY = "Exotic Ability"

if package.config:sub(1, 1) == "\\" then -- If we're on Windows, set the code page to UTF-8
	print("Windows detected, setting codepage to UTF-8")
	os.execute("chcp 65001")
	print()
end

local function fopen(file, mode)
	return assert(io.open(file, mode))
end

local function printf(f, ...)
	print(f:format(...))
end

local ADDON_DIR = WOW_DIR .. "Interface/AddOns/PetSpecialAttackButton"
local WOWHEAD_PATTERN = "new Listview%({template: 'pet', id: 'pets'.-data: (%[.+%])}%);"
local TEMPLATE = fopen(ADDON_DIR .. "/abilities_template.lua"):read("*a")
local ERROR_PATH = ADDON_DIR .. "/generate_errors.txt"

local hasErrors = false

local familyAbilities = {} -- [familiyID] = spellID

local function request(url, requestType, locale, id)
	local result, code, headers, status = (url:find("https://", 1, true) and https or http).request(url)
	if code ~= 200 then
		if type(code) == "string" then
			printf("ERROR: Request to %q failed: %q", url, code)
		else
			printf("ERROR: Request to %q failed with status %d: %q", url, code, status)
		end
		
		hasErrors = true
		
		local f = fopen(ERROR_PATH, "a")
		f:write(os.date("%Y-%m-%d %H:%M:%S %z"), "\t")
		f:write(requestType, "\t", locale, "\t")
		
		if id then
			f:write(id, "\t")
		end
		
		f:write(url, "\t", code)
		
		if status then
			f:write("\t", status)
		end
		
		f:write("\n")
		f:close()
	end
	
	return result
end

local function getPetData(locale)
	local pets = petFamilies[locale]
	
	if not pets then
		local html = request(LOCALES[locale].petsURL, "pets", locale)
		
		if not html then
			return nil
		end
		
		local petsJSON = assert(html:match(WOWHEAD_PATTERN), "ERROR: Failed to extract pet data from Wowhead page for locale " .. locale) -- Extract the pet data JSON from the page
		local petsArray = json.decode(petsJSON)
		
		pets = {count = #petsArray, data = {}}
		for _, petData in ipairs(petsArray) do
			pets.data[petData.id] = petData
		end
		
		petFamilies[locale] = pets
	end
	
	return pets
end

local function getSpellData(locale, spellID)
	local spellData = abilitySpellData[locale][spellID]
	
	if not spellData then
		local spellJSON = request(LOCALES[locale].spellURL:format(spellID), "spells", locale, spellID)
		
		if not spellJSON then
			return nil
		end
		
		spellData = json.decode(spellJSON)
		abilitySpellData[locale][spellID] = spellData
	end
	
	return spellData
end

local numErrors = 0

local defaultLocaleData = LOCALES[DEFAULT_LOCALE]
printf("Config:\n\tDefault locale code = %q\n\tSpecial ability text = %q\n\tExotic Ability Text: %q\n\tBattle.net address = %q\n\tWowhead address = %q\n\tWoW directory = %q\n",
		DEFAULT_LOCALE, SPECIAL_ABILITY, EXOTIC_ABILITY, defaultLocaleData.bnet, defaultLocaleData.wowhead, WOW_DIR
)

print("Finding abilities for pet families...")

local count = 0
local pets = assert(getPetData(DEFAULT_LOCALE), "Failed to retrieve pet data for default locale")
for familyID, petData in pairs(pets.data) do
	count = count + 1
	
	local familyName = petData.name
	printf("\nProcessing family: %q (%d of %d)", familyName, count, pets.count)
	
	local isExotic = false
	local isOveride = false
	
	local overrideID = OVERRIDES[familyID]
	if overrideID then -- Use a hardcoded ability if we have one for this family
		familyAbilities[familyID] = overrideID
		isOveride = true
	else
		for i, spellID in ipairs(petData.spells) do
			local spellData = getSpellData(DEFAULT_LOCALE, spellID)
			if spellData then
				local subtext = spellData.subtext
				
				if USE_EXOTIC and subtext == EXOTIC_ABILITY then -- If we're using exotic abilities and this ability is exotic, use it and break now.
					familyAbilities[familyID] = spellID
					isExotic = true
					break
				elseif subtext == SPECIAL_ABILITY then -- This ability is special, use it for now. If we're not using exotic abilities, break now.
					familyAbilities[familyID] = spellID
					if not USE_EXOTIC then break end
				end
			end
		end
	end
	
	local spellID = familyAbilities[familyID]
	if spellID then
		local spellData = getSpellData(DEFAULT_LOCALE, spellID)
		if spellData then
			printf("Family %q has %s ability %q%s", familyName, isExotic and "exotic" or "special", spellData.name, isOveride and " (override)" or "")
		else
			printf("ERROR: Failed to retrieve spell data for spellID %d", spellID)
		end
	else
		printf("ERROR: Couldn't find special ability for family %q", familyName)
		numErrors = numErrors + 1
		familyAbilities[familyID] = SPELLID_ERROR
	end
end

print() -- Print a newline

if numErrors == 0 then
	print("Successfully found abilities for all pet families.")
else
	printf("Encountered %d errors while finding abilities for pet families.", numErrors)
end

local tocFileName = ADDON_DIR .. "/PetSpecialAttackButton.toc"
local tocFile = fopen(tocFileName, "r+") -- Open the file in update mode so the existing text is preserved.
local tocContents = tocFile:read("*a")

for locale, localeData in pairs(LOCALES) do
	printf("\nGenerating abilities file for locale %s...", locale)

	local pets = getPetData(locale)
	if not pets then
		printf("Failed to retrieve pet data, skipping locale %s!", locale)
	else
		local count = 0
		local abilities = {}
		for familiyID, spellID in pairs(familyAbilities) do
			count = count + 1
			
			local petData = pets.data[familiyID]
			local familyName = petData.name
			
			printf("\nProcessing family: %q (%d of %d)", familyName, count, pets.count)
			
			local spellData = getSpellData(locale, spellID)
			if not spellData then
				printf("Failed to retrieve spell data for locale %s spellID %s!", locale, spellID)
				spellData = getSpellData(locale, SPELLID_ERROR)
			end
			
			local spellName = spellData.name
			abilities[petData.name] = spellName
			
			printf("Family %q has ability %q", familyName, spellName)
		end
	
	
		local abilitiesStr = PrettyPrint(abilities)
		
		local abilitiesFileName = "abilities_" .. locale .. ".lua"
		local abilitiesFile = fopen(ADDON_DIR .. "/" .. abilitiesFileName, "w")
		
		local finalString = TEMPLATE:gsub("$%((%a+)%)", function(var)
			if var == "ABILITIES" then
				return abilitiesStr
			elseif var == "LOCALE" then
				return locale
			else
				abilitiesFile:close()
				error(("ERROR: Unknown variable name %q"):format(var))
			end
		end)
		
		abilitiesFile:write(finalString)
		abilitiesFile:close()
			
		if not tocContents:find(abilitiesFileName, 1, true) then -- The new abilities file isn't in the TOC yet, add it now
			tocFile:seek("end", -8) -- Move to the beginning of "core.lua" (8 characters from the end of the file)
			tocFile:write(abilitiesFileName, "\ncore.lua") -- Write the abilities file name to the TOC. This overwrites "core.lua", so we rewrite it as well.
		end
		
		print("\nFinished generating abilities file")
	end
end

tocFile:close()

if hasErrors then
	printf("Errors written to %s.", ERROR_PATH)
end

print("Finished generating all abilities files.")
