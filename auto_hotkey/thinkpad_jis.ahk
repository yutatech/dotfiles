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

!+a::Send "^+a"
!+b::Send "^+b"
!+c::Send "^+c"
!+d::Send "^+d"
!+e::Send "^+e"
!+f::Send "^+f"
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

!+4::Send "<#+s"

PgUp::Return
PgDn::Return

Alt & /::Send "^/"

LAlt::return
RAlt::return

GroupAdd "AltGroup", "ahk_exe msedge.exe"

;無変換
LAlt up:: {
  Send "^0"
  if WinActive( "ahk_exe msedge.exe") {
  }
  else{
    Send "{Alt}"
  }
}

;変換
RAlt up:: {
  Send "^+0"
  Send "{vk1Csc079}"
  if WinActive( "ahk_exe msedge.exe") {
  }
  else {
    Send "{Alt}"
  }
}
