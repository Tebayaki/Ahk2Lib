/*******************************************************************************
* @param hWnd optional Handle of a window, default is current window
* @return Retrieves the identifier of the parent thread
* @example MsgBox(GetWindowThreadId())
********************************************************************************/
GetWindowThreadId(hWnd := "") => DllCall("GetWindowThreadProcessId", "ptr", hWnd ? hWnd : WinExist("A"), "ptr", 0, "uint")

/********************************************************************************
* @brief Retrieves processes belonging to a specific exe file
* @param exeName optional The exe file name without directory, blank it to get all processes
* @return An array containing pids
* @example MsgBox(GetProcessList("explorer.exe")[1])
********************************************************************************/
GetProcessList(exeName := ""){
	pProcessInfo := Buffer(304), NumPut("uint", pProcessInfo.Size, pProcessInfo, 0)
	; CreateToolhelp32Snapshot https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-createtoolhelp32snapshot
	if -1 = processSnapShot := DllCall("CreateToolhelp32Snapshot", "uint", 0x2, "uint", 0, "ptr")
		throw Error(A_LastError)
	; Process32First Process32Next https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-process32first
	if !DllCall("Process32First", "ptr", processSnapShot, "ptr", pProcessInfo.Ptr, "int"){
		err := A_LastError, DllCall("CloseHandle", "ptr", processSnapShot)
		throw Error(err)
	}
	processIds := []
	loop {
		; PROCESSENTRY32 structure https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/ns-tlhelp32-processentry32
		if !exeName or exeName = StrGet(pProcessInfo.Ptr + 44, "utf-8")
			processIds.Push(NumGet(pProcessInfo, 8, "uint"))
	} until !DllCall("Process32Next", "ptr", processSnapShot, "ptr", pProcessInfo.Ptr, "int")
	DllCall("CloseHandle", "ptr", processSnapShot)
	return processIds
}
/********************************************************************************
* @brief Retrieves threads belong to a process
* @param pid optional The process identifier, blank it to get all threads
* @return An array containing thread id
* @example MsgBox(GetThreadId(WinGetPID("A"))[1])
********************************************************************************/
GetThreadId(pid := ""){
	pThreadInfo := Buffer(28), NumPut("uint", pThreadInfo.Size, pThreadInfo, 0)
	; CreateToolhelp32Snapshot https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-createtoolhelp32snapshot
	if -1 = threadSnapShot := DllCall("CreateToolhelp32Snapshot", "uint", 0x4, "uint", 0, "ptr")
		throw Error(A_LastError)
	; Thread32First https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-thread32first
	if !DllCall("Thread32First", "ptr", threadSnapShot, "ptr", pThreadInfo.Ptr, "int"){
		err := A_LastError, DllCall("CloseHandle", "ptr", threadSnapShot)
		throw Error(err)
	}
	threadIds := []
	loop {
		; THREADENTRY32 structure https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/ns-tlhelp32-threadentry32
		if !pid or pid = NumGet(pThreadInfo, 12, "uint")
			threadIds.Push(NumGet(pThreadInfo, 8, "uint"))
	} until !DllCall("Thread32Next", "ptr", threadSnapShot, "ptr", pThreadInfo.Ptr, "int")
	DllCall("CloseHandle", "ptr", threadSnapShot)
	return threadIds
}

/********************************************************************************
* @brief Retrieves information of a thread
* @param threadId Thread identifier
* @return An objects containing threads information
* @example MsgBox(ThreadQuery(GetWindowThreadId()).MappedFileName)
********************************************************************************/
ThreadQuery(threadId) {
	Info := {}
	; https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openthread
	if !hThread := DllCall("OpenThread", "uint", 0x1F03FF, "int", 0, "uint", threadId, "ptr")
		throw Error(A_LastError)

	; System thread information
	pInfo := Buffer(80)
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 0x28, "ptr", pInfo.Ptr, "uint", pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	Info.KernelTime := NumGet(pInfo, 0, "ptr") / 10000000
	Info.UserTime := NumGet(pInfo, 8, "ptr") / 10000000
	pSysTime := Buffer(16), DllCall("kernel32\FileTimeToSystemTime", "ptr", pInfo.Ptr + 16, "ptr", pSysTime.Ptr, "int")
	pLocalTime := Buffer(16), DllCall("kernel32\SystemTimeToTzSpecificLocalTime", "ptr", 0, "ptr", pSysTime.Ptr, "ptr", pLocalTime.Ptr, "int")
	year := NumGet(pLocalTime, 0, "ushort"), month := NumGet(pLocalTime, 2, "ushort"), day := NumGet(pLocalTime, 6, "ushort")
	hour := NumGet(pLocalTime, 8, "ushort"), min   := NumGet(pLocalTime, 10, "ushort"), sec := NumGet(pLocalTime, 12, "ushort"), msec := NumGet(pLocalTime, 14, "ushort")
	Info.CreateTime := year month day " " hour ":" min ":" sec ":" msec
	Info.WaitTime :=  NumGet(pInfo, 24, "ptr")
	Info.ProcessID := NumGet(pInfo, 40, "ptr")
	Info.ThreadID := NumGet(pInfo, 48, "ptr")
	Info.Priority := NumGet(pInfo, 56, "uint")
	Info.BasePriority := NumGet(pInfo, 60, "uint")
	Info.ContextSwitches := NumGet(pInfo, 64, "uint")
	Info.ThreadState := NumGet(pInfo, 68, "uint")
	WaitReason := {0: "Executive(0)", 1: "FreePage(1)", 2: "PageIn(2)", 3: "PoolAllocation(3)", 4: "DelayExecution(4)", 5: "Suspended(5)", 6: "UserRequest(6)", 7: "WrExecutive(7)", 8: "WrFreePage(8)", 9: "WrPageIn(9)", 10: "WrPoolAllocation(10)", 11: "WrDelayExecution(11)", 12: "WrSuspended(12)", 13: "WrUserRequest(13)", 14: "WrEventPair(14)", 15: "WrQueue(15)", 16: "WrLpcReceive(16)", 17: "WrLpcReply(17)", 18: "WrVirtualMemory(18)", 19: "WrPageOut(19)", 20: "WrRendezvous(20)", 21: "WrKeyedEvent(21)", 22: "WrTerminated(22)", 23: "WrProcessInSwap(23)", 24: "WrCpuRateControl(24)", 25: "WrCalloutStack(25)", 26: "WrKernel(26)", 27: "WrResource(27)", 28: "WrPushLock(28)", 29: "WrMutex(29)", 30: "WrQuantumEnd(30)", 31: "WrDispatchInt(31)", 32: "WrPreempted(32)", 33: "WrYieldExecution(33)", 34: "WrFastMutex(34)", 35: "WrGuardedMutex(35)", 36: "WrRundown(36)", 37: "MaximumWaitReaso(37)"}
	Info.WaitReason := WaitReason.%NumGet(pInfo, 72, "uint")%

	; SuspendCount
	pInfo := Buffer(4)
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 0x23, "ptr", pInfo.Ptr, "uint", pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	Info.SuspendCount := NumGet(pInfo, 0, "uint")

	; Name
	pInfo := Buffer(42)
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 0x26, "ptr", pInfo.Ptr, "uint", pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	Info.ThreadName:= StrGet(NumGet(pInfo, 8, "ptr"), NumGet(pInfo, 0, "ushort"))

	; Basic information
	pInfo := Buffer(48)
	; https://docs.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntquerysysteminformation
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 0, "ptr", pInfo.Ptr, "uint", pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	Info.ExitStatus := NumGet(pInfo, 0, "int")
	Info.TebBaseAddress := Format("{:#016x}", NumGet(pInfo, 8, "ptr"))
	; Info.ProcessId := NumGet(pInfo, 16, "ptr")
	; Info.ThreadId := NumGet(pInfo, 24, "ptr")
	Info.AffinityMask := NumGet(pInfo, 32, "ptr")
	; Info.Priority := NumGet(pInfo, 40, "uint")
	; Info.BasePriority := NumGet(pInfo, 44, "uint")

	; Thread Times
	pInfo := Buffer(32)
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 1, "ptr", pInfo.Ptr, "uint", pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	; Info.CreateTime := NumGet(pInfo, 0, "int64")
	Info.ExitTime := NumGet(pInfo, 8, "int64")
	; Info.KernelTime := NumGet(pInfo, 16, "int64")
	; Info.UserTime := NumGet(pInfo, 24, "int64")

	; StartAddress
	pInfo := Buffer(8)
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 9, "ptr", pInfo.Ptr, "uint", pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	Info.StartAddress := Format("{:#016x}", NumGet(pInfo, 0, "ptr"))

	; PerformanceCount
	pInfo := Buffer(8)
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 11, "ptr",pInfo.Ptr, "uint",pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	Info.PerformanceCount := NumGet(pInfo, 0, "int64")

	; AmILastThread
	pInfo := Buffer(4)
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 12, "ptr", pInfo.Ptr, "uint", pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	Info.LastThread := NumGet(pInfo, 0, "int")

	; PriorityBoost
	pInfo := Buffer(4)
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 14, "ptr", pInfo.Ptr, "uint", pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	Info.PriorityBoost := NumGet(pInfo, 0, "int")

	; Last system call
	pInfo := Buffer(16)
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 0x15, "ptr", pInfo.Ptr, "uint", pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	Info.FirstArgument := NumGet(pInfo, 0, "ptr")
	Info.SystemCallNumber := NumGet(pInfo, 8, "ushort")

	; Cycle Time
	pInfo := Buffer(16)
	if NTSTATUS := DllCall("ntdll\NtQueryInformationThread", "ptr", hThread, "uint", 0x17, "ptr", pInfo.Ptr, "uint", pInfo.Size, "ptr", 0, "int"){
		DllCall("CloseHandle", "ptr", hThread)
		throw Error(NTSTATUS)
	}
	Info.AccumulatedCycles := NumGet(pInfo, 0, "uint64")
	Info.CurrentCycleCount := NumGet(pInfo, 8, "uint64")

	; MappedFileName
	pInfo := Buffer(260)
	; https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocess
	if (!hProcess := DllCall("OpenProcess", "uint", 0x1000, "int", 0, "ptr", Info.ProcessId))
		throw Error(A_LastError)
	; https://docs.microsoft.com/en-us/windows/win32/api/psapi/nf-psapi-getmappedfilenamew
	if (!length := DllCall("K32GetMappedFileNameW", "ptr", hProcess, "ptr", Info.StartAddress, "ptr", pInfo.Ptr, "uint", pInfo.Size))
		throw (err := A_LastError, DllCall("CloseHandle", "ptr", hProcess), err)
	DllCall("CloseHandle", "ptr", hProcess)
	Info.MappedFileName := StrGet(pInfo, length)
	DllCall("CloseHandle", "ptr", hThread)
	return Info
}

/********************************************************************************
* Terminates a thread
* @param threadIdID
* @return Bool
* @example
Run("notepad.exe",,, &pid)
WinWait("ahk_pid " pid)
Sleep(1000)
threadId := GetWindowThreadId(WinExist("ahk_pid " pid))
if MsgBox("Sure to terminate the main window thread of notepad?",, 0x1) == "OK"
	TerminateThread(threadId)
********************************************************************************/
TerminateThread(threadId) {
	if (!hThread := DllCall("OpenThread", "uint", 0x1f03ff, "int", 0, "uint", threadId, "ptr"))
		throw Error(A_LastError)
	if (!DllCall("GetExitCodeThread", "ptr", hThread, "uint*", &exitCode := 0))
		throw(err := A_LastError, DllCall("CloseHandle", "ptr", hThread), Error(err))
	bResult := DllCall("TerminateThread", "ptr", hThread, "uint", exitCode)
	return (DllCall("CloseHandle", "ptr", hThread), bResult)
}