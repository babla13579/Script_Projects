;{  #INCLUDE
#Include Rufaydium.ahk
;}

MSEdge := new Rufaydium("msedgedriver.exe","--port=9516")
Chrome := new Rufaydium("chromedriver.exe","--port=9515")
MSEdge_Persistent := new Rufaydium("msedgedriver.exe","--port=9526")
Chrome_Persistent := new Rufaydium("chromedriver.exe","--port=9525")

loop
{
  if ( (A_TimeIdlePhysical > 29999) && (A_TimeIdlePhysical < 35001 ) ) {
    Loop, Files, C:\Users\%username%\AppData\Local\Temp\*.*, D
    {
      if (A_TimeIdlePhysical > 29999) {
        if InStr(A_LoopFileFullPath, "scoped_dir") || InStr(A_LoopFileFullPath, "_BITS_")  {   ; Remove Edge Specific Temp Files
          FileRemoveDir, % A_LoopFileFullPath, 1
        }
      }
    }
  }
  Sleep 5000
}

reload_Function() {    ; Refresh HotKey help list    Flash Screen    Reload
  ;~ Run cmd.exe /c taskkill /f /t /im:msedgedriver.exe , , Min    ; Kills the web driver  /t flag  also kills open browsers launched from webdriver
  flash_Screen("Black")
  sleep 50  ; Sleep needed to prevent multiple script instances in case someone holds down the Reload hotkey
  Reload   ; Reloads script
}
flash_Screen(f_Color) {
  ; Used to flash screen
  Gui,Color,%f_Color%
  Gui,+AlwaysOnTop +ToolWindow -Caption
  Gui,Show,% "w" A_ScreenWidth "." "h" A_ScreenHeight + 100 "." "Hide NA"

  Gui,Show
  Sleep,50
  Gui,Hide
}

Escape::  ; Reload Scripts - Sourced from Local Desktop
  send, {Esc}
  reload_Function()
  return

+Escape::
  MSEdge.QuitAllSessions() ; close all session
  Chrome.QuitAllSessions() ; close all session
  reload_Function()
  return

!r::
    MSEdge_document := MSEdge.NewSession()
    MSEdge_document.Maximize()
    sleep 100
    MSEdge_document.Navigate("https://gist.github.com/CMCDragonkai/6c933f4a7d713ef712145c5eb94a1816")
    Table := MSEdge_document.querySelector("#file-regular_expression_engine_comparison-md-readme > article > table > tbody").innerHTML
    StringReplace, Table,Table,<span>,, UseErrorLevel
    StringReplace, Table,Table,</span>,, UseErrorLevel
    FileDelete, C:\Users\%username%\OneDrive\Desktop\Temp_Files\Regex_Table_InnerHTML.txt
    FileDelete, C:\Users\%username%\OneDrive\Desktop\Regex_Features.tsv
    FileAppend, %Table%,C:\Users\%username%\OneDrive\Desktop\Temp_Files\Regex_Table_InnerHTML.txt
    Array := []
    Topic= ;nul
    Loop, Read, C:\Users\%username%\OneDrive\Desktop\Temp_Files\Regex_Table_InnerHTML.txt
    {
      ;~ MsgBox % A_LoopReadLine
      if (RegExMatch(A_LoopReadLine, "^\s*<\/?tr>\s*$", SubPat)) {  ; If End or Start of Table Row, initialize vars and continue
        if (line = "") {
          line=%Topic%
        }
        if (Array.Count()) {
          for index, element in Array ; Enumeration is the recommended approach in most cases.
          {
            ;~ MsgBox % "Element number " . index . " is " . element . "`nElement Count is " . Array.Count()
            line=%line%`t%element%
          }
          ;~ MsgBox % line
          FileAppend, %line%`n,C:\Users\%username%\OneDrive\Desktop\Regex_Features.tsv
        }
        Array := []
        line= ;nul
        continue
      }
      if (RegExMatch(A_LoopReadLine, "^\s*<th colspan.*nofollow.>(.*?)<\/a>", SubPat)) {   ; Probably want to write current data here... Then reset data
        ;~ MsgBox % "Matched Topic Line" . "`n`n`n`n" . A_LoopReadLine
        Topic := SubPat1
        continue
      }
      if (RegExMatch(A_LoopReadLine, "^\s*<th>(<a href.*nofollow.>)?(.*?)(<\/.*)", SubPat)) {
        if (SubPat1 = "Feature") {
          Array.Push(SubPat1)
          ;~ MsgBox % "Matched Language Specific Feature Yes/No line" . "`n`n" . "Added  " . SubPat1 "  to Array" . "`n`n" . A_LoopReadLine
        } else {
          Array.Push(SubPat2)
          ;~ MsgBox % "Matched Language Specific Feature Yes/No line" . "`n`n" . "Added  " . SubPat2 "  to Array" . "`n`n" . A_LoopReadLine
        }
        continue
      }
      if ( (RegExMatch(A_LoopReadLine, "^\s*<td>(.*?)<\/td>\s*$", SubPat)) || (RegExMatch(A_LoopReadLine, "^\s*<td valign=.top.>(.*?)<\/td>\s*$", SubPat)) ) {
        Array.Push(SubPat1)
      }
      continue
    }

    return