/********************************************************************************
* @brief Duplicate a process's token and create a new process with this duplicte token. Only work with adminstrator privilege.
* @param targetPID The identifier of target process.
* @param exePath The path of an executable file which you want to start
* @param cmd optional Command
* @return The identifier of new process
* @example
RunAsAdmin()
StealToken(FindProcess("winlogon.exe"), "cmd.exe", "/k whoami") ; run cmd with system account
StealToken(FindProcess("explorer.exe"), "cmd.exe", "/k whoami") ; run cmd with normal user
********************************************************************************/
StealToken(targetPID, exePath, cmd := "") {
	; Enable SeDebugPrivilege
	; http://pinvoke.net/default.aspx/ntdll/RtlAdjustPrivilege.html
	DllCall("Ntdll\RtlAdjustPrivilege", "uint", 0x14, "char", 1, "char", 0, "ptr*", 0)

	; Get handle of target process
	; PROCESS_QUERY_INFORMATION (0x0400) PROCESS_QUERY_LIMITED_INFORMATION (0x1000)
	; https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocess
	if !hProcess := DllCall("OpenProcess", "uint", 0x0400, "int", 1, "uint", targetPID)
		if !hProcess := DllCall("OpenProcess", "uint", 0x1000, "int", 1, "uint", targetPID)
			throw Error(err := A_LastError)

	; https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocesstoken
	; TOKEN_DUPLICATE | TOKEN_ASSIGN_PRIMARY | TOKEN_QUERY
	if !DllCall("OpenProcessToken", "ptr", hProcess, "uint", 0x0002 | 0x0001 | 0x0008, "ptr*", &hTokenTargetProcess := 0) {
		err := A_LastError, DllCall("CloseHandle", "ptr", hProcess), DllCall("CloseHandle", "ptr", hTokenTargetProcess)
		throw Error(err)
	}

	; https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-impersonateloggedonuser
	if !DllCall("Advapi32\ImpersonateLoggedOnUser", "ptr", hTokenTargetProcess){
		err := A_LastError, DllCall("CloseHandle", "ptr", hProcess), DllCall("CloseHandle", "ptr", hTokenTargetProcess)
		throw Error(err)
	}
	DllCall("Advapi32\RevertToSelf")

	; Duplicate Token now
	; https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-duplicatetokenex
	; TOKEN_ADJUST_DEFAULT | TOKEN_ADJUST_SESSIONID | TOKEN_QUERY | TOKEN_DUPLICATE | TOKEN_ASSIGN_PRIMARY , SecurityImpersonation(2), TokenPrimary(1)
	if !DllCall("Advapi32\DuplicateTokenEx", "ptr", hTokenTargetProcess, "uint", 0x0080 | 0x0100 | 0x0008 | 0x0002 | 0x0001, "ptr", 0, "uint", 2, "uint", 1, "ptr*", &hTokenDuplicate := 0, "int"){
		err := A_LastError, DllCall("CloseHandle", "ptr", hProcess), DllCall("CloseHandle", "ptr", hTokenTargetProcess)
		throw Error(err)
	}

	; Prepare for startupinfo and processinfo struct
	; https://docs.microsoft.com/en-us/windows/win32/api/winbase/ns-winbase-startupinfoexa
	pStartInfo := Buffer(104, 0), pProcessInfo := Buffer(24)
	NumPut("uint", pStartInfo.Size, pStartInfo, 0), NumPut("ptr", StrPtr("winsta0\default"), pStartInfo, 16), NumPut("ushort", 1, pStartInfo, 64)

	; Create process with duplicate token
	; https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createprocesswithtokenw
	if !DllCall("Advapi32\CreateProcessWithTokenW", "ptr", hTokenDuplicate, "uint", 0, "ptr", StrPtr(exePath), "ptr", cmd ? StrPtr(A_Space cmd) : 0, "uint", 0x00000010, "ptr", 0, "ptr", 0, "ptr", pStartInfo, "ptr", pProcessInfo){
		err := A_LastError, DllCall("CloseHandle", "ptr", hProcess), DllCall("CloseHandle", "ptr", hTokenTargetProcess), DllCall("CloseHandle", "ptr", hTokenDuplicate)
		throw Error(err)
	}
	; Close all handles
	DllCall("CloseHandle", "ptr", hProcess), DllCall("CloseHandle", "ptr", NumGet(pProcessInfo, 0, "ptr")), DllCall("CloseHandle", "ptr", NumGet(pProcessInfo, 8, "ptr"))
	return NumGet(pProcessInfo, 16, "uint")
}
/********************************************************************************
* @brief Find process from an exe file name
* @param exeName Executable file without path
* @return Identifier of the first match, 0 if not found.
* @example MsgBox FindProcess("winlogon.exe")
********************************************************************************/
FindProcess(exeName){
	pProcessInfo := Buffer(304), NumPut("uint", pProcessInfo.Size, pProcessInfo, 0)
	; CreateToolhelp32Snapshot https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-createtoolhelp32snapshot
	if -1 = processSnapShot := DllCall("CreateToolhelp32Snapshot", "uint", 0x2, "uint", 0, "ptr")
		throw Error(A_LastError)
	; Process32First Process32Next https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-process32first
	if (!DllCall("Process32First", "ptr", processSnapShot, "ptr", pProcessInfo.Ptr, "int")){
		err := A_LastError, DllCall("CloseHandle", "ptr", processSnapShot)
		throw Error(err)
	}
	loop {
		; PROCESSENTRY32 structure https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/ns-tlhelp32-processentry32
		if exeName = found := StrGet(pProcessInfo.Ptr + 44, "CP936"){
			DllCall("CloseHandle", "ptr", processSnapShot)
			return NumGet(pProcessInfo, 8, "uint")
		}
	} until !DllCall("Process32Next", "ptr", processSnapShot, "ptr", pProcessInfo.Ptr, "int")
	DllCall("CloseHandle", "ptr", processSnapShot)
	return 0
}
/********************************************************************************
* @brief Run script with system account. Put this function at the beginning of scripts.
* @example RunAsSystem(), MsgBox("Current username：" A_UserName)
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