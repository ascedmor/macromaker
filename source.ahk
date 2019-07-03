SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
global maxRecDepth, listName, logFile, specOpen, specClose, waitChar, waitMul, mOpen, mClose, mSOpen, mSClose, separ, coordSeparator, logLevel
global combinedArray := {}
logFile = log.txt
logLevel = 0
log("----Initialising----", 0, -1)

OnError("logError")
OnExit("handleExit")

#MaxThreads 20
#MaxThreadsPerHotkey 5

loadSettings()
loadHotkeys()


; enter main loop
log("Entering main loop", 0, 2)
Loop
{

}

reloadHotkeys:
	loadHotkeys()
return

;Handle threaded hotkeys

hotkeyTrigger:
	log("Opening new thread for macro bound to " A_ThisHotkey, 0, 2)
	hotkey = %A_ThisHotkey%
	macro := ObjRawGet(combinedArray, hotkey)
	performSequence(macro, 0)
	log("Closing thread", 0,2)
return



performSequence(sequence, recDepth)
{
	log("Beginning sequence " sequence, 0, 4)
	global maxRecDepth, combinedArray
	send := true
	button := ""
	x := ""
	y := ""
	relX = 0
	relY = 0
	construct := false
	waitTime = 0
	Loop, parse, sequence
	{
		if (A_LoopField == specOpen)								;begin constructing button name
		{
			if not (construct)
			{
				construct := true
				button := ""
			}
		}
		else if (A_LoopField == separ)
		{
			recDepth := sendButton(button, recDepth, waitTime)
			waitTime = 0
			button := ""
			Continue
		}
		else if (A_LoopField == specClose)							;stop constructing button name
		{
			construct := false
			recDepth:= sendButton(button, recDepth, waitTime)
			waitTime = 0
		}
		else if (construct)								;add letter to button name
		{
			if (constructMouse)
			{

				if (A_LoopField = separ)
				{
					moveMouse(x,y,relX,relY)
					relX = 0
					relY = 0
					cConstruct := "x"
					x := ""
					Continue
				}
				else if (A_LoopField = mSOpen or A_LoopField = mClose)
				{
					moveMouse(x,y,relX,relY)
					constructMouse := false
				}
				if (cConstruct = "x")
				{
					if (A_LoopField = coordSeparator)
					{
						cConstruct := "y"
						y := ""
					}
					else if (A_LoopField = "+")
					{
						relX = 1
					}
					else if (A_LoopField = "-")
					{
						relX = -1
					}
					else
					{
						x = %x%%A_LoopField%
					}
				}
				else if (cConstruct = "y")
				{
					if (A_LoopField = "+")
					{
						relY = 1
					}
					else if (A_LoopField = "-")
					{
						relY = -1
					}
					else
					{
						y = %y%%A_LoopField%
					}
				}
			}
			if (A_LoopField = waitChar)
			{
				if (readWait)
				{
					readWait := false
					waitTime := wait * waitMul
					sendButton(button, recDepth, waitTime)
					waitTime = 0
					button := "" 
					Continue 
				}
				else
				{
					readWait := true
					wait := ""
				}		
			}
			else if (readWait)
			{
				wait = %wait%%A_LoopField%
			}
			else if (A_LoopField = mOpen or A_LoopField = mSClose)
			{
				constructMouse := true
				cConstruct := "x"
				relX := false
				relY := false
			}
			else
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
moveMouse(x,y,relX,relY)
{
	MouseGetPos, posX, posY
	if not (relX = 0)
	{
		x := x * relX
		x := x + posX
	}
	if not (relY = 0)
	{
		y := y * relY
		y := y + posY

	}
	MouseMove, x, y
}
sendButton(button, recDepth, waitTime)
{
	global combinedArray, maxRecDepth
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
	if (waitTime > 0)
	{
		Sleep, waitTime
		waitTime = 0
	}
	return recDepth, waitTime
}
loadFile(fileName)
{
	log("Loading from file " fileName, 0, 3)
	combinedArray := {}
	Loop, Read, %fileName%						;read file line by line
	{
		firstChar := ""
		StringLeft, firstChar, A_LoopReadLine, 1
		if not (firstChar = ";")
		{		
			array := StrSplit(A_LoopReadLine, ":")			;split using : as delimiter
			combinedArray[array[1]] := array[2]			;add array element with named key
			keyName := array[1]
		}
		
	}
	return combinedArray
}

loadSettings()
{
	log("Loading settings", 0, 3)
	global maxRecDepth, listName, logFile, specOpen, specClose, waitChar, waitMul, mOpen, mClose, mSOpen, mSClose, separ, coordSeparator, logLevel
	characterList := ""
	defList := {}
	defList["waitChar"] := "Wait"
	defList["specOpen"] := "SpecialOpen"
	defList["specClose"] := "SpecialClose"
	defList["mOpen"] := "MouseOpen"
	defList["mClose"] := "MouseClose"
	defList["mSOpen"] := "MouseSpecialOpen"
	defList["mSClose"] := "MouseSpecialClose"
	defList["separ"] := "Separator"
	defList["coordSeparator"] := "CoordinateSeparator"
	for variable, name in defList
	{
		IniRead, value, settings.ini, CharacterDefinitions, %name%
		%variable% := value
		if value in %characterList%
		{
			log("Identical syntax value detected: " name, 1, 0)
		}
		else
		{	
			characterList = %value%,%characterList%
		}
	}
	IniRead, maxRecDepth, settings.ini, Settings, MaxRecursionDepth
	IniRead, listName, settings.ini, Settings, ListName
	IniRead, waitMul, settings.ini, Settings, WaitMultiplier
	IniRead, reload, settings.ini, Settings, ReloadHotkey

	IniRead, logFile, settings.ini, Logging, LogFile
	IniRead, logLevel, settings.ini, Logging, Verbosity

	if not (reload)
	{
		reload := ">^>+r"
	}
	Hotkey, %reload%, reloadHotkeys

	log("Finished loading settings", 0, 3)
	
}
loadValue(file,section,name)
{
	IniRead, value, file, section, name
	return value
		
}
loadHotkeys()
{
	;Build macro list from file
	log("Loading hotkeys", 0, 3)
	combinedArray := loadFile(listName)
	For key in combinedArray
	{
		registerHotkey(key)
	}
	count := combinedArray.Count()
	Log("Found " count " hotkeys", 0, 3)
	
}

registerHotkey(key)
{
	try 
	{ 
		Hotkey, %key%, hotkeyTrigger
	} 
	catch e 
	{ 
		logError(e) 
	}

}

log(message, critical, level)
{
	global logLevel
	FormatTime, time, A_Now, d/M HH:mm:ss
	if (level <= logLevel)
	{
		FileAppend, %time% - %message%`n, %logFile%
	}
	if (critical = 1)
	{
		MsgBox % "Critical error, check log for details"
		Exit
	}
}

logError(exception)
{
	log(exception.Message, 0, 1)
	return false
}

handleExit()
{
	log("  ----Exiting----", 0, -1)
}