@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "SCRIPT_DIR=%~dp0"
set "YTDLP=%SCRIPT_DIR%yt-dlp.exe"
set "FFMPEG=%SCRIPT_DIR%ffmpeg.exe"
set "FFPROBE=%SCRIPT_DIR%ffprobe.exe"

title yt-dlp Menu v11

REM =========================
REM FOLDERS
REM =========================
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

REM =========================
REM OUTPUT TEMPLATES
REM =========================
set "VIDEO_OUT=%VIDEO_DIR%\%%(uploader,creator,channel|Unknown Creator)s\%%(title)s [%%(id)s].%%(ext)s"
set "AUDIO_OUT=%AUDIO_DIR%\%%(uploader,creator,channel|Unknown Creator)s\%%(title)s [%%(id)s].%%(ext)s"
set "PLAYLIST_VIDEO_OUT=%VIDEO_DIR%\%%(playlist_title,album|Playlist)s\%%(playlist_index)03d - %%(title)s [%%(id)s].%%(ext)s"
set "PLAYLIST_AUDIO_OUT=%AUDIO_DIR%\%%(playlist_title,album|Playlist)s\%%(playlist_index)03d - %%(title)s [%%(id)s].%%(ext)s"

REM =========================
REM COMMON OPTIONS
REM =========================
set "COMMON_BASE=--windows-filenames --no-mtime --embed-metadata --retries 10 --fragment-retries 10"
set "COMMON="
set "BEST_FMT=bv*+ba/b"
set "LAST_BROWSER=none"
set "NODE_STATUS=Checking..."

call :check_required_files
if errorlevel 1 goto end
call :configure_runtime

REM Drag-and-drop / passed argument mode still works immediately
if not "%~1"=="" (
    set "URL=%*"
    if defined URL if "!URL:~0,1!"=="^"" if "!URL:~-1!"=="^"" set "URL=!URL:~1,-1!"
    goto hot_download
)

:startup
call :header "yt-dlp STARTUP"
echo QUICK ACTIONS
echo   1. Download video from clipboard and choose quality
echo   2. Open full menu
echo   3. Auto-download MP3 from clipboard
echo   4. Exit
echo.
echo SAVE LOCATIONS
echo   Video: %VIDEO_DIR%
echo   Audio: %AUDIO_DIR%
echo   JavaScript runtime: %NODE_STATUS%
echo.
choice /c 1234 /n /m "Choose an option (1-4): "
if errorlevel 4 goto end
if errorlevel 3 goto hot_mp3
if errorlevel 2 goto main_menu
if errorlevel 1 (
    call :get_clip_url_only
    if not defined URL (
        echo.
        echo I could not find a valid web link in the clipboard.
        call :wait
        goto startup
    )
    goto hot_download
)
goto startup

:main_menu
call :header "yt-dlp MENU v11"
echo SAVE LOCATIONS
echo   Video: %VIDEO_DIR%
echo   Audio: %AUDIO_DIR%
echo   JavaScript runtime: %NODE_STATUS%
echo.
echo HOT MODE
echo   1. Video from clipboard and choose quality
echo   2. Instant MP3 from clipboard
echo.
echo GUIDED
echo   3. Guided download wizard
echo.
echo DIRECT
echo   4. Download video and choose quality
echo   5. Download audio only (MP3)
echo   6. Show available formats
echo   7. Download a specific format
echo   8. Download a playlist as video and choose quality
echo   9. Download single video only and choose quality
echo   10. Download playlist as MP3
echo.
echo SUBTITLES / THUMBNAILS / CONTAINER
echo   11. Download video with subtitle files and choose quality
echo   12. Download video, embed subtitles, and choose quality
echo   13. Download thumbnail only
echo   14. Download MP3 and embed thumbnail
echo   15. Download video as MP4 and choose quality
echo   16. Download video as MKV and choose quality
echo.
echo LOGGED-IN WEBPAGE / COOKIES
echo   17. Download from logged-in webpage (Chrome) and choose quality
echo   18. Show formats from logged-in webpage (Chrome)
echo   19. Download single video from logged-in webpage (Chrome) and choose quality
echo   20. Download from logged-in webpage (Edge) and choose quality
echo   21. Show formats from logged-in webpage (Edge)
echo   22. Download single video from logged-in webpage (Edge) and choose quality
echo.
echo TOOLS
echo   23. Open tools and settings
echo   24. Open Videos download folder
echo   25. Open Music download folder
echo   26. Exit
echo.
set "choice="
set /p "choice=Choose an option (1-26): "

if "%choice%"=="1" goto hot_video_manual
if "%choice%"=="2" goto hot_mp3
if "%choice%"=="3" goto guided
if "%choice%"=="4" goto bestvideo
if "%choice%"=="5" goto mp3
if "%choice%"=="6" goto formats
if "%choice%"=="7" goto specificformat
if "%choice%"=="8" goto playlistvideo
if "%choice%"=="9" goto singlevideo
if "%choice%"=="10" goto playlistmp3
if "%choice%"=="11" goto video_subtitles
if "%choice%"=="12" goto video_embed_subtitles
if "%choice%"=="13" goto thumbnail_only
if "%choice%"=="14" goto mp3_embed_thumb
if "%choice%"=="15" goto bestvideo_mp4
if "%choice%"=="16" goto bestvideo_mkv
if "%choice%"=="17" goto chrome_download
if "%choice%"=="18" goto chrome_formats
if "%choice%"=="19" goto chrome_single
if "%choice%"=="20" goto edge_download
if "%choice%"=="21" goto edge_formats
if "%choice%"=="22" goto edge_single
if "%choice%"=="23" goto tools_menu
if "%choice%"=="24" goto openvideos
if "%choice%"=="25" goto openmusic
if "%choice%"=="26" goto end

echo.
echo That was not a valid option.
call :wait
goto main_menu

:hot_video_manual
call :get_clip_url_only
if not defined URL (
    echo I could not find a valid web link in the clipboard.
    call :wait
    goto main_menu
)
goto hot_download

:hot_download
call :reset_download_vars
set "DL_TITLE=Hot Mode Video Download"
set "DL_STATUS=Video download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_OPEN_DIR=%VIDEO_DIR%"
set "DL_SUMMARY=Starting video download..."
call :run_download
goto main_menu

:hot_mp3
call :header "Hot Mode MP3 Download"
call :get_clip_url_only
if not defined URL (
    echo I could not find a valid web link in the clipboard.
    call :wait
    goto startup
)

call :reset_download_vars
set "DL_TITLE=Hot Mode MP3 Download"
set "DL_STATUS=MP3 download"
set "DL_OUT=%AUDIO_OUT%"
set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0"
set "DL_FALLBACK="
set "DL_OPEN_DIR=%AUDIO_DIR%"
set "DL_SUMMARY=Starting MP3 download..."
call :run_download
goto main_menu

:guided
call :header "Guided Download Wizard"
call :get_url
if not defined URL (
    echo.
    echo No link was entered.
    call :wait
    goto main_menu
)

call :header "Guided Download Wizard"
echo URL:
echo %URL%
echo.
echo What do you want to download?
echo.
echo 1. Video and choose quality
echo 2. Audio only (MP3)
echo 3. Video with subtitle files and choose quality
echo 4. Video with embedded subtitles and choose quality
echo 5. Thumbnail only
echo 6. MP3 with embedded thumbnail
echo 7. Show available formats only
echo 8. Download a specific format
echo.
choice /c 12345678 /n /m "Choose an option (1-8): "
set "G_MODE=%errorlevel%"

if "%G_MODE%"=="7" goto guided_formats
if "%G_MODE%"=="8" goto guided_specific

call :reset_download_vars
if "%G_MODE%"=="1" (
    set "DL_OUT=%VIDEO_OUT%"
    set "DL_FMT=-f "%BEST_FMT%""
    set "DL_PICK_QUALITY=1"
    set "DL_SUMMARY=Preparing video download..."
)
if "%G_MODE%"=="2" (
    set "DL_OUT=%AUDIO_OUT%"
    set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0"
    set "DL_FALLBACK="
    set "DL_SUMMARY=Preparing MP3 download..."
)
if "%G_MODE%"=="3" (
    set "DL_OUT=%VIDEO_OUT%"
    set "DL_FMT=-f "%BEST_FMT%""
    set "DL_PICK_QUALITY=1"
    set "DL_EXTRA=--write-subs --write-auto-subs --sub-langs "all,-live_chat""
    set "DL_SUMMARY=Preparing subtitle video download..."
)
if "%G_MODE%"=="4" (
    set "DL_OUT=%VIDEO_OUT%"
    set "DL_FMT=-f "%BEST_FMT%""
    set "DL_PICK_QUALITY=1"
    set "DL_EXTRA=--write-subs --write-auto-subs --embed-subs --sub-langs "all,-live_chat""
    set "DL_SUMMARY=Preparing video download with embedded subtitles..."
)
if "%G_MODE%"=="5" (
    set "DL_OUT=%VIDEO_OUT%"
    set "DL_EXTRA=--skip-download --write-thumbnail --convert-thumbnails jpg"
    set "DL_FALLBACK="
    set "DL_SUMMARY=Preparing thumbnail-only download..."
)
if "%G_MODE%"=="6" (
    set "DL_OUT=%AUDIO_OUT%"
    set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0 --embed-thumbnail --write-thumbnail"
    set "DL_FALLBACK="
    set "DL_SUMMARY=Preparing MP3 download with thumbnail..."
)

if not defined DL_OUT (
    echo That was not a valid option.
    call :wait
    goto main_menu
)

set "DL_TITLE=Guided Download Wizard"
set "DL_STATUS=Guided download"
call :choose_browser_cookie "Use browser cookies?"

call :header "Guided Download Wizard"
echo Download type?
echo.
echo 1. Normal
echo 2. Single video only
echo 3. Playlist
echo.
choice /c 123 /n /m "Choose an option (1-3): "
set "G_SCOPE=%errorlevel%"

if "%G_SCOPE%"=="2" set "DL_SCOPE=--no-playlist"
if "%G_SCOPE%"=="3" (
    if "%G_MODE%"=="1" set "DL_OUT=%PLAYLIST_VIDEO_OUT%"
    if "%G_MODE%"=="2" set "DL_OUT=%PLAYLIST_AUDIO_OUT%"
    if "%G_MODE%"=="3" set "DL_OUT=%PLAYLIST_VIDEO_OUT%"
    if "%G_MODE%"=="4" set "DL_OUT=%PLAYLIST_VIDEO_OUT%"
    if "%G_MODE%"=="6" set "DL_OUT=%PLAYLIST_AUDIO_OUT%"
)

if "%G_MODE%"=="1" goto guided_container
if "%G_MODE%"=="3" goto guided_container
if "%G_MODE%"=="4" goto guided_container
goto run_guided_download

:guided_container
call :header "Guided Download Wizard"
echo Container preference?
echo.
echo 1. Auto
echo 2. MP4
echo 3. MKV
echo.
choice /c 123 /n /m "Choose an option (1-3): "
set "G_CONTAINER=%errorlevel%"
if "%G_CONTAINER%"=="2" set "DL_REMUX=--remux-video mp4"
if "%G_CONTAINER%"=="3" set "DL_REMUX=--remux-video mkv"

:run_guided_download
call :run_download
goto main_menu

:guided_formats
call :choose_browser_cookie "Use browser cookies for format check?"
call :run_format_list "Available Formats" "Format check"
goto main_menu

:guided_specific
call :choose_browser_cookie "Use browser cookies for specific-format download?"
call :run_format_list "Fetch Available Formats" "Format check"
if errorlevel 1 goto main_menu

echo.
set "FORMATID="
set /p "FORMATID=Enter the format ID: "
if not defined FORMATID (
    echo.
    echo No format ID was entered.
    call :wait
    goto main_menu
)

call :header "Guided Specific Format"
echo Treat as:
echo.
echo 1. Normal
echo 2. Single video only
echo.
choice /c 12 /n /m "Choose an option (1-2): "
set "GSS=%errorlevel%"

call :reset_download_vars
set "DL_TITLE=Guided Specific Format"
set "DL_STATUS=Specific format download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%FORMATID%""
set "DL_COOKIE=%COOKIEOPT%"
if "%GSS%"=="2" set "DL_SCOPE=--no-playlist"
call :run_download
goto main_menu

:bestvideo
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download Video"
set "DL_STATUS=Video download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
call :run_download
goto main_menu

:mp3
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download Audio Only as MP3"
set "DL_STATUS=MP3 download"
set "DL_OUT=%AUDIO_OUT%"
set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0"
set "DL_FALLBACK="
call :run_download
goto main_menu

:formats
call :get_url_or_menu
set "COOKIEOPT="
call :run_format_list "Show Available Formats" "Format check"
goto main_menu

:specificformat
call :get_url_or_menu
set "COOKIEOPT="
call :run_format_list "Download Specific Format" "Format check"
if errorlevel 1 goto main_menu

echo.
set "FORMATID="
set /p "FORMATID=Enter format ID: "
if not defined FORMATID (
    echo.
    echo No format ID was entered.
    call :wait
    goto main_menu
)

call :reset_download_vars
set "DL_TITLE=Download Specific Format"
set "DL_STATUS=Specific format download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%FORMATID%""
call :run_download
goto main_menu

:playlistvideo
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download Playlist as Video"
set "DL_STATUS=Playlist video download"
set "DL_OUT=%PLAYLIST_VIDEO_OUT%"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_SUMMARY=Playlist downloads work best with Automatic best quality."
call :run_download
goto main_menu

:singlevideo
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download Single Video Only"
set "DL_STATUS=Single video download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_SCOPE=--no-playlist"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
call :run_download
goto main_menu

:playlistmp3
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download Playlist as MP3"
set "DL_STATUS=Playlist MP3 download"
set "DL_OUT=%PLAYLIST_AUDIO_OUT%"
set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0"
set "DL_FALLBACK="
call :run_download
goto main_menu

:video_subtitles
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download Video with Subtitle Files"
set "DL_STATUS=Subtitle download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_EXTRA=--write-subs --write-auto-subs --sub-langs "all,-live_chat""
call :run_download
goto main_menu

:video_embed_subtitles
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download Video and Embed Subtitles"
set "DL_STATUS=Embedded subtitle download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_EXTRA=--write-subs --write-auto-subs --embed-subs --sub-langs "all,-live_chat""
call :run_download
goto main_menu

:thumbnail_only
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download Thumbnail Only"
set "DL_STATUS=Thumbnail download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_EXTRA=--skip-download --write-thumbnail --convert-thumbnails jpg"
set "DL_FALLBACK="
call :run_download
goto main_menu

:mp3_embed_thumb
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download MP3 and Embed Thumbnail"
set "DL_STATUS=MP3 with thumbnail download"
set "DL_OUT=%AUDIO_OUT%"
set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0 --embed-thumbnail --write-thumbnail"
set "DL_FALLBACK="
call :run_download
goto main_menu

:bestvideo_mp4
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download Video as MP4"
set "DL_STATUS=MP4 download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_REMUX=--remux-video mp4"
call :run_download
goto main_menu

:bestvideo_mkv
call :get_url_or_menu
call :reset_download_vars
set "DL_TITLE=Download Video as MKV"
set "DL_STATUS=MKV download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_REMUX=--remux-video mkv"
call :run_download
goto main_menu

:chrome_download
call :get_url_or_menu
set "LAST_BROWSER=chrome"
call :reset_download_vars
set "DL_TITLE=Download from Logged-in Webpage (Chrome)"
set "DL_STATUS=Chrome cookie download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_COOKIE=--cookies-from-browser chrome"
call :run_download
goto main_menu

:chrome_formats
call :get_url_or_menu
set "LAST_BROWSER=chrome"
set "COOKIEOPT=--cookies-from-browser chrome"
call :run_format_list "Show Formats from Logged-in Webpage (Chrome)" "Chrome format check"
goto main_menu

:chrome_single
call :get_url_or_menu
set "LAST_BROWSER=chrome"
call :reset_download_vars
set "DL_TITLE=Download Single Video from Logged-in Webpage (Chrome)"
set "DL_STATUS=Chrome single video download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_SCOPE=--no-playlist"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_COOKIE=--cookies-from-browser chrome"
call :run_download
goto main_menu

:edge_download
call :get_url_or_menu
set "LAST_BROWSER=edge"
call :reset_download_vars
set "DL_TITLE=Download from Logged-in Webpage (Edge)"
set "DL_STATUS=Edge cookie download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_COOKIE=--cookies-from-browser edge"
call :run_download
goto main_menu

:edge_formats
call :get_url_or_menu
set "LAST_BROWSER=edge"
set "COOKIEOPT=--cookies-from-browser edge"
call :run_format_list "Show Formats from Logged-in Webpage (Edge)" "Edge format check"
goto main_menu

:edge_single
call :get_url_or_menu
set "LAST_BROWSER=edge"
call :reset_download_vars
set "DL_TITLE=Download Single Video from Logged-in Webpage (Edge)"
set "DL_STATUS=Edge single video download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_SCOPE=--no-playlist"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_COOKIE=--cookies-from-browser edge"
call :run_download
goto main_menu

:tools_menu
call :header "Tools and Settings"
echo 1. Show save locations and templates
echo 2. Show JavaScript runtime status
echo 3. Show program file locations
echo 4. Update yt-dlp
echo 5. Open Videos download folder
echo 6. Open Music download folder
echo 7. Open YouTube account tools
echo 8. Return to the main menu
echo.
choice /c 12345678 /n /m "Choose an option (1-8): "
if errorlevel 8 goto main_menu
if errorlevel 7 goto account_tools
if errorlevel 6 goto openmusic
if errorlevel 5 goto openvideos
if errorlevel 4 goto update
if errorlevel 3 goto showprogramfiles
if errorlevel 2 goto shownode
if errorlevel 1 goto showpaths
goto tools_menu

:showpaths
call :header "Save Locations and Templates"
echo VIDEO FOLDER
echo   %VIDEO_DIR%
echo.
echo AUDIO FOLDER
echo   %AUDIO_DIR%
echo.
echo VIDEO OUTPUT TEMPLATE
echo   %VIDEO_OUT%
echo.
echo AUDIO OUTPUT TEMPLATE
echo   %AUDIO_OUT%
echo.
echo PLAYLIST VIDEO TEMPLATE
echo   %PLAYLIST_VIDEO_OUT%
echo.
echo PLAYLIST AUDIO TEMPLATE
echo   %PLAYLIST_AUDIO_OUT%
echo.
echo PRIVATE ACCOUNT FOLDER
echo   %PRIVATE_DIR%
echo.
echo LOCAL YOUTUBE COOKIE FILE
echo   %YT_COOKIES%
echo.
echo SAVED COOKIE STORE
echo   %COOKIE_STORE_DIR%
call :wait
goto tools_menu

:shownode
call :header "JavaScript Runtime Status"
echo RUNTIME STATUS
echo   %NODE_STATUS%
echo.
echo ACTIVE yt-dlp OPTIONS
echo   %COMMON_BASE%
if /I "%NODE_STATUS%"=="Node.js detected" echo   --js-runtimes node
echo.
where node >nul 2>nul
if errorlevel 1 (
    echo Node.js is not currently available on PATH.
    echo yt-dlp will run with its default JavaScript handling.
    call :wait
    goto tools_menu
)
echo NODE EXECUTABLE FOUND ON PATH
for /f "delims=" %%A in ('where node 2^>nul') do (
    echo   %%A
    goto shownode_done
)
:shownode_done
call :wait
goto tools_menu

:showprogramfiles
call :header "Program File Locations"
echo yt-dlp
echo   %YTDLP%
echo.
echo ffmpeg
echo   %FFMPEG%
echo.
echo ffprobe
echo   %FFPROBE%
echo.
echo SCRIPT FOLDER
echo   %SCRIPT_DIR%
echo.
echo PRIVATE ACCOUNT FOLDER
echo   %PRIVATE_DIR%
echo.
echo LOCAL YOUTUBE COOKIE FILE
echo   %YT_COOKIES%
echo.
echo SAVED COOKIE STORE
echo   %COOKIE_STORE_DIR%
call :wait
goto tools_menu

:update
call :header "Update yt-dlp"
echo Updating yt-dlp...
echo.
"%YTDLP%" -U
call :show_result "yt-dlp update"
goto main_menu

:openvideos
start "" "%VIDEO_DIR%"
goto main_menu

:openmusic
start "" "%AUDIO_DIR%"
goto main_menu

:account_tools
call :header "YouTube Account Tools"
echo 1. Show local account cookie status
echo 2. Download video using local YouTube cookies and choose quality
echo 3. Download audio only ^(MP3^) using local YouTube cookies
echo 4. Show formats using local YouTube cookies
echo 5. Download single video using local YouTube cookies and choose quality
echo 6. Open cookie file manager
echo 7. Return to tools and settings
echo.
choice /c 1234567 /n /m "Choose an option (1-7): "
if errorlevel 7 goto tools_menu
if errorlevel 6 goto cookie_manager
if errorlevel 5 goto account_single
if errorlevel 4 goto account_formats
if errorlevel 3 goto account_mp3
if errorlevel 2 goto account_video
if errorlevel 1 goto showaccountstatus
goto account_tools

:showaccountstatus
call :header "Local YouTube Account Status"
call :count_saved_cookies
echo COOKIE FILE
echo   %YT_COOKIES%
echo.
echo SAVED COOKIE STORE
echo   %COOKIE_STORE_DIR%
echo.
echo SAVED COOKIE FILES
echo   %SAVED_COOKIE_COUNT%
echo.
if exist "%YT_COOKIES%" (
    echo STATUS
    echo   Ready for local account downloads
    for %%A in ("%YT_COOKIES%") do (
        echo.
        echo FILE SIZE
        echo   %%~zA bytes
        echo.
        echo LAST MODIFIED
        echo   %%~tA
    )
    echo.
    echo This file stays on this computer.
    call :wait
    goto account_tools
)
echo STATUS
echo   Not configured yet
echo.
echo To enable local account downloads:
echo   1. Export your YouTube cookies in Netscape format.
echo   2. Save the file here:
echo      %YT_COOKIES%
echo   3. Return to this menu and try again.
echo.
echo Your password is not stored in this menu.
call :wait
goto account_tools

:cookie_manager
call :header "Cookie File Manager"
call :count_saved_cookies
echo ACTIVE COOKIE FILE
echo   %YT_COOKIES%
echo.
if exist "%YT_COOKIES%" (
    echo ACTIVE COOKIE STATUS
    echo   Ready
) else (
    echo ACTIVE COOKIE STATUS
    echo   Not configured yet
)
echo.
echo SAVED COOKIE STORE
echo   %COOKIE_STORE_DIR%
echo.
echo SAVED COOKIE FILES
echo   %SAVED_COOKIE_COUNT%
echo.
echo 1. Show active cookie status
echo 2. Open Private account folder
echo 3. Open saved cookie store folder
echo 4. Save the current active cookie into the store
echo 5. Activate a saved cookie from the store
echo 6. Return to YouTube account tools
echo.
choice /c 123456 /n /m "Choose an option (1-6): "
if errorlevel 6 goto account_tools
if errorlevel 5 goto activate_saved_cookie
if errorlevel 4 goto archive_active_cookie
if errorlevel 3 goto open_cookie_store
if errorlevel 2 goto open_private_folder
if errorlevel 1 goto showaccountstatus
goto cookie_manager

:open_private_folder
start "" "%PRIVATE_DIR%"
goto cookie_manager

:open_cookie_store
start "" "%COOKIE_STORE_DIR%"
goto cookie_manager

:archive_active_cookie
call :header "Save Active Cookie to Store"
if not exist "%YT_COOKIES%" (
    echo There is no active cookie file to save right now.
    echo.
    echo Add or activate a cookie file first, then try again.
    call :wait
    goto cookie_manager
)
call :make_cookie_timestamp
set "COOKIE_ARCHIVE_TARGET=%COOKIE_STORE_DIR%\youtube-cookies-%COOKIE_TIMESTAMP%.txt"
copy /y "%YT_COOKIES%" "%COOKIE_ARCHIVE_TARGET%" >nul
if errorlevel 1 (
    echo I could not save the active cookie into the store.
) else (
    echo The active cookie was saved here:
    echo   %COOKIE_ARCHIVE_TARGET%
)
call :wait
goto cookie_manager

:activate_saved_cookie
call :header "Activate Saved Cookie"
call :count_saved_cookies
if "%SAVED_COOKIE_COUNT%"=="0" (
    echo There are no saved cookie files in the store yet.
    echo.
    echo Store folder:
    echo   %COOKIE_STORE_DIR%
    call :wait
    goto cookie_manager
)
echo STORE FOLDER
echo   %COOKIE_STORE_DIR%
echo.
echo SAVED COOKIE FILES
for /f "delims=" %%F in ('dir /b /a:-d "%COOKIE_STORE_DIR%\*.txt" 2^>nul') do echo   %%F
echo.
echo Type the file name exactly as shown above.
echo Type C to cancel.
echo.
:activate_saved_cookie_loop
set "COOKIE_SELECTION="
set /p "COOKIE_SELECTION=Saved cookie file to activate: "
set "COOKIE_SELECTION=%COOKIE_SELECTION:"=%"
if not defined COOKIE_SELECTION (
    echo Please enter a file name or C to cancel.
    goto activate_saved_cookie_loop
)
if /I "%COOKIE_SELECTION%"=="C" goto cookie_manager
if not exist "%COOKIE_STORE_DIR%\%COOKIE_SELECTION%" (
    echo I could not find that file in the cookie store.
    echo.
    goto activate_saved_cookie_loop
)
set "COOKIE_BACKUP_TARGET="
if exist "%YT_COOKIES%" (
    call :make_cookie_timestamp
    set "COOKIE_BACKUP_TARGET=%COOKIE_STORE_DIR%\active-before-switch-%COOKIE_TIMESTAMP%.txt"
    copy /y "%YT_COOKIES%" "%COOKIE_BACKUP_TARGET%" >nul
    if errorlevel 1 (
        echo I could not back up the current active cookie before switching.
        call :wait
        goto cookie_manager
    )
)
copy /y "%COOKIE_STORE_DIR%\%COOKIE_SELECTION%" "%YT_COOKIES%" >nul
if errorlevel 1 (
    echo I could not activate that saved cookie file.
) else (
    echo The active cookie file is now:
    echo   %YT_COOKIES%
    echo.
    echo Activated from:
    echo   %COOKIE_STORE_DIR%\%COOKIE_SELECTION%
    if defined COOKIE_BACKUP_TARGET (
        echo.
        echo Your previous active cookie was backed up here:
        echo   %COOKIE_BACKUP_TARGET%
    )
)
call :wait
goto cookie_manager

:account_video
call :require_account_cookie
if errorlevel 1 goto account_tools
call :get_url_or_account_tools
call :reset_download_vars
set "DL_TITLE=Download with Local YouTube Account"
set "DL_STATUS=Account video download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_COOKIE=--cookies ""%YT_COOKIES%"""
set "DL_OPEN_DIR=%VIDEO_DIR%"
set "DL_SUMMARY=Starting video download with local YouTube cookies..."
call :run_download
goto account_tools

:account_mp3
call :require_account_cookie
if errorlevel 1 goto account_tools
call :get_url_or_account_tools
call :reset_download_vars
set "DL_TITLE=Download MP3 with Local YouTube Account"
set "DL_STATUS=Account MP3 download"
set "DL_OUT=%AUDIO_OUT%"
set "DL_EXTRA=-x --audio-format mp3 --audio-quality 0"
set "DL_FALLBACK="
set "DL_COOKIE=--cookies ""%YT_COOKIES%"""
set "DL_OPEN_DIR=%AUDIO_DIR%"
set "DL_SUMMARY=Starting MP3 download with local YouTube cookies..."
call :run_download
goto account_tools

:account_formats
call :require_account_cookie
if errorlevel 1 goto account_tools
call :get_url_or_account_tools
set "COOKIEOPT=--cookies ""%YT_COOKIES%"""
call :run_format_list "Show Formats Using Local YouTube Account" "Account format check"
goto account_tools

:account_single
call :require_account_cookie
if errorlevel 1 goto account_tools
call :get_url_or_account_tools
call :reset_download_vars
set "DL_TITLE=Download Single Video with Local YouTube Account"
set "DL_STATUS=Account single video download"
set "DL_OUT=%VIDEO_OUT%"
set "DL_SCOPE=--no-playlist"
set "DL_FMT=-f "%BEST_FMT%""
set "DL_PICK_QUALITY=1"
set "DL_COOKIE=--cookies ""%YT_COOKIES%"""
set "DL_OPEN_DIR=%VIDEO_DIR%"
set "DL_SUMMARY=Starting single-video download with local YouTube cookies..."
call :run_download
goto account_tools

:get_clip_url_only
set "URL="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "try { $c = Get-Clipboard; if ($c -match '^https?://') { $c } } catch { '' }"`) do (
    if not defined URL set "URL=%%A"
)
goto :eof

:get_url
set "URL="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "try { Get-Clipboard } catch { '' }"`) do (
    if not defined URL set "URL=%%A"
)
echo.
if defined URL (
    echo CLIPBOARD TEXT FOUND
    echo !URL!
    echo.
    choice /c YN /n /m "Use this link? (Y/N): "
    if errorlevel 2 goto get_url_manual
    if errorlevel 1 goto :eof
)
:get_url_manual
set "URL="
set /p "URL=Paste the video or playlist link here: "
goto :eof

:get_url_or_menu
call :get_url
if defined URL goto :eof
echo.
echo No link was entered.
call :wait
goto main_menu

:get_url_or_account_tools
call :get_url
if defined URL goto :eof
echo.
echo No link was entered.
call :wait
goto account_tools

:reset_download_vars
set "DL_TITLE="
set "DL_STATUS="
set "DL_OUT="
set "DL_FMT="
set "DL_PICK_QUALITY="
set "DL_FORMAT_LABEL="
set "DL_EXTRA="
set "DL_SCOPE="
set "DL_REMUX="
set "DL_COOKIE="
set "DL_FALLBACK=1"
set "DL_OPEN_DIR="
set "DL_SUMMARY="
goto :eof

:run_download
if defined DL_PICK_QUALITY (
    call :choose_video_quality
    if errorlevel 2 (
        echo.
        echo Download cancelled.
        call :wait
        goto :eof
    )
    if errorlevel 1 (
        call :show_result "%DL_STATUS%"
        goto :eof
    )
)

call :header "%DL_TITLE%"
if /I "%DL_COOKIE%"=="--cookies-from-browser chrome" echo For best results, close Chrome completely first.
if /I "%DL_COOKIE%"=="--cookies-from-browser edge" echo For best results, close Edge completely first.
echo URL
echo %URL%
echo.
if defined DL_SUMMARY echo %DL_SUMMARY%
if defined DL_COOKIE echo Authentication: %DL_COOKIE%
if defined DL_FORMAT_LABEL echo Selected quality: %DL_FORMAT_LABEL%
if defined DL_SCOPE echo Download scope: %DL_SCOPE%
if defined DL_REMUX echo Container choice: %DL_REMUX%
echo.

"%YTDLP%" %COMMON% %DL_COOKIE% %DL_SCOPE% %DL_FMT% %DL_EXTRA% %DL_REMUX% -o "%DL_OUT%" "%URL%"
if errorlevel 1 (
    if defined DL_FALLBACK (
        echo.
        echo That attempt failed. Trying a safer fallback...
        echo.
        "%YTDLP%" %COMMON% %DL_COOKIE% %DL_SCOPE% -f "b/bv*+ba" %DL_EXTRA% %DL_REMUX% -o "%DL_OUT%" "%URL%"
    )
)

if not errorlevel 1 if defined DL_OPEN_DIR start "" "%DL_OPEN_DIR%"
call :show_result "%DL_STATUS%"
goto :eof

:choose_video_quality
call :header "Choose Video Quality"
if /I "%DL_COOKIE%"=="--cookies-from-browser chrome" echo For best results, close Chrome completely first.
if /I "%DL_COOKIE%"=="--cookies-from-browser edge" echo For best results, close Edge completely first.
echo URL
echo %URL%
echo.
if defined DL_SUMMARY echo %DL_SUMMARY%
if defined DL_SCOPE if /I not "%DL_SCOPE%"=="--no-playlist" echo If this link is a playlist, Automatic best quality is usually the safest choice.
echo.
echo Available qualities
echo.
"%YTDLP%" %COMMON% %DL_COOKIE% %DL_SCOPE% -F "%URL%"
if errorlevel 1 exit /b 1
echo.
echo Type one of the following:
echo   A = Automatic best quality
echo   C = Cancel this download
echo   Or enter a format ID or format combination exactly as shown above.
echo   Examples: 18   or   299+140
echo   If a row says "video only", add an audio format too.
echo.
:choose_video_quality_loop
set "QUALITY_CHOICE="
set /p "QUALITY_CHOICE=Quality choice: "
set "QUALITY_CHOICE=%QUALITY_CHOICE:"=%"
if not defined QUALITY_CHOICE (
    echo Please enter A, C, or a format choice from the list.
    goto choose_video_quality_loop
)
if /I "%QUALITY_CHOICE%"=="A" (
    set "DL_FORMAT_LABEL=Automatic best quality"
    exit /b 0
)
if /I "%QUALITY_CHOICE%"=="AUTO" (
    set "DL_FORMAT_LABEL=Automatic best quality"
    exit /b 0
)
if /I "%QUALITY_CHOICE%"=="C" exit /b 2
set "DL_FMT=-f "%QUALITY_CHOICE%""
set "DL_FORMAT_LABEL=%QUALITY_CHOICE%"
set "DL_FALLBACK="
exit /b 0

:run_format_list
call :header "%~1"
if /I "%COOKIEOPT%"=="--cookies-from-browser chrome" echo For best results, close Chrome completely first.
if /I "%COOKIEOPT%"=="--cookies-from-browser edge" echo For best results, close Edge completely first.
echo URL
echo %URL%
echo.
echo Checking available formats...
echo.
"%YTDLP%" %COMMON% %COOKIEOPT% -F "%URL%"
if errorlevel 1 (
    call :show_result "%~2"
    exit /b 1
)
call :show_result "%~2"
exit /b 0

:require_account_cookie
if exist "%YT_COOKIES%" exit /b 0
call :header "Local YouTube Cookie File Missing"
echo I could not find the local YouTube cookie file:
echo   %YT_COOKIES%
echo.
echo To enable account downloads:
echo   1. Export your YouTube cookies in Netscape format.
echo   2. Save the file at the path above.
echo   3. Or use the Cookie File Manager to activate a saved cookie.
echo   4. Run this option again.
echo.
echo Your password is not stored in this menu.
call :wait
exit /b 1

:count_saved_cookies
set "SAVED_COOKIE_COUNT=0"
for %%F in ("%COOKIE_STORE_DIR%\*.txt") do (
    if exist "%%~fF" set /a SAVED_COOKIE_COUNT+=1
)
goto :eof

:make_cookie_timestamp
set "COOKIE_TIMESTAMP="
for /f "delims=" %%A in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"') do (
    if not defined COOKIE_TIMESTAMP set "COOKIE_TIMESTAMP=%%A"
)
if not defined COOKIE_TIMESTAMP set "COOKIE_TIMESTAMP=manual-backup"
goto :eof

:check_required_files
set "MISSING="
if not exist "%YTDLP%" set "MISSING=%MISSING% yt-dlp.exe"
if not exist "%FFMPEG%" set "MISSING=%MISSING% ffmpeg.exe"
if not exist "%FFPROBE%" set "MISSING=%MISSING% ffprobe.exe"

if defined MISSING (
    call :header "Required Files Missing"
    echo The menu cannot run correctly because these required files are missing:
    echo.
    echo %MISSING%
    echo.
    echo Expected folder:
    echo %SCRIPT_DIR%
    call :wait
    exit /b 1
)

exit /b 0

:configure_runtime
set "COMMON=%COMMON_BASE%"
set "NODE_STATUS=Node.js not found (using yt-dlp defaults)"
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

:readarg
set "%~1=%2"
set "ARGRAW=!%~1!"
if defined ARGRAW if "!ARGRAW:~0,1!"=="^"" if "!ARGRAW:~-1!"=="^"" set "ARGRAW=!ARGRAW:~1,-1!"
set "%~1=%ARGRAW%"
set "ARGRAW="
goto :eof

:choose_browser_cookie
set "COOKIEOPT="

:choose_browser_cookie_loop
call :header "Browser Cookies"
echo %~1
echo.
echo 1. No
echo 2. Chrome
echo 3. Edge
echo 4. Reuse last browser choice (%LAST_BROWSER%)
echo.
choice /c 1234 /n /m "Choose an option (1-4): "
if errorlevel 4 (
    if /I "%LAST_BROWSER%"=="chrome" set "COOKIEOPT=--cookies-from-browser chrome"
    if /I "%LAST_BROWSER%"=="edge" set "COOKIEOPT=--cookies-from-browser edge"
    goto :eof
)
if errorlevel 3 (
    set "COOKIEOPT=--cookies-from-browser edge"
    set "LAST_BROWSER=edge"
    goto :eof
)
if errorlevel 2 (
    set "COOKIEOPT=--cookies-from-browser chrome"
    set "LAST_BROWSER=chrome"
    goto :eof
)
if errorlevel 1 goto :eof
goto choose_browser_cookie_loop

:header
cls
echo ==================================================
echo                 %~1
echo ==================================================
echo.
goto :eof

:show_result
if errorlevel 1 (
    echo.
    echo %~1 did not complete. Please review the message above.
    call :wait
    goto :eof
)

echo.
echo %~1 completed successfully.
call :wait
goto :eof

:wait
echo.
set "CONTINUE_PROMPT="
set /p "CONTINUE_PROMPT=Press Enter to continue... "
goto :eof

:end
exit /b 0
