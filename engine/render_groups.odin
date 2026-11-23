package engine

import sg "../sokol-odin/sokol/gfx"
import "system"

// The URL words (system.args) that leave a group out, and `pipelines=min`,
// which leaves out every group.
RENDER_GROUP_WORDS :: [Render_Group]string {
	.Shadows   = "shadows=0",
	.Bloom     = "bloom=0",
	.Skinned   = "skinned=0",
	.Coverage  = "coverage=0",
	.Particles = "particles=0",
	.Ui        = "ui=0",
}
RENDER_GROUPS_ALL :: Render_Groups{.Shadows, .Bloom, .Skinned, .Coverage, .Particles, .Ui}
// The Launch.programs field that names each group a game may leave out.
RENDER_GROUP_FIELDS :: [Render_Group]string {
	.Shadows   = "",
	.Bloom     = "",
	.Skinned   = "",
	.Coverage  = "coverage",
	.Particles = "particles",
	.Ui        = "ui",
}

// Groups of the renderer's GPU programs. A group left out makes no shader
// and no pipeline: each of its pipelines is only allocated, never made, so
// the browser compiles none of it. A game leaves out a group it never draws
// with Launch.programs, and a Frame that needs one then ends the run. A
// game's command line, on the web the page's URL query, can leave out any
// group, to measure what compiling it costs a browser before the first
// frame; sokol then skips every draw that applies one of its pipelines. The
// words are for measuring a game that draws nothing of the group, not for
// play.
Render_Group :: enum {
	Shadows,
	Bloom,
	Skinned,
	Coverage,
	Particles,
	Ui,
}
Render_Groups :: bit_set[Render_Group]

// The groups this run leaves out, read once at renderer_init: those the
// Launch declines, and those the command line leaves out.
g_render_omitted: Render_Groups
g_render_declined: Render_Groups

render_groups_from_args :: proc(args: []string) -> (omitted: Render_Groups) {
	for word in args {
		if word == "pipelines=min" { return RENDER_GROUPS_ALL }
		for group_word, group in RENDER_GROUP_WORDS {
			if word == group_word { omitted += {group} }
		}
	}
	return
}

render_groups_declined :: proc(programs: Programs) -> (declined: Render_Groups) {
	if !programs.coverage { declined += {.Coverage} }
	if !programs.particles { declined += {.Particles} }
	if !programs.ui { declined += {.Ui} }
	return
}

// A shader of the groups, or none when the run leaves any of them out.
render_shader :: proc(groups: Render_Groups, desc: sg.Shader_Desc) -> sg.Shader {
	if groups & g_render_omitted != {} { return {} }
	return sg.make_shader(desc)
}

// A pipeline of the groups. When the run leaves any of them out, the handle
// is allocated and never made: the browser compiles nothing, and its state
// never becomes valid, so sokol skips the draws that apply it.
render_pipeline :: proc(groups: Render_Groups, desc: sg.Pipeline_Desc) -> sg.Pipeline {
	if groups & g_render_omitted != {} { return sg.alloc_pipeline() }
	return sg.make_pipeline(desc)
}

// A Frame is about to draw with the group. A group the Launch declined ends
// the run, so a game never loses a pass to its Launch without being told.
render_group_needed :: proc(group: Render_Group) {
	if group not_in g_render_declined { return }
	fields := RENDER_GROUP_FIELDS
	system.eprintfln("Launch.programs.%v is False, but a Frame draws with it, so the run ends", fields[group])
	system.exit(1)
}
