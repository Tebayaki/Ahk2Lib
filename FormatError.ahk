FormatError(err, module := 0){
	flag := FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_IGNORE_INSERTS | (module ? FORMAT_MESSAGE_FROM_HMODULE : FORMAT_MESSAGE_FROM_SYSTEM)
	if FormatMessage(flag, module, err, 0, &pStr, 0, 0) && pStr
		return "(" err ") " StrGet(pStr.Lock())
	else
		return "No text found for this error code"
}

; #Include <Win32api>
FORMAT_MESSAGE_FROM_HMODULE         := 0x00000800
FORMAT_MESSAGE_FROM_SYSTEM          := 0x00001000
FORMAT_MESSAGE_ALLOCATE_BUFFER      := 0x00000100
FORMAT_MESSAGE_IGNORE_INSERTS       := 0x00000200

FormatMessage(dwFlags, lpSource, dwMessageId, dwLanguageId, &lpBuffer, nSize, Arguments) {
	if len := DllCall('Kernel32\FormatMessage', 'uint', dwFlags, 'ptr', lpSource, 'uint', dwMessageId, 'uint', dwLanguageId, 'ptr*', &lpBuffer := 0, 'uint', nSize, 'ptr', Arguments, 'uint')
		if dwFlags & FORMAT_MESSAGE_ALLOCATE_BUFFER
			lpBuffer := HLocal(lpBuffer)
	return len
}

class HLocal {
	__New(ptr) => this.Ptr := ptr
	__Delete() => this.Free()
	Lock() => LocalLock(this)
	Free() => LocalFree(this)
}

MsgBox FormatError(2)