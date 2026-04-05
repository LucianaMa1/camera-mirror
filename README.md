# Camera Mirror

A tiny macOS helper for screen recording.

If you record demos, tutorials, walkthroughs, or presentations, you probably know this feeling:

you want to record your screen, but you also want to keep an eye on your own face in real time.

That is exactly what this app is for.

`Camera Mirror` gives you a small always-on-top camera mirror window, so while you record your screen with any screen recorder, you can still see yourself live.

It works great with:

- macOS built-in screen recording
- QuickTime Player
- free screen recording tools
- your usual video workflow

## Why I made this

I kept running into the same pain point:

- I wanted a simple live face mirror while recording
- I did not want to pay a monthly subscription for another facecam app
- I wanted something lightweight and easy enough that even non-technical users could just double-click and use it

So I built one.

## What it does

- Opens your front camera and mirrors it live
- Stays on top while you record
- Lets you move and resize the mirror
- Lets you show watermark text
- Lets you drag the watermark separately from the mirror
- Opens settings by hover, click, or double-clicking the watermark text
- Can be packaged as a double-clickable macOS `.app`

## Quick Start

### Option 1: Run from script

```bash
chmod +x ./run_camera_mirror.sh
./run_camera_mirror.sh
```

### Option 2: Build a double-clickable `.app`

```bash
chmod +x ./build_camera_mirror_app.sh
./build_camera_mirror_app.sh
```

This generates:

`Camera Mirror.app`

You can then double-click it like a normal macOS app.

## First Launch

The first time you open it, macOS may ask for camera permission.

If permission does not pop up automatically, go to:

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
- `social-posts.md` — ready-to-post bilingual social media copy

## Notes

- This is a screen-recording companion, not a screen recorder itself
- It is designed for macOS
- It uses native macOS frameworks and does not require extra Python image libraries
