# Changelog

## 1.2.0

### New: Milestone Markers
- Added milestone markers on the progress bar - vertical lines at configurable % values per dungeon
- Ships with built-in "Last Boss" milestones for 6 dungeons showing the minimum % needed before the final boss area:
  - Windrunner Spire: 63.8%
  - Magisters' Terrace: 67.5%
  - Maisara Caverns: 72.2%
  - Nexus-Point Xenas: 77.5%
  - Pit of Saron: 78.4%
  - Seat of the Triumvirate: 81.3%
- Default milestones can be toggled on/off independently from custom milestones
- Full per-dungeon customization: add your own milestones with a % value and optional label
- Milestones support decimal precision up to 2 places (e.g. 78.4%)
- Optional labels above markers with configurable font, size, and color
- "Display %" option prepends the percentage to labels (e.g. "78.4% Last Boss")
- Completion color: milestone lines change color when your progress has reached that checkpoint
- All milestone settings found in /mpc > UI tab > Milestones section

### Fixes
- Fixed ElvUI nameplate forces count rendering behind the nameplate
- Fixed minimap icon positioning

### Additions
- Added TinyThreat nameplate support
