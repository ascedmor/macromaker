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
	Loop, parse, sequence
	{
		if (A_LoopField == "{")
		{
			
		}
		key = %A_LoopField%
		if %key%
		{
			if (key == "{")
			{
				send := false
				;button = %key%
				button := ""
			}
			else if (key == "}")
			{
				send := true
			}
			else
			{
				if (send)
				{
					key = %key%
				}
				else
				{
					button = %button%%key%	
				}
			}
		}
		else
		{
			key = Space
		}
		if (send)
		{
			if (button = "")
			{
				SendInput {%key%}
			}
			else if (combinedArray.HasKey(button))
			{
				if (recDepth < maxRecDepth)
				{
					recDepth += 1
					MsgBox %recDepth%
					nestedSequence := ObjRawGet(combinedArray, button)
					performSequence(nestedSequence, recDepth)
				}
				button := ""
			}
			else
			{
				SendInput {%button%}
				button := ""
			}
		}
		
	}
}

loadFile(fileName)
{
	combinedArray := {}
	Loop, Read, %fileName%
	{
		array := StrSplit(A_LoopReadLine, ":")
		combinedArray[array[1]] := array[2]
	}
	return combinedArray
}