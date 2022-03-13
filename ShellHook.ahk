class ShellHook {
	static Message := DllCall("RegisterWindowMessage", "str", "ShellHook")

	static RefCount := 0

    __New(function) {
        !ShellHook.RefCount++ ? DllCall("RegisterShellHookWindow", "ptr", A_ScriptHwnd) : ""
        OnMessage(ShellHook.Message, this.function := function)
    }

    __Delete() {
        !--ShellHook.RefCount ? DllCall("DeregisterShellHookWindow", "ptr", A_ScriptHwnd) : ""
        OnMessage(ShellHook.Message, this.function, 0)
    }
}