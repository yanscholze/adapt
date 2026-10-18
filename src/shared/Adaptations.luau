--!strict
export type Definition = {
	id: string, displayName: string, description: string, rarity: string, slot: string,
	visualData: { kind: string, color: { number }, scale: number },
	abilityData: { kind: string, speedMultiplier: number, durationMultiplier: number },
	requirements: { minLevel: number }, tags: { string }, synergyTags: { string },
}
local definitions: { [string]: Definition } = {
	Wings = { id = "Wings", displayName = "Wings", description = "Abra asas de cristal. Plane até a ilha no céu.", rarity = "Common", slot = "Back", visualData = { kind = "Wings", color = { 139, 164, 255 }, scale = 1 }, abilityData = { kind = "Glide", speedMultiplier = 1, durationMultiplier = 1 }, requirements = { minLevel = 0 }, tags = { "aerial" }, synergyTags = { "aerial" } },
	GripClaws = { id = "GripClaws", displayName = "Grip Claws", description = "Garras de âmbar. Escale paredes com marcas douradas.", rarity = "Common", slot = "Arms", visualData = { kind = "Claws", color = { 255, 194, 91 }, scale = 1 }, abilityData = { kind = "Climb", speedMultiplier = 1, durationMultiplier = 1 }, requirements = { minLevel = 0 }, tags = { "vertical" }, synergyTags = { "grip" } },
	NightEyes = { id = "NightEyes", displayName = "Night Eyes", description = "Olhos bioluminescentes. Revele a essência da caverna.", rarity = "Common", slot = "Head", visualData = { kind = "Eyes", color = { 101, 255, 205 }, scale = 1 }, abilityData = { kind = "NightVision", speedMultiplier = 1, durationMultiplier = 1 }, requirements = { minLevel = 0 }, tags = { "perception" }, synergyTags = { "night" } },
	DawnSails = { id = "DawnSails", displayName = "Dawn Sails", description = "Asas rosadas: plane mais rápido, por menos tempo. Substitui Wings.", rarity = "Rare", slot = "Back", visualData = { kind = "Wings", color = { 255, 133, 177 }, scale = 1.2 }, abilityData = { kind = "Glide", speedMultiplier = 1.15, durationMultiplier = 0.85 }, requirements = { minLevel = 1 }, tags = { "aerial" }, synergyTags = { "aerial" } },
	StoneHooks = { id = "StoneHooks", displayName = "Stone Hooks", description = "Garras violetas: escale mais devagar, por mais tempo. Substitui Grip Claws.", rarity = "Rare", slot = "Arms", visualData = { kind = "Claws", color = { 189, 155, 255 }, scale = 1.25 }, abilityData = { kind = "Climb", speedMultiplier = 0.85, durationMultiplier = 1.35 }, requirements = { minLevel = 1 }, tags = { "vertical" }, synergyTags = { "grip" } },
	EchoEyes = { id = "EchoEyes", displayName = "Echo Eyes", description = "Olhos de coral: uma nova assinatura para enxergar o oculto. Substitui Night Eyes.", rarity = "Rare", slot = "Head", visualData = { kind = "Eyes", color = { 255, 170, 122 }, scale = 1.2 }, abilityData = { kind = "NightVision", speedMultiplier = 1, durationMultiplier = 1 }, requirements = { minLevel = 1 }, tags = { "perception" }, synergyTags = { "night" } },
}
return definitions
