# PreviewLog

Overlays the screen with a resizeable console of log messages
for use in the Xcode Preview.

Usage:  makePreviewLog( yourViewName )
in the previews section

To log a message to the console, in command code use 
log( expression ), where expression is usually a String. interpolation is supported.
or
log ( expression, messageType),   where messageType = .info, .debug or .trace.   Different colors will be displayed to the log based on the messageType.


