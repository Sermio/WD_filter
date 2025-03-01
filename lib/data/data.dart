List<String> attributesList = [
  "hp_gen",
  "damage",
  "barrage_cost",
  "rocket_damage",
  "armor",
  "hp",
  "psi",
  "crit_chance",
  "healing_taken_mod",
  "psi_gen",
  "expose_target_chance",
  "shield_hull",
  "expose_target_armor_duration",
  "feed_psi_cost",
  "shield_percentabsorbtion",
  "grenade_radius",
  "nether_nova_damage",
  "repairdrones_power",
  "fortify_armor_add_perc",
  "confuse_chance",
  "inject_hp",
  "repairdrones_repair_per_tick",
  "ignite_duration",
  "rejuvenation_amount",
  "nether_nova_psi_cost",
  "power_fuse_area",
  "proton_shot_radius",
  "discharge_chance",
  "sweepingfire_damage_perc",
  "chain_shot_chance",
  "illusion_power_cost",
  "shield_fullabsorbchance",
  "repairdrones_heal_radius",
  "inject_power_cost",
  "feedback_heal",
  "life_leech_boost",
  "nether_nova_radius",
  "harvest_damage",
  "corruption_damage",
  "holy_aura_heal",
  "lightning_damage",
  "relief_psicost",
  "relief_duration",
  "corruption_duration",
  "growl_duration",
  "shield_regen",
  "nano_fix_heal",
  "vortex_heal",
  "holyshock_power",
  "overcharge_chance",
  "proton_shot_damage",
  "sweepingfire_power",
  "relief_healpersec",
  "bandage_amount",
  "harvest_duration",
  "feed_base",
  "stasis_shot_chance",
  "mend_power",
  "sweepingfire_duration",
  "drain_life_boost",
  "unholy_aura_heal",
  "charging_field_area",
  "fear_shock_duration",
  "mend_heal",
  "rejuvenation_psicost",
  "fear_shock_power",
  "incinerate_damage",
  "purify_psicost",
  "growl_chance",
  "chill_duration",
  "confuse_duration",
  "vortex_power",
  "throw_grenade_chance",
  "lightning_power",
  "nano_fix_power",
  "grenade_damage",
  "rocket_precision_chance",
  "harvest_chance",
  "vitality_surge_gain",
  "sweep_damage",
  "drain_psi_amount",
  "drain_life_chance",
  "rupture_chance",
  "sweep_power_cost",
  "stasis_shot_duration",
  "unholy_power_cooldown",
  "pyrowave_chance",
  "drain_psi_chance",
  "feedback_chance",
  "fortify_armor",
  "confuse_armor_perc_buff",
  "dimension_chain_power",
  "dimension_chain_duration",
  "enfeeble_chance",
  "enfeeble_duration",
  "chill_psi_cost",
  "death_rumble_damage",
  "confuse_power",
  "freeze_duration",
  "freeze_power",
  "incinerate_psi_cost",
  "whirlwind_chance",
  "death_rumble_area",
  "hollow_voice_area",
  "hollow_voice_chance",
  "shift_stun_duration",
  "hollow_voice_damage",
  "fortify_power_cost",
  "power_fuse_perc",
  "death_rumble_chance",
  "rocket_precision_damage_perc",
  "proton_shot_psi",
  "overcharge_stun_duration",
  "harvest_cooldown",
  "power_leak_drain",
  "charging_field_psi_perc",
  "rupture_stun_duration",
  "rocket_precision_duration",
  "vitality_surge_power",
  "howl_fear_duration",
  "breed_power",
  "power_leak_chance",
  "additive",
  "material_alpha",
  "diffuse",
  "ambient",
  "emissive"
];

List<Map<String, String>> units = [
  {'key': 'Commander', 'value': 'Commander'},
  {'key': 'Assassin', 'value': 'Assassin'},
  {'key': 'Constructor', 'value': 'Constructor'},
  {'key': 'Judge', 'value': 'Judge'},
  {'key': 'Surgeon', 'value': 'Surgeon'},
  {'key': 'Trooper', 'value': 'Trooper'},
  {'key': 'Ripper', 'value': 'Ripper'},
  {'key': 'AssaultBot', 'value': 'AssaultBot'},
  {'key': 'Hellfire', 'value': 'Hellfire'},
  {'key': 'HighPriest', 'value': 'HighPriest'},
  {'key': 'Guardian', 'value': 'Guardian'},
  {'key': 'Shaman', 'value': 'Shaman'},
  {'key': 'Sorcerer', 'value': 'Sorcerer'},
  {'key': 'StoneGhost', 'value': 'Stone Ghost'},
  {'key': 'Warrior', 'value': 'Warrior'},
  {'key': 'Brute', 'value': 'Brute'},
  {'key': 'AncientShade', 'value': 'AncientShade'},
  {'key': 'HowlingHorror', 'value': 'HowlingHorror'},
  {'key': 'Master', 'value': 'Master'},
  {'key': 'Arbiter', 'value': 'Arbiter'},
  {'key': 'Dominator', 'value': 'Dominator'},
  {'key': 'Harvester', 'value': 'Harvester'},
  {'key': 'Manipulator', 'value': 'Manipulator'},
  {'key': 'Trisat', 'value': 'Trisat'},
  {'key': 'Tritech', 'value': 'Tritech'},
  {'key': 'Shifter', 'value': 'Shifter'},
  {'key': 'Overseer', 'value': 'Overseer'}
];

// List<String> maps = [
//   "PVP GENERIC",
//   "Common Hard Boss",
//   "Common Dungeon",
//   "PvP Rewards",
//   "Safari",
//   "DTB",
//   "BSA",
//   "ROM",
//   "Kharum",
//   "JY 3min Reward",
//   "JY 3rd Side",
//   "JY Gorgar",
//   "JY Gorgar Hard",
//   "JY Ditz Left Side Hard",
//   "JY Ditz",
//   "JY Xessk",
//   "Common Low Boss",
//   "Mission Rewards",
//   "CF 1st encounter",
//   "CF 2nd encounter",
//   "CF Village 1",
//   "CF Village 2",
//   "CF Boss",
//   "CF Boss Extra 1",
//   "CF Boss Extra 2",
//   "AC West",
//   "AC East",
//   "AC Last",
//   "AC Hard",
//   "RH Officers",
//   "RH Zul Thark",
//   "RH Final Master",
//   "BRD Start",
//   "BRD Lan Zealot"
// ];
// 67710

List<String> races = ['Humans', 'Tribes', 'Aliens'];

List<Map<String, String>> maps = [
  {'key': 'Safari', 'value': 'Deadly safari'},
  {'key': 'DTB', 'value': 'Dunetown base'},
  {'key': 'BSA', 'value': 'Bloodsport Arena'},
  {'key': 'ROM', 'value': 'ROM base'},
  {'key': 'AC', 'value': 'Ancient corridors'},
  {'key': 'Kharum', 'value': 'Kharum'},
  {'key': 'JY', 'value': 'Junkyard'},
  {'key': 'CF', 'value': 'Corrupted fields'},
  {'key': 'RH', 'value': "The renegades' hideout"},
  {'key': 'BRD', 'value': 'Bridge of trial'},
];

// "PVP GENERIC"
// "Common Hard Boss"
// "Common Dungeon"
// "PvP Rewards"
// "Safari"
// "DTB"
// "BSA"
// "ROM"
// "Kharum"
// "JY 3min Reward"
// "JY 3rd Side"
// "JY Gorgar"
// "JY Gorgar Hard"
// "JY Ditz Left Side Hard"
// "JY Ditz"
// "JY Xessk"
// "Common Low Boss"
// "Mission Rewards"
// "CF 1st encounter"
// "CF 2nd encounter"
// "CF Village 1"
// "CF Village 2"
// "CF Boss"
// "CF Boss Extra 1"
// "CF Boss Extra 2"
// "AC West"
// "AC East"
// "AC Last"
// "AC Hard"
// "RH Officers"
// "RH Zul Thark"
// "RH Final Master"
// "BRD Start"
// "BRD Lan Zealot"
// "Safari - Queen"
// "Safari - Mech 0"
// "Safari - Jack"
// "Safari - Bill"
// "Safari - Bill Hard"
// "DTB - Cages"
// "DTB - Adam"
// "DTB - Frank"
// "BSA - Horror"
// "BSA - Yamu"
// "BSA - Champions"
// "ROM - HF1337"
// "ROM - Cannon"
// "Kharum - Village"
// "Kharum - Retaliate"
// "Kharum - Device"
// "Kharum - Ulf"
// "BRD Lan Zealot - Hard"

List<int> lootTable = [
  10,
  20,
  30,
  40,
  50,
  60,
  70,
  80,
  90,
  100,
  110,
  120,
  130,
  140,
  150,
  160,
  170,
  180,
  190,
  200,
  210,
  220,
  230,
  240,
  250,
  260,
  270,
  280,
  290,
  300,
  310,
  320,
  330,
  340,
  350,
  360,
  370,
  380,
  390,
  400,
  410,
  420,
  430,
  440,
  450,
  460,
  470
];

List<Map<String, String>> attributeList = [
  {'key': 'psi', 'value': 'Power'},
  {'key': 'hp_gen', 'value': 'Hit Point Generation'},
  {'key': 'psi_gen', 'value': 'Power Generation'},
  {'key': 'expose_target_chance', 'value': 'Expose Chance'},
  {'key': 'expose_target_armor_duration', 'value': 'Expose Duration'},
  {'key': 'crit_chance', 'value': 'Critical Hit Chance'},
  {
    'key': 'rocket_precision_damage_perc',
    'value': 'Concussion Rocket Effectiveness'
  },
  {'key': 'rocket_precision_duration', 'value': 'Concussion Rocket Duration'},
  {'key': 'rocket_precision_chance', 'value': 'Concussion Rocket Chance'},
  {'key': 'rocket_damage', 'value': 'Rocket Damage'},
  {'key': 'inject_hp', 'value': 'Inject Healing'},
  {'key': 'confuse_duration', 'value': 'Confuse Duration'},
  {'key': 'confuse_armor_perc_buff', 'value': 'Confuse Armor Increase'},
  {'key': 'inject_power_cost', 'value': 'Inject Power Cost'},
  {'key': 'confuse_power', 'value': 'Confusion Power Cost'},
  {'key': 'barrage_cost', 'value': 'Barrage Power Cost'},
  {'key': 'nano_fix_power', 'value': 'Nanofix Power Cost'},
  {'key': 'nano_fix_heal', 'value': 'Nanofix Healing'},
  {'key': 'repairdrones_power', 'value': "Repair Drones' Power"},
  {'key': 'repairdrones_heal_radius', 'value': "Repair Drones' Work Radius"},
  {'key': 'repairdrones_repair_per_tick', 'value': "Repair Drones' Healing"},
  {'key': 'overcharge_chance', 'value': 'Overcharge Chance'},
  {'key': 'overcharge_stun_duration', 'value': 'Overcharge Stun Duration'},
  {'key': 'shield_hull', 'value': 'Shield Durability'},
  {'key': 'shield_regen', 'value': 'Shield Generation'},
  {'key': 'shield_fullabsorbchance', 'value': 'Shield Deflection'},
  {'key': 'shield_percentabsorbtion', 'value': 'Shield Mitigation'},
  {'key': 'sweep_damage', 'value': 'Fire Sweep Damage'},
  {'key': 'sweep_power_cost', 'value': 'Fire Sweep Power Cost'},
  {'key': 'discharge_chance', 'value': 'Discharge Chance'},
  {'key': 'proton_shot_damage', 'value': 'Proton Grenade Damage'},
  {'key': 'proton_shot_radius', 'value': 'Proton Grenade Radius'},
  {'key': 'proton_shot_psi', 'value': 'Proton Grenade Power Cost'},
  {'key': 'sweepingfire_duration', 'value': 'Sweeping Fire Duration'},
  {'key': 'sweepingfire_damage_perc', 'value': 'Sweeping Fire Damage Increase'},
  {'key': 'sweepingfire_power', 'value': 'Sweeping Fire Power Cost'},
  {'key': 'rupture_chance', 'value': 'Rupture Chance'},
  {'key': 'rupture_stun_duration', 'value': 'Rupture Stun Duration'},
  {'key': 'bandage_amount', 'value': 'First Aid Healing'},
  {'key': 'bandage_crit', 'value': 'First Aid Crit Chance'},
  {'key': 'bandage_cooldown', 'value': 'First Aid Cooldown'},
  {'key': 'bandage_range', 'value': 'First Aid Range'},
  {'key': 'relief_duration', 'value': 'Relief Cell Duration'},
  {'key': 'relief_healpersec', 'value': 'Relief Cell Healing'},
  {'key': 'relief_psicost', 'value': 'Relief Power Cost'},
  {'key': 'mend_power', 'value': 'Mend Power Cost'},
  {'key': 'mend_heal', 'value': 'Mend Healing'},
  {'key': 'throw_grenade_chance', 'value': 'Grenade Chance'},
  {'key': 'grenade_damage', 'value': 'Grenade Damage'},
  {'key': 'grenade_radius', 'value': 'Grenade Radius'},
  {'key': 'growl_duration', 'value': 'Growl Duration'},
  {'key': 'growl_chance', 'value': 'Growl Chance'},
  {'key': 'ignite_duration', 'value': 'Ignite Duration'},
  {'key': 'whirlwind_chance', 'value': 'Whirlwind Chance'},
  {'key': 'illusion_power_cost', 'value': 'Illusions Power Cost'},
  {'key': 'fortify_power_cost', 'value': 'Fortify Power Cost'},
  {'key': 'fortify_armor_add_perc', 'value': 'Fortify Armor Increase'},
  {'key': 'fortify_armor', 'value': 'Fortify Armor Addition'},
  {'key': 'shift_stun_duration', 'value': 'Shift Stun Duration'},
  {'key': 'holy_aura_heal', 'value': 'Holy Aura Healing'},
  {'key': 'pyrowave_chance', 'value': 'Pyroblast Chance'},
  {'key': 'lightning_power', 'value': 'Lightning Power Cost'},
  {'key': 'lightning_damage', 'value': 'Lightning Damage'},
  {'key': 'holyshock_power', 'value': 'Holy Shock Power Cost'},
  {'key': 'freeze_duration', 'value': 'Freeze Duration'},
  {'key': 'freeze_power', 'value': 'Freeze Power Cost'},
  {'key': 'hollow_voice_chance', 'value': 'Hollow Voice Chance'},
  {'key': 'hollow_voice_damage', 'value': 'Hollow Voice Damage'},
  {'key': 'hollow_voice_area', 'value': 'Hollow Voice Size'},
  {'key': 'death_rumble_chance', 'value': 'Death Rumble Chance'},
  {'key': 'death_rumble_damage', 'value': 'Death Rumble Damage'},
  {'key': 'death_rumble_area', 'value': 'Death Rumble Size'},
  {'key': 'howl_fear_duration', 'value': 'Howl Fear Duration'},
  {'key': 'drain_life_chance', 'value': 'Drain Life Chance'},
  {'key': 'rejuvenation_psicost', 'value': 'Renew Power Cost'},
  {'key': 'rejuvenation_amount', 'value': 'Renew Healing'},
  {'key': 'purify_psicost', 'value': 'Purify Power Cost'},
  {'key': 'chill_psi_cost', 'value': 'Frost Wave Power Cost'},
  {'key': 'chill_duration', 'value': 'Chill Duration'},
  {'key': 'incinerate_psi_cost', 'value': 'Incinerate Power Cost'},
  {'key': 'incinerate_damage', 'value': 'Incinerate Damage'},
  {'key': 'drain_psi_amount', 'value': 'Drain Power Amount'},
  {'key': 'drain_psi_chance', 'value': 'Drain Power Chance'},
  {'key': 'unholy_aura_heal', 'value': 'Unholy Aura Healing'},
  {'key': 'corruption_damage', 'value': 'Corruption Damage'},
  {'key': 'corruption_duration', 'value': 'Corruption Duration'},
  {'key': 'unholy_power_cooldown', 'value': 'Unholy Power Cooldown'},
  {'key': 'chain_shot_chance', 'value': 'Chain Shot Chance'},
  {'key': 'chain_shot_hops', 'value': 'Chain Shot Chains'},
  {'key': 'fear_shock_power', 'value': 'Fear Shock Power Cost'},
  {'key': 'fear_shock_duration', 'value': 'Fear Shock Duration'},
  {'key': 'stasis_shot_chance', 'value': 'Stasis Shot Chance'},
  {'key': 'stasis_shot_duration', 'value': 'Stasis Shot Duration'},
  {'key': 'power_fuse_perc', 'value': 'Power Fuse Effectiveness'},
  {'key': 'power_fuse_area', 'value': 'Power Fuse Range'},
  {'key': 'dimension_chain_duration', 'value': 'Dimension Chain Duration'},
  {'key': 'dimension_chain_power', 'value': 'Dimension Chain Power Cost'},
  {'key': 'dimension_chain_area', 'value': 'Dimension Chain Size'},
  {'key': 'dimension_chain_cooldown', 'value': 'Dimension Chain Cooldown'},
  {'key': 'vitality_surge_gain', 'value': 'Vitality Surge Healing'},
  {'key': 'vitality_surge_power', 'value': 'Vitality Surge Power Cost'},
  {'key': 'harvest_chance', 'value': 'Harvest Chance'},
  {'key': 'harvest_damage', 'value': 'Harvest Damage'},
  {'key': 'harvest_duration', 'value': 'Harvest Duration'},
  {'key': 'harvest_cooldown', 'value': 'Harvest Cooldown'},
  {'key': 'confuse_chance', 'value': 'Imminence Chance'},
  {'key': 'vortex_power', 'value': 'Vortex Power Cost'},
  {'key': 'vortex_heal', 'value': 'Vortex Healing'},
  {'key': 'feed_psi_cost', 'value': 'Feed Power Cost'},
  {'key': 'feed_base', 'value': 'Feed Strength'},
  {'key': 'nether_nova_psi_cost', 'value': 'Nether Nova Power Cost'},
  {'key': 'nether_nova_radius', 'value': 'Nether Nova Size'},
  {'key': 'nether_nova_damage', 'value': 'Nether Nova Damage'},
  {'key': 'charging_field_area', 'value': 'Charging Field Size'},
  {
    'key': 'charging_field_psi_perc',
    'value': 'Charging Field Power Generation'
  },
  {'key': 'breed_power', 'value': 'Breed Power Cost'},
  {'key': 'enfeeble_chance', 'value': 'Enfeeble Chance'},
  {
    'key': 'enfeeble_damage_reduction_perc',
    'value': 'Enfeeble Damage Reduction'
  },
  {'key': 'enfeeble_duration', 'value': 'Enfeeble Duration'},
  {'key': 'power_leak_chance', 'value': 'Power Leak Chance'},
  {'key': 'power_leak_drain', 'value': 'Power Leak Drain'},
  {'key': 'feedback_chance', 'value': 'Feedback Chance'},
  {'key': 'feedback_heal', 'value': 'Feedback Heal'},
  {'key': 'healing_taken_mod', 'value': 'Healing Taken'},
  {'key': 'life_leech_boost', 'value': 'Life Leech Rate'},
  {'key': 'hp', 'value': 'Hit Points'},
  {'key': 'armor', 'value': 'Armor'},
  {'key': 'damage', 'value': 'Damage'},
  {'key': 'drain_life_boost', 'value': 'Drain Life Rate'},
];

Map<String, String> attributeFilter = {
  'Power': 'psi',
  'Hit Point Generation': 'hp_gen',
  'Power Generation': 'psi_gen',
  'Expose Chance': 'expose_target_chance',
  'Expose Duration': 'expose_target_armor_duration',
  'Critical Hit Chance': 'crit_chance',
  'Concussion Rocket Effectiveness': 'rocket_precision_damage_perc',
  'Concussion Rocket Duration': 'rocket_precision_duration',
  'Concussion Rocket Chance': 'rocket_precision_chance',
  'Rocket Damage': 'rocket_damage',
  'Inject Healing': 'inject_hp',
  'Confuse Duration': 'confuse_duration',
  'Confuse Armor Increase': 'confuse_armor_perc_buff',
  'Inject Power Cost': 'inject_power_cost',
  'Confusion Power Cost': 'confuse_power',
  'Barrage Power Cost': 'barrage_cost',
  'Nanofix Power Cost': 'nano_fix_power',
  'Nanofix Healing': 'nano_fix_heal',
  "Repair Drones' Power": 'repairdrones_power',
  "Repair Drones' Work Radius": 'repairdrones_heal_radius',
  "Repair Drones' Healing": 'repairdrones_repair_per_tick',
  'Overcharge Chance': 'overcharge_chance',
  'Overcharge Stun Duration': 'overcharge_stun_duration',
  'Shield Durability': 'shield_hull',
  'Shield Generation': 'shield_regen',
  'Shield Deflection': 'shield_fullabsorbchance',
  'Shield Mitigation': 'shield_percentabsorbtion',
  'Fire Sweep Damage': 'sweep_damage',
  'Fire Sweep Power Cost': 'sweep_power_cost',
  'Discharge Chance': 'discharge_chance',
  'Proton Grenade Damage': 'proton_shot_damage',
  'Proton Grenade Radius': 'proton_shot_radius',
  'Proton Grenade Power Cost': 'proton_shot_psi',
  'Sweeping Fire Duration': 'sweepingfire_duration',
  'Sweeping Fire Damage Increase': 'sweepingfire_damage_perc',
  'Sweeping Fire Power Cost': 'sweepingfire_power',
  'Rupture Chance': 'rupture_chance',
  'Rupture Stun Duration': 'rupture_stun_duration',
  'First Aid Healing': 'bandage_amount',
  'First Aid Crit Chance': 'bandage_crit',
  'First Aid Cooldown': 'bandage_cooldown',
  'First Aid Range': 'bandage_range',
  'Relief Cell Duration': 'relief_duration',
  'Relief Cell Healing': 'relief_healpersec',
  'Relief Power Cost': 'relief_psicost',
  'Mend Power Cost': 'mend_power',
  'Mend Healing': 'mend_heal',
  'Grenade Chance': 'throw_grenade_chance',
  'Grenade Damage': 'grenade_damage',
  'Grenade Radius': 'grenade_radius',
  'Growl Duration': 'growl_duration',
  'Growl Chance': 'growl_chance',
  'Ignite Duration': 'ignite_duration',
  'Whirlwind Chance': 'whirlwind_chance',
  'Illusions Power Cost': 'illusion_power_cost',
  'Fortify Power Cost': 'fortify_power_cost',
  'Fortify Armor Increase': 'fortify_armor_add_perc',
  'Fortify Armor Addition': 'fortify_armor',
  'Shift Stun Duration': 'shift_stun_duration',
  'Holy Aura Healing': 'holy_aura_heal',
  'Pyroblast Chance': 'pyrowave_chance',
  'Lightning Power Cost': 'lightning_power',
  'Lightning Damage': 'lightning_damage',
  'Holy Shock Power Cost': 'holyshock_power',
  'Freeze Duration': 'freeze_duration',
  'Freeze Power Cost': 'freeze_power',
  'Hollow Voice Chance': 'hollow_voice_chance',
  'Hollow Voice Damage': 'hollow_voice_damage',
  'Hollow Voice Size': 'hollow_voice_area',
  'Death Rumble Chance': 'death_rumble_chance',
  'Death Rumble Damage': 'death_rumble_damage',
  'Death Rumble Size': 'death_rumble_area',
  'Howl Fear Duration': 'howl_fear_duration',
  'Drain Life Chance': 'drain_life_chance',
  'Renew Power Cost': 'rejuvenation_psicost',
  'Renew Healing': 'rejuvenation_amount',
  'Purify Power Cost': 'purify_psicost',
  'Frost Wave Power Cost': 'chill_psi_cost',
  'Chill Duration': 'chill_duration',
  'Incinerate Power Cost': 'incinerate_psi_cost',
  'Incinerate Damage': 'incinerate_damage',
  'Drain Power Amount': 'drain_psi_amount',
  'Drain Power Chance': 'drain_psi_chance',
  'Unholy Aura Healing': 'unholy_aura_heal',
  'Corruption Damage': 'corruption_damage',
  'Corruption Duration': 'corruption_duration',
  'Unholy Power Cooldown': 'unholy_power_cooldown',
  'Chain Shot Chance': 'chain_shot_chance',
  'Chain Shot Chains': 'chain_shot_hops',
  'Fear Shock Power Cost': 'fear_shock_power',
  'Fear Shock Duration': 'fear_shock_duration',
  'Stasis Shot Chance': 'stasis_shot_chance',
  'Stasis Shot Duration': 'stasis_shot_duration',
  'Power Fuse Effectiveness': 'power_fuse_perc',
  'Power Fuse Range': 'power_fuse_area',
  'Dimension Chain Duration': 'dimension_chain_duration',
  'Dimension Chain Power Cost': 'dimension_chain_power',
  'Dimension Chain Size': 'dimension_chain_area',
  'Dimension Chain Cooldown': 'dimension_chain_cooldown',
  'Vitality Surge Healing': 'vitality_surge_gain',
  'Vitality Surge Power Cost': 'vitality_surge_power',
  'Harvest Chance': 'harvest_chance',
  'Harvest Damage': 'harvest_damage',
  'Harvest Duration': 'harvest_duration',
  'Harvest Cooldown': 'harvest_cooldown',
  'Imminence Chance': 'confuse_chance',
  'Vortex Power Cost': 'vortex_power',
  'Vortex Healing': 'vortex_heal',
  'Feed Power Cost': 'feed_psi_cost',
  'Feed Strength': 'feed_base',
  'Nether Nova Power Cost': 'nether_nova_psi_cost',
  'Nether Nova Size': 'nether_nova_radius',
  'Nether Nova Damage': 'nether_nova_damage',
  'Charging Field Size': 'charging_field_area',
  'Charging Field Power Generation': 'charging_field_psi_perc',
  'Breed Power Cost': 'breed_power',
  'Enfeeble Chance': 'enfeeble_chance',
  'Enfeeble Damage Reduction': 'enfeeble_damage_reduction_perc',
  'Enfeeble Duration': 'enfeeble_duration',
  'Power Leak Chance': 'power_leak_chance',
  'Power Leak Drain': 'power_leak_drain',
  'Feedback Chance': 'feedback_chance',
  'Feedback Heal': 'feedback_heal',
  'Healing Taken': 'healing_taken_mod',
  'Life Leech Rate': 'life_leech_boost',
  'Hit Points': 'hp',
  'Armor': 'armor',
  'Damage': 'damage',
  'Drain Life Rate': 'drain_life_boost',
};

//// Generic item descriptions	',
List<Map<String, String>> slots = [
  {
    'key': 'ALIEN_MASTER',
    'value': 'Master',
    'description': 'This item improves the statistics of your Master.'
  },
  {
    'key': 'ALIEN_ARBITER',
    'value': 'Arbiter',
    'description': 'This item improves the statistics of your Arbiters.'
  },
  {
    'key': 'ALIEN_DOMINATOR',
    'value': 'Dominator',
    'description': 'This item improves the statistics of your Dominators.'
  },
  {
    'key': 'ALIEN_HARVESTER',
    'value': 'Harvester',
    'description': 'This item improves the statistics of your Harvesters.'
  },
  {
    'key': 'ALIEN_MANIPULATOR',
    'value': 'Manipulator',
    'description': 'This item improves the statistics of your Manipulators.'
  },
  {
    'key': 'ALIEN_POWER',
    'value': 'Power',
    'description':
        'This item is related to Power, one of the aspects of the Cult.'
  },
  {
    'key': 'ALIEN_CORRUPTION',
    'value': 'Corruption',
    'description':
        'This item is related to Corruption, one of the aspects of the Cult.'
  },
  {
    'key': 'ALIEN_DOGMA',
    'value': 'Dogma',
    'description':
        'This item is related to Dogma, one of the aspects of the Cult.'
  },
  {
    'key': 'HUMAN_COMMANDER',
    'value': 'Lord Commander',
    'description': 'This item improves the statistics of your Lord Commander.'
  },
  {
    'key': 'HUMAN_ASSASSIN',
    'value': 'Assassin',
    'description': 'This item improves the statistics of your Assassins.'
  },
  {
    'key': 'HUMAN_CONSTRUCTOR',
    'value': 'Constructor',
    'description': 'This item improves the statistics of your Constructors.'
  },
  {
    'key': 'HUMAN_JUDGE',
    'value': 'Judge',
    'description': 'This item improves the statistics of your Judges.'
  },
  {
    'key': 'HUMAN_SURGEON',
    'value': 'Surgeon',
    'description': 'This item improves the statistics of your Surgeons.'
  },
  {
    'key': 'HUMAN_DEFENCE',
    'value': 'Xenotronics',
    'description':
        'This item is related to Xenotronics, one of the scientific disciplines of the Humans.'
  },
  {
    'key': 'HUMAN_IMPLANTS',
    'value': 'Nanotechnology',
    'description':
        'This item is related to Nanotechnology, one of the scientific disciplines of the Humans.'
  },
  {
    'key': 'HUMAN_WEAPONS',
    'value': 'Metachemistry',
    'description':
        'This item is related to Metachemistry, one of the scientific disciplines of the Humans.'
  },
  {
    'key': 'MUTANT_HIGHPRIEST',
    'value': 'High Priest',
    'description': 'This item improves the statistics of your High Priest.'
  },
  {
    'key': 'MUTANT_ADEPT',
    'value': 'Sorcerer',
    'description': 'This item improves the statistics of your Sorcerers.'
  },
  {
    'key': 'MUTANT_GUARDIAN',
    'value': 'Guardian',
    'description': 'This item improves the statistics of your Guardians.'
  },
  {
    'key': 'MUTANT_SHAMAN',
    'value': 'Shaman',
    'description': 'This item improves the statistics of your Shamans.'
  },
  {
    'key': 'MUTANT_STONEGHOST',
    'value': 'Stone Ghost',
    'description': 'This item improves the statistics of your Stone Ghosts.'
  },
  {
    'key': 'MUTANT_BLOOD',
    'value': 'Blood',
    'description':
        'This item is related to Blood, one of the aspects of the Tribes.'
  },
  {
    'key': 'MUTANT_MIND',
    'value': 'Mind',
    'description':
        'This item is related to Mind, one of the aspects of the Tribes.'
  },
  {
    'key': 'MUTANT_NATURE',
    'value': 'Nature',
    'description':
        'This item is related to Nature, one of the aspects of the Tribes.'
  },
];
