; https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwineventhook
class WinEventHook {
	__New(min_event, max_event, callback, modname := "", pid := 0, tid := 0, flags := 0){
		this.Proc := CallbackCreate(callback, "F")
		this.Module := modname ? DllCall("LoadLibrary", "str", modname, "ptr") : 0
		if !this.Ptr := DllCall("SetWinEventHook", "uint", min_event, "uint", max_event, "ptr", this.Module, "ptr", this.Proc, "uint", pid, "uint", tid, "uint", flags)
			throw OSError(A_LastError)
	}
	__Delete() => (DllCall("UnhookWinEvent", "ptr", this), CallbackFree(this.Proc), this.Module ? DllCall("FreeLibrary", "ptr", this.Module) : "")
}

; hook := WinEventHook(0x800C, 0x800C, WinEventCallback)
; WinEventCallback(hook, event, hwnd, objid, childid, tid, time) {
; }