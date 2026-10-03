# AquaRings

A water basketball toy for Windows, macOS and Linux, made with Godot 4.7.
Nine mini balls drift inside a tank with a hoop on the ceiling, and two pumps
at the bottom fire water jets that push every ball at once.


## Features


- No character to control: the balls are rigid bodies with real physics, so
  reading where they will be is the whole game.
- Two pumps, left and right, each pushing all nine balls. Every jet is
  randomised, so the same press twice never gives the same result.
- Scoring is picky on purpose. A ball scores falling through the hoop centred,
  slowly and from above. Fast shots across the rim do not count, and a ball
  that pokes up from underneath and comes back down does not fool it either.
- A point is lost again if the scored ball drifts out of the hoop.
- Anti-cheat hoop: an invisible one-way collider stops balls passing upward
  through the hoop, backed up by a second check in code for the case where a
  fast ball tunnels anyway.
- Animated background with no textures and no per-frame work: the shader runs
  on `TIME`, so nothing in `main.gd` touches it.
- Press animations for both pump buttons, driven by sprite sheets.
- Runs on integrated graphics, including machines from around 2012. Uses the
  compatibility renderer rather than Vulkan.


## Controls


| Key | Action |
| --- | ------ |
| <kbd>A</kbd> or <kbd>←</kbd> | left pump |
| <kbd>D</kbd> or <kbd>→</kbd> | right pump |
| <kbd>Space</kbd> | both pumps at once |
| <kbd>R</kbd> | restart |

There are two pump buttons at the bottom of the screen, and a reset button in
the top bar.


## Downloads


Binaries for 64 and 32 bit Windows, 64 bit Linux and macOS are in the
**Releases** tab of this repository.


To build it yourself you need **standard** Godot 4.7, not the .NET or Mono
build, and there are no dependencies: open the project and press
<kbd>F5</kbd>. To produce an executable use *Project → Export*.

Export templates have to be downloaded first, via *Editor → Manage Export
Templates*. The `.import` files next to the assets are required; if Godot does
not regenerate them, delete the `.godot/` folder and reopen the project.


## Development notes


A few things in the code are not obvious from reading it.


**The mouse buttons are currently dead.** `main.gd` still contains a branch
that would fire the left pump when clicking the left half of the screen and
the right pump on the right half, but the `shoot` and `pump` input actions both
also carry a left mouse button, so those presses are consumed by the keyboard
branch first and the click never reaches the half-screen check. Fixing it means
taking the mouse button out of the `shoot` and `pump` actions in
`project.godot`, which leaves the keyboard working exactly as it is now.


**The score labels are empty.** `ScoreLabel` and `HintLabel` are in the scene
and `main.gd` has an `_update_ui()` that is called on every scoring event, but
the function body is a bare `pass`. The score is tracked correctly, it just is
not drawn anywhere yet.


**Physics constants are defined twice.** Mass and physics material appear both
in `ball.tscn` and in `ball.gd`'s `_ready()`. The script assignments run last
and win, so changing one of the two alone does nothing.


**The gravity setting does not apply.** `project.godot` selects Jolt as the
**3D** physics engine; this is a 2D game, so the balls run on the default
GodotPhysics2D and that line has no effect.


## Credits and licences


Project under the [Apache 2.0](LICENSE) licence. Engine by
[Godot](https://godotengine.org), MIT.