RunAsSystem()
MsgBox A_UserName " " A_IsAdmin
StealToken(FindProcess("explorer.exe"), "D:\AutoHotkey2\AutoHotkey64.exe", "D:\Code\AutoHotkey2\test\2.ah2") ; 以普通用户身份打开cmd
/********************************************************************************
* @brief 获取指定进程的令牌，可借此以System权限和其他用户身份启动进程，使用时需要管理员权限
* @param targetPID 进程标识，将复制其令牌
* @param exePath 可执行程序路径, 使用获取的令牌启动的可执行程序
* @param cmd optional 启动命令
* @return 成功返回新进程id
* @example
RunAsAdmin()
StealToken(FindProcess("winlogon.exe"), "cmd.exe", "/k whoami") ; 以system身份打开cmd
StealToken(FindProcess("explorer.exe"), "cmd.exe", "/k whoami") ; 以普通用户身份打开cmd
********************************************************************************/
StealToken(targetPID, exePath, cmd := "") {
	; Enable SeDebugPrivilege
	if !DllCall("OpenProcessToken", "ptr", DllCall("GetCurrentProcess", "ptr"), "uint", 0x0020, "ptr*", &hTokenCurrentProcess := 0)
		throw Error(DllCall("GetLastError"))
	if !DllCall("Advapi32\LookupPrivilegeValue", "ptr", 0, "ptr", StrPtr("SeDebugPrivilege"), "ptr*", &pLuid := 0){
		err := DllCall("GetLastError"), DllCall("CloseHandle", "ptr", hTokenCurrentProcess)
		throw Error(err)
	}
	pTokenPriv := Buffer(16) ; sizeof(TOKEN_PRIVILEGES) = 16
	NumPut("uint", 1, pTokenPriv) ; PrivilegeCount := 1
	NumPut("uint64", pLuid, pTokenPriv)
	NumPut("uint", 0x2, pTokenPriv, 12) ; SE_PRIVILEGE_ENABLED (0x2)
	if !DllCall("Advapi32\AdjustTokenPrivileges", "ptr", hTokenCurrentProcess, "int", 0, "ptr", pTokenPriv, "uint", 0, "ptr", 0, "ptr", 0){
		err := DllCall("GetLastError"), DllCall("CloseHandle", "ptr", hTokenCurrentProcess)
		throw Error(err)
	}
	DllCall("CloseHandle", "ptr", hTokenCurrentProcess)

	; Get handle of target process
	; PROCESS_QUERY_INFORMATION (0x0400) PROCESS_QUERY_LIMITED_INFORMATION (0x1000)
	if !hProcess := DllCall("OpenProcess", "uint", 0x0400, "int", 1, "uint", targetPID)
		if !hProcess := DllCall("OpenProcess", "uint", 0x1000, "int", 1, "uint", targetPID)
			throw Error(err := DllCall("GetLastError"))
	; TOKEN_DUPLICATE | TOKEN_ASSIGN_PRIMARY | TOKEN_QUERY
	if !DllCall("OpenProcessToken", "ptr", hProcess, "uint", 0x0002 | 0x0001 | 0x0008, "ptr*", &hTokenTargetProcess := 0) {
		err := DllCall("GetLastError"), DllCall("CloseHandle", "ptr", hProcess), DllCall("CloseHandle", "ptr", hTokenTargetProcess)
		throw Error(err)
	}

	if !DllCall("Advapi32\ImpersonateLoggedOnUser", "ptr", hTokenTargetProcess){
		err := DllCall("GetLastError"), DllCall("CloseHandle", "ptr", hProcess), DllCall("CloseHandle", "ptr", hTokenTargetProcess)
		throw Error(err)
	}
	DllCall("Advapi32\RevertToSelf")

	; Duplicate Token now
	; TOKEN_ADJUST_DEFAULT | TOKEN_ADJUST_SESSIONID | TOKEN_QUERY | TOKEN_DUPLICATE | TOKEN_ASSIGN_PRIMARY , SecurityImpersonation(2), TokenPrimary(1)
	if !DllCall("Advapi32\DuplicateTokenEx", "ptr", hTokenTargetProcess, "uint", 0x0080 | 0x0100 | 0x0008 | 0x0002 | 0x0001, "ptr", 0, "uint", 2, "uint", 1, "ptr*", &hTokenDuplicate := 0, "int"){
		err := DllCall("GetLastError"), DllCall("CloseHandle", "ptr", hProcess), DllCall("CloseHandle", "ptr", hTokenTargetProcess)
		throw Error(err)
	}

	; Prepare for startupinfo and processinfo struct
	pStartInfo := Buffer(104, 0), pProcessInfo := Buffer(24)
	NumPut("uint", pStartInfo.Size, pStartInfo, 0)
	NumPut("ptr", StrPtr("winsta0\default"), pStartInfo, 16)
	NumPut("ushort", 1, pStartInfo, 64)

	; Create process with duplicate token
	if !DllCall("Advapi32\CreateProcessWithTokenW", "ptr", hTokenDuplicate, "uint", 0, "ptr", StrPtr(exePath), "ptr", cmd ? StrPtr(A_Space cmd) : 0, "uint", 0x00000010, "ptr", 0, "ptr", 0, "ptr", pStartInfo, "ptr", pProcessInfo){
		err := DllCall("GetLastError"), DllCall("CloseHandle", "ptr", hProcess), DllCall("CloseHandle", "ptr", hTokenTargetProcess), DllCall("CloseHandle", "ptr", hTokenDuplicate)
		throw Error(err)
	}
	; Close all handles
	DllCall("CloseHandle", "ptr", hProcess), DllCall("CloseHandle", "ptr", NumGet(pProcessInfo, 0, "ptr")), DllCall("CloseHandle", "ptr", NumGet(pProcessInfo, 8, "ptr"))
	return NumGet(pProcessInfo, 16, "uint")
}
/********************************************************************************
* @brief 放在脚本开头，如果不是system身份，则以system身份重启
* @example RunAsSystem(), MsgBox("当前身份：" A_UserName)
********************************************************************************/
RunAsSystem(){
	try{
		if "SYSTEM" = A_UserName
			return
		if A_IsAdmin
			if A_IsCompiled
				StealToken(FindProcess("winlogon.exe"), A_AhkPath, "/restart")
			else
				StealToken(FindProcess("winlogon.exe"), A_AhkPath, "/restart " A_ScriptFullPath)
		else if !(DllCall("GetCommandLine", "str") ~= " /restart(?!\S)")
			if A_IsCompiled
				Run '*RunAs "' A_ScriptFullPath '" /restart'
			else
				Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
	}
	ExitApp
}
/********************************************************************************
* @brief 查找指定文件的创建的进程
* @param exeName 可执行文件名，不包含路径
* @return 找到符合条件的第一个进程反回其进程id，否则返回0
* @example MsgBox FindProcess("winlogon.exe")
********************************************************************************/
FindProcess(exeName){
	pProcessInfo := Buffer(304), NumPut("uint", pProcessInfo.Size, pProcessInfo, 0)
	; CreateToolhelp32Snapshot https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-createtoolhelp32snapshot
	if -1 = processSnapShot := DllCall("CreateToolhelp32Snapshot", "uint", 0x2, "uint", 0, "ptr")
		throw Error(DllCall("GetLastError"))
	; Process32First Process32Next https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-process32first
	if (!DllCall("Process32First", "ptr", processSnapShot, "ptr", pProcessInfo.Ptr, "int")){
		err := DllCall("GetLastError"), DllCall("CloseHandle", "ptr", processSnapShot)
		throw Error(err)
	}
	loop {
		; PROCESSENTRY32 structure https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/ns-tlhelp32-processentry32
		if exeName = found := StrGet(pProcessInfo.Ptr + 44, "utf-8"){
			DllCall("CloseHandle", "ptr", processSnapShot)
			return NumGet(pProcessInfo, 8, "uint")
		}
	} until !DllCall("Process32Next", "ptr", processSnapShot, "ptr", pProcessInfo.Ptr, "int")
	DllCall("CloseHandle", "ptr", processSnapShot)
	return 0
}

RunAsAdmin(){
	if not (A_IsAdmin or RegExMatch(DllCall("GetCommandLine", "str"), " /restart(?!\S)")){
		try{
			if A_IsCompiled
				Run '*RunAs "' A_ScriptFullPath '" /restart'
			else
				Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
		}
		ExitApp
	}
}