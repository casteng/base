{$Include base.inc}

{/$DEFINE TEMPLATE_HINTS}        // Turns on compiler hints when instantiating template classes

{.$DEFINE USEFASTMM}             // Use FastMM memory manager
{.$DEFINE PUREPASCAL}           // Turns off any assembler optimizations

{$DEFINE PROFILE}              // Turns on profiling
{.$DEFINE CODEGENERATOR}        // Include license code generation routines
{.$DEFINE MULTITHREADLOG}       // Turns on multithreading-ready logging
{.$DEFINE MULTITHREADASSERT}    // Makes AssertErrorProc based features (i.e. source line number getting) thread safe
{$DEFINE DYNAMICALLOC}          // Use dynamic memory allocation when possible to save memory

{$IFNDEF PUREPASCAL}
  {$DEFINE USEP6ASM}             // Turns on optimizations that requires P6 (or newer) architecture
  {$DEFINE USESSE}               // Turns on optimizations that requires SSE (or newer) architecture
{$ENDIF}

{.$DEFINE DEBUGMODE}
{$DEFINE LOGGING}              // Turns on logging
{.$DEFINE DEBUGLOG}             // Turns on detail debug logging
{.$DEFINE SHAREWARE}            // Turns on nags, registration
{.$DEFINE RUSSIAN}              // Turns on some russian language specific features
{.$DEFINE COMPATMODE}           // Compatibility with changing file formats mode
{.$DEFINE GENERATE_CLEAN_INI}   // Generate a clean .ini file

{.$DEFINE USED_VIRTUAL_TREEVIEW}   // VCL helper takes in account that TVirtualTreeview component is being used

{.$DEFINE USEVAMPYRE}              // Use Vampyre Imaging library

{$IFDEF DELPHI}{$IFDEF WINDOWS}{$IFDEF DEBUG}
  {$DEFINE USE_JCLDEBUG}            // Use JCLDebug unit for runtime source code information from Jedi Code Library project
{$ENDIF}{$ENDIF}{$ENDIF}

{$IFNDEF WINDOWS}
  {$DEFINE USEGLUT}                 // Use FreeGLUT for OS interactions instead of Windows or X11
{$ENDIF}

{$DEFINE JUGGLE_EXTENSION}         // Turns on Juggle extension facility. See juggle_ext.inc for details.