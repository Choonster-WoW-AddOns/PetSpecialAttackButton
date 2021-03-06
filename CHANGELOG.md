## 1.13
- Bump TOC Interface version to 8.1
- Remove the Rylak override from the generate script
	- The Rylak family has been merged into the Chimaera family in 8.0
- Update generate script to new use new Battle.net API
	- Add Portuguese (Portugal) and Korean locales
	- Update WoW folder paths to match the new structure introduced in 8.1
- Update abilities to 8.1
	- zhCN (Simplified Chinese) had to be updated from Wowhead manually as the China region's Battle.net API isn't working
- Add abilities for Portuguese (Portugal) and Korean locales

## 1.12
- Bump TOC Interface version to 8.0
- Update abilities and generate script to 8.0
	- Remove overrides for abilities that no longer exist
	- Remove overrides for abilities that are chosen automatically
	- zhCN abilities haven't been updated because the CN region API is no longer accessible without a CN account
	- The Rylak pet family is missing from Wowhead, so it's not included in the abilities tables
- Add .travis.yml file and TOC properties for the BigWigs packager script
	- https://www.wowinterface.com/forums/showthread.php?t=55801

## 1.11
- Restructure repository for p3lim's AddOn Packager Proxy

## 1.10
- Change generate script to generate abilities for all available locales
-- Add strict and PrettyPrint depenencies for generate script
-- Add all generated abilities files
-- Move generate script and depenencies to subdirectory
- Add Stone Scale override for Basilisk

## 1.09
- Add German (deDE) abilities
	-  Contributed by Baine of WoWI

## 1.08
- Add override abilities for Nether Ray and Rylak
- Fix typo in generate script

## 1.07
- Update generate script to use new BNet API
- Update overrides and abilities_enUS.lua with current (6.0) data
- Bump TOC Interface number

## 1.06
- Add missing comma to abilities_enUS.lua
- Change generate script to add a trailing comma to the abilities table

## 1.05
- Add option to update a macro's icon with the current pet's special ability
	-  Add slash command (/psab_update, /psabu) to manually trigger an icon update
- Change EXCEPTIONS table to OVERRIDES in generate script
	-  Change output for each family to show whether the selected ability is an override
- Add overrides for Cat, Shale Spider and Silithid as per Tybudd's recommendations
	-  Re-generate abilities_enUS.lua with these overrides

## 1.04
- Add manual ability exceptions to generate script
	-  Default exception list is Surface Trot for Water Strider
	-  Re-generate abilities_enUS.lua with this exception list and sort entries into alphabetical order

## 1.03
- Fix macro not being initialised properly at login
	-  See my post at http://us.battle.net/wow/en/forum/to...4980?page=2#23 for an explanation of the issue and the solution.

## 1.02
- Add option in generate script to use exotic abilities where possible.
	-  Re-generate abilities_enUS.lua with this option enabled.

## 1.01
- Fix "Attempt to index global 'ns' (a nil value)"
- Add .pkgmeta for CurseForge packager
- Change TOC to use CurseForge's version
- Update README.md with information about availability from Curse/WoWI