﻿SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
global maxRecDepth, listName, logFile, specOpen, specClose, waitChar, waitMul, logLevel
global combinedArray := {}
logFile = log.txt
logLevel = 0
log("----Initialising----", 0, -1)
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
		else if (A_LoopField == specClose)							;stop constructing button name
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

			if (waitTime > 0)
			{
				Sleep, waitTime
				waitTime = 0
			}
		}
		else if (construct)								;add letter to button name
		{
			
			if (A_LoopField = waitChar)
			{
				if (readWait)
				{
					readWait := false
					waitTime := wait * waitMul
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
	global maxRecDepth, listName, logFile, specOpen, specClose, waitChar, waitMul, logLevel
	OnError("logError")
	OnExit("handleExit")
	settings := loadFile("settings.txt")
	maxRecDepth := ObjRawGet(settings, "MaxRecursionDepth")
	listName := ObjRawGet(settings, "listName")
	logFile := ObjRawGet(settings, "logFile")
	specOpen := ObjRawGet(settings, "open")
	specClose := ObjRawGet(settings, "close")
	waitChar := ObjRawGet(settings, "waitChar")
	waitMul := ObjRawGet(settings, "waitMul")
	logLevel := ObjRawGet(settings, "logLevel")

	reload := ObjRawGet(settings, "reload")
	Hotkey, %reload%, reloadHotkeys

	if (specOpen = specClose)
	{
		log("Special open and special close keys cannot be identical", 1, 0)
	}
	log("Finished loading settings", 0, 3)
	
}

loadHotkeys()
{
	; Build macro list from file
	log("Loading hotkeys", 0, 3)
	combinedArray := loadFile(listName)
	registerHotkeys(combinedArray)
	count := combinedArray.Count()
	Log("Found " count " hotkeys", 0, 3)
	
}

registerHotkeys(array)
{
	For key in array
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