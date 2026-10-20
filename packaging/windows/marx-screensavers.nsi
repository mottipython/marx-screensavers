; The Marx Brothers screen savers, all in one. Each one's own setup program comes
; inside this one and is run quietly for each one ticked, so they install exactly as
; they do from their own downloads, and each can still be removed by itself from
; Settings, Apps. Then the one chosen is made the screen saver.
;
; Built by tools/build-bundle.sh, which fetches the setups and writes
; build/savers.nsh: one "!insertmacro SAVER n title setup scr" line for each.
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"
!include "Sections.nsh"
!include "x64.nsh"

!ifndef VERSION
  !define VERSION "1.0.0"
!endif

Name "The Marx Brothers Screen Savers"
Caption "The Marx Brothers Screen Savers ${VERSION}"
OutFile "..\..\dist\MarxBrothers-ScreenSavers-Setup-${VERSION}.exe"
RequestExecutionLevel admin
SetCompress off                 ; the setups inside are compressed already
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

; ---- the screen savers: a section for each, which runs its own setup quietly
!macro SAVER N TITLE SETUP SCR
  !define TITLE_${N} "${TITLE}"
  !define SCR_${N} "${SCR}"
  Section "${TITLE}" sec${N}
    SetOutPath "$PLUGINSDIR"
    DetailPrint "Installing ${TITLE}..."
    File "..\..\build\setups\${SETUP}"
    ExecWait '"$PLUGINSDIR\${SETUP}" /S' $0
    ${If} $0 != 0
      DetailPrint "${TITLE}: its setup stopped with code $0"
    ${EndIf}
    Delete "$PLUGINSDIR\${SETUP}"
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
    ${EndIf}
  !endif
!macroend
Section "-the one that comes on"
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
  Exec 'rundll32.exe shell32.dll,Control_RunDLL desk.cpl,,1'
FunctionEnd
