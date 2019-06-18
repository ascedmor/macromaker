SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
global maxRecDepth, listName, logFile, specOpen, specClose, waitChar, waitMul
logFile = log.txt
log("----Initialising----",0)
#MaxThreads 20
#MaxThreadsPerHotkey 5
loadSettings()
global combinedArray := {}
; Build macro list from file
log("Loading hotkeys from " listName, 0)
combinedArray := loadFile(listName)
registerHotkeys(combinedArray)
count := combinedArray.Count()
Log("Found " count " hotkeys", 0)



; enter main loop
log("Entering main loop", 0)
Loop
{

}

;Handle threaded hotkeys

hotkeyTrigger:
	log("Opening new thread for macro bound to " A_ThisHotkey, 0)
	hotkey = %A_ThisHotkey%
	macro := ObjRawGet(combinedArray, hotkey)
	performSequence(macro, 0)
	log("Closing thread", 0)
return



performSequence(sequence, recDepth)
{
	log("Beginning sequence " sequence, 0)
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

loadSettings()
{
	log("Loading settings", 0)
	global maxRecDepth, listName, logFile, specOpen, specClose, waitChar, waitMul
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

	if (specOpen = specClose)
	{
		log("Special open and special close keys cannot be identical", 1)
	}
	log("Finished loading settings", 0)
	
}

log(message, critical)
{
	FormatTime, time, A_Now, d/M HH:mm:ss
	FileAppend, %time% - %message%`n, %logFile%
	if (critical = 1)
	{
		MsgBox % "Critical error, check log for details"
		Exit
	}
}

logError(exception)
{
	log(exception.Message, 0)
	return false
}

handleExit()
{
	log("----Exiting----",0)
}