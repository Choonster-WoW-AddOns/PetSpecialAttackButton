﻿local locale = GetLocale()
if locale ~= "deDE" then return end

local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

local _, ns = ...
ns.PET_ABILITIES = {
	["Aasvogel"] = "Blutiges Kreischen",
	["Affe"] = "Urtümliche Beweglichkeit",
	["Basilisk"] = "Steinschuppen",
	["Blutbestie"] = "Blutblitz",
	["Bär"] = "Dickes Fell",
	["Drachenfalke"] = "Drachenlist",
	["Eber"] = "Borsten aufstellen",
	["Echse"] = "Schrecklicher Biss",
	["Federmähnen"] = "Aufwind",
	["Felshetzer"] = "Verheeren",
	["Fledermaus"] = "Überschall",
	["Flussbestie"] = "Grausamer Biss",
	["Fuchs"] = "Flexible Reflexe",
	["Geisterbestie"] = "Geistheilung",
	["Gorilla"] = "Silberrücken",
	["Grollhuf"] = "Blut des Rhinozeros",
	["Hirsch"] = "Anmut der Natur",
	["Hund"] = "Beinbiss",
	["Hydra"] = "Ätzender Biss",
	["Hyäne"] = "Infizierter Biss",
	["Katze"] = "Schleichen",
	["Kernhund"] = "Lavafell",
	["Kranich"] = "Chi-Jis Gelassenheit",
	["Krebs"] = "Zwicker",
	["Krokilisk"] = "Wadenbiss",
	["Krolusk"] = "Bollwerk",
	["Kröte"] = "Fliegenschwarm",
	["Käfer"] = "Panzer verhärten",
	["Mechanisch"] = "Verteidigungsmatrix",
	["Motte"] = "Gleichmutsstaub",
	["Nager"] = "Nagen",
	["Netherrochen"] = "Netherwinde",
	["Ochse"] = "Niuzaos Seelenstärke",
	["Pterrordax"] = "Aufwind",
	["Qilen"] = "Ewiger Wächter",
	["Raptor"] = "Wildes Verwunden",
	["Raubvogel"] = "Reißende Krallen",
	["Schieferspinne"] = "Robuster Panzer",
	["Schildkröte"] = "Panzerschild",
	["Schimäre"] = "Froststurmatem",
	["Schlange"] = "Schnelligkeit der Schlange",
	["Schuppenbalg"] = "Schuppenschild",
	["Silithid"] = "Sehnenriss",
	["Skorpid"] = "Tödlicher Stich",
	["Sphärenjäger"] = "Zeit krümmen",
	["Spinne"] = "Gespinstschauer",
	["Sporensegler"] = "Sporenwolke",
	["Terrorhorn"] = "Aufspießen",
	["Teufelssaurier"] = "Laben",
	["Wasserschreiter"] = "Oberflächenspannung",
	["Weitschreiter"] = "Staubwolke",
	["Wespe"] = "Giftiger Stich",
	["Windnatter"] = "Beflügelte Beweglichkeit",
	["Wolf"] = "Rasender Biss",
	["Wurm"] = "Bodenangriff",
	["Ziege"] = "Schroff",
}