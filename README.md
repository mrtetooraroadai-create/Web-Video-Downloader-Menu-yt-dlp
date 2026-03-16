# yt-dlp Menu Project

yt-dlp Menu Project is a Windows-based downloader setup built around `yt-dlp`.

It includes:

- a human-friendly batch menu
- an AI/script-friendly command interface
- local project download folders
- optional logged-in YouTube downloads using a local cookie file

## Contents

- Requirements
- Installation
- Getting the Required Files
- Usage
- Human Menu
- AI CLI
- Local YouTube Account Mode
- Cookie Manager
- Notes

## Requirements

- Windows
- `yt-dlp.exe`
- `ffmpeg.exe`
- `ffprobe.exe`

Optional:

- Node.js on `PATH`

If Node.js is installed, the scripts will use it automatically for better JavaScript handling when needed.

## Installation

Place these files in the project folder:

```text
yt-dlp.exe
ffmpeg.exe
ffprobe.exe
yt-dlp-menu.bat
yt-dlp-ai.bat
```

Downloads will be stored inside this project:

```text
Downloads\Videos
Downloads\Music
```

## Getting the Required Files

1. Download `yt-dlp.exe`

Use the official yt-dlp pages:

- [yt-dlp installation guide](https://github.com/yt-dlp/yt-dlp/wiki/Installation)
- [yt-dlp releases](https://github.com/yt-dlp/yt-dlp/releases)

Put `yt-dlp.exe` in this project folder.

2. Download FFmpeg

Use the Windows builds from:

- [Gyan.dev FFmpeg builds](https://www.gyan.dev/ffmpeg/builds/)

For this project, the `ffmpeg-git-essentials.7z` build was used.

After downloading it:

- extract the archive
- open the `bin` folder inside it
- take `ffmpeg.exe`
- take `ffprobe.exe`
- place both files in this project folder

That is how the current project setup was made.

3. Optional: install Node.js

Node.js is optional.

If Node.js is installed and available on `PATH`, the scripts will use it automatically.

## Usage

### Human Menu

Run:

```bat
yt-dlp-menu.bat
```

Main paths:

- startup `2` opens the full menu
- main menu `23` opens tools and settings
- `23 -> 7` opens YouTube account tools
- `23 -> 7 -> 6` opens the cookie manager

For video downloads, the menu can show the available qualities first.

You can then:

- press `A` for automatic best quality
- press `C` to cancel
- enter a format such as `137+140`

### AI CLI

Run:

```bat
yt-dlp-ai.bat help
```

Examples:

```bat
yt-dlp-ai.bat video "<url>"
yt-dlp-ai.bat mp3 "<url>"
yt-dlp-ai.bat formats "<url>"
yt-dlp-ai.bat specific "<url>" 137+140
yt-dlp-ai.bat account-formats "<url>"
yt-dlp-ai.bat account-specific "<url>" 137+140
```

The AI CLI is non-interactive and returns machine-readable output with real exit codes.

## Local YouTube Account Mode

The project can use a local YouTube cookie file for logged-in downloads.

Active cookie file:

```text
Private\youtube-cookies.txt
```

Saved cookie store:

```text
Private\Cookie Store\
```

Recommended logged-in quality flow:

1. Run `account-formats`
2. Pick the format ID or format combination you want
3. Run `account-specific`

This is the most reliable way to request a specific logged-in quality.

## Cookie Manager

The cookie manager makes it easier to swap cookie files in and out later.

It can:

- keep one active cookie file
- save the current cookie into the store
- activate a saved cookie from the store
- back up the previous active cookie before switching

Useful AI commands:

```bat
yt-dlp-ai.bat account-status
yt-dlp-ai.bat account-list
yt-dlp-ai.bat account-archive
yt-dlp-ai.bat account-activate saved-cookie.txt
```

## Notes

- downloads stay inside this project folder
- highest available quality depends on what YouTube exposes for each video
- some videos offer `1080p60`, while others only offer `1080p` or lower
- keep cookie files private
- large `.exe` files can be awkward to upload through the GitHub website, so it may be easier to download them separately
