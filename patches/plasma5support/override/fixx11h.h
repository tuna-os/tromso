#pragma once
/* Stub fixx11h.h — for Wayland-only builds without KDE's X11 compat layer.
 * The real fixx11h.h undefines X11 macros that collide with C++ identifiers.
 * These macros are not present here, so the stubs are intentional no-ops. */
#ifdef None
#undef None
#endif
#ifdef Bool
#undef Bool
#endif
#ifdef Status
#undef Status
#endif
#ifdef Cursor
#undef Cursor
#endif
#ifdef KeyPress
#undef KeyPress
#endif
#ifdef KeyRelease
#undef KeyRelease
#endif
#ifdef FocusIn
#undef FocusIn
#endif
#ifdef FocusOut
#undef FocusOut
#endif
#ifdef FontChange
#undef FontChange
#endif
#ifdef Expose
#undef Expose
#endif
#ifdef Unsorted
#undef Unsorted
#endif
#ifdef Always
#undef Always
#endif
#ifdef Success
#undef Success
#endif
#ifdef Above
#undef Above
#endif
#ifdef Below
#undef Below
#endif
