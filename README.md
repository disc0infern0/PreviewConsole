PreviewConsole
==============

Overlays a resizeable console of log messages over the Code preview screen  

**N.B. After import, no code will be added to production release builds except for one line definitions of global functions log, and Log,  which, in production code, will both default to no action, and an EmptyView() respectively. After debugging, code containing log messages may thus be safely left in place**

Usage
=====
```swift
import PreviewConsole 
```
Then, in your preview section, enclose the Preview body with ```console{ }```
e.g. ;-

    struct ContentView_Previews: PreviewProvider {    
        static var previews: some View {  
            console {
              ContentView()  
            }
        }  
    }

that's it! A draggable console will now appear in your previews. (and only in your previews )

Code Logging
------------
To log a message to the console, in imperative code you can continue to use `print()` (as normal?), or use   `log( _:,_: )`   
***Important:*** Using `print()` will continue to produce output in production code, whereas any messages sent to `log()` will be silenced.

The first parameter is any expression,  usually a String. Interpolation is supported.  
The second paramter can be omitted, and is used to indicates a log type.  
Valid values are `.info`, `.debug`, `.trace` . If not supplied, .debug is defaulted.

e.g.

    func complexCalc() -> Int {
        log("About to calculate a tricky number...")
        return 7*6
        log("this line should never be executed \(7*6)", .info )
    }

Different colors will be displayed to the log based on the messageType. 

View Logging
------------
In view / declarative code, you can use the alternate form, 

    Log(_:,_:) 
which takes the same parameters as above, the second parameter if not supplied will default to `.debug`
An EmptyView() is returned.

e.g.

    struct DeepThought: View {
        var body: some View {
            VStack{ 
                Log(" showing tricky view")
                Text("Tricky calculation")
            }   
        }
    }


Using the console
=================
Drag the bar up from the bottom of the screen to see logged messages.  
Click the indicator on the console bar header to open/close. (The last open position is remembered)  
Swipe left on a log message to see the time it was logged.

Installation
============
Swift Package Manager
---------------------
Add package from Xcode directly from git.  https://github.com/disc0infern0/PreviewConsole

Cocoapods/Carthage etc
----------------------
Unforunately I have zero knowledge of these package managers, so you are on your own with these, but since the package is made entirely from two swift files, I'm sure you'll be fine.


<br>  
<br>  
<br>  

To-Do / Backlog  / Unnecessary gilding of the lily?
===================================================
If there is interest, and sufficient motivation, I may implement none, one, or more of the following:-

- *Settings*  - To change colors, fonts, and maybe alter various control parameters such as the maximum number of logged messages stored.
- *Filters* - To filter the console for specific message types
- *Search* - Find any messages containing supplied text/regular expression.

LICENSE
=======
Copyright (c) 2021 Andrew Cowley.  See LICENSE file attached. 
