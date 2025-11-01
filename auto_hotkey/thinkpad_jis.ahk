#Requires AutoHotkey v2.0
; 本体が日本語キーボードの環境下でUS配列の外部キーボードを使うための環境
; 左AltでUS配列の英字入力、右AltでJIS配列の日本語入力が可能

!a::Send "^a"
!b::Send "^b"
!c::Send "^c"
!d::Send "^d"
!e::Send "^e"
!f::Send "^f"
!g::Send "^g"
!h::Send "^h"
!i::Send "^i"
!j::Send "^j"
!k::Send "^k"
!l::Send "^l"
!m::Send "^m"
!n::Send "^n"
!o::Send "^o"
!p::Send "^p"
!q::Send "^q"
!r::Send "^r"
!s::Send "^s"
!t::Send "^t"
!u::Send "^u"
!v::Send "^v"
!w::Send "^w"
!x::Send "^x"
!y::Send "^y"
!z::Send "^z"
!Enter::Send "^{Enter}"

!+a::Send "^+a"
!+b::Send "^+b"
!+c::Send "^+c"
!+d::Send "^+d"
!+e::Send "^+e"
#!+f::Send "^+f"
!+g::Send "^+g"
!+h::Send "^+h"
!+i::Send "^+i"
!+j::Send "^+j"
!+k::Send "^+k"
!+l::Send "^+l"
!+m::Send "^+m"
!+n::Send "^+n"
!+o::Send "^+o"
!+p::Send "^+p"
!+q::Send "^+q"
!+r::Send "^+r"
!+s::Send "^+s"
!+t::Send "^+t"
!+u::Send "^+u"
!+v::Send "^+v"
!+w::Send "^+w"
!+x::Send "^+x"
!+y::Send "^+y"
!+z::Send "^+z"
!+Enter::Send "^+{Enter}"

!+4::Send "<#+s"

PgUp::Return
PgDn::Return

Alt & /::Send "^/"

LAlt::Return
Alt::Return

; 現在の入力方式を取得
GetInputLang() {
    hWnd := WinActive("A")  ; アクティブウィンドウのハンドル取得
    threadId := DllCall("GetWindowThreadProcessId", "ptr", hWnd, "uint*", 0)
    hkl := DllCall("GetKeyboardLayout", "uint", threadId, "ptr")
    return Format("{:04X}", hkl & 0xFFFF)  ; 下位16ビットが言語ID
}

GroupAdd "AltGroup", "ahk_exe msedge.exe"
GroupAdd "AltGroup", "ahk_exe powerpnt.exe"

;無変換
LAlt up:: {
  lang := GetInputLang()
  if (lang = "0411")  ; 入力方式が日本語なら
      Send "#{Space}" ; 英語入力に切り替え

  if (WinActive("ahk_group AltGroup")) {
    Send "{Alt}"
  }
}

;変換
Alt up:: {
  lang := GetInputLang()
  if (lang = "0409")  ; 入力方式が英語なら
      Send "#{Space}" ; 日本語入力に切り替え
  if (WinActive("ahk_group AltGroup")) {
    Send "{Alt}"
  }
  Send "{vk1Csc079}"
}
