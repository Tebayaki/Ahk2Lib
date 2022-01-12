; MsgBox ProcessIDFromName("QQ.exe")
#Include <ThrowFmtMsg>

ProcessIDFromName(name){
	for in obj := ToolHelp("Process")
		if obj.Entry.Name = name
			return obj.Entry.ProcessID
	return 0
}

ProcessInformationFromName(name := "") {
	arr := []
	for in obj := ToolHelp("Process")
		if "" = name || obj.Entry.Name = name
			arr.Push(obj.Entry.Load())
	return arr.Length ? arr : 0
}

ThreadInformationFromProcessID(pid := 0){
	arr := []
	for in obj := ToolHelp("Thread")
		if !pid || obj.Entry.OwnerProcessID = pid
			arr.Push(obj.Entry.Load())
	return arr
}

ModuleInformationFromProcessID(pid){
	arr := []
	for in Obj := ToolHelp("Module", pid)
		arr.Push(obj.Entry.Load())
	return arr
}

class ToolHelp {
	static EntryType => Map("Process", 0x2, "Thread", 0x4, "Module", 0x8)
	__New(entryType, pid := 0, inherit := 0) {
		if (-1 = this.Ptr := DllCall("Kernel32\CreateToolhelp32Snapshot", "uint", ToolHelp.EntryType[entryType] | (inherit ? 0x80000000 : 0), "uint", pid, "ptr"))
			ThrowFormatedMessage()
		this.Entry := %entryType%ENTRY32(), this.EntryType := entryType
	}
	__Delete() => DllCall("CloseHandle", "ptr", this)
	__Enum(*) {
		if !DllCall("Kernel32\" this.EntryType "32First", "ptr", this, "ptr", this.Entry)
			ThrowFormatedMessage()
		return () => DllCall("Kernel32\" this.EntryType "32Next", "ptr", this, "ptr", this.Entry)
	}
}

class PROCESSENTRY32 extends Buffer {
	static Size => 568
	__New() => (super.__New(PROCESSENTRY32.Size), NumPut("uint", this.Size, this))
	ProcessID => NumGet(this, 8, "uint")
	ThreadsCount => NumGet(this, 28, "uint")
	ParentProcessID => NumGet(this, 32, "uint")
	BasePriority => NumGet(this, 36, "uint")
	Name => StrGet(this.Ptr + 44, "CP936")
	Load() => { ProcessID: this.ProcessID, ThreadsCount: this.ThreadsCount, ParentProcessID: this.ParentProcessID, BasePriority: this.BasePriority, Name: this.Name }
}

class THREADENTRY32 extends Buffer {
	static Size => 28
	__New() => (super.__New(THREADENTRY32.Size), NumPut("uint", this.Size, this))
	ThreadID => NumGet(this, 8, "uint")
	OwnerProcessID => NumGet(this, 12, "uint")
	BasePriority => NumGet(this, 16, "uint")
	Load() => {ThreadID: this.ThreadID, OwnerProcessID: this.OwnerProcessID, BasePriority: this.BasePriority}
}

class MODULEENTRY32 extends Buffer {
	static Size => 1080
	__New() => (super.__New(MODULEENTRY32.Size), NumPut("uint", this.Size, this))
	OwnerProcessID => NumGet(this, 8, "uint")
	BaseAddr => Format("{:#016x}", NumGet(this, 24, "ptr"))
	BaseSize => NumGet(this, 32, "uint")
	Handle => NumGet(this, 40, "ptr")
	Name => StrGet(this.Ptr + 48, "CP936")
	Load() => {OwnerProcessID: this.OwnerProcessID, BaseAddr: this.BaseAddr, BaseSize: this.BaseSize, Handle: this.Handle, Name: this.Name}
}