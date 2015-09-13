local locale = GetLocale()
if locale ~= "frFR" then return end

local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

local _, ns = ...
ns.PET_ABILITIES = {
	["Araignée"] = "Jet de toiles",
	["Araignée de schiste"] = "Carapace solide",
	["Basilic"] = "Ecailles de pierre",
	["Cerf"] = "Grâce",
	["Charognard"] = "Hurlement sanguinaire",
	["Chauve-souris"] = "Focalisation sonore",
	["Chèvre"] = "Pas d'attaque spéciale",
	["Chien"] = "Pas d'attaque spéciale",
	["Chien du magma"] = "Peau en fusion",
	["Chimère"] = "Souffle de givre",
	["Crabe"] = "Carapace durcie",
	["Crocilisque"] = "Entorse de cheville",
	["Diablosaure"] = "Dévorer",
	["Esprit de bête"] = "Marche de l'esprit",
	["Faucon-dragon"] = "Attaques vivaces",
	["Félin"] = "Rugissement de courage",
	["Gorille"] = "Pas d'attaque spéciale",
	["Grue"] = "Tour",
	["Guêpe"] = "Vitesse de l’essaim",
	["Hanneton"] = "Carapace endurcie",
	["Haut-trotteur"] = "Marche-plaine",
	["Hydre"] = "Sens aux aguets",
	["Hyène"] = "Ricanement sonore",
	["Loup"] = "Pas d'attaque spéciale",
	["Navrecorne"] = "Plaque d’armure réfléchissante",
	["Oiseau de proie"] = "Ténacité",
	["Ours"] = "Rugissement vivifiant",
	["Phalène"] = "Pas d'attaque spéciale",
	["Porc-épic"] = "Piquants défensifs",
	["Potamodonte"] = "Morsure atroce",
	["Quilen"] = "Rugissement intrépide",
	["Raie du Néant"] = "Pas d'attaque spéciale",
	["Raptor"] = "Force de la meute",
	["Ravageur"] = "Armure en chitine",
	["Renard"] = "Réflexes aiguisés",
	["Rylak"] = "Courant ascendant",
	["Sabot-fourchu"] = "Force sauvage",
	["Sanglier"] = "Indomptable",
	["Scorpide"] = "Piqûre mortelle",
	["Serpent"] = "Ruse du serpent",
	["Serpent des vents"] = "Souffle des vents",
	["Silithide"] = "Déchirure du tendon",
	["Singe"] = "Agilité primordiale",
	["Sporoptère"] = "Pas d'attaque spéciale",
	["Tortue"] = "Carapace bouclier",
	["Traqueur dim."] = "Distorsion temporelle",
	["Trotteur aquatique"] = "Pas d'attaque spéciale",
	["Ver"] = "Pas d'attaque spéciale",
}