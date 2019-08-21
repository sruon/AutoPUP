# AutoPUP
### Automates PUP maneuvers.
Automatically keeps up PUP maneuvers.

##### Commands: 
when typing commands don't use "[ ]" or "|". 

[on|off] is optional and when not provided will toggle states.

	//pup [on|off]                 -  Turn actions on/off.
	//pup actions [on|off]         -  Same as above.
	//pup active [on|off]          -  Display active settings in text box
    //pup [element] [n]            -  Set maneuvers to x[n] or off.*
	//pup save                     -  Saves settings on a per character basis.

To configure maneuvers use:
	
	"//pup [element] [n|off]" 
	e.g. //pup light 2 - sets number of light maneuvers to 2.*

To turn a maneuver off:
	
	"//pup [element] 0" or "//pup [element] off"
	e.g. //pup fire 0 - sets number of fire maneuvers to 0 - Fire Maneuver will not be used.*


## Credits
* Code largely based on [Ivaar's Singer addon](https://github.com/Ivaar/Windower-addons/tree/master/Singer)