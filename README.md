# 3DJ
3DJ is a system that lets you "copy" a group of people from one instance and render them in multiple others.

## What is this for?
For example in a big club where we have multiple instances and main with DJ usually being full, people in other instances can see the 3D copy of DJ instead of just nothing, or well 2D version.

> [!NOTE]
> 3DJ will record players nearby the player you choose in `Control Desk`, it depends on who recording-client can see or not.

> [!NOTE]
> The avatar "clone" is placed in world space, where the player that being recorded goes, their "clone" will be where they are

## How to install
[3DJ VCC Link](https://www.matthewherber.com/3DJ/)

## How to set it up in your world

### Base setup
1. Place `3DJManager` prefab from `Packages/3DJ/Runtime/Prefabs` into scene.
   - It's the core component that renders the avatar or records it.
2. Put your Video Render texture into the `Video Texture` field in `Manager` component on `3DJManager` prefab in your scene.
   - If there's any recomendations, please click auto fix errors that script suggests (one-click button)
3. Place `Control Desk` prefab from `Packages/3DJ/Runtime/Fixtures/Control Desk` into your scene to control 3DJManager.
   - from there you select what player it sticks and records in-game
   - it will record players nearby, depends on who recording-client can see or not

### Configuring UVs
1. For managing how it's reading data from texture, you need to manually go through `Visualise Color`, `Visualise Depth` and adjust their values in the same component
2. It's by default set up for 1920x1080 (comes with default UV image that represents what space it uses, but you can edit it however you want it) so make sure your render texture uses that resolution

## How to record
- TBD

## How to play it back
3DJ works either in `RECORD` or `PLAYBACK` modes, it doesn't "Record and play it".
You can test data through debug prefabs:
1. `Packages/3DJ/Runtime/Fixtures/Debug Cubes` - internal data
2. `Packages/3DJ/Runtime/Fixtures/Large Scale Platform` - avatar result

## LICENSES
[3DJ](https://github.com/Happyrobot33/3DJ/blob/main/LICENSE)
