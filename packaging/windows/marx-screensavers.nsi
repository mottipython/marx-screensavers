; The Marx Brothers screen savers, all in one. Each one ticked is put in just as its
; own setup does it (the same folder, the same entry in Settings, Apps, and an
; uninstaller that removes it alone); then the one chosen is made the screen saver.
; Its files are unpacked from its own setup at build time: running those setups from
; inside this one looked to antivirus like a dropper, and it quietly stopped them.
;
; Built by tools/build-bundle.sh, which writes build/savers.nsh: one
; "!insertmacro SAVER n title id key version" line for each.
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"
!include "Sections.nsh"
!include "x64.nsh"
!include "FileFunc.nsh"

!ifndef VERSION
  !define VERSION "1.0.0"
!endif

Name "The Marx Brothers Screen Savers"
Caption "The Marx Brothers Screen Savers ${VERSION}"
OutFile "..\..\dist\MarxBrothers-ScreenSavers-Setup-${VERSION}.exe"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
Unicode true
ShowInstDetails show
!define MUI_ICON "marx-screensavers.ico"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "The Marx Brothers Screen Savers"
!define MUI_WELCOMEPAGE_TEXT "This puts the Marx Brothers screen savers on this computer. Tick the ones you want on the next page, then choose which one comes on.$\r$\n$\r$\nEach one installs just as it does from its own download, and each can be removed by itself later from Settings, Apps."
!define MUI_COMPONENTSPAGE_NODESC
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Open Screen Saver Settings"
!define MUI_FINISHPAGE_RUN_FUNCTION OpenSettings

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
Page custom ChoosePage ChooseLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE "English"

Var Chosen        ; the one that comes on: its number, or -1 for the one there was
Var ChosenText    ; and its name, to show again if they come back to the page
Var Original      ; the screen saver there was before
Var List
Var Failed        ; the ones that did not install, to tell the user

; ---- the screen savers: a section for each, which puts in its files, its shortcuts and
; its entry in Settings, Apps, just as its own setup does
!macro SAVER N TITLE ID KEY VER
  !define TITLE_${N} "${TITLE}"
  !define SCR_${N} "${KEY}.scr"
  !define KEY_${N} "${KEY}"
  !define ID_${N} "${ID}"
  Section "${TITLE}" sec${N}
    SetRegView 64
    DetailPrint "Installing ${TITLE}..."
    SetOutPath "$PROGRAMFILES64\${TITLE}"
    File "..\..\build\files\${ID}\${ID}.exe"
    File "..\..\build\files\${ID}\*.dll"
    File "..\..\build\files\${ID}\README.txt"
    File "..\..\build\files\${ID}\LICENSE.txt"
    WriteUninstaller "$OUTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\${KEY}" "InstallDir" "$OUTDIR"
    ${DisableX64FSRedirection}
    SetOutPath "$WINDIR\System32"
    File "..\..\build\files\${ID}\${KEY}.scr"
    ${EnableX64FSRedirection}
    StrCpy $1 "$PROGRAMFILES64\${TITLE}"
    CreateDirectory "$SMPROGRAMS\${TITLE}"
    CreateShortcut "$SMPROGRAMS\${TITLE}\${TITLE} (window).lnk" "$1\${ID}.exe" "--window"
    CreateShortcut "$SMPROGRAMS\${TITLE}\${TITLE} (full screen).lnk" "$1\${ID}.exe" "/s"
    CreateShortcut "$SMPROGRAMS\${TITLE}\Uninstall.lnk" "$1\Uninstall.exe"
    !define UK_${N} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KEY}"
    WriteRegStr HKLM "${UK_${N}}" "DisplayName" "${TITLE} screensaver"
    WriteRegStr HKLM "${UK_${N}}" "DisplayVersion" "${VER}"
    WriteRegStr HKLM "${UK_${N}}" "DisplayIcon" "$1\${ID}.exe"
    WriteRegStr HKLM "${UK_${N}}" "UninstallString" '"$1\Uninstall.exe"'
    WriteRegStr HKLM "${UK_${N}}" "InstallLocation" "$1"
    WriteRegDWORD HKLM "${UK_${N}}" "NoModify" 1
    WriteRegDWORD HKLM "${UK_${N}}" "NoRepair" 1
    ${GetSize} "$1" "/S=0K" $2 $3 $4
    IntFmt $2 "0x%08X" $2
    WriteRegDWORD HKLM "${UK_${N}}" "EstimatedSize" "$2"
    ; and check it really is there
    ${DisableX64FSRedirection}
    ${If} ${FileExists} "$WINDIR\System32\${KEY}.scr"
    ${AndIf} ${FileExists} "$1\${ID}.exe"
      ${EnableX64FSRedirection}
      DetailPrint "${TITLE}: installed"
    ${Else}
      ${EnableX64FSRedirection}
      DetailPrint "${TITLE}: NOT installed"
      StrCpy $Failed "$Failed$\r$\n  ${TITLE}"
    ${EndIf}
  SectionEnd
!macroend
!include "..\..\build\savers.nsh"

; a macro for each screen saver there is (up to ten)
!macro EACH M
  !insertmacro ${M} 0
  !insertmacro ${M} 1
  !insertmacro ${M} 2
  !insertmacro ${M} 3
  !insertmacro ${M} 4
  !insertmacro ${M} 5
  !insertmacro ${M} 6
  !insertmacro ${M} 7
  !insertmacro ${M} 8
  !insertmacro ${M} 9
!macroend

; ---- last: the chosen one comes on (each setup made itself the screen saver)
!macro MAKE_CURRENT N
  !ifdef SCR_${N}
    ${If} $Chosen == ${N}
      WriteRegStr HKCU "Control Panel\Desktop" "SCRNSAVE.EXE" "$WINDIR\System32\${SCR_${N}}"
      WriteRegStr HKCU "Control Panel\Desktop" "ScreenSaveActive" "1"
      ReadRegStr $1 HKCU "Control Panel\Desktop" "ScreenSaveTimeOut"
      ${If} $1 == ""
        WriteRegStr HKCU "Control Panel\Desktop" "ScreenSaveTimeOut" "300"
      ${EndIf}
    ${EndIf}
  !endif
!macroend
Section "-the one that comes on"
  ${If} $Failed != ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "These did not install:$Failed$\r$\n$\r$\nIf Windows Security says it stopped something, that is a mistake (these programs aren't signed with a paid certificate): allow it there, then run this setup again." /SD IDOK
    SetErrorLevel 2
  ${EndIf}
  ${If} $Chosen < 0
    ${If} $Original == ""
      DeleteRegValue HKCU "Control Panel\Desktop" "SCRNSAVE.EXE"
    ${Else}
      WriteRegStr HKCU "Control Panel\Desktop" "SCRNSAVE.EXE" "$Original"
    ${EndIf}
  ${Else}
    !insertmacro EACH MAKE_CURRENT
  ${EndIf}
SectionEnd

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "The Marx Brothers screen savers need 64-bit Windows."
    Abort
  ${EndIf}
  ReadRegStr $Original HKCU "Control Panel\Desktop" "SCRNSAVE.EXE"
  StrCpy $Chosen 0
  StrCpy $ChosenText ""
FunctionEnd

; ---- the page to choose which one comes on: the ticked ones, or the one there was
!macro ADD_IF_TICKED N
  !ifdef TITLE_${N}
    SectionGetFlags ${sec${N}} $1
    IntOp $1 $1 & ${SF_SELECTED}
    ${If} $1 <> 0
      ${NSD_CB_AddString} $List "${TITLE_${N}}"
      ${If} $2 == ""
        StrCpy $2 "${TITLE_${N}}"
      ${EndIf}
      ${If} $ChosenText == "${TITLE_${N}}"
        StrCpy $2 "${TITLE_${N}}"
        StrCpy $3 1
      ${EndIf}
    ${EndIf}
  !endif
!macroend
!define KEEP "Keep the screen saver I have now"
Function ChoosePage
  !insertmacro MUI_HEADER_TEXT "Which one comes on?" "The one Windows shows when the computer has been left alone."
  nsDialogs::Create 1018
  Pop $0
  ${NSD_CreateLabel} 0 0 100% 24u "Choose the screen saver to come on. You can change it any time: type screen saver in the Start menu and open Change screen saver."
  Pop $0
  ${NSD_CreateDropList} 0 32u 100% 80u ""
  Pop $List
  StrCpy $2 ""          ; the one to show chosen: the first ticked, unless one was chosen before
  StrCpy $3 0
  !insertmacro EACH ADD_IF_TICKED
  ${NSD_CB_AddString} $List "${KEEP}"
  ${If} $ChosenText == "${KEEP}"
  ${OrIf} $2 == ""
    StrCpy $2 "${KEEP}"
  ${EndIf}
  ${NSD_CB_SelectString} $List $2
  nsDialogs::Show
FunctionEnd
!macro MATCH N
  !ifdef TITLE_${N}
    ${If} $ChosenText == "${TITLE_${N}}"
      StrCpy $Chosen ${N}
    ${EndIf}
  !endif
!macroend
Function ChooseLeave
  ${NSD_GetText} $List $ChosenText
  StrCpy $Chosen -1
  !insertmacro EACH MATCH
FunctionEnd

Function OpenSettings
  ; the 64-bit Settings: this setup is a 32-bit program, and a 32-bit rundll32 looks
  ; for screen savers in SysWOW64, finds none of these, and shows (None)
  Exec '"$WINDIR\Sysnative\rundll32.exe" shell32.dll,Control_RunDLL desk.cpl,,1'
FunctionEnd

; ---- the uninstaller, in each one's folder: it removes the one it sits beside
!macro UN_ONE N
  !ifdef TITLE_${N}
    ${If} $INSTDIR == "$PROGRAMFILES64\${TITLE_${N}}"
      ReadRegStr $1 HKCU "Control Panel\Desktop" "SCRNSAVE.EXE"
      ${If} $1 == "$WINDIR\System32\${SCR_${N}}"
        DeleteRegValue HKCU "Control Panel\Desktop" "SCRNSAVE.EXE"
      ${EndIf}
      ${DisableX64FSRedirection}
      Delete "$WINDIR\System32\${SCR_${N}}"
      ${EnableX64FSRedirection}
      Delete "$INSTDIR\${ID_${N}}.exe"
      Delete "$SMPROGRAMS\${TITLE_${N}}\${TITLE_${N}} (window).lnk"
      Delete "$SMPROGRAMS\${TITLE_${N}}\${TITLE_${N}} (full screen).lnk"
      Delete "$SMPROGRAMS\${TITLE_${N}}\Uninstall.lnk"
      RMDir "$SMPROGRAMS\${TITLE_${N}}"
      DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KEY_${N}}"
      DeleteRegKey HKLM "Software\${KEY_${N}}"
    ${EndIf}
  !endif
!macroend
Section "Uninstall"
  SetRegView 64
  !insertmacro EACH UN_ONE
  Delete "$INSTDIR\SDL2.dll"
  Delete "$INSTDIR\SDL3.dll"
  Delete "$INSTDIR\README.txt"
  Delete "$INSTDIR\LICENSE.txt"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
SectionEnd
