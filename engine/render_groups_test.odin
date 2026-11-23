#+test
package engine

import "core:testing"

// A run with no group words leaves nothing out, so every game draws as before.
@(test)
test_render_groups_from_args_leaves_out_only_what_is_named :: proc(t: ^testing.T) {
	testing.expect_value(t, render_groups_from_args({}), Render_Groups{})
	testing.expect_value(t, render_groups_from_args({"", "grass=0", "shadows=1"}), Render_Groups{})
	testing.expect_value(t, render_groups_from_args({"", "shadows=0", "skinned=0"}), Render_Groups{.Shadows, .Skinned})
	testing.expect_value(t, render_groups_from_args({"", "bloom=0", "pipelines=min"}), RENDER_GROUPS_ALL)
}
