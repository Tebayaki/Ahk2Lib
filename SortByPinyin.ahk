MsgBox SortByPinyin("滴答`n必须`na`n耳机`nb`nc`n感觉`nd`ne`n才能`nf`ng`n非常`n啊不", "`n", "`n", 1)

SortByPinyin(str, deliIn := "`n", deliOut := "`n", reverse := 0) {
	words := StrSplit(str, deliIn)
	if (reverse) {
		loop words.length - 1
			loop words.length - A_Index
				if (PinyinCompare(words[A_Index], words[A_Index + 1]) < 0) {
					buf := words[A_Index]
					words[A_Index] := words[A_Index + 1]
					words[A_Index + 1] := buf
				}
	}
	else {
		loop words.length - 1
			loop words.length - A_Index
				if (PinyinCompare(words[A_Index], words[A_Index + 1]) > 0) {
					buf := words[A_Index]
					words[A_Index] := words[A_Index + 1]
					words[A_Index + 1] := buf
				}
	}
	sorted := ""
	for , word in words
		sorted .= deliOut word
	return StrReplace(sorted, deliOut, , , , 1)
}

PinyinCompare(str1, str2) {
	static alphabet := Map(
		"a", 45216.1, "A", 45216.2, "b", 45252.1, "B", 45252.2,
		"c", 45760.1, "C", 45761.2, "d", 46317.1, "D", 46317.2,
		"e", 46825.1, "E", 46825.2, "f", 47009.1, "F", 47009.2,
		"g", 47296.1, "G", 47296.2, "h", 47613.1, "H", 47613.2,
		"i", 48118.1, "I", 48118.2, "j", 48118.3, "J", 48118.4,
		"k", 49061.1, "K", 49061.2, "l", 49323.1, "L", 49323.2,
		"m", 49895.1, "M", 49895.2, "n", 50370.1, "N", 50370.2,
		"o", 50613.1, "O", 50613.2, "p", 50621.1, "P", 50621.2,
		"q", 50905.1, "Q", 50905.2, "r", 51386.1, "R", 51386.2,
		"s", 51445.1, "S", 51445.2, "t", 52217.1, "T", 52217.2,
		"u", 52697.1, "U", 52697.2, "v", 52697.3, "V", 52697.4,
		"w", 52697.5, "W", 52697.6, "x", 52979.1, "X", 52979.2,
		"y", 53688.1, "Y", 53688.2, "z", 54480.1, "Z", 54480.2)
	static buf := Buffer(2)
	chars1 := StrSplit(Trim(str1, " `t`n")), chars2 := StrSplit(Trim(str2, " `t`n"))
	loop (chars1.length < chars2.length) ? chars1.length : chars2.length {
		if (IsAlpha(chars1[A_Index]))
			code1 := alphabet[chars1[A_Index]]
		else {
			StrPut(chars1[A_Index], buf.Ptr, 2, "cp936")
			code1 := (NumGet(buf.Ptr, 0, "UChar") << 8) + NumGet(buf.Ptr, 1, "UChar")
		}
		if (IsAlpha(chars2[A_Index]))
			code2 := alphabet[chars2[A_Index]]
		else {
			StrPut(chars2[A_Index], buf.Ptr, 2, "cp936")
			code2 := (NumGet(buf.Ptr, 0, "UChar") << 8) + NumGet(buf.Ptr, 1, "UChar")
		}
		if (code1 != code2)
			return code1 - code2
	}
	return chars1.Length - chars2.length
}