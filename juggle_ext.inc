(*
 Juggle library extension point
 (C) 2006-2011 George "Mirage" Bakhtadze. 
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file.
 Created: Oct 31, 2011

 To use the extension facility switch it on by defining JUGGLE_EXTENSION conditional in GDefines.inc 
 of your project and add "juggle_extension.inc" file to your project.

 To use an existing Juggle extension add an include directive with the extension's .inc file 
 in juggle_extension.inc.

 To make your own extension create an .inc file with the following in mind:
 
 The extension will be included in main Juggle unit three times:
   1. in uses clause with _juggle_uses conditional variable defined
   2. in TJItems class interface section with _juggle_interface conditional variable defined
   3. in TJItems class implementation section with _juggle_implementation conditional variable defined
*)
{$IFDEF JUGGLE_EXTENSION}
  {$I juggle_extension.inc}
{$ENDIF}