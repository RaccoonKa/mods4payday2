1.7.5:
* Fix crash when some weapons had non string animation parameters.

1.7.4:
* Update weapon code to accommodate latest changes, fixes a crash with the Vulcan Minigun and XL 5.56 Microgun, relating to autoaim changes.
* Added an extra sanity check to fix More Weapon Stats compatibility, because it's running more crazy in-game code in the menu.

1.7.3:
* Adjustment to hooking order so that player state hooks run last. This fixes some incompatibilities.
* Add reload speed multiplier caching.

1.7.2:
* Don't make use of fire_rate_multiplier if it's not a player using the weapon.

1.7.1:
* Switch to using dedicated weapon achievement functions.

1.7.0:
* Fix `magazine_empty` and `fire(_steelsight)` playing at the same time
* Move firing tweak data animations to the weapon base.
* Adjust akimbos for this change.
* Added `disable_empty_shell_eject` and `disable_not_empty_shell_eject` weapon tweak data.
* Adjusted fire function not play firing and jamming at the same time.
* Removed unnecessary extra tweak data checks.
* Fix missing speed multiplier from jam timer.
* Fixed a bug with multi-reload-type weapons, where specifying a normal reload timer would override shell by shell timers.
* Small fix for falsey overrides.
* Add some logging to clarify potential weapon override errors.
* Fixed empty reload flag getting stuck.
* Added `ignore_prediction` visual object feature.
* Fixed recoil animation playing whilst reload_enter is playing.
* Made `is_empty` animation global update on weapon equip and underbarrel switch.

1.6.3:
* Removed unnecessary log.
* Removed some no longer needed functions, fixing the alt fire mode firerates. (Issue #39)

1.6.2:
* Fixed detection of penetration related sniper achievements. i.e. `Maximum Penetration` and `You Can't Hide`. (Issue #35)
* Fixed some underbarrel stuff relating to `custom_stats` (Issue #36)
* Fixed alt fire feature. Used on the latest shotgun.
* Added the ability for underbarrel units to use their own `fire` or `a_shell` objects if they exist.

1.6.1:
* Started working on localising the small parts of localised texts. (Thanks to Awberry, Killerwolf, Matthelzor and Kuziz so far).
* Part incompatiblity and requirements no longer rely on sentence construction and are just a simple more readable list.
* Fixed More Weapon Stats compatibility.

1.6.0:
* Fixed weapon getting stuck invisible when scoping in with sights that use `steelsight_weapon_visible`.
* Split up newraycastweaponbase.lua into smaller more manageable sections.
* Added support for arm redirect animations to passthrough to the weapon animation system, allowing for new weapon animations such as: `cash_inspect`, `melee` and `use`
* Implemented my own version of fake full auto animations.
* Added an `is_empty` animation global to allow different hand animations to be played when a magazine is empty.
* Added `bipod_reload_only`
* Added `use_shotgun_reload_on_empty` and `use_shotgun_reload_on_not_empty`
* Added `bipod_reload_allowed`
* Fixed category overrides not changing the reported skill stats in the inventory.
* Implemented `animation_redirects` as a new tweak data option for weapons and parts. Example:
```
<animation_redirects
	equip="equip"
	equip_stop="idle"
	fire="fire"
	fire_stop="idle"
	reload="reload"
	reload_stop="idle"
	reload_not_empty="reload"
	reload_not_empty_stop="idle"
/>
```
* Added support for `use_fix` and `fire/fire_single` on npc/crew weapons.
* Allow weapon bases to define a `run_and_reload_allowed` function.
* Added `required_trail_distance` tweak data.
* Added the `set_state_machine_global` function to control weapon globals on all parts.
* Fixed some missing `shotgun_shell_data` logic.
* Changes for U233

1.5.7:
* Updated License Information for 2023
* Fixed copycat perkdeck reloading not fully reloading shell by shell weapons (Issue #33)
* Fixed NPC weapons not being hidden pre-maskup (Issue #34)

1.5.6:
* Experimental spread changes.
* Fixed burst fire on the akimbo weapon base.
* Fixed `disallow_replenish` not being passed on certain weapon bases, causing buggy behaviour when switching firemodes on them.

1.5.5:
* Fix issue with ammo buffs, used in the new Christmas event.

1.5.4:
* Fixed support for the new official second sight system.

1.5.3:
* Added a missing charging weapon interruption, which was preventing empty reloads triggered by left mouse from being sprint cancelled.

1.5.2:
* Fixed shell-by-shell reloads loading into the chamber from empty.
* Removed some unneeded sanity checks.
* Fixed More Weapon Stats support, ~~I really shouldn't have had to fix it this way.~~

1.5.1:
* Fixed missing stop shooting call, which caused issues with the recent patch.
* Fixed underbarrel support whilst using the volley fire mode.
* Update shell ejection in `_update_stats_values` to allow overriding.

1.5.0:
* Added `ammo_usage` and `reserve_objects`.
* Fixed auto fire sound fix compatibility.
* Experimental Weapon Jamming
* Implemented `is_jammed` first person animation global.
* Temporary patch until BeardLib updates it's AFSF implementation.
* Moved `Ammo Usage & Jamming` to raycastweaponbase.lua to improve compatibility.
* Bipod Only Firing!
* Fixed `advanced_bullet_objects` not showing objects correctly.
* Added `total_bullet_objects` which behave based on pure internal clip count, instead of factoring in the chamber size.
* Also added support for going into negative ammo counts, relative to the magazine, niche but it opens up some doors.
* Fixed `lowest_index`
* Updated to include 'volley' fire mode related features.

1.4.2:
* Fixed burst crashing when used with the akimbo weapon base.

1.4.1:
* Changed backward compatibility checks to use new tweak data.

1.4.0:
* New firemode selection logic to provide support for new burst-fire. Including new tweak data `CAN_TOGGLE_SPECIFIC_FIREMODE`!
* Deep clone the output of cached data to prevent accidental editing of cached outputs.
* Added support for new bullet object `offset` parameter.

1.3.3:
* Fixed Potential Ammo Object Crash

1.3.2:
* Removed some underbarrel switching animation fallback code because it was breaking the akimbo underbarrel shotguns.
* Fixed post heist accuracy calculation logic.
* Fixed scope overlay not updating for resolution correctly.
* Added a potential fix for certain crashes related to tweak data overriding.

1.3.1:
* Fixed a potential crash when viewing certain attachments.

1.3.0:
* Built my own firing function which supports way more than the shotgun and normal raycast ones used to, let me know if this doesn't always act as expected.
* Fixed infinitely reloading AI.
* Fixed fire rate overrides not being applied.

1.2.6:
* Actually fixed the Full Speed Swarm stuff now.
* Fixed a menu crash.

1.2.5:
* Any raycast weapon can now use `rays`. ( This was primarily a stat tracking fix. )
* Shotgun base code now correctly checks for an underbarrel when firing.
* Fixed some grammar in the weapon modification UI.
* Full Speed Swarm compatibility should finally be fixed.

1.2.4:
* Fixed some dumb Tdlq Full Speed Swarm code from infecting my code and breaking it.

1.2.3:
* Removed a useless function, fixing an incompatibility with Full Speed Swarm.

1.2.2:
* Fixed some problematic override code, which primarily caused crashes when interacting with AI crew weapons.

1.2.1:
* Fixed some weapons having 0 clip size.
* More sanity checks.
* Removed underbarrel type limit.

1.2.0:
* Fixed player names not showing above scope overlays.
* Added `scope_overlay_border_color` to control scope overlay border color.
* Added a few extra sanity checks around getting the equipped weapon unit.
* Fixed underbarrels not having firing sounds.
* Fixed More Weapon Stats incompatibility.
* Fixed crash when going into custody.
* Fixed overriden magazine size not appearing in all menus.

1.1.2:
* Gave scope overlays their own panel, instead of accidentally using the generic workspace one.

1.1.1:
* Temporarily removed the total ammo mod changes until I can figure out what causes the ammo issues.

1.1.0:
* Fixed hooks not loading because of a comment which SuperBLT couldn't handle.
* Added fractional support to Total Ammo Mod. Allowing for down to 1% changes by using `0.2` increments!

**1.0.0**:
* Full rewrite release!
* I'm actually happy enough with this release to take WeaponLib out of beta. The vast majority of pre-existing issues have been fixed in this full rewrite.
* This also includes a few new features, including `chamber_size` and `reload_num` for every weapon type.
* Also a whole bunch of improvements to bullet objects.
* Several fixes to underbarrels which Overkill have neglected, including full auto support, and shell by shell reloading support!

---

0.4.8:
* I think I fixed that flamethrower other client crash.

0.4.7:
* Hotfixed the Hotfix

0.4.6:
* Hotfix for 8th Anniversary Cash Launcher thing.

0.4.5:
* Fixed an older piece of code that conflicted with More Weapon Stats due to an old misunderstanding of how Overkill's class implementation works.

0.4.4:
* Updated some internal code to include Overkill's stinky way of changing underbarrel projectiles.
* Unhardcoded underbarrel entering and exiting, now it uses the `weapon_hold` of the underbarrel tweak data, `weapon_hold` of the main weapon, and finally just the `id`, in that order of priority.

0.4.3:
* A tweak to the previous hotfix.
* Actually remembered to change the internal version this time.

0.4.2:
* Potential table adding issue fix.

0.4.1:
* Fixed some cosmetic related stuff.

**0.4.0**:
* Look, I genuinely don't know what changed. MWS has been out of date for so long and I've started two rewrites off-site.
* Some shit is probably fixed.
* Some shit is probably still broken.
* Some shit is probably now broken.

---

0.3.1:
* Added an extra check when generating unique blueprint keys for caching. Occasionally a blueprint would have a nil value inside it causing default Lua functions to freak out.

**0.3.0**:
* Fixed weapon scope effects not properly handling the players custom colour grading choice.
* Fixed some incompatibility issues with some stuff.
* Added `Requires Attachment` module.
* Changed some internal code so that default weapon parts get re-added properly when they get removed due to a forbids.
* Added `Custom Attachment Points Legacy`, maintaining backwards compatibility with new code was getting too messy.

---

**0.2.0**: 
* 'Weapon Tweak Data Overrides' rewritten again, fallback code works now and should prevent the majority of crashes related to it.
* 'Custom Attachment Points' now works with parts that would normally parent to an existing attachment, e.g. silencers.
* Added 'Different Akimbos' module to expand the visual functionality of akimbo weapons.
* Removed excess logging.
* Selection indexes should use the defined function for it now instead of using the tweak data in order to expand mod support.
* Updated the internal hook order.
* Added 'Weapon Factory Manager Caching', caches data in order to improve performance when modding weapons.
* Fixed 'Weapon Tweak Data Overrides' using the wrong tables for add and multiply.
* Added backwards compatibility for: 'New magazine size for weapons', 'Attachment Animations', and 'Fire Rate Multiplier'.
* Added warning for out of date tweak data.

---

0.1.2: 
* Moved in some fixes from the development copy.
* Custom Attachment Points should work properly 90% of the time now.
* The weapon tweak data stuff should produce correct tables most of the time now.
* General small fixes.

0.1.1: 
* Fixed the replacement audio file naming.
* Added some extra code which should hopefully stop a crash with RestorationMod.

**0.1.0**: 
* Initial Beta Release!