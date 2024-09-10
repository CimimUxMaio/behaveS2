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
		behaviour = "src/behaviour/init.lua",
		["behaviour.physicsbody"] = "src/behaviour/physicsbody.lua",
		camera = "src/camera.lua",
		entity = "src/entity.lua",
		game = "src/game.lua",
		grid = "src/grid.lua",
		["utils.math"] = "src/utils/math.lua",
	},
}
