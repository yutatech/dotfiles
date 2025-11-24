; AutoHotkey v2 version

!a::Send("^a")
!b::Send("^b")
!c::Send("^c")
!d::Send("^d")
!e::Send("^e")
!f::Send("^f")
!g::Send("^g")
!h::Send("^h")
!i::Send("^i")
!j::Send("^j")
!k::Send("^k")
!l::Send("^l")
!m::Send("^m")
!n::Send("^n")
!o::Send("^o")
!p::Send("^p")
!q::Send("^q")
!r::Send("^r")
!s::Send("^s")
!t::Send("^t")
!u::Send("^u")
!v::Send("^v")
!w::Send("^w")
!x::Send("^x")
!y::Send("^y")
!z::Send("^z")
!1::Send("^1")
!2::Send("^2")
!3::Send("^3")
!4::Send("^4")
!5::Send("^5")
!6::Send("^6")
!7::Send("^7")
!8::Send("^8")
!9::Send("^9")
!0::Send("^0")
!F1::Send("^{F1}")
!F2::Send("^{F2}")
!F3::Send("^{F3}")
!F4::Send("^{F4}")
!F5::Send("^{F5}")
!F6::Send("^{F6}")
!F7::Send("^{F7}")
!F8::Send("^{F8}")
!F9::Send("^{F9}")
!F10::Send("^{F10}")
!F11::Send("^{F11}")
!F12::Send("^{F12}")
!`::Send("^{`}")
!~::Send("^{~}")
!!::Send("^!")
!@::Send("^@")
!#::Send("^#")
!$::Send("^$")
!%::Send("^%")
!^::Send("^^")
!&::Send("^&")
!*::Send("^*")
!(::Send("^(")
!)::Send("^)")
!-::Send("^-")
!_::Send("^_")
!::Send("^=")
!+::Send("^+")
![::Send("^[")
!{::Send("^{")
!]::Send("^]")
!}::Send("^}")
!\::Send("^\\")
!|::Send("^|")
!;::Send("^;")
!'::Send("^'")
!"::Send('^"')
!,::Send("^,")
!<::Send("^<")
!.::Send("^.")
!>::Send("^>")
!/::Send("^/")
!?::Send("^?")
!Esc::Send("^{Esc}")
!Tab::Send("^{Tab}")
!Space::Send("^{Space}")
!Left::Send("^{Left}")
!Right::Send("^{Right}")
!Up::Send("^{Up}")
!Down::Send("^{Down}")
!Enter::Send("^{Enter}")
!PrintScreen::Send("^{PrintScreen}")
!Delete::Send("^{Delete}")
!Home::Send("^{Home}")
!End::Send("^{End}")
!PgUp::Send("^{PgUp}")
!PgDn::Send("^{PgDn}")


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

; --- Alt release behavior ---
; 左 Alt 空打ちで IME を OFF
#HotIf !WinActive("ahk_exe mstsc.exe")
LAlt up::
{
    if (A_PriorHotkey == "*~LAlt") {
        IME_SET(0)
    }
    Return
}
#HotIf

; 右 Alt 空打ちで IME を ON
#HotIf !WinActive("ahk_exe mstsc.exe")
RAlt up::
{
    if (A_PriorHotkey == "*~RAlt") {
        IME_SET(1)
    }
    Return
}
#HotIf
