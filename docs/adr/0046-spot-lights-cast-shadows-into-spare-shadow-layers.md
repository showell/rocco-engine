# 0046: Spot lights cast shadows into spare shadow-map layers

Status: accepted, 2026-11-24. Built for Milestone 44 (gml8qg4r), task
6ywwf194, without its grilling.

## Context

Only the Sun casts a shadow, in 1 to 4 cascades (ADR 0014, Milestone 33).
Task 6ywwf194, "More than one shadow caster", is open under Milestone 44
and blocked in dex by the virtual shadow map research (68cd3o1w). It asks
for a grilling before the work.

Steve Howell, who keeps the fork this comes from, works by one rule for
open dex tasks: "We don't need permission to add anything that's still
open on dex. We can just do it. We should just be good at keeping commits
organized." So this lands ahead of the research and the grilling, as the
smallest version a game can use, and the research can still replace it.

A Point Light shadow needs six maps, a cube, or more passes. A Spot needs
one perspective map, and a lamp over a table or a bar is a Spot. The
shadow map is already an array texture with one layer a cascade, drawn by a
depth-only pipeline that takes any view and projection.

## Decision

- Light gets a `Spot` tag: `pos`, `dir`, `color`, `range`, `inner` and
  `outer` half angles in radians, and `shadow`. `Light.spot` and
  `Light.shadowed_spot` build one; the inner edge sits at 0.8 of the cone.
- Spots share the clustered light buffer with Points. Each light grows
  from 32 to 64 bytes for its direction and the cosines of its cone. A
  Point's direction is zero, which the shader reads as no cone.
- Launch gets `shadow_spots`, 0 by default. `shadow_cascades` and
  `shadow_spots` together are at most 4, the existing `MAX_CASCADES`. The
  array gets one layer for each, after the cascades.
- The first Spots in Scene order that set `shadow` cast, up to
  `shadow_spots`. Each draws one perspective view, reversed-Z out to its
  range, through the existing depth-only shadow pipeline, with only the
  casters whose box reaches into that view.
- A Spot's map is read with one tap, its 2 x 2 hardware compare, whatever
  the Scene's filter: each Spot costs every pixel it lights, and its map's
  texels are small beside a cascade's.
- `basic.glsl` samples up to four Spot layers before its light loop, under
  branches on uniforms only, so D3D keeps uniform control flow around
  SampleCmp. A Spot's lane rides in its light's cone vector.
- The count of casting Spots and their first layer use two lanes the light
  uniforms did not use (`shadow.y`, once the Sun's slot, always 0, and
  `fog_ramp.w`), so the block stays at 512 bytes.

## Considered options

- A `shadow` flag on `Point`, with cube maps. Rejected for now: six passes
  a light, and every game that builds a `Point` record would change.
- A Scene field naming which Points cast. Rejected: it changes `Shadow`
  and still needs cube maps.
- Choosing the casting Spots by distance or brightness. Deferred: Scene
  order is predictable and a game can order its lights.
- A larger light uniform block. Rejected: the renderer reserves 512 bytes
  for it.

## Consequences

- No pipeline or shader module is added. A Spot shadow costs one shadow
  pass and one layer of the shadow map.
- A Spot's map covers its cone, so a cone near 180 degrees gets a coarse
  shadow. The builder's note asks for a half angle under about 1.4.
- `examples/spot-shadows` draws two shadowed Spots with no Sun.
- The virtual shadow map research (68cd3o1w) and Point Light shadows stay
  open under Milestone 44.
