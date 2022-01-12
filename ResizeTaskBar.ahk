; narrow win10 taskbar that is on left of desktop without dll inject.

; ~LButton::{
; 	DllCall("GetCursorPos", "ptr", lpPoint := Buffer(8))
; 	if 11 = SendMessage(0x0084, 0, NumGet(lpPoint, 4,"int") << 16 | NumGet(lpPoint, "int"), WinExist("ahk_class Shell_TrayWnd")) {
; 		posLast := ""
; 		while A_Cursor == "SizeWE" && GetKeyState("LButton", "P") {
; 			if posLast != posNow := NumGet(lpPoint, "int")
; 				ResizeTB(posLast := posNow)
; 			DllCall("GetCursorPos", "ptr", lpPoint)
; 		}
; 	}
; }

ResizeTB(size){
	pAppBarData := Buffer(48), NumPut("uint", pAppBarData.Size, pAppBarData)
	DllCall("Shell32\SHAppBarMessage", "uint", 0x00000005, "ptr", pAppBarData)
	; if taskbar is on left of screen
	if 0 = NumGet(pAppBarData, 20, "uint") {
		hTB := WinExist("ahk_class Shell_TrayWnd")
		NumPut("int", -A_ScreenWidth, pAppBarData, 24), NumPut("int", size, pAppBarData, 32)
		; if taskbar is locked
		if 0 = bMovable := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", "TaskbarSizeMove") {
			RegWrite(1, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", "TaskbarSizeMove")
			SendMessage(0x0111, 0x1A065, 0,, hTB)
		}
		SendMessage(0x0214, 2, pAppBarData.Ptr + 24,, hTB), WinMove(0, 0)
		if 0 = bMovable {
			RegWrite(0, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", "TaskbarSizeMove")
			SendMessage(0x0111, 0x1A065, 0,, hTB)
		}
	}
}