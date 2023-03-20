; Silver Zachara <silver.zachara@gmail.com> 2018

#NoEnv
#Persistent
#UseHook On
#SingleInstance Force

SaveFileDir := "c:\Users\Silver Zachara\AppData\Roaming\DarkSoulsIII\0110000100000666\"
SaveFileName := "DS30000.sl2"
SaveBakFileName := "DS30000.sl2.bak"
SaveFile := SaveFileDir . SaveFileName
SaveBakFile := SaveFileDir . SaveBakFileName

BackupDirName := "new_game_2\"
BackupDir := SaveFileDir . BackupDirName

IndexFileName := ".index"
IndexFile := BackupDir . IndexFileName
Index := 0

DarkSouls3ExeName := "DarkSoulsIII.exe"
ToggleSuspended := false

DSWindowTitle := "DARK SOULS III"

; If the Backup Save File was not found, try to Restore previous one
; This is the counter, which counts, how how many times to try to Restore
TryRestoreCounter := 8

; Create Backup Folder if doesn't exist
if (!FileExist(BackupDir))
    FileCreateDir, %BackupDir%

SetWorkingDir, %BackupDir%

; Save Hotkey. Change 'F6' to the Key of your choice.
; This hotkey will create a new save in the current run, and select it.
~F6::
{
    ; Execute function only when DS3 window is active
    if (!IsDarkSouls3WindowActive())
        return

    if (!FileExist(SaveFile)) {
        MsgBox, Dark Souls 3 Save File doesn't exist:`n`n%SaveFile%
        return
    }

    ; Quit, if Backup Folder doesn't exist
    if (!FileExist(BackupDir)) {
        MsgBox, Backup Folder doesn't exist:`n`n%BackupDir%
        return
    }

    ; Read and Write Index from .index file
    file := FileOpen(IndexFile, "rw", "UTF-8-RAW")
    if (!IsObject(file)) {
        MsgBox, Can't open Index File for rw.`n`n%IndexFile%
        return
    }
    ; Set hidden attribute for a Index File
    FileGetAttrib, IndexFileAttrs, %IndexFile%
    if (!InStr(IndexFileAttrs, "H", true))
        FileSetAttrib, +H, %IndexFile%

    Index := file.Read(20)
    Index := Index ? Index : 0
    ++Index
    file.Pos := 0
    file.Length := 0
    file.Write(Index)
    file.Close()

    ; Create Backup File by Index variable
    bakFileName := Index . "_" . SaveFileName
    FileCopy, %SaveFile%, %bakFileName%, 1

    return

    ; Errors Shorcut Code
    ;~ MsgBox, %ErrorLevel%
    ;~ MsgBox, %A_LastError%
    ;~ return
}


; Load Hotkey. Change 'F8'to the key of your choice.
; This hotkey loads the last save selected, or last save created - whichever is most recent.
~F8::
{
    ; Execute function only when DS3 window is active
    if (!IsDarkSouls3WindowActive())
        return

    if (!FileExist(IndexFile)) {
        MsgBox, Index File doesn't exist, nothing to Restore.`n`n%IndexFile%
        return
    }

    ; On the first run, a Index may not be valid
    if (!Index) {
        file := FileOpen(IndexFile, "r", "UTF-8-RAW")
        if (!IsObject(file)) {
            MsgBox, Can't open Index File for reading.`n`n%IndexFile%
            return
        }
        Index := file.Read(20)
        file.Close()
    }

    ; Restore Backup File loop
    wasRestored := false
    Loop % TryRestoreCounter {
        ; Calculate Current / Previous Index
        tmpIndex := Index - (A_Index - 1)
        ; Get Backup File Name by Index
        bakFileName := tmpIndex . "_" . SaveFileName

        ; If Save File does not exist, try next one
        if (!FileExist(bakFileName))
            continue

        ; Backup current Save File
        FileCopy, %SaveFile%, %SaveBakFile%, 1
        ; Restore Last Backup File
        FileCopy, %bakFileName%, %SaveFile%, 1

        ; Break after successful restore
        wasRestored := true
        break
    }

    if (!wasRestored)
        MsgBox % "Failed to Restore Save File.`n`n"
            . "Tried to Restore last %TryRestoreCounter% Backed Up Save Files, but neither was found."

    return
}

; Suspend / Resume a Dark Souls III process - ctrl + F2
~^F2::
{
    if ToggleSuspended {
        ProcessResume(DarkSouls3ExeName)
        ToggleSuspended := false
    } else {
        ProcessSuspend(DarkSouls3ExeName)
        ToggleSuspended := true
    }

    return
}

; Check if DS3 window is active
IsDarkSouls3WindowActive()
{
    global DSWindowTitle

    WinGetActiveTitle, Title
    ; Case-sensitive compare
    if (DSWindowTitle == Title)
        return true

    return false
}

ProcessSuspend(PID_or_Name)
{
    pid := InStr(PID_or_Name,".") ? ProcessExist(PID_or_Name) : PID_or_Name

    h := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", pid)
    if (!h)
        return -1

    DllCall("ntdll.dll\NtSuspendProcess", "Int", h)
    DllCall("CloseHandle", "Int", h)
}

ProcessResume(PID_or_Name)
{
    pid := InStr(PID_or_Name,".") ? ProcessExist(PID_or_Name) : PID_or_Name

    h := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", pid)
    if (!h)
        return -1

    DllCall("ntdll.dll\NtResumeProcess", "Int", h)
    DllCall("CloseHandle", "Int", h)
}

ProcessExist(PID_or_Name = "")
{
    Process, Exist, %PID_or_Name%

    return Errorlevel
}
