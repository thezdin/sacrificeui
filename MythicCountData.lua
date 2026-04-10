-- SacrificeUI M+ Mob Count Data
-- Enemy forces % values for each trash mob in Midnight Season 1 dungeons.
--
-- HOW TO FIND NPC IDs:
--   Target or mouseover a mob in-game, then run:
--   /run print(select(6, strsplit("-", UnitGUID("mouseover"))))
--
-- FORMAT:
--   M(npcID, pct, "Mob Name")
--   pct = enemy forces % this mob contributes (e.g. 0.42 means 0.42%)

SacrificeUI.MobCount = SacrificeUI.MobCount or {}

local function M(npcID, pct, name)
    SacrificeUI.MobCount[npcID] = { pct = pct, name = name }
end

-- ============================================================
-- Algeth'ar Academy (mapID 2526)
-- ============================================================
-- M(000000, 0.00, "Unruly Textbook")
-- M(000000, 0.00, "Spectral Invoker")
-- M(000000, 0.00, "Corrupted Manafiend")
-- M(000000, 0.00, "Arcane Ravager")
-- M(000000, 0.00, "Algeth'ar Echoknight")
-- M(000000, 0.00, "Alpha Eagle")

-- ============================================================
-- Magister's Terrace (mapID 585)
-- ============================================================
-- M(000000, 0.00, "Arcane Magister")
-- M(000000, 0.00, "Blazing Pyromancer")
-- M(000000, 0.00, "Void Terror")
-- M(000000, 0.00, "Dreaded Voidwalker")
-- M(000000, 0.00, "Animated Codex")
-- M(000000, 0.00, "Spellwoven Familiar")
-- M(000000, 0.00, "Shadowrift Voidcaller")
-- M(000000, 0.00, "Runed Spellbreaker")
-- M(000000, 0.00, "Arcane Sentry")
-- M(000000, 0.00, "Sunblade Enforcer")
-- M(000000, 0.00, "Lightward Healer")

-- ============================================================
-- Maisara Caverns (mapID 2773)
-- ============================================================
-- M(000000, 0.00, "Ritual Hexxer")
-- M(000000, 0.00, "Tormented Shade")
-- M(000000, 0.00, "Umbral Shadowbinder")
-- M(000000, 0.00, "Keen Headhunter")
-- M(000000, 0.00, "Reanimated Warrior")
-- M(000000, 0.00, "Hollow Soulrender")
-- M(000000, 0.00, "Gloomwing Bat")
-- M(000000, 0.00, "Dread Souleater")
-- M(000000, 0.00, "Hulking Juggernaut")
-- M(000000, 0.00, "Hex Guardian")
-- M(000000, 0.00, "Zil'jan")

-- ============================================================
-- Nexus Point Xenas (mapID 2774)
-- ============================================================
-- M(000000, 0.00, "Grand Nullifier")
-- M(000000, 0.00, "Corewright Arcanist")
-- M(000000, 0.00, "Nexus Adept")
-- M(000000, 0.00, "Lightwrought")
-- M(000000, 0.00, "Shadowguard Defender")
-- M(000000, 0.00, "Lingering Image")
-- M(000000, 0.00, "Flux Engineer")
-- M(000000, 0.00, "Circuit Seer")
-- M(000000, 0.00, "Null Sentinel")

-- ============================================================
-- Pit of Saron (mapID 658)
-- ============================================================
-- M(000000, 0.00, "Dreadpulse Lich")
-- M(000000, 0.00, "Arcanist Cadaver")
-- M(000000, 0.00, "Gloombound Shadebringer")
-- M(000000, 0.00, "Rimebone Coldwraith")
-- M(000000, 0.00, "Plungetalon")
-- M(000000, 0.00, "Glacieth")
-- M(000000, 0.00, "Quarry Tormentor")

-- ============================================================
-- Seat of the Triumvirate (mapID 1753)
-- ============================================================
-- M(000000, 0.00, "Dark Conjuror")
-- M(000000, 0.00, "Ruthless Riftstalker")
-- M(000000, 0.00, "Dire Voidbender")
-- M(000000, 0.00, "Merciless Subjugator")
-- M(000000, 0.00, "Bound Voidcaller")
-- M(000000, 0.00, "Rift Warden")
-- M(000000, 0.00, "Void-Infused Destroyer")

-- ============================================================
-- Skyreach (mapID 1209)
-- ============================================================
-- M(000000, 0.00, "Driving Gale-Caller")
-- M(000000, 0.00, "Blinding Sun Priestess")
-- M(000000, 0.00, "Initiate of the Rising Sun")
-- M(000000, 0.00, "Adorned Bladetalon")
-- M(000000, 0.00, "Adept of the Dawn")
-- M(000000, 0.00, "Solar Elemental")
-- M(000000, 0.00, "Solar Construct")
-- M(000000, 0.00, "Sun Talon Tamer")

-- ============================================================
-- Windrunner Spire (mapID 2775)
-- ============================================================
-- M(000000, 0.00, "Ardent Cutthroat")
-- M(000000, 0.00, "Devoted Woebringer")
-- M(000000, 0.00, "Phantasmal Mystic")
-- M(000000, 0.00, "Restless Steward")
-- M(000000, 0.00, "Bloated Lasher")
-- M(000000, 0.00, "Territorial Dragonhawk")
-- M(000000, 0.00, "Spectral Axethrower")
