Persistent
hook := WindowsHookEx(3, "GetMsgProc", "D:\Code\C\Dll2\x64\Debug\Dll2.dll", DllCall('GetWindowThreadProcessId', 'ptr', WinExist("ahk_class Notepad"), 'uint*', 0, 'uint'))

; https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowshookexw
class WindowsHookEx {
	__New(idHook, fn, modname := unset, idThread := 0) {
		if !IsSet(modname){
			hMod := 0
		} else if !modname{
			if !hMod := DllCall("GetModuleHandle", "ptr", 0, "ptr")
				throw OSError()
		} else {
			if !this.Module := hMod := DllCall("LoadLibraryW", "str", modname, "ptr")
				throw OSError()
		}
		if !this.Callback := fn is Func ? CallbackCreate(fn) : DllCall("GetProcAddress", "ptr", hMod, "astr", fn, "ptr")
			throw OSError()
		if !this.Hook := DllCall("SetWindowsHookEx", "int", idHook, "ptr", this.Callback, "ptr", hMod, "uint", idThread, "ptr")
			throw OSError()
	}

	__Delete() {
		if this.HasOwnProp("Hook")
			DllCall("UnhookWindowsHookEx", "ptr", this.Hook)
		if this.HasOwnProp("Callback")
			DllCall("GlobalFree", "ptr", this.Callback, "ptr")
		if this.HasOwnProp("Module")
			DllCall("FreeLibrary", "ptr", this.Module)
	}

	class KBDLLHOOKSTRUCT {
		__New(ptr) => (this.Ptr := ptr, this.Size := 24)
		VirtualKeyCode => NumGet(this, "uint")
		ScanCode => NumGet(this, 4, "uint")
		Flag => NumGet(this, 8, "uint")
		Time => NumGet(this, 12, "uint")
		ExtraInfo => NumGet(this, 16, "ptr")
	}

	class MSLLHOOKSTRUCT {
		__New(ptr) => (this.Ptr := ptr, this.Size := 32)
		x => NumGet(this, "int")
		y => NumGet(this, 4, "int")
		Data => NumGet(this, 8, "uint")
		Flag => NumGet(this, 12, "uint")
		Time => NumGet(this, 16, "uint")
		ExtraInfo => NumGet(this, 24, "ptr")
	}
}

; LowLevelMouseProc(nCode, wParam, lParam){
; 	mouseInfo := WindowsHookEx.MSLLHOOKSTRUCT(lParam)
; 	OutputDebug mouseInfo.x "," mouseInfo.y "`n"
; }