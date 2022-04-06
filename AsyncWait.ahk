Persistent

class AsyncWait {
	static Process(pid, function, pParam := 0, timeout := -1, flags := 0x8) {
		if !hProcess := DllCall("OpenProcess", "uint", 0x100000, "int", false, "uint", pid, "ptr")
			throw OSError()
		handle := { ptr: hProcess, __Delete: this => DllCall("CloseHandle", "ptr", this) }
		return this(handle, function, pParam, timeout, flags)
	}

	static Thread(tid, function, pParam := 0, timeout := -1, flags := 0x8) {
		if !hThread := DllCall("OpenThread", "uint", 0x100000, "int", false, "uint", tid, "ptr")
			throw OSError()
		handle := { ptr: hThread, __Delete: this => DllCall("CloseHandle", "ptr", this) }
		return this(handle, function, pParam, timeout, flags)
	}

	static FileChangeNotification(dir, function, bWatchSubtree := false, filter := 0x10, pParam := 0, timeout := -1, flags := 0x4) {
		if -1 == hChange := DllCall("FindFirstChangeNotificationW", "str", dir, "int", bWatchSubtree, "uint", filter, "ptr")
			throw OSError()
		handle := { Ptr: hChange, Next: this => DllCall("FindNextChangeNotification", "ptr", this), __Delete: this => DllCall("FindCloseChangeNotification", "ptr", this) }
		return this(handle, function, pParam, timeout, flags)
	}

	static Semaphore(name, function, pParam := 0, timeout := -1, flags := 0x4) {
		if !hSem := DllCall("OpenSemaphoreW", "uint", 0x100000, "int", false, "str", name, "ptr")
			throw OSError()
		handle := { ptr: hSem, __Delete: this => DllCall("CloseHandle", "ptr", this) }
		return this(handle, function, pParam, timeout, flags)
	}

	static Event(name, function, pParam := 0, timeout := -1, flags := 0x8) {
		if !hEvent := DllCall("OpenEventW", "uint", 0x100000, "int", false, "str", name, "ptr")
			throw OSError()
		handle := { ptr: hEvent, __Delete: this => DllCall("CloseHandle", "ptr", this) }
		return this(handle, function, pParam, timeout, flags)
	}

	__New(handle, function, pParam := 0, timeout := -1, flags := 0x8) {
		if !DllCall("RegisterWaitForSingleObject", "ptr*", &hWait := 0, "ptr", handle, "ptr", this.Callback := CallbackCreate(function, "F"), "ptr", pParam, "uint", timeout, "uint", flags)
			throw OSError()
		this.Ptr := hWait, this.Obj := handle
	}

	__Delete() => (this.HasOwnProp("Ptr") && DllCall("UnregisterWaitEx", "ptr", this, "ptr", 0), this.HasOwnProp("Callback") && CallbackFree(this.Callback))
}

class Semaphore {
	static Open(name, dwDesiredAccess := 0x1f0003, bInheritHandle := false){
		if !h := DllCall("OpenSemaphoreW", "uint", dwDesiredAccess, "int", bInheritHandle, "str", name)
			throw OSError()
		return (ins := {Base: this.Prototype, Ptr: h}, ins.__Init(), ins)
	}

	__New(lInitialCount, lMaximumCount, name := unset, dwDesiredAccess := 0x1f0003, lpSemaphoreAttributes := 0) {
		if !this.Ptr := DllCall("CreateSemaphoreExW", "ptr", lpSemaphoreAttributes, "int", lInitialCount, "int", lMaximumCount, "ptr", IsSet(name) ? StrPtr(name) : 0, "uint", 0, "uint", dwDesiredAccess, "ptr")
			throw OSError()
	}

	__Delete() => this.Ptr && DllCall("CloseHandle", "ptr", this)

	Release(lReleaseCount := 1, &lpPreviousCount := 0) => DllCall("ReleaseSemaphore", "ptr", this, "uint", lReleaseCount, "int*", &lpPreviousCount)
}

class Event {
	static Open(name, dwDesiredAccess := 0x1f0003, bInheritHandle := false){
		if !h := DllCall("OpenEventW", "uint", dwDesiredAccess, "int", bInheritHandle, "str", name, "ptr")
			throw OSError()
		return (ins := {Base: this.Prototype, Ptr: h}, ins.__Init(), ins)
	}

	__New(name := unset, dwFlags := 1, dwDesiredAccess := 0x1f0003, lpSemaphoreAttributes := 0) {
		if !this.Ptr := DllCall("CreateEventExW", "ptr", 0, "ptr", IsSet(name) ? StrPtr(name) : 0, "uint", dwFlags, "uint", dwDesiredAccess, "ptr")
			throw OSError()
	}

	__Delete() => this.Ptr && DllCall("CloseHandle", "ptr", this)

	Set() => DllCall("SetEvent", "ptr", this)

	Reset() => DllCall("ResetEvent", "ptr", this)
}