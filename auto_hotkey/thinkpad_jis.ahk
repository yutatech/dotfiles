#Requires AutoHotkey v2.0
; 本体が日本語キーボードの環境下でUS配列の外部キーボードを使うための環境
; 左AltでUS配列の英字入力、右AltでJIS配列の日本語入力が可能


PgUp::Return
PgDn::Return


; Alt + key -> Ctrl + key
!a::^a
!b::^b
!c::^c
!d::^d
!e::^e
!f::^f
!g::^g
!h::^h
!i::^i
!j::^j
!k::^k
!l::^l
!m::^m
!n::^n
!o::^o
!p::^p
!q::^q
!r::^r
!s::^s
!t::^t
!u::^u
!v::^v
!w::^w
!x::^x
!y::^y
!z::^z
!1::^1
!2::^2
!3::^3
!4::^4
!5::^5
!6::^6
!7::^7
!8::^8
!9::^9
!0::^0
!F1::^F1
!F2::^F2
!F3::^F3
!F4::^F4
!F5::^F5
!F6::^F6
!F7::^F7
!F8::^F8
!F9::^F9
!F10::^F10
!F11::^F11
!F12::^F12
!`::^`
!~::^~
!!::^!
!@::^@
!#::^#
!$::^$
!%::^%
!^::^^
!&::^&
!*::^*
!(::^(
!)::^)
!-::^-
!_::^_
!=::^=
!+::^+
![::^[
!{::^{
!]::^]
!}::^}
!\::^\
!|::^|
!;::^;
!'::^'
!"::^"
!,::^,
!<::^<
!.::^.
!>::^>
!/::^/
!?::^?
!Esc::^Esc
;!Tab::^Tab
!Space::^Space
!Left::^Left
!Right::^Right
!Up::^Up
!Down::^Down
!Enter::^Enter
!PrintScreen::^PrintScreen
!Delete::^Delete
!Home::^Home
!End::^End
!PgUp::^PgUp
!PgDn::^PgDn


; Alt + Shift + key -> Ctrl + Shift + key
!+a::^+a
!+b::^+b
!+c::^+c
!+d::^+d
!+e::^+e
!+f::^+f
!+g::^+g
!+h::^+h
!+i::^+i
!+j::^+j
!+k::^+k
!+l::^+l
!+m::^+m
!+n::^+n
!+o::^+o
!+p::^+p
!+q::^+q
!+r::^+r
!+s::^+s
!+t::^+t
!+u::^+u
!+v::^+v
!+w::^+w
!+x::^+x
!+y::^+y
!+z::^+z
!+1::^+1
!+2::^+2
!+3::^+3
!+4::^+4
!+5::^+5
!+6::^+6
!+7::^+7
!+8::^+8
!+9::^+9
!+0::^+0
!+F1::^+F1
!+F2::^+F2
!+F3::^+F3
!+F4::^+F4
!+F5::^+F5
!+F6::^+F6
!+F7::^+F7
!+F8::^+F8
!+F9::^+F9
!+F10::^+F10
!+F11::^+F11
!+F12::^+F12
!+`::^+`
!+~::^+~
!+!::^+!
!+@::^+@
!+#::^+#
!+$::^+$
!+%::^+%
!+^::^+^
!+&::^+&
!+*::^+*
!+(::^+(
!+)::^+)
!+-::^+-
!+_::^+_
!+=::^+=
!++::^++
!+[::^+[
!+{::^+{
!+]::^+]
!+}::^+}
!+\::^+\
!+|::^+|
!+;::^+;
!+'::^+'
!+"::^+"
!+,::^+,
!+<::^+<
!+.::^+.
!+>::^+>
!+/::^+/
!+?::^+?
!+Esc::^+Esc
;!+Tab::^+Tab
!+Space::^+Space
!+Left::^+Left
!+Right::^+Right
!+Up::^+Up
!+Down::^+Down
!+Enter::^+Enter
!+PrintScreen::^+PrintScreen
!+Delete::^+Delete
!+Home::^+Home
!+End::^+End
!+PgUp::^+PgUp
!+PgDn::^+PgDn




;-----------------------------------------------------------
; IMEの状態の取得
;   WinTitle="A"    対象Window
;   戻り値          1:ON / 0:OFF
;-----------------------------------------------------------
IME_GET(WinTitle:="A")  {
    hwnd := WinExist(WinTitle)
    if  (WinActive(WinTitle))   {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        cbSize := 4+4+(PtrSize*6)+16
        stGTI := Buffer(cbSize,0)
        NumPut("DWORD", cbSize, stGTI.Ptr,0)   ;   DWORD   cbSize;
        hwnd := DllCall("GetGUIThreadInfo", "Uint",0, "Uint", stGTI.Ptr)
                 ? NumGet(stGTI.Ptr,8+PtrSize,"Uint") : hwnd
    }
    return DllCall("SendMessage"
          , "UInt", DllCall("imm32\ImmGetDefaultIMEWnd", "Uint",hwnd)
          , "UInt", 0x0283  ;Message : WM_IME_CONTROL
          ,  "Int", 0x0005  ;wParam  : IMC_GETOPENSTATUS
          ,  "Int", 0)      ;lParam  : 0
}

;-----------------------------------------------------------
; IMEの状態をセット
;   SetSts          1:ON / 0:OFF
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------
IME_SET(SetSts, WinTitle:="A")    {
    hwnd := WinExist(WinTitle)
    if  (WinActive(WinTitle))   {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        cbSize := 4+4+(PtrSize*6)+16
        stGTI := Buffer(cbSize,0)
        NumPut("Uint", cbSize, stGTI.Ptr,0)   ;   DWORD   cbSize;
        hwnd := DllCall("GetGUIThreadInfo", "Uint",0, "Uint",stGTI.Ptr)
                 ? NumGet(stGTI.Ptr,8+PtrSize,"Uint") : hwnd
    }
    return DllCall("SendMessage"
          , "UInt", DllCall("imm32\ImmGetDefaultIMEWnd", "Uint",hwnd)
          , "UInt", 0x0283  ;Message : WM_IME_CONTROL
          ,  "Int", 0x006   ;wParam  : IMC_SETOPENSTATUS
          ,  "Int", SetSts) ;lParam  : 0 or 1
}


; 上部メニューがアクティブになるのを抑制 / Xbox Game Bar 起動用仮想キーコードとのバッティング回避 (vk07 -> vkFF)
*~LAlt::
{
    Send("{Blind}{vkFF}")
}
*~RAlt::
{
    Send("{Blind}{vkFF}")
}


; 左 Alt 空打ちで IME を OFF
#HotIf !WinActive("ahk_exe mstsc.exe")
LAlt up::
{
    lang := GetInputLang()
    ;if (A_PriorHotkey == "*~LAlt") {
    ;    IME_SET(0)
    ;}
    if (lang = "0411")  ; 入力方式が日本語なら
        Send "#{Space}" ; 英語入力に切り替え
    Return
}
#HotIf

; 右 Alt 空打ちで IME を ON
#HotIf !WinActive("ahk_exe mstsc.exe")
RAlt up::
{
    lang := GetInputLang()
    if (lang = "0409")  ; 入力方式が英語なら
        Send "#{Space}" ;日本語入力に切り替え
    if (A_PriorHotkey == "*~RAlt") {
        IME_SET(1)
    }
    Return
}
#HotIf


; 現在の入力方式を取得
GetInputLang() {
    hWnd := WinActive("A")  ; アクティブウィンドウのハンドル取得
    threadId := DllCall("GetWindowThreadProcessId", "ptr", hWnd, "uint*", 0)
    hkl := DllCall("GetKeyboardLayout", "uint", threadId, "ptr")
    return Format("{:04X}", hkl & 0xFFFF)  ; 下位16ビットが言語ID
}

