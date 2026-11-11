///The icon_state for space.  There is 25 total icon states that vary based on the x/y/z position of the turf
#define SPACE_ICON_STATE	"[((x + y) ^ ~(x * y) + z) % 25]"

GLOBAL_LIST_EMPTY(in_space_moveables) // TODO - move by area not by turf??
