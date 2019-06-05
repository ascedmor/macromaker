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
			performSequence(macro, 0)
			recDepth = 0
		}
	}
}

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
				SendInput {%button%}
				button := ""
			}
		}
		else if (construct)								;add letter to button name
		{
			button = %button%%A_LoopField%
		}
		else										;send key
		{
			key = %A_LoopField%

			if (key = "")								;change blank keys to spaces
			{
				key = Space
			}

			SendInput {%key%}
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
	}
	return combinedArray
}