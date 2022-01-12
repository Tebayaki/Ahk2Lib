ThrowFormatedMessage(msg := unset, hModule := 0){
	if !DllCall('Kernel32\FormatMessage', 'uint', 0x100 | 0x200 | (hModule ? 0x800 : 0x1000), 'ptr', hModule, 'uint', IsSet(msg) ? msg : msg := A_LastError, 'uint', 0, 'ptr*', &pStr := 0, 'uint', 0, 'ptr', 0, 'uint')
		throw Error("Message code not found", -1)
	str := StrGet(pStr), DllCall('Kernel32\LocalFree', 'ptr', pStr, 'ptr')
	throw Error("(" msg ") " str, -1)
}