package = "behaveS2"
version = "dev-1"
source = {
	url = "git+https://github.com/CimimUxMaio/behaveS2.git",
}
description = {
	summary = "Behave is a Lua framework designed to extend the LOVE2D game framework with a powerful entity-behaviour system.",
	detailed = [[
Create dynamic entities and attach customizable behaviors to them, making it easy to develop complex game mechanics in a modular, reusable way. Behave helps you keep your game architecture clean while seamlessly integrating with LOVE2D's rendering, physics, and input systems.
]],
	homepage = "https://github.com/CimimUxMaio/behaveS2",
	license = "MIT",
}

build = {
	type = "builtin",
	modules = {
		["behaves2.behaviour"] = "src/behaviour/init.lua",
		["behaves2.behaviour.physicsbody"] = "src/behaviour/physicsbody.lua",
		["behaves2.camera"] = "src/camera.lua",
		["behaves2.entity"] = "src/entity.lua",
		["behaves2.game"] = "src/game.lua",
		["behaves2.grid"] = "src/grid.lua",
		["behaves2.utils.math"] = "src/utils/math.lua",
	},
}
