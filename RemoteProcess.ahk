#Include <ToolHelp>

; MEMORY_TASKBAR_WIDTH := ["Explorer.exe", 0x328350, 0xA0]
; pm := RemoteProcess("explorer.exe")
; ptr := pm.TracePointer(MEMORY_TASKBAR_WIDTH*)
; MsgBox pm.ReadMemory(ptr, "int")

class RemoteProcess {
	static DataSize := Map("char", 1, "uchar", 1, "short", 2, "ushort", 2, "int", 4, "uint", 4, "ptr", 8, "uptr", 8, "int64", 8, "uint64", 8, "folat", 4, "double", 8)

	__New(process_var) {
		pid := process_var is String ? ToolHelp.FindProcess(process_var).ProcessId : process_var
		if !this.Ptr := DllCall("OpenProcess", "uint", 0x1f0fff, "int", false, "uint", this.ProcessId := pid, "ptr")
			throw OSError()
	}

	__Delete() => this.Ptr && DllCall("CloseHandle", "ptr", this)

	VirtualAlloc(dwSize, flAllocationType := 0x1000, flProtect := 0x40){
		if !pRemoteBuf := DllCall("VirtualAllocEx", "ptr", this, "ptr", 0, "ptr", dwSize, "uint", flAllocationType, "uint", flProtect, "ptr")
			throw OSError()
		return pRemoteBuf
	}

	VirtualFree(lpAddress, dwSize, dwFreeType := 0x4000){
		if !DllCall("VirtualFreeEx", "ptr", this, "ptr", lpAddress, "uptr", dwSize, "uint", dwFreeType)
			throw OSError()
	}

	VirtualProtect(lpAddress, dwSize, flNewProtect, &flOldProtect := 0){
		if !DllCall("VirtualProtectEx", "ptr", this, "ptr", lpAddress, "uptr", dwSize, "uint", flNewProtect, "uint*", &flOldProtect := 0)
			throw OSError()
	}

	CreateThread(lpStartAddress, lpParameter, dwCreationFlags := 0, &threadId := 0){
		if !hThread := DllCall("CreateRemoteThread", "ptr", this, "ptr", 0, "uptr", 0, "ptr", lpStartAddress, "ptr", lpParameter, "uint", dwCreationFlags, "uint*", threadId := 0, "ptr")
			throw OSError()
		return handle := { ptr: hThread, __Delete: this => DllCall("CloseHandle", "ptr", this) }
	}

	/*
	@example1 ReadMemory(0xffffff, "int") => Number
	@example2 ReadMemory(0xffffff, 1024) => Buffer
	*/
	ReadMemory(addr, byte := "int") {
		switch Type(byte) {
			case "Integer": res := DllCall("ReadProcessMemory", "ptr", this, "ptr", addr, "ptr", buf := Buffer(byte), "uptr", byte, "uptr*", &byte_done := 0)
			case "String": res := DllCall("ReadProcessMemory", "ptr", this, "ptr", addr, byte "*", &buf := 0, "uptr", ProcessMemory.DataSize[byte], "uptr*", &byte_done := 0)
			default:throw TypeError("Invalid parameter")
		}
		if !res
			throw OSError()
		return buf
	}

	/*
	@example1 WriteMemory(0xffffff, 100, "int")
	@example2 WriteMemory(0xffffff, buf := Buffer(2048), buf.Size)
	@example3 WriteMemory(0xffffff, "string", "utf-16")
	 */
	WriteMemory(addr, buf, byte := 0) {
		switch Type(buf) {
			case "Buffer": res := DllCall("WriteProcessMemory", "ptr", this, "ptr", addr, "ptr", buf, "uptr", byte ? byte : buf.Size, "uptr*", &byte_written := 0)
			case "String": res := DllCall("WriteProcessMemory", "ptr", this, "ptr", addr, "str", buf, "uptr", StrPut(buf, byte ? byte : "CP0"), "uptr*", &byte_written := 0)
			case "Integer", "Float": res := DllCall("WriteProcessMemory", "ptr", this, "ptr", addr, (byte := byte ? byte : "int") "*", &buf, "uptr", ProcessMemory.DataSize[byte], "uptr*", &byte_written := 0)
			default:throw TypeError("WriteMemory: Invalid type")
		}
		if !res
			throw OSError()
	}

	/*
	@example1 TracePointer(0xffffff, 0x4, 0x8, 0x10) => Ptr
	@example2 TracePointer("kernel32.dll", 0x4, 0x8, 0x10) => Ptr
	@example3 TracePointer("THREADSTACK0", 0x4, 0x8, 0x10) => Ptr
	*/
	TracePointer(addr, offsets*){
		DllCall("IsWow64Process2", "ptr", this, "ushort*", &is_wow64 := 0, "ushort*", 0)
		if addr is String{
			found := false
			if RegExMatch(addr, "i)^THREADSTACK(\d+)$", &match) {
				num := match[1]
				for thread in ToolHelp.EnumThread() {
					if thread.OwnerProcessId = this.ProcessId {
						if --num < 0 {
							mod_info := ToolHelp.FindModule("Kernel32.dll", this.ProcessId)
							mod_start := mod_info.BaseAddress
							mod_end := mod_start + mod_info.BaseSize
							thread_handle := DllCall("OpenThread", "uint", 0x1f03ff, "int", 0, "uint", thread.ThreadID)
							DllCall("Ntdll\NtQueryInformationThread", "ptr", thread_handle, "uint", 0, "ptr", buf := Buffer(48), "uint", buf.Size, "uint*", 0)
							teb_addr := NumGet(buf, 8, "ptr")
							DllCall("CloseHandle", "ptr", thread_handle)
							offset := 4096
							if is_wow64 {
								teb_addr += offset * 2
								stack_top := this.ReadMemory(teb_addr + 4, "uint")
								buf := this.ReadMemory(stack_top - offset, offset)
								while (offset -= 4) >= 0 {
									ptr := NumGet(buf, offset, "uint")
									if ptr >= mod_start && ptr <= mod_end {
										addr := stack_top - 4096 + offset
										found := true
										break
									}
								}
							} else {
								stack_top := this.ReadMemory(teb_addr + 8, "ptr")
								buf := this.ReadMemory(stack_top - offset, offset)
								while (offset -= 8) >= 0 {
									ptr := NumGet(buf, offset, "ptr")
									if ptr >= mod_start && ptr <= mod_end {
										addr := stack_top - 4096 + offset
										found := true
										break
									}
								}
							}
							break
						}
					}
				}
			} else {
				for module_info in ToolHelp.EnumModule(this.ProcessId){
					if module_info.Name = addr{
						addr := module_info.BaseAddress
						found := true
						break
					}
				}
			}
			if !found
				throw OSError(126)
		}
		if offsets.Length
			last_offset := offsets.Pop()
		if is_wow64{
			for k, v in offsets
				addr := this.ReadMemory(addr + v, "uint")
		} else {
			for k, v in offsets
				addr := this.ReadMemory(addr + v, "ptr")
		}
		return addr + last_offset
	}

	ReadCommandLine(){
		if nts := DllCall("Ntdll\NtQueryInformationProcess", "ptr", this, "uint", 0, "ptr", buf := Buffer(48), "uint", buf.Size, "uint*", 0)
			throw Error(nts, - 1)
		peb_ptr := NumGet(buf, 8, "ptr")
		DllCall("IsWow64Process2", "ptr", this, "ushort*", &is_wow64 := 0, "ushort*", 0)
		if is_wow64{
			param_ptr := this.ReadMemory(peb_ptr + 4096 + 16, "uint")
			cmd_unicode := this.ReadMemory(param_ptr + 64, 8)
			cmd_buf := this.ReadMemory(NumGet(cmd_unicode, 4, "uint"), NumGet(cmd_unicode, "ushort"))
		} else {
			param_ptr := this.ReadMemory(peb_ptr + 32, "ptr")
			cmd_unicode := this.ReadMemory(param_ptr + 112, 16)
			cmd_buf := this.ReadMemory(NumGet(cmd_unicode, 8, "ptr"), NumGet(cmd_unicode, "ushort"))
		}
		return cmd := StrGet(cmd_buf)
	}
}