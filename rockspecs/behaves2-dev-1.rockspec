rockspec_format = "3.0"
package = "behaveS2"
version = "dev-1"
source = {
	url = "git+https://github.com/CimimUxMaio/behaveS2.git",
}
description = {
	summary = "Create dynamic entities and attach customizable behaviors to them, making it easy to develop complex game mechanics in a modular, reusable way.",
	detailed = [[
Create dynamic entities and attach customizable behaviors to them, making it easy to develop complex game mechanics in a modular, reusable way. Behave helps you keep your game architecture clean while seamlessly integrating with LOVE2D's rendering, physics, and input systems.
]],
	homepage = "https://github.com/CimimUxMaio/behaveS2",
	license = "MIT",
}
dependencies = {
	"lua == 5.1",
	"oopsie",
}
build = {
	type = "builtin",
	modules = {
		["behaves2.behaviour.init"] = "src/behaves2/behaviour/init.lua",
		["behaves2.behaviour.physicsbody"] = "src/behaves2/behaviour/physicsbody.lua",
		["behaves2.entity"] = "src/behaves2/entity.lua",
		["behaves2.game"] = "src/behaves2/game.lua",
		["behaves2.utils.math"] = "src/behaves2/utils/math.lua",
	},
}
test_dependencies = {
	"busted",
}
test = {
	type = "busted",
}
