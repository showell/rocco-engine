app [init, launch, loaded, step, view] { cam: "../../packages/camera/main.roc", mesh: "../../packages/mesh/main.roc", pf: platform "../../platform/main.roc", roc: "0.1.0-rc1" }

## Two Spot lights over a few shapes on a floor, each casting its shadow:
## a warm one from the left and a cool one from the right, so every shape
## throws two shadows, one away from each lamp, inside each lamp's cone. A
## dim ambient and no Sun, so the cones and their shadows carry the
## picture. The Launch keeps room for two Spot shadows beside the one
## cascade.

import cam.Camera as Cam
import mesh.Mesh as Mesh
import pf.Config
import pf.Draw
import pf.Launch
import pf.Light
import pf.Scene
import pf.Vocabulary exposing [Command, Manifest]

Model : { cube : U32, sphere : U32, plane : U32, cylinder : U32 }

launch : Vocabulary.Config -> Vocabulary.Launch
launch = |_config| { ..Launch.default, window: { ..Launch.default.window, title: "Spot shadows", width: 800, height: 600 }, shadow_spots: 2 }

init : Vocabulary.Config -> { model : Model, commands : List(Command) }
init = |_config| {
	model = { cube: Mesh.primitive(Cube), sphere: Mesh.primitive(Sphere), plane: Mesh.primitive(Plane), cylinder: Mesh.primitive(Cylinder) }
	{ model, commands: [] }
}

loaded : Model, Str, Manifest -> Model
loaded = |model, _pack, _manifest| model

step : Model, Vocabulary.Input, Vocabulary.QueryResults, F32 -> { model : Model, commands : List(Command) }
step = |model, _input, _results, _dt| { model, commands: [] }

## The two lamps: above and to each side, pointing down and in at the
## shapes.
warm_lamp : Vocabulary.Light
warm_lamp = Light.shadowed_spot({ x: -2.5, y: 4.0, z: 1.0 }, { x: 0.45, y: -1.0, z: -0.2 }, { r: 30.0, g: 20.0, b: 10.0 }, 12.0, 0.55)

cool_lamp : Vocabulary.Light
cool_lamp = Light.shadowed_spot({ x: 2.5, y: 4.0, z: 1.0 }, { x: -0.45, y: -1.0, z: -0.2 }, { r: 10.0, g: 16.0, b: 30.0 }, 12.0, 0.55)

view : Model -> Vocabulary.Scene
view = |model| {
	ground = { ..Draw.default, id: 1, mesh: model.plane, scale: { x: 10.0, y: 1.0, z: 8.0 }, tint: { r: 0.6, g: 0.6, b: 0.6 } }
	cube = { ..Draw.default, id: 2, mesh: model.cube, pos: { x: -1.0, y: 0.5, z: 0.0 }, tint: { r: 0.9, g: 0.3, b: 0.1 } }
	sphere = { ..Draw.default, id: 3, mesh: model.sphere, pos: { x: 0.6, y: 0.5, z: -0.4 }, tint: { r: 0.3, g: 0.6, b: 0.9 } }
	post = { ..Draw.default, id: 4, mesh: model.cylinder, pos: { x: 0.0, y: 1.0, z: -1.6 }, scale: { x: 0.3, y: 2.0, z: 0.3 }, tint: { r: 0.4, g: 0.8, b: 0.4 } }
	{
		..Scene.empty,
		camera: Cam.look_at({ x: 0.0, y: 4.5, z: 6.5 }, { x: 0.0, y: 0.5, z: -0.5 }),
		nodes: [
			Light(Light.ambient({ r: 0.06, g: 0.06, b: 0.07 })),
			Light(warm_lamp),
			Light(cool_lamp),
			Draw(ground),
			Draw(cube),
			Draw(sphere),
			Draw(post),
		],
	}
}

expect launch(Config.empty).shadow_spots == 2

expect view(init(Config.empty).model).nodes.len() == 7

expect match warm_lamp {
	Spot(s) => s.shadow
	_ => Bool.False
}
