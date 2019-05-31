# macromaker
Macro Maker by Braeden Wilson

This program allows the user to create an arbitrary amount of custom macros, using normal keys (a-z 0-9 etc) as well as special keys (Enter, space, Control etc).


Creating a Macro

Macros are stored in macroList.txt and are loaded into memory when the program starts, meaning the program will need to be restarted when you make changes to the file.

This is the structure of a macro:

	hotkey:macro sequence

Hotkey is the key that will trigger the macro. This can be any key on the keyboard; use https://www.autohotkey.com/docs/commands/Send.htm for a list of possible hotkeys.

Macro Sequence is the actual key sequence of the macro. This can be any number, letter, special character or special key. Special keys are the only input that requires special formatting and should be encapsulated in braces (i.e {RCtrl}).



Known issues

Due to the use of braces to encapsulate special keys, they cannot be used as part of a key sequence
