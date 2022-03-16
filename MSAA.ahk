#DllLoad "Oleacc"

; https://docs.microsoft.com/en-us/windows/win32/api/oleacc/
class MSAA {
	static AccessibleObjectFromEvent(hwnd, objid, childid, &child) => (DllCall("Oleacc\AccessibleObjectFromEvent", "ptr", hwnd, "uint", objid, "uint", childid, "ptr*", &pacc := 0, "ptr", child := Buffer(24), "HRESULT"), child := NumGet(child, 8, "int"), IAccessible(ComObjFromPtr(pacc)))

	static AccessibleChildren(acc) {
		if !len := acc.ChildCount
			return
		DllCall("Oleacc\AccessibleChildren", "ptr", acc, "int", 0, "int", len, "ptr", children_var := Buffer(24 * len), "int*", 0, "HRESULT")
		arr := []
		loop len {
			offset := (A_Index - 1) * 24
			vt := NumGet(children_var, offset, "ushort")
			arr.Push((vt = 9) ? IAccessible(ComObjFromPtr(NumGet(children_var, offset + 8, "ptr"))) : NumGet(children_var, offset + 8, "int"))
		}
		return arr
	}

	static AccessibleObjectFromWindow(hwnd := unset, objid := 0) => (DllCall("Oleacc\AccessibleObjectFromWindow", "ptr", IsSet(hwnd) ? hwnd : WinExist("A"), "uint", objid, "ptr", CLSIDFromString("{618736E0-3C3D-11CF-810C-00AA00389B71}"), "ptr*", &pacc := 0, "HRESULT"), IAccessible(ComObjFromPtr(pacc)))

	static AccessibleObjectFromPoint(pt := unset, &childid := 0) => (DllCall("Oleacc\AccessibleObjectFromPoint", "int64", IsSet(pt) ? pt : (DllCall("GetCursorPos", "Int64*", &pt := 0), pt), "ptr*", &pacc := 0, "ptr", child_var := Buffer(24), "HRESULT"), childid := NumGet(child_var, 8, "int"), IAccessible(ComObjFromPtr(pacc)))

	static AccessibleObjectFocused() => this.AccessibleObjectFromWindow().Focus
}

class IAccessible {
	__New(co){
		if !co
			throw Error("invalid Object")
		this.Ptr := ComObjValue(this.Co := co)
	}

	Parent => IAccessible(this.Co.accParent())

	ChildCount => this.Co.accChildCount()

	Child[childid := 0] => IAccessible(this.Co.accChild(childid))

	Children => MSAA.AccessibleChildren(this)

	Name[childid := 0] => this.Co.accName(childid)

	Value[childid := 0] => this.Co.accValue(childid)

	Description[childid := 0] => this.Co.accDescription(childid)

	Role[childid := 0] => this.Co.accRole(childid)

	State[childid := 0] => this.Co.accState(childid)

	Help[childid := 0] => this.Co.accHelp(childid)

	KeyboardShortcut[childid := 0] => this.Co.accKeyboardShortcut(childid)

	Focus => IAccessible(this.Co.accFocus())

	Selection => this.Co.accSelection()

	DefaultAction[childid] => this.Co.accDefaultAction(childid)

	ParentWindow => (DllCall("Oleacc\WindowFromAccessibleObject", "ptr", this, "ptr*", &hwnd := 0, "HRESULT"), hwnd)

	Select(flag := 1, childid := 0) => this.Co.accSelect(flag, childid)

	Location(&x := 0, &y := 0, &w := 0, &h := 0, childid := 0) => this.Co.accLocation(ComValue(0x4003, ObjPtr(&x := 0) + 16), ComValue(0x4003, ObjPtr(&y := 0) + 16), ComValue(0x4003, ObjPtr(&w := 0) + 16), ComValue(0x4003, ObjPtr(&h := 0) + 16), childid)

	Navigate(dir, start := 0) => (ele := this.Co.accNavigate(dir, start), ele is ComObject ? IAccessible(ele) : "")

	HitTest(x, y) => this.Co.accHitTest(x, y)

	DoDefaultAction(childid := 0) => this.Co.accDoDefaultAction(childid)

	Find(path) {
		ele := this
		loop parse, path, "."
			try
				ele := ele.Children[A_LoopField]
			catch
				return
		return ele
	}
}

CLSIDFromString(str) => (DllCall("ole32\CLSIDFromString", "str", str, "ptr", pClsid := Buffer(16), "HRESULT"), pClsid)