class DllInjector {
	__New(pid, filename) {
		this.Pid := pid, this.Filename := filename
		if !this.Ptr := DllCall("OpenProcess", "uint", 0x1f0fff, "int", false, "uint", pid, "ptr")
			throw OSError()
		if !remote_buf := DllCall("VirtualAllocEx", "ptr", this, "ptr", 0, "ptr", bytes := StrPut(filename), "uint", 0x00001000, "uint", 0x40, "ptr")
			throw OSError()
		if !DllCall("WriteProcessMemory", "ptr", this, "ptr", remote_buf, "str", filename, "ptr", bytes, "ptr", 0)
			throw OSError()
		if !load_library := DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "kernel32", "ptr"), "astr", "LoadLibraryW", "ptr")
			throw OSError()
		if !DllCall("CreateRemoteThread", "ptr", this, "ptr", 0, "uint", 0, "ptr", load_library, "ptr", remote_buf, "uint", 0, "ptr", 0)
			throw OSError()
	}

	__Delete(){
		SplitPath(this.Filename, &filename)
		if !snap_shot := DllCall("CreateToolhelp32Snapshot", "uint", 0x18, "uint", this.Pid, "ptr")
			throw OSError()
		mod_entry := Buffer(1080), NumPut("uint", mod_entry.Size, mod_entry)
		if !DllCall("Module32FirstW", "ptr", snap_shot, "ptr", mod_entry)
			throw OSError()
		while StrGet(mod_entry.Ptr + 48) != filename{
			if !DllCall("Module32NextW", "ptr", snap_shot, "ptr", mod_entry)
				throw OSError()
		}
		modbase := NumGet(mod_entry, 24, "ptr")
		if !free_library := DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "kernel32", "ptr"), "astr", "FreeLibrary", "ptr")
			throw OSError()
		if !DllCall("CreateRemoteThread", "ptr", this, "ptr", 0, "uint", 0, "ptr", free_library, "ptr", modbase, "uint", 0, "ptr", 0)
			throw OSError()
		DllCall("CloseHandle", "ptr", this)
	}
}