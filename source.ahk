SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
global maxRecDepth = 5
global combinedArray := {}

; Build macro list from file macroList.txt
combinedArray := loadFile("macroList.txt")
MsgBox % "Found " combinedArray.Count() " hotkey(s)"





; enter main loop
Loop
{
	for hotkey, macro in combinedArray
	{
		if (GetKeyState(hotkey))
		{
			;performSequence(macro, 0)
			recDepth = 0
		}
	}
}

;Handle threaded hotkeys

hotkeyTrigger:
	hotkey = A_ThisHotkey
	macro := ObjRawGet(combinedArray, hotkey)
	performSequence(macro, 0)
return



performSequence(sequence, recDepth)
{
	global maxRecDepth, combinedArray
	send := true
	button := ""
	construct := false
	Loop, parse, sequence
	{
		if (A_LoopField == "{")								;begin constructing button name
		{
			if not (construct)
			{
				construct := true
				button := ""
			}
		}
		else if (A_LoopField == "}")							;stop constructing button name
		{
			construct := false
			if (combinedArray.HasKey(button))						;perform nested macro
			{
				if (recDepth < maxRecDepth)
				{
					recDepth += 1
					nestedSequence := ObjRawGet(combinedArray, button)
					performSequence(nestedSequence, recDepth)
				}
				button := ""
			}
			else										;send as button
			{
				Send {%button%}
				button := ""
			}
		}
		else if (construct)								;add letter to button name
		{

			if (insSpace)
			{
				button = %button% %A_LoopField%
				insSpace := false
			}
			else
			{
				button = %button%%A_LoopField%
			}

			if (A_LoopField = " ")								;prepare to insert a space before the next character
			{
				insSpace := true
			}
		}
		else										;send key
		{
			key = %A_LoopField%

			if (key = "")								;change blank keys to spaces
			{
				key = Space
			}

			Send {%key%}
			key := ""

		}

		
	}
}

loadFile(fileName)
{
	combinedArray := {}
	Loop, Read, %fileName%						;read file line by line
	{
		array := StrSplit(A_LoopReadLine, ":")			;split using : as delimiter
		combinedArray[array[1]] := array[2]			;add array element with named key
		keyName := array[1]
		Try Hotkey, %keyName%, hotkeyTrigger
		
	}
	return combinedArray
}