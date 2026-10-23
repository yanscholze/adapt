--!strict
return {
	SchemaVersion = 2,
	DataStoreName = "ADAPT_Profile_v1",
	-- Keep Studio separate from live saves. Explicitly enable to test API persistence.
	StudioPersistence = false,
	AutosaveSeconds = 60,
	SessionLeaseSeconds = 180,
	AdminUserIds = {} :: { number },
	AnalyticsEnabled = false,
	WalkSpeed = 20,
	JumpPower = 42,
	CollectRadius = 6,
	SpawnProtectionSeconds = 6,
	MaxBankedEnergy = 5000,
	Ability = { GlideSpeed = 34, GlideFallSpeed = 9, GlideSeconds = 9, ClimbSpeed = 12, ClimbSeconds = 6, WallDistance = 4.5, InputTimeout = 0.8 },
	Guardian = { MaxHealth = 120, Damage = 18, AttackRange = 13, ArenaRange = 28, AttackCooldown = 2.4, Windup = 0.85, Reward = 45, RespawnSeconds = 35, PlayerDamage = 16, PlayerRange = 14, PlayerCooldown = 0.55 },
	Remotes = { "State", "Feedback", "Choose", "Ability", "Attack", "RequestState", "Codex", "Setting", "Debug", "Journey", "Equip", "Travel" },
}
