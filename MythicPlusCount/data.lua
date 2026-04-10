-- MythicPlusCount - Data
-- Static mob force count tables, keyed by challengeMapID -> npcID
--
-- HOW TO UPDATE FOR A NEW SEASON:
--   1. Replace the dungeons table below with new season data
--   2. Each dungeon needs: challengeMapID, name, totalForces
--   3. Each mob needs: npcID, name, count (forces value)
--   4. percent is auto-computed at load time from count/totalForces*100
--   5. You can obtain this data from the Mythic Dungeon Tools (MDT) addon
--      database, Wowhead, or Blizzard's API/journal data
--
-- DATA FORMAT:
--   [challengeMapID] = {
--       name = "Dungeon Name",
--       totalForces = <total enemy forces required>,
--       mobs = {
--           [npcID] = { name = "Mob Name", count = <forces value> },
--       },
--   }
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local RAW_DUNGEONS = {
    -- Midnight Season 1 (data from MDT v6.x, ChallengeMapIDs from Keystone Polaris)
    [558] = {
        name = "Magisters' Terrace",
        totalForces = 585,
        mobs = {
            [232369] = { name = "Arcane Magister", count = 7 },
            [234089] = { name = "Animated Codex", count = 0 },
            [251861] = { name = "Blazing Pyromancer", count = 12 },
            [240973] = { name = "Runed Spellbreaker", count = 12 },
            [234069] = { name = "Voidling", count = 1 },
            [234065] = { name = "Hollowsoul Shredder", count = 5 },
            [234064] = { name = "Dreaded Voidwalker", count = 7 },
            [234068] = { name = "Shadowrift Voidcaller", count = 12 },
            [234066] = { name = "Devouring Tyrant", count = 12 },
            [249086] = { name = "Void Infuser", count = 7 },
            [232106] = { name = "Brightscale Wyrm", count = 1 },
            [234062] = { name = "Arcane Sentry", count = 16 },
            [234067] = { name = "Vigilant Librarian", count = 0 },
            [234124] = { name = "Sunblade Enforcer", count = 5 },
            [234486] = { name = "Lightward Healer", count = 5 },
            [241354] = { name = "Void-Infused Brightscale", count = 1 },
            [255376] = { name = "Unstable Voidling", count = 0 },
            [257447] = { name = "Hollowsoul Shredder", count = 5 },
            [259387] = { name = "Spellwoven Familiar", count = 0 },
            -- Bosses
            [231861] = { name = "Arcanotron Custos", count = 0 },
            [231863] = { name = "Seranel Sunlash", count = 0 },
            [231864] = { name = "Gemellus", count = 0 },
            [231865] = { name = "Degentrius", count = 0 },
            [239636] = { name = "Gemellus", count = 0 },
            [241397] = { name = "Celestial Drifter", count = 0 },
        },
    },

    -- Maisara Caverns (challengeMapID = 560)
    [560] = {
        name = "Maisara Caverns",
        totalForces = 607,
        mobs = {
            [248684] = { name = "Frenzied Berserker", count = 5 },
            [242964] = { name = "Keen Headhunter", count = 7 },
            [248686] = { name = "Dread Souleater", count = 15 },
            [248685] = { name = "Ritual Hexxer", count = 7 },
            [249020] = { name = "Hexbound Eagle", count = 3 },
            [253302] = { name = "Hex Guardian", count = 15 },
            [249002] = { name = "Warding Mask", count = 2 },
            [249022] = { name = "Bramblemaw Bear", count = 5 },
            [248693] = { name = "Mire Laborer", count = 1 },
            [248678] = { name = "Hulking Juggernaut", count = 15 },
            [254740] = { name = "Umbral Shadowbinder", count = 5 },
            [249030] = { name = "Restless Gnarldin", count = 15 },
            [248692] = { name = "Reanimated Warrior", count = 2 },
            [248690] = { name = "Grim Skirmisher", count = 2 },
            [249036] = { name = "Tormented Shade", count = 7 },
            [253683] = { name = "Rokh'zal", count = 10 },
            [249025] = { name = "Bound Defender", count = 15 },
            [249024] = { name = "Hollow Soulrender", count = 15 },
            [253458] = { name = "Zil'jan", count = 7 },
            [253473] = { name = "Gloomwing Bat", count = 5 },
            [250443] = { name = "Unstable Phantom", count = 0 },
            [251047] = { name = "Soulbind Totem", count = 0 },
            [253701] = { name = "Death's Grasp", count = 0 },
            [254233] = { name = "Rokh'zal", count = 0 },
            -- Bosses
            [247570] = { name = "Muro'jin", count = 0 },
            [247572] = { name = "Nekraxx", count = 0 },
            [248595] = { name = "Vordaza", count = 0 },
            [248605] = { name = "Rak'tul", count = 0 },
        },
    },

    -- Nexus-Point Xenas (challengeMapID = 559)
    [559] = {
        name = "Nexus-Point Xenas",
        totalForces = 596,
        mobs = {
            [241643] = { name = "Shadowguard Defender", count = 6 }, -- averaged: shares fingerprint with Flux Engineer (5 vs 7)
            [248501] = { name = "Reformed Voidling", count = 1 },
            [241644] = { name = "Corewright Arcanist", count = 5 },
            [241645] = { name = "Hollowsoul Scrounger", count = 3 },
            [241647] = { name = "Flux Engineer", count = 6 }, -- averaged: shares fingerprint with Shadowguard Defender (7 vs 5)
            [248708] = { name = "Nexus Adept", count = 7 },
            [248373] = { name = "Circuit Seer", count = 15 },
            [248706] = { name = "Cursed Voidcaller", count = 3 },
            [248506] = { name = "Dreadflail", count = 8 },
            [241660] = { name = "Duskfright Herald", count = 15 },
            [251853] = { name = "Grand Nullifier", count = 7 },
            [248502] = { name = "Null Sentinel", count = 15 },
            [241642] = { name = "Lingering Image", count = 15 },
            [254932] = { name = "Radiant Swarm", count = 2 },
            [254926] = { name = "Lightwrought", count = 7 },
            [254928] = { name = "Flarebat", count = 3 },
            [248769] = { name = "Smudge", count = 0 },
            [250299] = { name = "[DNT] Conduit Stalker", count = 0 },
            [251024] = { name = "Null Guardian", count = 0 },
            [251031] = { name = "Wretched Supplicant", count = 0 },
            [251568] = { name = "Fractured Image", count = 0 },
            [251852] = { name = "Nullifier", count = 0 },
            [251878] = { name = "Voidcaller", count = 0 },
            [252825] = { name = "Mana Battery", count = 0 },
            [252852] = { name = "Corespark Conduit", count = 0 },
            [254227] = { name = "Corewarden Nysarra", count = 0 },
            [254459] = { name = "Broken Pipe", count = 0 },
            [254485] = { name = "Corespark Pylon", count = 0 },
            [255179] = { name = "Fractured Image", count = 0 },
            [259569] = { name = "Mana Battery", count = 0 },
            [249711] = { name = "Core Technician", count = 0 },
            -- Bosses
            [241539] = { name = "Kasreth", count = 0 },
            [241542] = { name = "Corewarden Nysarra", count = 0 },
            [241546] = { name = "Lothraxion", count = 0 },
        },
    },

    -- Windrunner Spire (challengeMapID = 557)
    [557] = {
        name = "Windrunner Spire",
        totalForces = 591,
        mobs = {
            [232070] = { name = "Restless Steward", count = 7 },
            [232071] = { name = "Dutiful Groundskeeper", count = 4 },
            [232113] = { name = "Spellguard Magus", count = 15 },
            [232116] = { name = "Windrunner Soldier", count = 5 },
            [232173] = { name = "Fervent Apothecary", count = 5 },
            [232171] = { name = "Ardent Cutthroat", count = 6 },
            [232232] = { name = "Zealous Reaver", count = 4 },
            [232175] = { name = "Devoted Woebringer", count = 15 },
            [232176] = { name = "Flesh Behemoth", count = 20 },
            [232056] = { name = "Territorial Dragonhawk", count = 7 },
            [234673] = { name = "Spindleweb Hatchling", count = 1 },
            [232067] = { name = "Creeping Spindleweb", count = 7 },
            [232063] = { name = "Apex Lynx", count = 15 },
            [238099] = { name = "Pesty Lashling", count = 1 },
            [236894] = { name = "Bloated Lasher", count = 17 },
            [238049] = { name = "Scouting Trapper", count = 5 },
            [232119] = { name = "Swiftshot Archer", count = 7 },
            [232122] = { name = "Phalanx Breaker", count = 15 },
            [232283] = { name = "Loyal Worg", count = 5 },
            [232147] = { name = "Lingering Marauder", count = 6 },
            [232148] = { name = "Spectral Axethrower", count = 7 },
            [232146] = { name = "Phantasmal Mystic", count = 15 },
            [258868] = { name = "Haunting Grunt", count = 4 },
            [250883] = { name = "Scouting Trapper", count = 2 },
            [232118] = { name = "Flaming Updraft", count = 0 },
            [232121] = { name = "Phalanx Breaker", count = 0 },
            -- Bosses
            [231606] = { name = "Emberdawn", count = 0 },
            [231626] = { name = "Kalis", count = 0 },
            [231629] = { name = "Latch", count = 0 },
            [231631] = { name = "Commander Kroluk", count = 0 },
            [231636] = { name = "Restless Heart", count = 0 },
        },
    },

    -- Algeth'ar Academy (challengeMapID = 402)
    [402] = {
        name = "Algeth'ar Academy",
        totalForces = 460,
        mobs = {
            [196045] = { name = "Corrupted Manafiend", count = 5 },
            [196577] = { name = "Spellbound Battleaxe", count = 5 },
            [196671] = { name = "Arcane Ravager", count = 15 },
            [196694] = { name = "Arcane Forager", count = 4 },
            [196044] = { name = "Unruly Textbook", count = 4 },
            [192680] = { name = "Guardian Sentry", count = 18 },
            [192329] = { name = "Territorial Eagle", count = 2 },
            [192333] = { name = "Alpha Eagle", count = 15 },
            [197406] = { name = "Aggravated Skitterfly", count = 4 },
            [197219] = { name = "Vile Lasher", count = 9 },
            [197398] = { name = "Hungry Lasher", count = 2 },
            [196200] = { name = "Algeth'ar Echoknight", count = 15 },
            [196202] = { name = "Spectral Invoker", count = 5 },
            -- Bosses
            [194181] = { name = "Vexamus", count = 0 },
            [191736] = { name = "Crawth", count = 0 },
            [196482] = { name = "Overgrown Ancient", count = 0 },
            [190609] = { name = "Echo of Doragosa", count = 0 },
        },
    },

    -- The Seat of the Triumvirate (challengeMapID = 239)
    [239] = {
        name = "The Seat of the Triumvirate",
        totalForces = 568,
        mobs = {
            [124171] = { name = "Merciless Subjugator", count = 10 },
            [122571] = { name = "Rift Warden", count = 20 },
            [122413] = { name = "Ruthless Riftstalker", count = 9 },
            [255320] = { name = "Ravenous Umbralfin", count = 8 },
            [122421] = { name = "Umbral War-Adept", count = 15 },
            [122404] = { name = "Dire Voidbender", count = 8 },
            [252756] = { name = "Void-Infused Destroyer", count = 15 },
            [122423] = { name = "Grand Shadow-Weaver", count = 15 },
            [122322] = { name = "Famished Broken", count = 1 },
            [122403] = { name = "Shadowguard Champion", count = 3 },
            [122405] = { name = "Dark Conjurer", count = 7 },
            [122412] = { name = "Bound Voidcaller", count = 0 },
            [122716] = { name = "Coalesced Void", count = 0 },
            [122827] = { name = "Umbral Tentacle", count = 0 },
            [125340] = { name = "Shadewing", count = 0 },
            [255551] = { name = "Depravation Wave Stalker", count = 0 },
            [256424] = { name = "Void Tentacle", count = 0 },
            -- Bosses
            [122313] = { name = "Zuraal the Ascended", count = 0 },
            [122316] = { name = "Saprish", count = 0 },
            [122319] = { name = "Darkfang", count = 0 },
            [122056] = { name = "Viceroy Nezhar", count = 0 },
            [124729] = { name = "L'ura", count = 0 },
        },
    },

    -- Skyreach (challengeMapID = 161)
    -- Names verified against Wowhead NPC database and keystone.guru (April 2026)
    -- Force counts sourced from keystone.guru live game data
    [161] = {
        name = "Skyreach",
        totalForces = 431,
        mobs = {
            [76132] = { name = "Soaring Chakram Master", count = 5 },
            [78932] = { name = "Driving Gale-Caller", count = 7 },
            [250992] = { name = "Raging Squall", count = 1 },
            [75976] = { name = "Lowborn Servant", count = 1 },
            [79462] = { name = "Blinding Sun Priestess", count = 5 },
            [79466] = { name = "Initiate of the Rising Sun", count = 7 },
            [79467] = { name = "Adept of the Dawn", count = 7 },
            [78933] = { name = "Solar Elemental", count = 15 },
            [76087] = { name = "Solar Construct", count = 12 },
            [79093] = { name = "Suntalon", count = 2 },
            [76154] = { name = "Suntalon Tamer", count = 5 },
            [76149] = { name = "Dread Raven", count = 15 },
            [76205] = { name = "Outcast Warrior", count = 5 },
            [76227] = { name = "Sunwing", count = 0 },
            [76285] = { name = "Arakkoa Magnifying Glass", count = 0 },
            [79303] = { name = "Adorned Bladetalon", count = 12 },
            [251880] = { name = "Solar Orb", count = 0 },
            -- Bosses
            [75964] = { name = "Ranjit", count = 0 },
            [76141] = { name = "Araknath", count = 0 },
            [76142] = { name = "Skyreach Sun Construct Prototype", count = 0 },
            [76143] = { name = "Rukhran", count = 0 },
            [76266] = { name = "High Sage Viryx", count = 0 },
        },
    },

    -- Pit of Saron (challengeMapID = 556)
    [556] = {
        name = "Pit of Saron",
        totalForces = 643,
        mobs = {
            [252551] = { name = "Deathwhisper Necrolyte", count = 15 },
            [252602] = { name = "Risen Soldier", count = 0 },
            [252603] = { name = "Arcanist Cadaver", count = 0 },
            [252567] = { name = "Gloombound Shadebringer", count = 7 },
            [252561] = { name = "Quarry Tormentor", count = 5 },
            [252563] = { name = "Dreadpulse Lich", count = 15 },
            [252558] = { name = "Rotting Ghoul", count = 5 },
            [252610] = { name = "Ymirjar Graveblade", count = 11 },
            [252559] = { name = "Leaping Geist", count = 2 },
            [252606] = { name = "Plungetalon Gargoyle", count = 6 },
            [252555] = { name = "Lumbering Plaguehorror", count = 6 },
            [257190] = { name = "Iceborn Proto-Drake", count = 9 },
            [252565] = { name = "Wrathbone Enforcer", count = 5 },
            [252566] = { name = "Rimebone Coldwraith", count = 7 },
            [252564] = { name = "Glacieth", count = 20 },
            [254684] = { name = "Rotling", count = 0 },
            [254691] = { name = "Scourge Plaguespreader", count = 0 },
            -- Bosses
            [252621] = { name = "Krick", count = 0 },
            [252625] = { name = "Ick", count = 0 },
            [252635] = { name = "Forgemaster Garfrost", count = 0 },
            [252648] = { name = "Scourgelord Tyrannus", count = 0 },
            [252653] = { name = "Rimefang", count = 0 },
            [255037] = { name = "Shade of Krick", count = 0 },
        },
    },
}

local function BuildData()
    local dungeons = {}
    for mapID, dungeon in pairs(RAW_DUNGEONS) do
        local d = {
            name = dungeon.name,
            totalForces = dungeon.totalForces,
            mobs = {},
        }
        for npcID, mob in pairs(dungeon.mobs) do
            d.mobs[npcID] = {
                name = mob.name,
                count = mob.count,
                percent = (dungeon.totalForces > 0) and (mob.count / dungeon.totalForces * 100) or 0,
            }
        end
        dungeons[mapID] = d
    end
    return dungeons
end

MPC.Data = {
    dungeons = BuildData(),

    -- Default "last boss" milestones: minimum % needed before the final boss area.
    -- Value = ceil(100 - max_trash_% available in last boss section).
    DEFAULT_MILESTONES = {
        [556] = { { pct = 78.4, label = "Last Boss" } },  -- Pit of Saron (21.6% trash before last boss)
        [239] = { { pct = 81.3, label = "Last Boss" } },  -- Seat of the Triumvirate (18.7% trash in last boss room)
        [558] = { { pct = 67.5, label = "Last Boss" } },  -- Magisters' Terrace (32.5% max before last boss)
        [560] = { { pct = 72.2, label = "Last Boss" } },  -- Maisara Caverns (27.8% max before last boss)
        [559] = { { pct = 77.5, label = "Last Boss" } },  -- Nexus-Point Xenas (22.5% max before last boss)
        [557] = { { pct = 63.8, label = "Last Boss" } },  -- Windrunner Spire (36.2% max before last boss)
    },
}

function MPC.Data:GetDungeon(challengeMapID)
    return self.dungeons[challengeMapID]
end

function MPC.Data:GetMob(challengeMapID, npcID)
    local dungeon = self.dungeons[challengeMapID]
    if not dungeon then return nil end
    return dungeon.mobs[npcID]
end

function MPC.Data:GetAllMapIDs()
    local ids = {}
    for id in pairs(self.dungeons) do
        ids[#ids + 1] = id
    end
    return ids
end
