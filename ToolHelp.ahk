/*
@TH32CS_SNAPHEAPLIST 0x1
@TH32CS_SNAPPROCESS 0x2
@TH32CS_SNAPTHREAD 0x4
@TH32CS_SNAPMODULE 0x8
@TH32CS_SNAPMODULE32 0x10
@TH32CS_INHERIT 0x80000000
@TH32CS_SNAPALL 0xf
*/
class ToolHelp {
	static FindProcess(process_name){
		for entry in ToolHelp(0x2).Process()
			if entry.Name = process_name
				return entry
		throw OSError(127, -1)
	}

	static FindModule(module_name, pid := 0){
		for mod_entry in ToolHelp(0x18, pid).Module()
			if mod_entry.Name = module_name
				return mod_entry
		throw OSError(126, -1)
	}

	static ListProcesses(process_name := unset){
		arr := []
		if IsSet(process_name){
			for entry in this(0x2).Process(true)
				if entry.Name = process_name
					arr.Push(entry)
		} else for entry in this(0x2).Process(true)
			arr.Push(entry)
		return arr
	}

	static ListModules(pid := 0){
		arr := []
		for mod_entry in ToolHelp(0x18, pid).Module(true)
			arr.Push(mod_entry)
		return arr
	}

	static ListThreads(pid := unset){
		arr := []
		if IsSet(pid){
			for thread_entry in ToolHelp(0x4).Thread(true)
				if thread_entry.OwnerProcessId = pid
					arr.Push(thread_entry)
		} else for thread_entry in ToolHelp(0x4).Thread(true)
			arr.Push(thread_entry)
		return arr
	}

	static EnumProcess(){
		return this(0x2).Process()
	}

	static EnumThread(){
		return this(0x4).Thread()
	}

	static EnumModule(pid := 0){
		return this(0x18, pid).Module()
	}

	static ReadProcessMemory(pid, addr, byte, &byte_read){
		switch Type(byte) {
			case "Integer": res := DllCall("Toolhelp32ReadProcessMemory", "uint", pid, "ptr", addr, "ptr", buf := Buffer(byte), "uint", byte, "uint*", &byte_read := 0)
			case "String": res := DllCall("Toolhelp32ReadProcessMemory", "uint", pid, "ptr", addr, byte "*", &buf := 0, "uint", sizeof(byte), "uint*", &byte_read := 0)
			default: throw TypeError("Invalid parameter")
		}
		if !res
			throw OSError(A_LastError)
		return buf
		sizeof(type) => Map("char", 1, "uchar", 1, "short", 2, "ushort", 2, "int", 4, "uint", 4, "ptr", 8, "uptr", 8, "int64", 8, "uint64", 8, "folat", 4, "double", 8)[type]
	}

	__New(flags := 0x1F, process_var := 0) {
		if -1 = this.Ptr := DllCall("CreateToolhelp32Snapshot", "uint", flags, "uint", process_var is String ? ToolHelp.FindProcess(process_var).ProcessId : process_var, "ptr")
			throw OSError(A_LastError, -1)
	}

	__Delete() => this.HasOwnProp("Ptr") && DllCall("CloseHandle", "ptr", this)

	__Traverse(entry, first, next, list) {
		next := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "str", "kernel32", "ptr"), "astr", next, "ptr")
		if list
			return (&o_entry) => DllCall(A_Index = 1 ? first : next, "ptr", this, "ptr", o_entry := entry())
		entry := entry()
		return (&o_entry) => DllCall(A_Index = 1 ? first : next, "ptr", this, "ptr", o_entry := entry)
	}

	Process(list := false) => this.__Traverse(ToolHelp._PROCESSENTRY32, "Process32FirstW", "Process32NextW", list)

	Thread(list := false) => this.__Traverse(ToolHelp._THREADENTRY32, "Thread32First", "Thread32Next", list)

	Module(list := false) => this.__Traverse(ToolHelp._MODULEENTRY32, "Module32FirstW", "Module32NextW", list)

	HeapList(list := false) => this.__Traverse(ToolHelp._HEAPLIST32, "Heap32ListFirst", "Heap32ListNext", list)

	Heap(list := false) {
		heap_list := ToolHelp._HEAPLIST32()
		heap := ToolHelp._HEAPENTRY32()
		hmod := DllCall("GetModuleHandle", "str", "kernel32", "ptr")
		heap_list_next := DllCall("GetProcAddress", "Ptr", hmod, "astr", "Heap32ListNext", "ptr")
		heap_first := DllCall("GetProcAddress", "Ptr", hmod, "astr", "Heap32First", "ptr")
		heap_next := DllCall("GetProcAddress", "Ptr", hmod, "astr", "Heap32Next", "ptr")
		return (&heap_out) => A_Index = 1 ? DllCall("Heap32ListFirst", "ptr", this, "ptr", heap_list) && DllCall(heap_first, "ptr", heap_out := heap, "uint", heap_list.ProcessId, "ptr", heap_list.HeapId)
			: DllCall(heap_next, "ptr", heap) || (DllCall(heap_list_next, "ptr", this, "ptr", heap_list) && DllCall(heap_first, "ptr", heap, "uint", heap_list.ProcessId, "ptr", heap_list.HeapId))
	}

	class _PROCESSENTRY32 extends Buffer {
		__New() => (super.__New(568), NumPut("uint", this.Size, this))
		ProcessId => NumGet(this, 8, "uint")
		ThreadsCount => NumGet(this, 28, "uint")
		ParentProcessId => NumGet(this, 32, "uint")
		BasePriority => NumGet(this, 36, "uint")
		Name => StrGet(this.Ptr + 44)
	}

	class _THREADENTRY32 extends Buffer {
		__New() => (super.__New(28), NumPut("uint", this.Size, this))
		ThreadId => NumGet(this, 8, "uint")
		OwnerProcessId => NumGet(this, 12, "uint")
		BasePriority => NumGet(this, 16, "uint")
	}

	class _MODULEENTRY32 extends Buffer {
		__New() => (super.__New(1080), NumPut("uint", this.Size, this))
		OwnerProcessId => NumGet(this, 8, "uint")
		BaseAddress => NumGet(this, 24, "ptr")
		BaseSize => NumGet(this, 32, "uint")
		Handle => NumGet(this, 40, "ptr")
		Name => StrGet(this.Ptr + 48)
	}

	class _HEAPENTRY32 extends Buffer {
		__New() => (super.__New(56), NumPut("ptr", this.Size, this))
		Handle => NumGet(this, 8, "ptr")
		Address => NumGet(this, 16, "ptr")
		BlockSize => NumGet(this, 24, "uint")
		Flags => NumGet(this, 32, "uint")
		ProcessId => NumGet(this, 44, "uint")
		HeapId => NumGet(this, 48, "ptr")
	}

	class _HEAPLIST32 extends Buffer {
		__New() => (super.__New(32), NumPut("ptr", this.Size, this))
		ProcessId => NumGet(this, 8, "uint")
		HeapId => NumGet(this, 16, "ptr")
		Flags => NumGet(this, 24, "uint")
	}
}
