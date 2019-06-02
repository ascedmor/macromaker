SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
combinedArray := {}
count = 0
send := true
; Build hotkey list from file macroList.txt
Loop, Read, macroList.txt
{

	array := StrSplit(A_LoopReadLine, ":")
	combinedArray[array[1]] := array[2]
	count += 1
}
MsgBox % "Found " count " hotkey(s)"
; enter main loop
Loop
{
	for hotkey, macro in combinedArray
	{
		if (GetKeyState(hotkey))
		{
			Loop, parse, macro
			{
				key = %A_LoopField%
				if %key%
				{
					if (key == "{")
					{
						send := false
						;button = %key%
						button =
					}
					else if (key == "}")
					{
						send := true
						key = %button%
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
					SendInput {%key%}
				}
				
			}
		}
	}
}