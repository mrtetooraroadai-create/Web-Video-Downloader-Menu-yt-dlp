@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "SELF=%~f0"
set "SCRIPT_DIR=%~dp0"
set "YTDLP=%SCRIPT_DIR%yt-dlp.exe"
set "FFMPEG=%SCRIPT_DIR%ffmpeg.exe"
set "FFPROBE=%SCRIPT_DIR%ffprobe.exe"

set "DOWNLOAD_ROOT=%SCRIPT_DIR%Downloads"
set "VIDEO_DIR=%DOWNLOAD_ROOT%\Videos"
set "AUDIO_DIR=%DOWNLOAD_ROOT%\Music"
set "PRIVATE_DIR=%SCRIPT_DIR%Private"
set "YT_COOKIES=%PRIVATE_DIR%\youtube-cookies.txt"
set "COOKIE_STORE_DIR=%PRIVATE_DIR%\Cookie Store"

if not exist "%DOWNLOAD_ROOT%" mkdir "%DOWNLOAD_ROOT%"
if not exist "%VIDEO_DIR%" mkdir "%VIDEO_DIR%"
if not exist "%AUDIO_DIR%" mkdir "%AUDIO_DIR%"
if not exist "%PRIVATE_DIR%" mkdir "%PRIVATE_DIR%"
if not exist "%COOKIE_STORE_DIR%" mkdir "%COOKIE_STORE_DIR%"

set "VIDEO_OUT=%VIDEO_DIR%\%%(uploader,creator,channel|Unknown Creator)s\%%(title)s [%%(id)s].%%(ext)s"
set "AUDIO_OUT=%AUDIO_DIR%\%%(uploader,creator,channel|Unknown Creator)s\%%(title)s [%%(id)s].%%(ext)s"
set "PLAYLIST_VIDEO_OUT=%VIDEO_DIR%\%%(playlist_title,album|Playlist)s\%%(playlist_index)03d - %%(title)s [%%(id)s].%%(ext)s"
set "PLAYLIST_AUDIO_OUT=%AUDIO_DIR%\%%(playlist_title,album|Playlist)s\%%(playlist_index)03d - %%(title)s [%%(id)s].%%(ext)s"

set "COMMON_BASE=--windows-filenames --no-mtime --embed-metadata --retries 10 --fragment-retries 10"
set "COMMON="
set "BEST_FMT=bv*+ba/b"
set "NODE_STATUS=Checking..."

call :check_required_files
if errorlevel 1 exit /b 1
set "COMMON=%COMMON_BASE%"
set "NODE_STATUS=Node.js not found"
where node >nul 2>nul
if not errorlevel 1 (
    set "COMMON=%COMMON_BASE% --js-runtimes node"
    set "NODE_STATUS=Node.js detected"
)

set "COMMAND=%~1"
if not defined COMMAND goto help

if /I "%COMMAND%"=="help" goto help
if /I "%COMMAND%"=="task" goto task
if /I "%COMMAND%"=="clipboard-video" goto clipboard_video
if /I "%COMMAND%"=="clipboard-mp3" goto clipboard_mp3
if /I "%COMMAND%"=="video" goto video
if /I "%COMMAND%"=="mp3" goto mp3
if /I "%COMMAND%"=="formats" goto formats
if /I "%COMMAND%"=="specific" goto specific
if /I "%COMMAND%"=="playlist-video" goto playlist_video
if /I "%COMMAND%"=="single-video" goto single_video
if /I "%COMMAND%"=="playlist-mp3" goto playlist_mp3
if /I "%COMMAND%"=="video-subs" goto video_subs
if /I "%COMMAND%"=="video-embed-subs" goto video_embed_subs
if /I "%COMMAND%"=="thumbnail" goto thumbnail_only
if /I "%COMMAND%"=="mp3-embed-thumb" goto mp3_embed_thumb
if /I "%COMMAND%"=="video-mp4" goto video_mp4
if /I "%COMMAND%"=="video-mkv" goto video_mkv
if /I "%COMMAND%"=="browser-video" goto browser_video
if /I "%COMMAND%"=="browser-formats" goto browser_formats
if /I "%COMMAND%"=="browser-single" goto browser_single
if /I "%COMMAND%"=="account-status" goto account_status
if /I "%COMMAND%"=="account-list" goto account_list
if /I "%COMMAND%"=="account-video" goto account_video
if /I "%COMMAND%"=="account-mp3" goto account_mp3
if /I "%COMMAND%"=="account-formats" goto account_formats
if /I "%COMMAND%"=="account-archive" goto account_archive
if /I "%COMMAND%"=="account-specific" goto account_specific
if /I "%COMMAND%"=="account-activate" goto account_activate
if /I "%COMMAND%"=="account-single" goto account_single
if /I "%COMMAND%"=="paths" (
    call :emitlocations
    exit /b !errorlevel!
)
if /I "%COMMAND%"=="locations" (
    call :emitlocations
    exit /b 0
)
if /I "%COMMAND%"=="runtime" goto runtime
if /I "%COMMAND%"=="files" goto files
if /I "%COMMAND%"=="open-videos" goto open_videos
if /I "%COMMAND%"=="open-music" goto open_music
if /I "%COMMAND%"=="update" goto update_cmd

echo STATUS=ERROR
set "MESSAGE=Unknown command: %COMMAND%"
call :emitvar MESSAGE MESSAGE
exit /b 2

:clipboard_video
call :get_clip_url_only
if not defined URL (
    echo STATUS=ERROR
    echo MESSAGE=No valid web link found in clipboard
    exit /b 2
)
call :reset_download_vars
set "DL_NAME=clipboard-video"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:clipboard_mp3
call :get_clip_url_only
if not defined URL (
    echo STATUS=ERROR
    echo MESSAGE=No valid web link found in clipboard
    exit /b 2
)
call :reset_download_vars
set "DL_NAME=clipboard-mp3"
set "DL_OUT=%AUDIO_OUT%"
set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0"
set "DL_FALLBACK="
set "DL_OUTPUT_ROOT=%AUDIO_DIR%"
call :run_download
exit /b !errorlevel!

:video
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=video"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:mp3
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=mp3"
set "DL_OUT=%AUDIO_OUT%"
set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0"
set "DL_FALLBACK="
set "DL_OUTPUT_ROOT=%AUDIO_DIR%"
call :run_download
exit /b !errorlevel!

:formats
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
set "COOKIEOPT="
call :run_format_list formats
exit /b !errorlevel!

:specific
call :readtail 1 %*
for /f "tokens=1,* delims= " %%A in ("%TAIL%") do (
    set "URL=%%A"
    set "FORMATID=%%B"
)
call :stripquotes URL
call :stripquotes FORMATID
if not defined URL goto missing_url
if not defined FORMATID goto missing_format
call :reset_download_vars
set "DL_NAME=specific"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%FORMATID%"
set "DL_FALLBACK="
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:playlist_video
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=playlist-video"
set "DL_OUT=%PLAYLIST_VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:single_video
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=single-video"
set "DL_OUT=%VIDEO_OUT%"
set "DL_SCOPE=--no-playlist"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:playlist_mp3
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=playlist-mp3"
set "DL_OUT=%PLAYLIST_AUDIO_OUT%"
set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0"
set "DL_FALLBACK="
set "DL_OUTPUT_ROOT=%AUDIO_DIR%"
call :run_download
exit /b !errorlevel!

:video_subs
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=video-subs"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_EXTRA=--write-subs --write-auto-subs --sub-langs "all,-live_chat""
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:video_embed_subs
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=video-embed-subs"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_EXTRA=--write-subs --write-auto-subs --embed-subs --sub-langs "all,-live_chat""
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:thumbnail_only
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=thumbnail"
set "DL_OUT=%VIDEO_OUT%"
set "DL_EXTRA=--skip-download --write-thumbnail --convert-thumbnails jpg"
set "DL_FALLBACK="
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:mp3_embed_thumb
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=mp3-embed-thumb"
set "DL_OUT=%AUDIO_OUT%"
set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0 --embed-thumbnail --write-thumbnail"
set "DL_FALLBACK="
set "DL_OUTPUT_ROOT=%AUDIO_DIR%"
call :run_download
exit /b !errorlevel!

:video_mp4
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=video-mp4"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_REMUX=--remux-video mp4"
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:video_mkv
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :reset_download_vars
set "DL_NAME=video-mkv"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_REMUX=--remux-video mkv"
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:browser_video
call :readtail 1 %*
for /f "tokens=1,* delims= " %%A in ("%TAIL%") do (
    set "BROWSER=%%A"
    set "URL=%%B"
)
call :stripquotes BROWSER
call :stripquotes URL
if not defined URL goto missing_browser_url
call :set_browser_cookie "%BROWSER%"
if errorlevel 1 exit /b 2
call :reset_download_vars
set "DL_NAME=browser-video"
set "DL_COOKIE=%COOKIEOPT%"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:browser_formats
call :readtail 1 %*
for /f "tokens=1,* delims= " %%A in ("%TAIL%") do (
    set "BROWSER=%%A"
    set "URL=%%B"
)
call :stripquotes BROWSER
call :stripquotes URL
if not defined URL goto missing_browser_url
call :set_browser_cookie "%BROWSER%"
if errorlevel 1 exit /b 2
call :run_format_list browser-formats
exit /b !errorlevel!

:browser_single
call :readtail 1 %*
for /f "tokens=1,* delims= " %%A in ("%TAIL%") do (
    set "BROWSER=%%A"
    set "URL=%%B"
)
call :stripquotes BROWSER
call :stripquotes URL
if not defined URL goto missing_browser_url
call :set_browser_cookie "%BROWSER%"
if errorlevel 1 exit /b 2
call :reset_download_vars
set "DL_NAME=browser-single"
set "DL_COOKIE=%COOKIEOPT%"
set "DL_SCOPE=--no-playlist"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:account_status
call :count_saved_cookies
echo STATUS=OK
echo COOKIE_FILE=%YT_COOKIES%
echo COOKIE_STORE_DIR=%COOKIE_STORE_DIR%
echo SAVED_COOKIE_COUNT=%SAVED_COOKIE_COUNT%
if exist "%YT_COOKIES%" (
    echo ACCOUNT_READY=1
    for %%A in ("%YT_COOKIES%") do (
        echo COOKIE_FILE_SIZE=%%~zA
        echo COOKIE_FILE_MODIFIED=%%~tA
    )
    echo MESSAGE=Local YouTube cookie file is ready
    exit /b 0
)
echo ACCOUNT_READY=0
echo MESSAGE=Local YouTube cookie file was not found
echo HINT=Export YouTube cookies in Netscape format to the COOKIE_FILE path above
exit /b 0

:account_list
call :count_saved_cookies
echo STATUS=OK
echo COOKIE_STORE_DIR=%COOKIE_STORE_DIR%
echo SAVED_COOKIE_COUNT=%SAVED_COOKIE_COUNT%
if "%SAVED_COOKIE_COUNT%"=="0" (
    echo MESSAGE=No saved cookie files were found in the cookie store
    exit /b 0
)
call :emit_saved_cookie_list
echo MESSAGE=Saved cookie files are listed below
exit /b 0

:account_video
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :set_account_cookie
if errorlevel 1 exit /b 2
call :reset_download_vars
set "DL_NAME=account-video"
set "DL_COOKIE=%COOKIEOPT%"
set "DL_ACCOUNT_COOKIE=%COOKIE_FILE%"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:account_mp3
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :set_account_cookie
if errorlevel 1 exit /b 2
call :reset_download_vars
set "DL_NAME=account-mp3"
set "DL_COOKIE=%COOKIEOPT%"
set "DL_ACCOUNT_COOKIE=%COOKIE_FILE%"
set "DL_OUT=%AUDIO_OUT%"
set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0"
set "DL_FALLBACK="
set "DL_OUTPUT_ROOT=%AUDIO_DIR%"
call :run_download
exit /b !errorlevel!

:account_formats
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :set_account_cookie
if errorlevel 1 exit /b 2
call :run_format_list account-formats
exit /b !errorlevel!

:account_archive
if not exist "%YT_COOKIES%" (
    echo STATUS=ERROR
    echo MESSAGE=There is no active cookie file to save right now
    echo COOKIE_FILE=%YT_COOKIES%
    exit /b 2
)
call :make_cookie_timestamp
set "COOKIE_ARCHIVE_TARGET=%COOKIE_STORE_DIR%\youtube-cookies-%COOKIE_TIMESTAMP%.txt"
copy /y "%YT_COOKIES%" "%COOKIE_ARCHIVE_TARGET%" >nul
if errorlevel 1 (
    echo STATUS=ERROR
    echo MESSAGE=The active cookie file could not be saved into the cookie store
    exit /b 1
)
echo STATUS=OK
echo ACTIVE_COOKIE_FILE=%YT_COOKIES%
echo ARCHIVED_FILE=%COOKIE_ARCHIVE_TARGET%
exit /b 0

:account_specific
call :readtail 1 %*
for /f "tokens=1,* delims= " %%A in ("%TAIL%") do (
    set "URL=%%A"
    set "FORMATID=%%B"
)
call :stripquotes URL
call :stripquotes FORMATID
if not defined URL goto missing_url
if not defined FORMATID goto missing_format
call :set_account_cookie
if errorlevel 1 exit /b 2
call :reset_download_vars
set "DL_NAME=account-specific"
set "DL_COOKIE=%COOKIEOPT%"
set "DL_ACCOUNT_COOKIE=%COOKIE_FILE%"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%FORMATID%"
set "DL_FALLBACK="
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:account_activate
call :readtail 1 %*
set "COOKIE_NAME=%TAIL%"
call :stripquotes COOKIE_NAME
if not defined COOKIE_NAME goto missing_saved_cookie_name
if not exist "%COOKIE_STORE_DIR%\%COOKIE_NAME%" (
    echo STATUS=ERROR
    echo MESSAGE=The requested saved cookie file was not found
    echo COOKIE_STORE_DIR=%COOKIE_STORE_DIR%
    echo REQUESTED_COOKIE=%COOKIE_NAME%
    exit /b 2
)
set "COOKIE_BACKUP_TARGET="
if exist "%YT_COOKIES%" (
    call :make_cookie_timestamp
    set "COOKIE_BACKUP_TARGET=%COOKIE_STORE_DIR%\active-before-switch-%COOKIE_TIMESTAMP%.txt"
    copy /y "%YT_COOKIES%" "%COOKIE_BACKUP_TARGET%" >nul
    if errorlevel 1 (
        echo STATUS=ERROR
        echo MESSAGE=The current active cookie could not be backed up before switching
        exit /b 1
    )
)
copy /y "%COOKIE_STORE_DIR%\%COOKIE_NAME%" "%YT_COOKIES%" >nul
if errorlevel 1 (
    echo STATUS=ERROR
    echo MESSAGE=The saved cookie could not be activated
    exit /b 1
)
echo STATUS=OK
echo ACTIVE_COOKIE_FILE=%YT_COOKIES%
echo ACTIVATED_FROM=%COOKIE_STORE_DIR%\%COOKIE_NAME%
if defined COOKIE_BACKUP_TARGET echo PREVIOUS_ACTIVE_ARCHIVE=%COOKIE_BACKUP_TARGET%
exit /b 0

:account_single
call :readtail 1 %*
set "URL=%TAIL%"
call :stripquotes URL
if not defined URL goto missing_url
call :set_account_cookie
if errorlevel 1 exit /b 2
call :reset_download_vars
set "DL_NAME=account-single"
set "DL_COOKIE=%COOKIEOPT%"
set "DL_ACCOUNT_COOKIE=%COOKIE_FILE%"
set "DL_SCOPE=--no-playlist"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT_VALUE=%BEST_FMT%"
set "DL_OUTPUT_ROOT=%VIDEO_DIR%"
call :run_download
exit /b !errorlevel!

:runtime
echo STATUS=OK
echo NODE_STATUS=%NODE_STATUS%
echo COMMON=%COMMON%
where node >nul 2>nul
if errorlevel 1 exit /b 0
for /f "delims=" %%A in ('where node 2^>nul') do (
    echo NODE_PATH=%%A
    goto runtimedone
)
:runtimedone
exit /b 0

:files
echo STATUS=OK
echo SCRIPT_DIR=%SCRIPT_DIR%
echo YTDLP=%YTDLP%
echo FFMPEG=%FFMPEG%
echo FFPROBE=%FFPROBE%
exit /b 0

:open_videos
start "" "%VIDEO_DIR%"
echo STATUS=OK
echo OPENED=%VIDEO_DIR%
exit /b 0

:open_music
start "" "%AUDIO_DIR%"
echo STATUS=OK
echo OPENED=%AUDIO_DIR%
exit /b 0

:update_cmd
echo COMMAND=update
"%YTDLP%" -U
if errorlevel 1 (
    echo STATUS=ERROR
    exit /b 1
)
echo STATUS=OK
exit /b 0

:missing_url
echo STATUS=ERROR
echo MESSAGE=Missing URL argument
echo HINT=Run "%~nx0 help" for usage
exit /b 2

:missing_format
echo STATUS=ERROR
echo MESSAGE=Missing format ID argument
echo HINT=Run "%~nx0 help" for usage
exit /b 2

:missing_saved_cookie_name
echo STATUS=ERROR
echo MESSAGE=Missing saved cookie file name
echo HINT=Run "%~nx0 help" for usage
exit /b 2

:missing_browser_url
echo STATUS=ERROR
echo MESSAGE=Missing browser or URL argument
echo HINT=Run "%~nx0 help" for usage
exit /b 2

:task
set "TASK_KIND=%~2"
call :readtail 2 %*
set "TASK_TAIL=%TAIL%"
if not defined TASK_KIND (
    call :task_help
    exit /b !errorlevel!
)

if /I "%TASK_KIND%"=="clip-video" (
    call :runalias clipboard-video
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="clip-mp3" (
    call :runalias clipboard-mp3
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="download" (
    call :taskdownloadroute
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="inspect" (
    call :taskinspectroute
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="manage" (
    call :taskmanageroute
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="clipboard" (
    call :taskclipboardroute
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="video" (
    call :taskvideoroute
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="best-video" (
    call :taskvideoroute
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="mp3" (
    call :taskmp3route
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="formats" (
    if not defined TASK_TAIL (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias formats "!TASK_TAIL!"
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="format-list" (
    if not defined TASK_TAIL (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias formats "!TASK_TAIL!"
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="specific" (
    call :taskspecificroute
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="specific-format" (
    call :taskspecificroute
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="thumbnail" (
    if not defined TASK_TAIL (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias thumbnail "!TASK_TAIL!"
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="browser" (
    call :taskbrowserroute
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="paths" (
    call :emitlocations
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="locations" (
    call :emitlocations
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="runtime" (
    call :runalias runtime
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="files" (
    call :runalias files
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="update" (
    call :runalias update
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="open-videos" (
    call :runalias open-videos
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="open-music" (
    call :runalias open-music
    exit /b !errorlevel!
)
if /I "%TASK_KIND%"=="open" (
    call :taskopenroute
    exit /b !errorlevel!
)

echo STATUS=ERROR
echo MESSAGE=Unknown task: %TASK_KIND%
echo HINT=Run "%~nx0 help" for task examples
exit /b 2

:taskclipboardroute
call :tasksplit
if /I "!TASK_FIRST!"=="video" (
    call :runalias clipboard-video
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="mp3" (
    call :runalias clipboard-mp3
    exit /b !errorlevel!
)
call :task_help
exit /b !errorlevel!

:taskvideoroute
call :tasksplit
if not defined TASK_FIRST (
    call :missing_task_url
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="single" (
    if not defined TASK_REST (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias single-video "!TASK_REST!"
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="playlist" (
    if not defined TASK_REST (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias playlist-video "!TASK_REST!"
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="mp4" (
    if not defined TASK_REST (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias video-mp4 "!TASK_REST!"
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="mkv" (
    if not defined TASK_REST (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias video-mkv "!TASK_REST!"
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="subs" (
    if not defined TASK_REST (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias video-subs "!TASK_REST!"
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="embed-subs" (
    if not defined TASK_REST (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias video-embed-subs "!TASK_REST!"
    exit /b !errorlevel!
)
call :runalias video "!TASK_TAIL!"
exit /b !errorlevel!

:taskmp3route
call :tasksplit
if not defined TASK_FIRST (
    call :missing_task_url
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="playlist" (
    if not defined TASK_REST (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias playlist-mp3 "!TASK_REST!"
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="embed-thumb" (
    if not defined TASK_REST (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias mp3-embed-thumb "!TASK_REST!"
    exit /b !errorlevel!
)
call :runalias mp3 "!TASK_TAIL!"
exit /b !errorlevel!

:taskspecificroute
call :tasksplit
if not defined TASK_FIRST (
    call :missing_task_format
    exit /b !errorlevel!
)
if not defined TASK_REST (
    call :missing_task_url
    exit /b !errorlevel!
)
call :runalias specific "!TASK_REST!" "!TASK_FIRST!"
exit /b !errorlevel!

:taskbrowserroute
call :tasksplit
if not defined TASK_FIRST (
    call :task_help
    exit /b !errorlevel!
)
set "TASK_ACTION=!TASK_FIRST!"
set "TASK_TAIL=!TASK_REST!"
call :tasksplit
if not defined TASK_FIRST (
    call :missing_browser_or_task_url
    exit /b !errorlevel!
)
if not defined TASK_REST (
    call :missing_browser_or_task_url
    exit /b !errorlevel!
)
if /I "!TASK_ACTION!"=="video" (
    call :runalias browser-video "!TASK_FIRST!" "!TASK_REST!"
    exit /b !errorlevel!
)
if /I "!TASK_ACTION!"=="formats" (
    call :runalias browser-formats "!TASK_FIRST!" "!TASK_REST!"
    exit /b !errorlevel!
)
if /I "!TASK_ACTION!"=="single" (
    call :runalias browser-single "!TASK_FIRST!" "!TASK_REST!"
    exit /b !errorlevel!
)
call :task_help
exit /b !errorlevel!

:taskopenroute
call :tasksplit
if /I "!TASK_FIRST!"=="videos" (
    call :runalias open-videos
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="music" (
    call :runalias open-music
    exit /b !errorlevel!
)
call :task_help
exit /b !errorlevel!

:taskdownloadroute
call :tasksplit
if not defined TASK_FIRST (
    call :task_help
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="video" (
    set "TASK_TAIL=!TASK_REST!"
    call :taskvideoroute
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="best-video" (
    set "TASK_TAIL=!TASK_REST!"
    call :taskvideoroute
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="mp3" (
    set "TASK_TAIL=!TASK_REST!"
    call :taskmp3route
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="thumbnail" (
    if not defined TASK_REST (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias thumbnail "!TASK_REST!"
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="specific" (
    set "TASK_TAIL=!TASK_REST!"
    call :taskspecificroute
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="browser" (
    set "TASK_TAIL=!TASK_REST!"
    call :taskbrowserroute
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="account" (
    set "TASK_TAIL=!TASK_REST!"
    call :tasksplit
    if /I "!TASK_FIRST!"=="video" (
        if not defined TASK_REST (
            call :missing_task_url
            exit /b !errorlevel!
        )
        call :runalias account-video "!TASK_REST!"
        exit /b !errorlevel!
    )
    if /I "!TASK_FIRST!"=="mp3" (
        if not defined TASK_REST (
            call :missing_task_url
            exit /b !errorlevel!
        )
        call :runalias account-mp3 "!TASK_REST!"
        exit /b !errorlevel!
    )
    if /I "!TASK_FIRST!"=="specific" (
        set "TASK_TAIL=!TASK_REST!"
        call :tasksplit
        if not defined TASK_FIRST (
            call :missing_task_format
            exit /b !errorlevel!
        )
        if not defined TASK_REST (
            call :missing_task_url
            exit /b !errorlevel!
        )
        call :runalias account-specific "!TASK_REST!" "!TASK_FIRST!"
        exit /b !errorlevel!
    )
    if /I "!TASK_FIRST!"=="single" (
        if not defined TASK_REST (
            call :missing_task_url
            exit /b !errorlevel!
        )
        call :runalias account-single "!TASK_REST!"
        exit /b !errorlevel!
    )
    call :task_help
    exit /b !errorlevel!
)
call :task_help
exit /b !errorlevel!

:taskinspectroute
call :tasksplit
if not defined TASK_FIRST (
    call :task_help
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="paths" (
    call :emitlocations
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="locations" (
    call :emitlocations
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="runtime" (
    call :runalias runtime
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="files" (
    call :runalias files
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="formats" (
    if not defined TASK_REST (
        call :missing_task_url
        exit /b !errorlevel!
    )
    call :runalias formats "!TASK_REST!"
    exit /b !errorlevel!
)
if /I "!TASK_FIRST!"=="account" (
    set "TASK_TAIL=!TASK_REST!"
    call :tasksplit
    if /I "!TASK_FIRST!"=="status" (
        call :runalias account-status
        exit /b !errorlevel!
    )
    if /I "!TASK_FIRST!"=="list" (
        call :runalias account-list
        exit /b !errorlevel!
    )
    if /I "!TASK_FIRST!"=="formats" (
        if not defined TASK_REST (
            call :missing_task_url
            exit /b !errorlevel!
        )
        call :runalias account-formats "!TASK_REST!"
        exit /b !errorlevel!
    )
    call :task_help
    exit /b !errorlevel!
)
call :task_help
exit /b !errorlevel!

:taskmanageroute
call :tasksplit
if /I "!TASK_FIRST!"=="account" (
    set "TASK_TAIL=!TASK_REST!"
    call :tasksplit
    if /I "!TASK_FIRST!"=="archive" (
        call :runalias account-archive
        exit /b !errorlevel!
    )
    if /I "!TASK_FIRST!"=="activate" (
        if not defined TASK_REST (
            call :missing_saved_cookie_name
            exit /b !errorlevel!
        )
        call :runalias account-activate "!TASK_REST!"
        exit /b !errorlevel!
    )
)
call :task_help
exit /b !errorlevel!

:tasksplit
set "TASK_FIRST="
set "TASK_REST="
for /f "tokens=1,* delims= " %%A in ("!TASK_TAIL!") do (
    set "TASK_FIRST=%%A"
    set "TASK_REST=%%B"
)
if defined TASK_FIRST if "!TASK_FIRST:~0,1!"=="^"" if "!TASK_FIRST:~-1!"=="^"" set "TASK_FIRST=!TASK_FIRST:~1,-1!"
if defined TASK_REST if "!TASK_REST:~0,1!"=="^"" if "!TASK_REST:~-1!"=="^"" set "TASK_REST=!TASK_REST:~1,-1!"
goto :eof

:missing_task_url
echo STATUS=ERROR
echo MESSAGE=Missing task URL argument
echo HINT=Run "%~nx0 help" for task examples
exit /b 2

:missing_task_format
echo STATUS=ERROR
echo MESSAGE=Missing task format ID argument
echo HINT=Run "%~nx0 help" for task examples
exit /b 2

:missing_browser_or_task_url
echo STATUS=ERROR
echo MESSAGE=Missing browser or task URL argument
echo HINT=Run "%~nx0 help" for task examples
exit /b 2

:task_help
echo STATUS=ERROR
echo MESSAGE=Task syntax was incomplete
echo HINT=Run "%~nx0 help" for task examples
exit /b 2

:help
echo STATUS=OK
echo MODE=HELP
echo yt-dlp AI CLI
echo.
echo Commands:
echo   %~nx0 clipboard-video
echo   %~nx0 clipboard-mp3
echo   %~nx0 video "<url>"
echo   %~nx0 mp3 "<url>"
echo   %~nx0 formats "<url>"
echo   %~nx0 specific "<url>" ^<format_id^>
echo   %~nx0 playlist-video "<url>"
echo   %~nx0 single-video "<url>"
echo   %~nx0 playlist-mp3 "<url>"
echo   %~nx0 video-subs "<url>"
echo   %~nx0 video-embed-subs "<url>"
echo   %~nx0 thumbnail "<url>"
echo   %~nx0 mp3-embed-thumb "<url>"
echo   %~nx0 video-mp4 "<url>"
echo   %~nx0 video-mkv "<url>"
echo   %~nx0 browser-video ^<chrome^|edge^> "<url>"
echo   %~nx0 browser-formats ^<chrome^|edge^> "<url>"
echo   %~nx0 browser-single ^<chrome^|edge^> "<url>"
echo   %~nx0 account-status
echo   %~nx0 account-list
echo   %~nx0 account-video "<url>"
echo   %~nx0 account-mp3 "<url>"
echo   %~nx0 account-formats "<url>"
echo   %~nx0 account-archive
echo   %~nx0 account-specific "<url>" ^<format_id^>
echo   %~nx0 account-activate "<saved_cookie_file.txt>"
echo   %~nx0 account-single "<url>"
echo   %~nx0 paths
echo   %~nx0 locations
echo   %~nx0 runtime
echo   %~nx0 files
echo   %~nx0 open-videos
echo   %~nx0 open-music
echo   %~nx0 update
echo.
echo Task aliases:
echo   %~nx0 task best-video "<url>"
echo   %~nx0 task best-video single "<url>"
echo   %~nx0 task best-video playlist "<url>"
echo   %~nx0 task best-video mp4 "<url>"
echo   %~nx0 task best-video mkv "<url>"
echo   %~nx0 task best-video subs "<url>"
echo   %~nx0 task best-video embed-subs "<url>"
echo   %~nx0 task mp3 "<url>"
echo   %~nx0 task mp3 playlist "<url>"
echo   %~nx0 task mp3 embed-thumb "<url>"
echo   %~nx0 task formats "<url>"
echo   %~nx0 task specific ^<format_id^> "<url>"
echo   %~nx0 task browser video ^<chrome^|edge^> "<url>"
echo   %~nx0 task browser formats ^<chrome^|edge^> "<url>"
echo   %~nx0 task browser single ^<chrome^|edge^> "<url>"
echo   %~nx0 task clip-video
echo   %~nx0 task clip-mp3
echo   %~nx0 task paths
echo   %~nx0 task locations
echo   %~nx0 task runtime
echo   %~nx0 task download video "<url>"
echo   %~nx0 task download video single "<url>"
echo   %~nx0 task download mp3 playlist "<url>"
echo   %~nx0 task download browser video ^<chrome^|edge^> "<url>"
echo   %~nx0 task download account video "<url>"
echo   %~nx0 task download account mp3 "<url>"
echo   %~nx0 task download account specific ^<format_id^> "<url>"
echo   %~nx0 task download account single "<url>"
echo   %~nx0 task inspect paths
echo   %~nx0 task inspect runtime
echo   %~nx0 task inspect formats "<url>"
echo   %~nx0 task inspect account status
echo   %~nx0 task inspect account list
echo   %~nx0 task inspect account formats "<url>"
echo   %~nx0 task manage account archive
echo   %~nx0 task manage account activate "<saved_cookie_file.txt>"
echo.
echo Notes:
echo   - No prompts, no pauses, and non-zero exit codes on errors.
echo   - Download commands print STATUS=OK or STATUS=ERROR.
echo   - Info commands print machine-friendly KEY=VALUE lines.
echo   - For the highest logged-in YouTube quality, run account-formats first, then account-specific with the format ID or combo you want.
echo   - account-video and account-single use automatic best quality with the local cookie file.
echo ACCOUNT_COOKIE_FILE=%YT_COOKIES%
echo COOKIE_STORE_DIR=%COOKIE_STORE_DIR%
echo   - account-archive saves the current active cookie into the store with a timestamped file name.
echo   - account-activate swaps in a saved cookie file and automatically backs up the previous active one.
echo   - Local account mode uses a cookie file on this machine, not your password.
exit /b 0

:reset_download_vars
set "DL_NAME="
set "DL_COMMON=%COMMON%"
set "DL_COOKIE="
set "DL_ACCOUNT_COOKIE="
set "DL_SCOPE="
set "DL_FMT_VALUE="
set "DL_EXTRA="
set "DL_REMUX="
set "DL_OUT="
set "DL_FALLBACK=1"
set "DL_OUTPUT_ROOT="
goto :eof

:run_download
call :emitvar COMMAND DL_NAME
call :emitvar URL URL
if defined DL_OUTPUT_ROOT call :emitvar OUTPUT_ROOT DL_OUTPUT_ROOT
if defined DL_ACCOUNT_COOKIE call :emitvar ACCOUNT_COOKIE_FILE DL_ACCOUNT_COOKIE
if not defined DL_ACCOUNT_COOKIE if defined DL_COOKIE call :emitvar BROWSER_COOKIES DL_COOKIE
if defined DL_SCOPE call :emitvar SCOPE DL_SCOPE
if defined DL_REMUX call :emitvar REMUX DL_REMUX
if defined DL_FMT_VALUE call :emitvar FORMAT DL_FMT_VALUE

if defined DL_FMT_VALUE (
    "%YTDLP%" %DL_COMMON% %DL_COOKIE% %DL_SCOPE% -f "%DL_FMT_VALUE%" %DL_EXTRA% %DL_REMUX% -o "%DL_OUT%" "%URL%"
) else (
    "%YTDLP%" %DL_COMMON% %DL_COOKIE% %DL_SCOPE% %DL_EXTRA% %DL_REMUX% -o "%DL_OUT%" "%URL%"
)

if errorlevel 1 (
    if defined DL_FALLBACK (
        echo FALLBACK=1
        "%YTDLP%" %DL_COMMON% %DL_COOKIE% %DL_SCOPE% -f "b/bv*+ba" %DL_EXTRA% %DL_REMUX% -o "%DL_OUT%" "%URL%"
    )
)

if errorlevel 1 (
    echo STATUS=ERROR
    exit /b 1
)

echo STATUS=OK
exit /b 0

:run_format_list
set "FORMAT_COMMAND=%~1"
call :emitvar COMMAND FORMAT_COMMAND
call :emitvar URL URL
if defined COOKIE_FILE call :emitvar ACCOUNT_COOKIE_FILE COOKIE_FILE
if not defined COOKIE_FILE if defined COOKIEOPT call :emitvar BROWSER_COOKIES COOKIEOPT
"%YTDLP%" %COMMON% %COOKIEOPT% -F "%URL%"
if errorlevel 1 (
    echo STATUS=ERROR
    exit /b 1
)
echo STATUS=OK
exit /b 0

:set_browser_cookie
set "COOKIEOPT="
set "COOKIE_FILE="
if /I "%~1"=="chrome" (
    set "COOKIEOPT=--cookies-from-browser chrome"
    exit /b 0
)
if /I "%~1"=="edge" (
    set "COOKIEOPT=--cookies-from-browser edge"
    exit /b 0
)
echo STATUS=ERROR
echo MESSAGE=Browser must be chrome or edge
exit /b 1

:set_account_cookie
set "COOKIEOPT="
set "COOKIE_FILE="
if exist "%YT_COOKIES%" (
    set "COOKIEOPT=--cookies ""%YT_COOKIES%"""
    set "COOKIE_FILE=%YT_COOKIES%"
    exit /b 0
)
echo STATUS=ERROR
echo MESSAGE=Local YouTube cookie file was not found
echo COOKIE_FILE=%YT_COOKIES%
echo COOKIE_STORE_DIR=%COOKIE_STORE_DIR%
echo HINT=Export YouTube cookies in Netscape format to the COOKIE_FILE path above
exit /b 1

:count_saved_cookies
set "SAVED_COOKIE_COUNT=0"
for %%F in ("%COOKIE_STORE_DIR%\*.txt") do (
    if exist "%%~fF" set /a SAVED_COOKIE_COUNT+=1
)
exit /b 0

:emit_saved_cookie_list
set "SAVED_COOKIE_INDEX=0"
for /f "delims=" %%F in ('dir /b /a:-d "%COOKIE_STORE_DIR%\*.txt" 2^>nul') do (
    set /a SAVED_COOKIE_INDEX+=1
    set "SAVED_COOKIE_ENTRY=%%F"
    call :emitvar SAVED_COOKIE_!SAVED_COOKIE_INDEX! SAVED_COOKIE_ENTRY
)
set "SAVED_COOKIE_INDEX="
set "SAVED_COOKIE_ENTRY="
exit /b 0

:make_cookie_timestamp
set "COOKIE_TIMESTAMP="
for /f "delims=" %%A in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"') do (
    if not defined COOKIE_TIMESTAMP set "COOKIE_TIMESTAMP=%%A"
)
if not defined COOKIE_TIMESTAMP set "COOKIE_TIMESTAMP=manual-backup"
exit /b 0

:get_clip_url_only
set "URL="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "try { $c = Get-Clipboard; if ($c -match '^https?://') { $c } } catch { '' }"`) do (
    if not defined URL set "URL=%%A"
)
goto :eof

:check_required_files
set "MISSING="
if not exist "%YTDLP%" set "MISSING=%MISSING% yt-dlp.exe"
if not exist "%FFMPEG%" set "MISSING=%MISSING% ffmpeg.exe"
if not exist "%FFPROBE%" set "MISSING=%MISSING% ffprobe.exe"
if not defined MISSING exit /b 0
echo STATUS=ERROR
set "MESSAGE=Missing required files:%MISSING%"
call :emitvar MESSAGE MESSAGE
exit /b 1

:configureruntime
set "COMMON=%COMMON_BASE%"
set "NODE_STATUS=Node.js not found"
where node >nul 2>nul
if not errorlevel 1 (
    set "COMMON=%COMMON_BASE% --js-runtimes node"
    set "NODE_STATUS=Node.js detected"
)
goto :eof

:readtail
set "SKIPCOUNT=%~1"
set "TAIL=%*"
for /f "tokens=1,* delims= " %%A in ("!TAIL!") do set "TAIL=%%B"
for /l %%N in (1,1,!SKIPCOUNT!) do (
    for /f "tokens=1,* delims= " %%A in ("!TAIL!") do set "TAIL=%%B"
)
if defined TAIL if "!TAIL:~0,1!"=="^"" if "!TAIL:~-1!"=="^"" set "TAIL=!TAIL:~1,-1!"
set "SKIPCOUNT="
goto :eof

:stripquotes
call set "STRIP_VALUE=%%%~1%%"
set "STRIP_VALUE=!STRIP_VALUE:"=!"
set "%~1=%STRIP_VALUE%"
set "STRIP_VALUE="
goto :eof

:readarg
set "%~1=%2"
set "ARGRAW=!%~1!"
if defined ARGRAW if "!ARGRAW:~0,1!"=="^"" if "!ARGRAW:~-1!"=="^"" set "ARGRAW=!ARGRAW:~1,-1!"
set "%~1=%ARGRAW%"
set "ARGRAW="
goto :eof

:emitlocations
echo STATUS=OK
call :emitvar VIDEO_DIR VIDEO_DIR
call :emitvar AUDIO_DIR AUDIO_DIR
call :emitvar PRIVATE_DIR PRIVATE_DIR
call :emitvar ACCOUNT_COOKIE_FILE YT_COOKIES
call :emitvar COOKIE_STORE_DIR COOKIE_STORE_DIR
call :emitvar VIDEO_OUT VIDEO_OUT
call :emitvar AUDIO_OUT AUDIO_OUT
call :emitvar PLAYLIST_VIDEO_OUT PLAYLIST_VIDEO_OUT
call :emitvar PLAYLIST_AUDIO_OUT PLAYLIST_AUDIO_OUT
exit /b 0

:runalias
"%ComSpec%" /d /c ""%SELF%" %1 %2 %3 %4 %5 %6 %7 %8"
exit /b !errorlevel!

:emitvar
set "EMIT_KEY=%~1"
call set "EMIT_VALUE=%%%~2%%"
<nul set /p "=%EMIT_KEY%=%EMIT_VALUE%"
echo(
goto :eof
