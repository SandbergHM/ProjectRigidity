extends Node
class_name globals

#region constants
# Highlight outline color constants
const COLOR_RED = Color(1.0, 0.0, 0.0,1.0)
const COLOR_GREEN = Color(0.0, 1.0, 0.0, 1.0)
const COLOR_BLUE = Color(0.0, 0.0, 1.0, 1.0)
const COLOR_YELLOW = Color(1.0, 1.0, 0.0, 1.0)
const COLOR_CYAN = Color(0.0, 1.0, 1.0, 1.0)
const COLOR_MAGENTA = Color(1.0, 0.0, 1.0, 1.0)
const COLOR_WHITE = Color(1.0, 1.0, 1.0, 1.0)

# Physics constants for object interactions such as gravity and terminal velocity
const FALL_ACCELLERATION = 9.8
const TERMINAL_VELOCITY = -50.0
#endregion

#region enums
enum Player_state {
	DEAD,
	IDLE,
	JUMP,
	LIFT,
	FALL,
	RUN,
	SPRINT
}
#endregion
