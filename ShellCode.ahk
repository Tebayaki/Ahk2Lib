x64 := "B800010000C20000"
code := ShellCode(x64)
MsgBox DllCall(code)

ShellCode(hex){
	if !DllCall("crypt32\CryptStringToBinary", "str", hex, "uint", 0, "uint", 4, "ptr", 0, "uint*", &bytes := 0, "ptr", 0, "ptr", 0)
		throw OSError()
	if !DllCall("crypt32\CryptStringToBinary", "str", hex, "uint", 0, "uint", 4, "ptr", code := Buffer(bytes), "uint*", &bytes, "ptr", 0, "ptr", 0)
		throw OSError()
	if !DllCall("VirtualProtect", "ptr", code, "uint", bytes, "uint", 0x40, "uint*", 0)
		throw OSError()
	return code
}