#SingleInstance Force

#HotIf !WinActive("ahk_exe sldworks.exe")

A_HotkeyInterval := 1000
A_MaxHotkeysPerInterval := 200

global isWheelUp := false
global isWheelDown := false
global isWheelLeft := false
global isWheelRight := false

WheelUp::hookWheelUp()
WheelDown::hookWheelDown()
WheelLeft::hookWheelLeft()
WheelRight::hookWheelRight()

MButton::Return
MButton Up::hookMButtonUP()

hookWheelUp() {
    global isWheelUp
    Send("{WheelUp}")
    isWheelUp := true
}

hookWheelDown() {
    global isWheelDown
    Send("{WheelDown}")
    isWheelDown := true
}

hookWheelLeft() {
    global isWheelLeft
    Send("{WheelLeft}")
    isWheelLeft := true
}

hookWheelRight() {
    global isWheelRight
    Send("{WheelRight}")
    isWheelRight := true
}

hookMButtonUP() {
    global isWheelUp, isWheelDown, isWheelLeft, isWheelRight
    ; スクロールされていない場合のみ MButton を送信
    if !(isWheelUp || isWheelDown || isWheelLeft || isWheelRight)
        Send("{MButton}")

    isWheelUp := false
    isWheelDown := false
    isWheelLeft := false
    isWheelRight := false
}
#HotIf
