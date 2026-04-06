# A tiny MacOS app for always-on-top camera mirror window

I built this because I didn’t want to pay $18/month for Loom.

If you record tutorials, demos, or walkthroughs and want your face visible while recording your screen — this gives you a simple floating camera mirror.

No subscription. No login. Just open and record.

`Camera Mirror` gives you a small always-on-top camera mirror window, so while you record your screen with any screen recorder, you can still see yourself live.

It works great with:

- macOS built-in screen recording
- QuickTime Player
- free screen recording tools
- your usual video workflow

## What it does

- Opens your front camera and mirrors it live
- Stays on top while you record
- Lets you move and resize the mirror
- Lets you show watermark text
- Lets you drag the watermark separately from the mirror
- Opens settings by hover, click, or double-clicking the watermark text
- Can be built into a double-clickable macOS `.app`

## How to use it

Open the Terminal on your Mac and paste the following code in

```bash
gh repo clone LucianaMa1/camera-mirror
cd camera-mirror
chmod +x ./build_camera_mirror_app.sh
./build_camera_mirror_app.sh
open "Camera Mirror.app"
```

This will generate: `Camera Mirror.app` and open the app for you.

After you have built it for the first time, you can access this app from the applicartion menu on your computer next time.

The first time you open it, macOS may ask for camera permission.

If the permission prompt does not appear automatically, go to:

`System Settings` -> `Privacy & Security` -> `Camera`

and allow Camera Mirror to access the camera.

## Typical Workflow

1. Open `Camera Mirror`
2. Move the mirror where you want it
3. Resize it so it does not block your content
4. Add your name or watermark text if you want
5. Open any screen recording tool
6. Start recording

That is it.

## Open Settings

You can open settings by:

- hovering over the mirror and clicking the small dot
- double-clicking the watermark text


## Project Files

- `main.m` — native macOS app source
- `run_camera_mirror.sh` — quick launcher
- `build_camera_mirror_app.sh` — builds the `.app`
- `generate_icon.m` — generates the app icon
- `camera-mirror-icon-1024.png` — exported icon image

## Notes

- This is a screen-recording companion, not a screen recorder itself
- It is designed for macOS
- It uses native macOS frameworks and does not require extra Python image libraries
