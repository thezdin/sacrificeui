# MythicPlusCount

**Per-mob enemy forces % on nameplates and tooltips for Mythic+ dungeons.**

Created by **Noobheartx**

## Features

### Nameplate Forces Display
Shows the enemy forces percentage directly on each mob's nameplate. At a glance, see exactly how much each trash mob is worth before you pull it.

### Tooltip Forces
Hover over any mob to see its forces count and percentage in the tooltip.

### Progress Bar
A customizable bar showing your current dungeon completion percentage. During combat, it splits into:
- **Green** = confirmed forces (from kills)
- **Yellow** = estimated forces from your current pull (alive mobs you're fighting)

When your pull would push you past 100%, the bar glows gold.

### Pull Counter
Shows forces gained during your current combat pull. Updates in real-time as mobs die.

### Fully Customizable
- Choose fonts, font sizes, and colors
- Position bars anywhere on your UI
- Inside or outside nameplate placement
- Multiple nameplate addon support (Blizzard, Plater, ElvUI, Platynator)

### Auto Accept Queue (Extra)
Optional feature that auto-accepts dungeon queue pops and auto-signs for premade groups. Enable in the Extras tab.

## How It Works

### Midnight (WoW 12.0) Compatibility
In Midnight, Blizzard restricted addon access to enemy NPC data inside instances (Secret Values). MythicPlusCount uses a **compound fingerprint system** to identify mobs using the readable properties that remain:
- 3D Model File ID
- Unit Level (relative)
- Unit Classification
- Unit Class
- Power Type
- Buff Count (as tiebreaker)

### First-Time Setup
The addon ships with pre-built fingerprint data for all 8 Midnight Season 1 dungeons. Most mobs will be identified automatically.

If a mob isn't showing forces, you can teach it:
1. Target the mob
2. Type `/mpc teach`
3. Click the mob name in the picker

Taught data persists forever across sessions.

### Slash Commands
- `/mpc` - Open settings panel
- `/mpc teach` - Teach a mob (target first)
- `/mpc mobs` - List known/unknown mobs for current dungeon
- `/mpc lock` / `/mpc unlock` - Lock or unlock frame positions
- `/mpc reset` - Reset frame positions

## Dungeons Supported (Midnight Season 1)
- Magisters' Terrace
- Maisara Caverns
- Nexus-Point Xenas
- Windrunner Spire
- Algeth'ar Academy
- The Seat of the Triumvirate
- Skyreach
- Pit of Saron

## Settings
Open with `/mpc` or click the minimap button.

**Tabs:**
- **General** - Core settings, dungeon data info
- **Tooltip** - Forces display on mouseover
- **Nameplates** - Forces display on nameplates, font, color, anchor position
- **UI** - Progress bar and pull counter customization
- **Layout** - Frame positioning and lock/unlock
- **Extras** - Optional features (minimap button, auto queue, developer mode)

## Known Limitations
- Some mobs sharing the same 3D model cannot be distinguished (averaged forces shown)
- Forces display may briefly disappear during heavy combat (model loading)
- Pack/pull prediction accuracy depends on how many mob fingerprints are taught

## Export / Import Settings
Share your UI setup with friends:
1. Open `/mpc` > Extras > Export Settings
2. Copy the string
3. Friend pastes it in Import Settings
4. Reload UI

## Updating for New Seasons
When the M+ dungeon rotation changes:
1. Update `data.lua` with new dungeon mob data
2. Update `fingerprints.lua` with new fingerprint mappings
3. Or use `/mpc teach` to build new mappings in-game

## Support
Report issues on GitHub or CurseForge.
