-- SacrificeUI Dungeon Data
-- Midnight Season 1 M+ dungeon ability data.
-- Sourced from Method.gg dungeon ability trackers by Tactyks.
-- All credit to Method and Tactyks for the original guide content.
-- Content was rephrased for compliance with licensing restrictions.
--
-- Format: SacrificeUI.DungeonData[instanceMapID] = { ... }
-- Also indexed by name for fallback matching.

SacrificeUI.DungeonData = SacrificeUI.DungeonData or {}
SacrificeUI.DungeonDataByName = SacrificeUI.DungeonDataByName or {}

local function Register(mapID, data)
    SacrificeUI.DungeonData[mapID] = data
    SacrificeUI.DungeonDataByName[data.name] = data
end

-- ============================================================
-- Magister's Terrace (Midnight rework)
-- ============================================================
Register(585, {
    name = "Magister's Terrace",
    interrupts = {
        "Arcane Magister - Polymorph (CC, top priority)",
        "Arcane Magister - Arcane Bolt",
        "Blazing Pyromancer - Pyroblast (heavy damage)",
        "Void Terror - Terror Wave (fear, can LoS)",
        "Dreaded Voidwalker - Shadow Bolt",
    },
    dangerous = {
        "Animated Codex - Arcane Volley (unavoidable party damage)",
        "Spellwoven Familiar - Blink (party damage, important)",
        "Shadowrift Voidcaller - Consuming Shadows (party damage, LoS to avoid)",
        "Runed Spellbreaker - Runic Glaive (party damage + bleed, can Shadowmeld)",
        "Arcane Sentry - Arcane Beam (dodge, can Shadowmeld)",
        "Arcane Sentry - Crowd Dispersal (party damage)",
    },
    dispels = {
        "Polymorph - magic CC on party member",
        "Unstable Energy - magic DoT (Arcanotron Custos boss)",
        "Consuming Void - magic DoT (Void Terror, use Stoneform)",
        "Holy Fire - magic DoT (Lightward Healer, use Stoneform)",
    },
    buffs = {
        "Sunblade Enforcer - Arcane Blade (self-buff, increases tank damage taken)",
        "Lightward Healer - Power Word: Shield (purge/spellsteal)",
        "Blazing Pyromancer - Ignition (self-buff + party damage)",
    },
    notes = {
        "Boss: Arcanotron Custos - dodge Arcane Expulsion, break Ethereal Shackles (Freedom)",
        "Boss: Seranel Sunlash - avoid Runic Mark zones, dodge Null Reaction (CC)",
        "Boss: Gemellus - kill Triplicate adds, dodge Cosmic Sting + Astral Grasp",
        "Boss: Degentrius - dodge Void Torrent, manage Hulking Fragment adds",
    },
    classTips = {},
})

-- ============================================================
-- Algeth'ar Academy
-- ============================================================
Register(2526, {
    name = "Algeth'ar Academy",
    interrupts = {
        "Unruly Textbook - Monotonous Lecture (CC/stop, top priority)",
        "Spectral Invoker - Mystic Brand (magic debuff)",
        "Spectral Invoker - Arcane Bolt",
        "Corrupted Manafiend - Surge",
        "Overgrown Ancient (Boss) - Healing Touch (heal interrupt)",
    },
    dangerous = {
        "Alpha Eagle - Raging Screech (party damage + buff + tank buster)",
        "Corrupted Manafiend - Mana Void (avoid, magic debuff)",
        "Arcane Ravager - Vicious Ambush (avoid, magic debuff, can Shadowmeld)",
        "Algeth'ar Echoknight - Arcane Smash (party damage, LoS)",
    },
    dispels = {
        "Mana Void - magic debuff (Corrupted Manafiend)",
        "Mystic Brand - magic debuff (Spectral Invoker)",
        "Vicious Ambush - magic debuff (Arcane Ravager)",
    },
    buffs = {
        "Alpha Eagle - Raging Screech grants damage buff, purge if possible",
    },
    notes = {
        "Monotonous Lecture is the highest priority interrupt in this dungeon",
        "Healing Touch on Overgrown Ancient boss must be kicked or boss heals",
    },
    classTips = {},
})

-- ============================================================
-- Maisara Caverns
-- ============================================================
Register(2773, {
    name = "Maisara Caverns",
    interrupts = {
        "Ritual Hexxer - Hex (CC, top priority)",
        "Ritual Hexxer - Shadow Bolt",
        "Tormented Shade - Spirit Rend (debuff, use Stoneform)",
        "Umbral Shadowbinder - Shrink",
        "Keen Headhunter - Hooked Snare",
        "Reanimated Warrior - Reanimation",
        "Hollow Soulrender - Shadowfrost Blast",
        "Gloomwing Bat - Piercing Screech",
        "Vordaza (Boss) - Necrotic Convergence",
        "Rak'tul (Boss) - Eternal Suffering",
    },
    dangerous = {
        "Dread Souleater - Necrotic Wave (party damage + magic debuff)",
        "Hulking Juggernaut - Deafening Roar (heavy party damage)",
        "Hex Guardian - Magma Surge (frontal, face away)",
        "Zil'jan - Ritual Drums (party damage, avoid zones)",
    },
    dispels = {
        "Necrotic Wave - magic debuff (Dread Souleater)",
        "Ritual Sacrifice - magic debuff (Rokh'zal, use Freedom)",
        "Spirit Rend - debuff (Tormented Shade, use Stoneform)",
    },
    buffs = {},
    notes = {
        "Hex is the top priority kick - turns a party member into a frog",
        "Rokh'zal Ritual Sacrifice can be removed with Blessing of Freedom",
    },
    classTips = {},
})

-- ============================================================
-- Nexus Point Xenas
-- ============================================================
Register(2774, {
    name = "Nexus Point Xenas",
    interrupts = {
        "Grand Nullifier - Nullify (top priority)",
        "Corewright Arcanist - Arcane Explosion",
        "Nexus Adept - Umbra Bolt",
        "Lightwrought - Holy Bolt",
        "Lothraxion (Boss) - Divine Guile",
    },
    dangerous = {
        "Shadowguard Defender - Null Sunder (buff + magic debuff + tank buster)",
        "Lingering Image - Blistering Smite (magic debuff)",
        "Flux Engineer - Mana Battery (party damage)",
        "Flux Engineer - Suppression Field (avoid, magic debuff, use Freedom)",
        "Circuit Seer - Arcing Mana (party damage)",
        "Null Sentinel - Dreadbellow (party damage + magic debuff)",
        "Lightwrought - Burning Radiance (party damage + debuff, use Stoneform)",
    },
    dispels = {
        "Null Sunder - magic debuff (Shadowguard Defender)",
        "Blistering Smite - magic debuff (Lingering Image)",
        "Suppression Field - magic debuff (Flux Engineer)",
        "Dreadbellow - magic debuff (Null Sentinel)",
        "Burning Radiance - debuff (Lightwrought, use Stoneform)",
    },
    buffs = {
        "Shadowguard Defender - Null Sunder self-buff, increases tank damage",
    },
    notes = {
        "Suppression Field can be removed with Blessing of Freedom",
        "Lothraxion boss - interrupt Divine Guile",
    },
    classTips = {},
})

-- ============================================================
-- Pit of Saron
-- ============================================================
Register(658, {
    name = "Pit of Saron",
    interrupts = {
        "Dreadpulse Lich - Icy Blast (tank buster, top priority)",
        "Arcanist Cadaver - Netherburst (party damage)",
        "Gloombound Shadebringer - Shadow Bolt",
        "Rimebone Coldwraith - Icebolt",
        "Ick and Krick (Boss) - Shadowbind",
        "Ick and Krick (Boss) - Death Bolt",
        "Scourgelord Tyrannus (Boss) - Plague Bolt",
        "Plungetalon - Plungegrip (buff + debuff + stop, use Freedom)",
    },
    dangerous = {
        "Dreadpulse Lich - Dread Pulse (heavy party damage)",
        "Rimebone Coldwraith - Permeating Cold (party damage + debuff, use Freedom)",
        "Glacieth - Cryoburst (party damage, avoid)",
    },
    dispels = {
        "Curse of Torment - curse (Quarry Tormentor, use Stoneform)",
        "Permeating Cold - debuff (Rimebone Coldwraith, use Freedom)",
    },
    buffs = {
        "Plungetalon - Plungegrip grants self-buff, purge if possible",
    },
    notes = {
        "Icy Blast on Dreadpulse Lich is the most dangerous trash cast",
        "Plungetalon Plungegrip can be stopped with Freedom",
        "Boss: Ick and Krick - kick Shadowbind and Death Bolt",
        "Boss: Tyrannus - kick Plague Bolt, avoid Overlord's Brand",
    },
    classTips = {},
})

-- ============================================================
-- Seat of the Triumvirate
-- ============================================================
Register(1753, {
    name = "Seat of the Triumvirate",
    interrupts = {
        "Dark Conjuror - Summon Voidcaller (top priority, spawns add)",
        "Dark Conjuror - Umbral Bolt",
        "Ruthless Riftstalker - Shadowmend (heal)",
        "Dire Voidbender - Abyssal Enhancement (buff + party damage + tank buster)",
        "Viceroy Nezhar (Boss) - Mind Blast",
        "Saprish (Boss) - Dread Screech",
    },
    dangerous = {
        "Merciless Subjugator - Chains of Subjugation (party damage + avoid + magic debuff, use Freedom)",
        "Bound Voidcaller - Pulsing Void (party damage)",
        "Rift Warden - Rift Tear (party damage, avoid)",
        "Void-Infused Destroyer - Eruption (party damage + avoid + magic debuff)",
    },
    dispels = {
        "Chains of Subjugation - magic debuff (Merciless Subjugator, use Freedom)",
        "Eruption - magic debuff (Void-Infused Destroyer)",
        "Backstab - debuff (Ruthless Riftstalker)",
    },
    buffs = {
        "Dire Voidbender - Abyssal Enhancement (self-buff, purge/kick)",
    },
    notes = {
        "Summon Voidcaller is the top kick - prevents add spawn",
        "Abyssal Enhancement must be interrupted or purged immediately",
        "Chains of Subjugation can be removed with Blessing of Freedom",
    },
    classTips = {},
})

-- ============================================================
-- Skyreach
-- ============================================================
Register(1209, {
    name = "Skyreach",
    interrupts = {
        "Driving Gale-Caller - Repel (party damage, top priority)",
        "Blinding Sun Priestess - Blinding Light (magic debuff CC)",
        "Initiate of the Rising Sun - Solar Bolt",
        "High Sage Viryx (Boss) - Solar Blast",
    },
    dangerous = {
        "Adorned Bladetalon - Blade Rush (party damage + debuff + tank buster, use Stoneform)",
        "Adept of the Dawn - Fiery Talon (buff + magic debuff + tank buster)",
        "Solar Elemental - Solar Orb (party damage)",
        "Solar Construct - Solar Flame (magic debuff, can Shadowmeld)",
        "Sun Talon Tamer - Mark of Death (debuff)",
    },
    dispels = {
        "Blinding Light - magic CC (Blinding Sun Priestess)",
        "Fiery Talon - magic debuff (Adept of the Dawn)",
        "Solar Flame - magic debuff (Solar Construct)",
        "Blade Rush - debuff (Adorned Bladetalon, use Stoneform)",
    },
    buffs = {
        "Adept of the Dawn - Fiery Talon self-buff, increases tank damage",
    },
    notes = {
        "Repel is the highest priority kick - knocks party back + damage",
        "Blinding Light CC must be dispelled or interrupted immediately",
        "Boss: High Sage Viryx - interrupt Solar Blast",
    },
    classTips = {},
})

-- ============================================================
-- Windrunner Spire
-- ============================================================
Register(2775, {
    name = "Windrunner Spire",
    interrupts = {
        "Ardent Cutthroat - Poison Blades (buff + debuff + tank buster, use Stoneform)",
        "Devoted Woebringer - Pulsing Shriek (party damage + buff)",
        "Devoted Woebringer - Shadow Bolt",
        "Phantasmal Mystic - Chain Lightning (party damage)",
        "Restless Steward - Spirit Bolt",
        "Bloated Lasher - Fungal Bolt",
        "Derelict Duo (Boss) - Shadow Bolt",
    },
    dangerous = {
        "Territorial Dragonhawk - Fire Spit (stop cast, can Shadowmeld)",
        "Bloated Lasher - Spore Dispersal (party damage + magic debuff + tank buster)",
        "Spectral Axethrower - Throw Axe (debuff, use Stoneform)",
        "Phantasmal Mystic - Ephemeral Bloodlust (buff + tank buster, purge)",
    },
    dispels = {
        "Spore Dispersal - magic debuff (Bloated Lasher)",
        "Poison Blades - debuff (Ardent Cutthroat, use Stoneform)",
        "Throw Axe - debuff (Spectral Axethrower, use Stoneform)",
    },
    buffs = {
        "Phantasmal Mystic - Ephemeral Bloodlust (purge/spellsteal, increases tank damage)",
        "Ardent Cutthroat - Poison Blades self-buff",
        "Devoted Woebringer - Pulsing Shriek self-buff",
    },
    notes = {
        "Poison Blades is the top priority kick - buffs mob + debuffs tank",
        "Ephemeral Bloodlust must be purged immediately",
        "Fire Spit can be stopped or Shadowmelded",
    },
    classTips = {},
})
