import Vocabulary exposing [Rgb, Vec3]

## Builds the Lights that your game puts in `Scene.nodes` with the `Light` tag.
## A colour carries its intensity and can exceed 1.
Light := [].{

	## Light from all directions.
	ambient : Rgb -> Vocabulary.Light
	ambient = |color| Ambient(color)

	## Light that travels along `dir` and casts no shadow.
	directional : Vec3, Rgb -> Vocabulary.Light
	directional = |dir, color| Directional({ dir, color, shadow: False })

	## A Directional light that casts a shadow. Only the first one in a
	## depth-first walk of `Scene.nodes` casts a shadow.
	sun : Vec3, Rgb -> Vocabulary.Light
	sun = |dir, color| Directional({ dir, color, shadow: True })

	## Light from `pos` that falls off to zero at `range`.
	point : Vec3, Rgb, F32 -> Vocabulary.Light
	point = |pos, color, range| Point({ pos, color, range })

	## Light from `pos` along `dir` in a cone, falling off to zero at `range`.
	## `cone` is the half angle of its edge in radians, and the light softens
	## over the outer fifth of it.
	spot : Vec3, Vec3, Rgb, F32, F32 -> Vocabulary.Light
	spot = |pos, dir, color, range, cone| Spot({ pos, dir, color, range, inner: 0.8 * cone, outer: cone, shadow: False })

	## A Spot that casts a shadow, while `Launch.shadow_spots` has room for
	## it: the first ones in Scene order cast. Its `cone` should be under
	## about 1.4, since one map covers it.
	shadowed_spot : Vec3, Vec3, Rgb, F32, F32 -> Vocabulary.Light
	shadowed_spot = |pos, dir, color, range, cone| Spot({ pos, dir, color, range, inner: 0.8 * cone, outer: cone, shadow: True })
}

grey : Rgb
grey = { r: 0.1, g: 0.1, b: 0.1 }

expect Light.ambient(grey) == Ambient(grey)
expect Light.directional({ x: 0.0, y: -1.0, z: 0.0 }, grey) == Directional({ dir: { x: 0.0, y: -1.0, z: 0.0 }, color: grey, shadow: False })
expect Light.sun({ x: 0.0, y: -1.0, z: 0.0 }, grey) == Directional({ dir: { x: 0.0, y: -1.0, z: 0.0 }, color: grey, shadow: True })
expect Light.point({ x: 1.0, y: 2.0, z: 3.0 }, grey, 6.0) == Point({ pos: { x: 1.0, y: 2.0, z: 3.0 }, color: grey, range: 6.0 })
expect Light.spot({ x: 1.0, y: 2.0, z: 3.0 }, { x: 0.0, y: -1.0, z: 0.0 }, grey, 6.0, 0.5) == Spot({ pos: { x: 1.0, y: 2.0, z: 3.0 }, dir: { x: 0.0, y: -1.0, z: 0.0 }, color: grey, range: 6.0, inner: 0.4, outer: 0.5, shadow: False })
