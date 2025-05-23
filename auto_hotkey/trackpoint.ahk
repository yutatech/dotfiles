#MaxHotkeysPerInterval 2000
#SingleInstance force

WheelUp:: hookWheelUp()
global isWheelUP := false
hookWheelUp(){
    send {Wheelup}
    isWheelUp := true
}

WheelDown:: hookWheelDown()
global isWheelDown := false
hookWheelDown(){
    send {WheelDown}
    isWheelDown := true
}

WheelLeft:: hookWheelLeft()
global isWheelLeft := false
hookWheelLeft(){
    send {WheelLeft}
    isWheelLeft := true
}

WheelRight:: hookWheelRight()
global isWheelRight := false
hookWheelRight(){
    send {WheelRight}
    isWheelRight := true
}

; MButton を無効化
MButton::return

MButton up::hookMButtonUP()
hookMButtonUP(){
    ; MButton を押して離すまでにスクロールされなかった場合、MButton を押す
    if(!(isWheelUp | isWheelDown | isWheelLeft | isWheelRight)){
        send {MButton}
    }
    isWheelUp   := false
    isWheelDown := false
    isWheelLeft := false
    isWheelRight := false
}