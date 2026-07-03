return {
	Oak = {
		Name = "Oak",

		MaxLength = 10,
		MaxTrunkRadius = 1,

		MaxLeafLength = 3,
		MaxLeafRadius = 5,

		LeafMultiplier = 1.00,
		LengthMultiplier = 0.8,
		TrunkRadiusMultiplier = 1,

		LeafMaterial = Enum.Material.Grass,
		LeafColour = Color3.fromRGB(18, 82, 28),
		leafTransparency = 0,

		BarkMaterial = Enum.Material.Concrete,
		BarkColour = Color3.fromRGB(101, 67, 33),

		PlankMaterial = Enum.Material.Wood,
		PlankColour = Color3.fromRGB(255, 168, 81),

		MaxSubBranches = 3,

		LengthMode = "Exponential",
		ChildrenMode = "Exponential",
		ChildrenLimit = 3,
	},
}
