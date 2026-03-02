#Requires AutoHotkey v2.0

; bacause all this just won't work I gess I  cannot get win+l to work.
; so I'll use a keybord hack instead


; free up win+l for future use by enabeling and disabling screen locking as needed

; value = 1 disable locking (and the Win+L shortcut)
; value = 0 enables locking (either by the shortcut or other means)
; SetDisableLockWorkstationRegKeyValue( value ) {
;     MsgBox(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System" , "DisableLockWorkstation", "not set"))
;     RegWrite(value, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableLockWorkstation")
;     MsgBox(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System" , "DisableLockWorkstation", "not set"))
; 
; }
; 
; OnExitSub(ExitReason, ExitCode) {
;   ; Enable LockWorkStation, because this script is ending (so other applications aren't further disturbed)
;   SetDisableLockWorkstationRegKeyValue( 0 )
;   ExitApp
; }
; 
; OnExit(OnExitSub)
; SetDisableLockWorkstationRegKeyValue( 1 )
; 
; ^!l:: ; Ctrl-Alt-l
; {
;   MsgBox("Attempting to Lock screen")
;   ; Temporary enable locking
;   SetDisableLockWorkstationRegKeyValue( 0 )
;   DllCall( "User32\LockWorkStation" )
;   ; Disable locking again 
;   SetDisableLockWorkstationRegKeyValue( 1 )
; }




; source https://github.com/isomoes/ahk-win/blob/main/key.ahk
; but with the vim stuff striped because vim_ahk is better for this

; Window focus navigation functions
GetVisibleWindows() {
    windows := []
    windowList := WinGetList()

    for hwnd in windowList {
        ; Skip if window is minimized or not visible
        if (WinGetMinMax(hwnd) == -1 || !WinExist(hwnd))
            continue

        ; Get window position and size
        WinGetPos(&x, &y, &width, &height, hwnd)

        ; Skip windows with invalid dimensions
        if (width <= 0 || height <= 0)
            continue

        ; Get window title for debugging
        title := WinGetTitle(hwnd)

        ; Skip windows without titles (usually system windows)
        if (title == "")
            continue

        ; Skip keyviz tool windows (key visualization tools)
        if (InStr(title, "keyviz") || InStr(title, "KeyViz") || InStr(title, "KEYVIZ"))
            continue

        windows.Push({
            hwnd: hwnd,
            x: x,
            y: y,
            width: width,
            height: height,
            title: title,
            right: x + width,
            bottom: y + height
        })
    }

    return windows
}

GetCurrentWindow() {
    hwnd := WinGetID("A")
    if (!hwnd)
        return ""

    WinGetPos(&x, &y, &width, &height, hwnd)
    title := WinGetTitle(hwnd)

    return {
        hwnd: hwnd,
        x: x,
        y: y,
        width: width,
        height: height,
        title: title,
        right: x + width,
        bottom: y + height
    }
}

FindWindowInDirection(direction) {
    current := GetCurrentWindow()
    if (!current)
        return ""

    windows := GetVisibleWindows()
    bestWindow := ""
    bestDistance := 999999

    for window in windows {
        ; Skip current window
        if (window.hwnd == current.hwnd)
            continue

        distance := 999999

        switch direction {
            case "left":
                ; Find window to the left (compare left edges)
                if (window.x < current.x) {
                    hDistance := current.x - window.x
                    vOverlap := Max(0, Min(current.bottom, window.bottom) - Max(current.y, window.y))
                    vPenalty := vOverlap > 0 ? 0 : Min(Abs(current.y - window.bottom), Abs(current.bottom - window.y))
                    distance := hDistance + vPenalty
                }

            case "right":
                ; Find window to the right (compare left edges)
                if (window.x > current.x) {
                    hDistance := window.x - current.x
                    vOverlap := Max(0, Min(current.bottom, window.bottom) - Max(current.y, window.y))
                    vPenalty := vOverlap > 0 ? 0 : Min(Abs(current.y - window.bottom), Abs(current.bottom - window.y))
                    distance := hDistance + vPenalty
                }

            case "up":
                ; Find window above (compare top edges)
                if (window.y < current.y) {
                    vDistance := current.y - window.y
                    hOverlap := Max(0, Min(current.right, window.right) - Max(current.x, window.x))
                    hPenalty := hOverlap > 0 ? 0 : Min(Abs(current.x - window.right), Abs(current.right - window.x))
                    distance := vDistance + hPenalty
                }

            case "down":
                ; Find window below (compare top edges)
                if (window.y > current.y) {
                    vDistance := window.y - current.y
                    hOverlap := Max(0, Min(current.right, window.right) - Max(current.x, window.x))
                    hPenalty := hOverlap > 0 ? 0 : Min(Abs(current.x - window.right), Abs(current.right - window.x))
                    distance := vDistance + hPenalty
                }
        }

        if (distance < bestDistance) {
            bestDistance := distance
            bestWindow := window
        }
    }

    return bestWindow
}

; Window focus navigation with Win+hjkl -> No turns out windwos really is just a gameboy and won't let me remap win+l at all even wtih those registry tricks I cannot get this to work so lets just use a gaming like up dwon left right but shifted to the mittel of the home row
#s::  ; Win+h - focus left window
{
    window := FindWindowInDirection("left")
    if (window && window.hwnd) {
        WinActivate(window.hwnd)
    }
}

#d::  ; Win+j - focus down window
{
    window := FindWindowInDirection("down")
    if (window && window.hwnd) {
        WinActivate(window.hwnd)
    }
}

#e::  ; Win+k - focus up window
{
    window := FindWindowInDirection("up")
    if (window && window.hwnd) {
        WinActivate(window.hwnd)
    }
}

#f::  ; Win+l - focus right window
{
    window := FindWindowInDirection("right")
    if (window && window.hwnd) {
        WinActivate(window.hwnd)
    }
}

#q::  ; Win+w - close current window
{
    WinClose("A")
}

;#Space::  ; Win+Space - mapped to Ctrl+Space
;{
;    Send("^{Space}")
;}

; Helper function to focus first available window after desktop switch
FocusFirstWindow() {
    ; Small delay to ensure desktop switch completes
    Sleep(100)

    ; Get all visible windows and focus the first one
    windows := GetVisibleWindows()
    if (windows.Length > 0) {
        WinActivate(windows[1].hwnd)
    }
}

; Virtual desktop switching with Win+Shift+H/L
#+s::  ; Win+Shift+h - switch to left desktop
{
    Send("^#{Left}")
    ;FocusFirstWindow()
}

#+f::  ; Win+Shift+l - switch to right desktop
{
    Send("^#{Right}")
    ;FocusFirstWindow()
}
