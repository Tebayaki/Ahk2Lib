#Include <COM>
; Remove some functions that rarely used.
; IDs: https://docs.microsoft.com/en-us/windows/win32/winauto/uiauto-entry-propids
class UIA {
	static PropertyVarTypeMap := [0x2003, 0x2005, 0x3, 0x3, 0x8, 0x8, 0x8, 0x8, 0xB, 0xB, 0xB, 0x8, 0x8, 0x8, 0x2005, 0x3, 0xB, 0xB, 0xD, 0xB, 0x3, 0x8, 0xB, 0x3, 0x8, 0xB, 0x8, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0x8, 0xB, 0x5, 0xB, 0x5, 0x5, 0x5, 0x5, 0x5, 0x5, 0x5, 0x5, 0xB, 0xB, 0x200D, 0xB, 0xB, 0x3, 0x3, 0x3, 0x3, 0x3, 0x3, 0xD, 0x3, 0x3, 0x3, 0x2003, 0xB, 0xB, 0x3, 0x3, 0xB, 0xB, 0xB, 0xD, 0x200D, 0x200D, 0x3, 0x200D, 0x200D, 0x3, 0xB, 0xB, 0xB, 0xB, 0x3, 0x8, 0x8, 0x8, 0x3, 0x3, 0x8, 0x8, 0x200D, 0x8, 0x8, 0x8, 0xB, 0x200D, 0x200D, 0x200D, 0x8, 0xB, 0xB, 0xB, 0xB, 0xB, 0x3, 0x8, 0x8, 0x8, 0xD, 0xB, 0xB, 0x3, 0x8, 0x3, 0x8, 0x8, 0x3, 0x8, 0xB, 0xB, 0x8, 0x200D, 0x2003, 0xB, 0xB, 0xB, 0x3, 0xB, 0xB, 0xB, 0x8, 0x2008, 0xB, 0x8, 0x2008, 0x200D, 0x5, 0x5, 0x5, 0x200D, 0xB, 0xB, 0xB, 0x3, 0x3, 0x3, 0x2003, 0x2003, 0x3, 0x8, 0x8, 0x3, 0x2003, 0x3, 0x3, 0x2005, 0x2005, 0x5, 0x2005, 0x3, 0xB]

	static ControlPatternMap := [IUIAutomationInvokePattern, IUIAutomationSelectionPattern, IUIAutomationValuePattern, IUIAutomationRangeValuePattern, IUIAutomationScrollPattern, IUIAutomationExpandCollapsePattern, IUIAutomationGridPattern, IUIAutomationGridItemPattern,,, IUIAutomationSelectionItemPattern,,,, IUIAutomationTextPattern,,, IUIAutomationScrollItemPattern, IUIAutomationLegacyIAccessiblePattern,,,,,, IUIAutomationTextPattern,,,,, IUIAutomationTextChildPattern,,, IUIAutomationTextEditPattern,]

	static Ptr := ComObjValue(this.Co := ComObject("{e22ad333-b25f-460c-83d0-0581107395c9}", "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}"))

	static EnumDescendants(parent, callback) {
		try {
			walker := this.ControlViewWalker
			node := walker.GetFirstChildElement(parent)
		} catch {
			return
		}
		loop {
			callback(node)
			this.EnumDescendants(node, callback)
			try
				node := walker.GetNextSiblingElement(node)
			catch
				break
		}
	}

	static CompareElements(ele1, ele2) => (ComCall(3, this, "ptr", ele1, "ptr", ele2, "int*", &same := 0), same)

	static CompareRuntimeIds(id1, id2) => (ComCall(4, this, "ptr", id1, "ptr", id2, "int*", &same := 0), same)

	static GetRootElement() => (ComCall(5, this, "ptr*", &ele := 0), IUIAutomationElement(ele))

	static ElementFromHandle(hwnd := unset) => (ComCall(6, this, "ptr", IsSet(hwnd) ? hwnd : WinExist("A"), "ptr*", &ele := 0), IUIAutomationElement(ele))

	static ElementFromPoint(pt := unset) => (ComCall(7, this, "int64", IsSet(pt) ? pt : (DllCall("GetCursorPos", "Int64*", &pt := 0), pt), "ptr*", &ele := 0), IUIAutomationElement(ele))

	static GetFocusedElement() => ComCall(8, this, "ptr*", &ele := 0) ? "" : IUIAutomationElement(ele)

	static CreateTreeWalker(condition) => (ComCall(13, this, "ptr", condition, "ptr*", &walker := 0), IUIAutomationTreeWalker(walker))

	static ControlViewWalker => (ComCall(14, this, "ptr*", &walker := 0), IUIAutomationTreeWalker(walker))

	static ContentViewWalker => (ComCall(15, this, "ptr*", &walker := 0), IUIAutomationTreeWalker(walker))

	static RawViewWalker => (ComCall(16, this, "ptr*", &walker := 0), IUIAutomationTreeWalker(walker))

	static RawViewCondition => (ComCall(17, this, "ptr*", &condition := 0), IUIAutomationCondition(condition))

	static ControlViewCondition => (ComCall(18, this, "ptr*", &condition := 0), IUIAutomationCondition(condition))

	static ContentViewCondition => (ComCall(19, this, "ptr*", &condition := 0), IUIAutomationCondition(condition))

	static CreateTrueCondition() => (ComCall(21, this, "ptr*", &condition := 0), IUIAutomationBoolCondition(condition))

	static CreateFalseCondition() => (ComCall(22, this, "ptr*", &condition := 0), IUIAutomationBoolCondition(condition))

	static CreatePropertyCondition(property_id, val) => (ComCall(23, this, "int", property_id, "ptr", Variant(UIA.PropertyVarTypeMap[property_id - 29999], val), "ptr*", &condition := 0), IUIAutomationPropertyCondition(condition))

	static CreatePropertyConditionEx(property_id, val, flags) => (ComCall(24, this, "int", property_id, "ptr", Variant(UIA.PropertyVarTypeMap[property_id - 29999], val), "uint", flags, "ptr*", &condition := 0), IUIAutomationPropertyCondition(condition))

	static CreateAndCondition(condition1, condition2) => (ComCall(25, this, "ptr", condition1, "ptr", condition2, "ptr*", &condition := 0), IUIAutomationAndCondition(condition))

	static CreateAndConditionFromNativeArray(conditions) => (ComCall(27, this, "ptr", NativeArray("ptr", conditions), "int", conditions.Length, "ptr*", &conditon := 0), IUIAutomationAndCondition(conditon))

	static CreateOrCondition(condition1, condition2) => (ComCall(28, this, "ptr", condition1, "ptr", condition2, "ptr*", &condition := 0), IUIAutomationOrCondition(condition))

	static CreateOrConditionFromNativeArray(conditions) => (ComCall(30, this, "ptr", NativeArray("ptr", conditions), "ptr", conditions.Length, "ptr*", &condition := 0), IUIAutomationOrCondition(condition))

	static CreateNotCondition(condition) => (ComCall(31, this, "ptr", condition, "ptr*", &new_condition := 0), IUIAutomationNotCondition(new_condition))

	static AddAutomationEventHandler(event_id, element, callback, scope := 5) => (ComCall(32, this, "int", event_id, "ptr", element, "int", scope, "ptr", 0, "ptr", handler := EventHandler(callback, "{146C3C17-F12E-4E22-8C27-F894B9B79C69}")), handler)

	static RemoveAutomationEventHandler(event_id, element, handler) => ComCall(33, this, "int", event_id, "ptr", element, "ptr", handler)

	static AddPropertyChangedEventHandlerNativeArray(element, callback, property_array, scope := 5) => (ComCall(34, this, "ptr", element, "int", scope, "ptr", 0, "ptr", handler := EventHandler(callback, "{40CD37D4-C756-4B0C-8C6F-BDDFEEB13B50}"), "ptr", NativeArray("int", property_array), "int", property_array.Length), handler)

	static RemovePropertyChangedEventHandler(element, handler) => ComCall(36, this, "ptr", element, "ptr", handler)

	static AddStructureChangedEventHandler(element, callback, scope := 5) => (ComCall(37, this, "ptr", element, "int", scope, "ptr", 0, "ptr", handler := EventHandler(callback, "{E81D1B4E-11C5-42F8-9754-E7036C79F054}")), handler)

	static RemoveStructureChangedEventHandler(element, handler) => ComCall(38, this, "ptr", element, "ptr", handler)

	static AddFocusChangedEventHandler(callback) => (ComCall(39, this, "ptr", 0, "ptr", handler := EventHandler(callback, "{C270F6B5-5C69-4290-9745-7A7F97169468}")), handler)

	static RemoveFocusChangedEventHandler(handler) => ComCall(40, this, "ptr", handler)

	static RemoveAllEventHandlers() => ComCall(41, this)
}

class IUIAutomationElement extends Interface {
	SetFocus() => ComCall(3, this)

	GetRuntimeId() => (ComCall(4, this, "ptr*", &id := 0), ComValue(0x2003, id))

	FindFirst(condition, scope := 4) => (ComCall(5, this, "uint", scope, "ptr", condition, "ptr*", &ele := 0), IUIAutomationElement(ele))

	FindAll(condition, scope := 4) => (ComCall(6, this, "uint", scope, "ptr", condition, "ptr*", &eles := 0), IUIAutomationElementArray(eles))

	GetCurrentPropertyValue(property_id) => (ComCall(10, this, "int", property_id, "ptr", val := Variant()), val[])

	GetCurrentPropertyValueEx(property_id, ignore_default_value) => (ComCall(11, this, "int", property_id, "int", ignore_default_value, "ptr", val := Variant()), val[])

	GetCurrentPattern(pattern_id) => (ComCall(16, this, "int", pattern_id, "ptr*", &patternObject := 0), UIA.ControlPatternMap[pattern_id - 9999](patternObject))

	CurrentProcessId => (ComCall(20, this, "int*", &ret_val := 0), ret_val)

	CurrentControlType => (ComCall(21, this, "int*", &ret_val := 0), ret_val)

	CurrentLocalizedControlType => (ComCall(22, this, "ptr*", &ret_val := 0), BSTR2STR(ret_val))

	CurrentName => (ComCall(23, this, "ptr*", &ret_val := 0), BSTR2STR(ret_val))

	CurrentAcceleratorKey => (ComCall(24, this, "ptr*", &ret_val := 0), BSTR2STR(ret_val))

	CurrentAccessKey => (ComCall(25, this, "ptr*", &ret_val := 0), BSTR2STR(ret_val))

	CurrentHasKeyboardFocus => (ComCall(26, this, "int*", &ret_val := 0), ret_val)

	CurrentIsKeyboardFocusable => (ComCall(27, this, "int*", &ret_val := 0), ret_val)

	CurrentIsEnabled => (ComCall(28, this, "int*", &ret_val := 0), ret_val)

	CurrentAutomationId => (ComCall(29, this, "ptr*", &ret_val := 0), BSTR2STR(ret_val))

	CurrentClassName => (ComCall(30, this, "ptr*", &ret_val := 0), BSTR2STR(ret_val))

	CurrentHelpText => (ComCall(31, this, "ptr*", &ret_val := 0), BSTR2STR(ret_val))

	CurrentCulture => (ComCall(32, this, "int*", &ret_val := 0), ret_val)

	CurrentIsControlElement => (ComCall(33, this, "int*", &ret_val := 0), ret_val)

	CurrentIsContentElement => (ComCall(34, this, "int*", &ret_val := 0), ret_val)

	CurrentIsPassword => (ComCall(35, this, "int*", &ret_val := 0), ret_val)

	CurrentNativeWindowHandle => (ComCall(36, this, "ptr*", &ret_val := 0), ret_val)

	CurrentIsOffscreen => (ComCall(38, this, "int*", &ret_val := 0), ret_val)

	CurrentBoundingRectangle => (ComCall(43, this, "ptr", ret_val := Buffer(16)), { Left: NumGet(ret_val, "int"), Top: NumGet(ret_val, 4, "int"), Right: NumGet(ret_val, 8, "int"), Bottom: NumGet(ret_val, 12, "int") })

	CurrentProviderDescription => (ComCall(51, this, "ptr*", &ret_val := 0), BSTR2STR(ret_val))

	GetClickablePoint(&clickable) => (ComCall(84, this, "int64*", &clickable := 0, "int*", &got_clickable := 0), got_clickable)

	FindFirstWithOptions(condition, traversal_options, root := 0, scope := 4) => (ComCall(110, this, "int", scope, "ptr", condition, "int", traversal_options, "ptr", root, "ptr*", &found := 0), IUIAutomationElement(found))

	FindAllWithOptions(condition, traversal_options, root := 0, scope := 4) => (ComCall(111, this, "int", scope, "ptr", condition, "int", traversal_options, "ptr", root, "ptr*", &found := 0), IUIAutomationElementArray(found))
}

class IUIAutomationElementArray extends Interface {
	Length => (ComCall(3, this, "int*", &len := 1), len)

	GetElement(index) => (ComCall(4, this, "int", index, "ptr*", &ele := 0), IUIAutomationElement(ele))
}

class IUIAutomationTreeWalker extends Interface {
	; Parent 0x10000 FirstChild 0x20000 LastChild 0x30000 NextSibling 0x40000 PreviousSibling 0x50000
	Navigate(ele, way) {
		static action := [this.GetParentElement, this.GetFirstChildElement, this.GetLastChildElement, this.GetNextSiblingElement, this.GetPreviousSiblingElement]
		for , v in way {
			loop v & 0x0000ffff
				ele := action[(v >> 16)](this, ele)
		}
		return ele
	}

	GetWayFromContainerWindow(ele, &container := 0) {
		desktop := UIA.GetRootElement()
		if UIA.CompareElements(desktop, ele)
			throw Error("The element is a root element or container window.")
		way := [0x20000]
		loop {
			parent := this.GetParentElement(ele)
			if UIA.CompareElements(desktop, parent) {
				container := ele
				return way[way.Length] = 0x20000 ? (way.Pop(), way) : way
			}
			idx := 0
			child := this.GetFirstChildElement(parent)
			while !UIA.CompareElements(ele, child)
				child := this.GetNextSiblingElement(child), idx++
			if idx
				way.InsertAt(1, 0x20001, 0x40000 | idx)
			else
				way[1]++
			ele := parent
		}
	}

	GetParentElement(ele) => (ComCall(3, this, "ptr", ele, "ptr*", &parent := 0), IUIAutomationElement(parent))

	GetFirstChildElement(ele) => (ComCall(4, this, "ptr", ele, "ptr*", &first := 0), IUIAutomationElement(first))

	GetLastChildElement(ele) => (ComCall(5, this, "ptr", ele, "ptr*", &last := 0), IUIAutomationElement(last))

	GetNextSiblingElement(ele) => (ComCall(6, this, "ptr", ele, "ptr*", &next := 0), IUIAutomationElement(next))

	GetPreviousSiblingElement(ele) => (ComCall(7, this, "ptr", ele, "ptr*", &previous := 0), IUIAutomationElement(previous))
}

class IUIAutomationInvokePattern extends Interface {
	Invoke() => ComCall(3, this)
}

class IUIAutomationSelectionPattern extends Interface {
	GetCurrentSelection() => (ComCall(3, this, "ptr*", &ret_val := 0), IUIAutomationElementArray(ret_val))

	CurrentCanSelectMultiple => (ComCall(4, this, "int*", &ret_val := 0), ret_val)

	CurrentIsSelectionRequired => (ComCall(5, this, "int*", &ret_val := 0), ret_val)
}

class IUIAutomationRangeValuePattern extends Interface {
	SetValue(val) => ComCall(3, this, "double", val)

	CurrentValue => (ComCall(4, this, "double*", &ret_val := 0), ret_val)

	CurrentIsReadOnly => (ComCall(5, this, "int*", &ret_val := 0), ret_val)

	CurrentMaximum => (ComCall(6, this, "double*", &ret_val := 0), ret_val)

	CurrentMinimum => (ComCall(7, this, "double*", &ret_val := 0), ret_val)

	CurrentLargeChange => (ComCall(8, this, "double*", &ret_val := 0), ret_val)

	CurrentSmallChange => (ComCall(9, this, "double*", &ret_val := 0), ret_val)
}

class IUIAutomationScrollPattern extends Interface {
	Scroll(horizontal_amount, vertical_amount) => ComCall(3, this, "int", horizontal_amount, "int", vertical_amount)

	SetScrollPercent(horizontal_percent, vertical_percent) => ComCall(4, this, "double", horizontal_percent, "double", vertical_percent)

	CurrentHorizontalScrollPercent => (ComCall(5, this, "double*", &ret_val := 0), ret_val)

	CurrentVerticalScrollPercent => (ComCall(6, this, "double*", &ret_val := 0), ret_val)

	CurrentHorizontalViewSize => (ComCall(7, this, "double*", &ret_val := 0), ret_val)

	CurrentVerticalViewSize => (ComCall(8, this, "double*", &ret_val := 0), ret_val)

	CurrentHorizontallyScrollable => (ComCall(9, this, "int*", &ret_val := 0), ret_val)

	CurrentVerticallyScrollable => (ComCall(10, this, "int*", &ret_val := 0), ret_val)
}

class IUIAutomationScrollItemPattern extends Interface {
	ScrollIntoView() => ComCall(3, this)
}

class IUIAutomationValuePattern extends Interface {
	SetValue(val) => ComCall(3, this, "wstr", val)

	CurrentValue => (ComCall(4, this, "ptr*", &ret_val := 0), BSTR2STR(ret_val))

	CurrentIsReadOnly => (ComCall(5, this, "int*", &ret_val := 0), ret_val)
}

class IUIAutomationGridPattern extends Interface {
	GetItem(row, column) => (ComCall(3, this, "int", row, "int", column, "ptr*", &element := 0), IUIAutomationGridItemPattern(element))

	CurrentRowCount => (ComCall(4, this, "int*", &ret_val := 0), ret_val)

	CurrentColumnCount => (ComCall(5, this, "int*", &ret_val := 0), ret_val)
}

class IUIAutomationGridItemPattern extends Interface {
	CurrentContainingGrid => (ComCall(3, this, "ptr*", &ret_val := 0), IUIAutomationElement(ret_val))

	CurrentRow => (ComCall(4, this, "int*", &ret_val := 0), ret_val)

	CurrentColumn => (ComCall(5, this, "int*", &ret_val := 0), ret_val)

	CurrentRowSpan => (ComCall(6, this, "int*", &ret_val := 0), ret_val)

	CurrentColumnSpan => (ComCall(7, this, "int*", &ret_val := 0), ret_val)
}

class IUIAutomationTextChildPattern extends Interface {
	TextContainer => (ComCall(3, this, "ptr*", &container := 0), IUIAutomationElement(container))

	TextRange => (ComCall(4, this, "ptr*", &range := 0), IUIAutomationTextRange(range))
}

class IUIAutomationTextPattern extends Interface {
	RangeFromPoint(pt) => (ComCall(3, this, "int64", pt, "ptr*", &range := 0), IUIAutomationTextRange(range))

	RangeFromChild(child) => (ComCall(4, this, "ptr", child, "ptr*", &range := 0), IUIAutomationTextRange(range))

	GetSelection() => (ComCall(5, this, "ptr*", &ranges := 0), IUIAutomationTextRangeArray(ranges))

	GetVisibleRanges() => (ComCall(6, this, "ptr*", &ranges := 0), IUIAutomationTextRangeArray(ranges))

	DocumentRange => (ComCall(7, this, "ptr*", &range := 0), IUIAutomationTextRange(range))

	SupportedTextSelection => (ComCall(8, this, "int*", &supported_text_selection := 0), supported_text_selection)

	RangeFromAnnotation(annotation) => (ComCall(9, this, "ptr" annotation, "ptr*", &range := 0), IUIAutomationTextRange(range))

	GetCaretRange() => (ComCall(10, this, "int*", &is_active := 0, "ptr*", &range := 0), IUIAutomationTextRange(range))
}

class IUIAutomationTextRangeArray extends Interface {
	Length => (ComCall(3, this, "int*", &length := 0), length)

	GetElement(index) => (ComCall(4, this, "int", index, "ptr*", &element := 0), IUIAutomationTextRange(element))
}

class IUIAutomationLegacyIAccessiblePattern extends Interface {
	Select(flags_select) => ComCall(3, this, "int", flags_select)

	DoDefaultAction() => ComCall(4, this)

	SetValue(value) => ComCall(5, this, "wstr", value)

	CurrentChildId => (ComCall(6, this, "int*", &ret_val := 0), ret_val)

	CurrentName => (ComCall(7, this, "ptr*", &name := 0), BSTR2STR(name))

	CurrentValue => (ComCall(8, this, "ptr*", &value := 0), BSTR2STR(value))

	CurrentDescription => (ComCall(9, this, "ptr*", &description := 0), BSTR2STR(description))

	CurrentRole => (ComCall(10, this, "uint*", &role := 0), role)

	CurrentState => (ComCall(11, this, "uint*", &state := 0), state)

	CurrentHelp => (ComCall(12, this, "ptr*", &help := 0), BSTR2STR(help))

	CurrentKeyboardShortcut => (ComCall(13, this, "ptr*", &keyboard_shortcut := 0), BSTR2STR(keyboard_shortcut))

	GetCurrentSelection() => (ComCall(14, this, "ptr*", &selected_children := 0), IUIAutomationElementArray(selected_children))

	CurrentDefaultAction => (ComCall(15, this, "ptr*", &default_action := 0), BSTR2STR(default_action))

	GetIAccessible() => (ComCall(26, this, "ptr*", &accessible := 0), ComValue(0xd, accessible))
}

class IUIAutomationTextRange extends Interface {
	CompareEndpoints(src_end_point, range, target_end_point) => (ComCall(5, this, "int", src_end_point, "ptr", range, "int", target_end_point, "int*", &comp_value := 0), comp_value)

	GetAttributeValue(attr) => (ComCall(9, this, "int", attr, "ptr", val := Variant()), val[])

	GetText(max_length := -1) => (ComCall(12, this, "int", max_length, "ptr*", &text := 0), BSTR2STR(text))

	GetBoundingRectangles(){
		ComCall(10, this, "ptr*", &bounding_rects := 0)
		rect := ComValue(0x2005, bounding_rects)
		if rect.MaxIndex(1) < 3
			throw Error("Unsupported property")
		return {Left: rect[0], Top: rect[1], Right: rect[2], Bottom: rect[3]}
	}

	Select() => ComCall(16, this)
}

class IUIAutomationExpandCollapsePattern extends Interface {
	Expand() => ComCall(3, this)

	Collapse() => ComCall(4, this)

	CurrentExpandCollapseState => (ComCall(5, this, "int*", &ret_val := 0), ret_val)
}

class IUIAutomationSelectionItemPattern extends Interface {
	Select() => ComCall(3, this)

	AddToSelection() => ComCall(4, this)

	RemoveFromSelection() => ComCall(5, this)

	CurrentIsSelected => (ComCall(6, this, "int*", &ret_val := 0), ret_val)

	CurrentSelectionContainer => (ComCall(7, this, "ptr*", &ret_val := 0), IUIAutomationElement(ret_val))
}

class IUIAutomationTextEditPattern extends Interface {
	GetActiveComposition() => (ComCall(3, this, "ptr*", &range := 0), IUIAutomationTextRange(range))

	GetConversionTarget() => (ComCall(4, this, "ptr*", &range := 0), IUIAutomationTextRange(range))
}

class IUIAutomationPropertyCondition extends Interface {
}

class IUIAutomationCondition extends Interface {
}

class IUIAutomationBoolCondition extends IUIAutomationCondition {
}

class IUIAutomationAndCondition extends IUIAutomationCondition {
}

class IUIAutomationOrCondition extends IUIAutomationCondition {
}

class IUIAutomationNotCondition extends IUIAutomationCondition {
}

class NativeArray {
	__New(type, arr) {
		static bytes_map := Map("char", 1, "uchar", 1, "short", 2, "ushort", 2, "int", 4, "uint", 4, "ptr", 8, "uptr", 8, "int64", 8, "uint64", 8, "folat", 4, "double", 8)
		this.Length := arr.Length
		this.BaseType := type
		this.BaseSize := bytes_map[type]
		this.Buffer := Buffer(this.BaseSize * this.Length)
		this.Ptr := this.Buffer.Ptr
		this.Size := this.Buffer.Size
		if arr[1] is Object {
			for v in arr
				NumPut("ptr", v.Ptr, this.Buffer, (A_Index - 1) * 8)
		} else {
			for v in arr
				NumPut(type, v, this.Buffer, (A_Index - 1) * this.BaseSize)
		}
	}
	__Item[index] => NumGet(this, index * this.BaseSize, this.BaseType)
	__Enum(*) => (&item) => (A_Index <= this.Length ? (item := this[A_Index - 1], true) : false)
}

/*
 * HandleAutomationEvent(this, sender, event_id)
 * HandleFocusChangedEvent(this, sender)
 * HandlePropertyChangedEvent(this, sender, property_id, new_value)
 * HandleStructureChangedEvent(this, sender, change_type, runtime_id)
 */
class EventHandler {
	__New(fn, iid) {
		this.Callback := CallbackCreate(fn, "F")
		this.QueryInterfaceCallBack := CallbackCreate(this.__QueryInterface.Bind(, , , iid), "F", 3)
		this.AddReleaseCallBack := CallbackCreate(this.__AddRelease, "F")
		this.Interface := Buffer(40), this.Ptr := this.Interface.Ptr
		NumPut("ptr", this.Interface.Ptr + 8, "ptr", this.QueryInterfaceCallBack, "ptr", this.AddReleaseCallBack, "ptr", this.AddReleaseCallBack, "ptr", this.Callback, this.Interface)
	}
	__Delete() => this.HasOwnProp("Callback") ? (CallbackFree(this.Callback), CallbackFree(this.QueryInterfaceCallBack), CallbackFree(this.AddReleaseCallBack)) : ""
	__QueryInterface(riid, object, iid) {
		static IID_IUnknown := "{00000000-0000-0000-C000-000000000046}"
		iid_str := StringFromCLSID(riid)
		if iid_str = iid || iid_str = IID_IUnknown {
			return (NumPut("ptr", this, object), 0)
		} else {
			return 0x80004002
		}
	}
	__AddRelease() {
	}
}