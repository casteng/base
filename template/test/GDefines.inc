{$Include base.inc}

{.$DEFINE USEFASTMM}             // Use FastMM memory manager
{.$DEFINE PUREPASCAL}           // Turns off any assembler optimizations
{$DEFINE PROFILE}              // Turns on profiling
{.$DEFINE CODEGENERATOR}        // Include license code generation routines
{.$DEFINE MULTITHREADLOG}       // Turns on multithreading-ready logging
{$DEFINE DYNAMICALLOC}          // Use dynamic memory allocation when possible to save memory

{$IFNDEF PUREPASCAL}
  {$DEFINE USEP6ASM}             // Turns on optimizations that requires P6 (or newer) architecture (doesn't work under FPC yet)
  {$DEFINE USESSE}               // Turns on optimizations that requires SSE (or newer) architecture
{$ENDIF}

{$IFDEF Has_Inline}
  {$INLINE ON}
{$ENDIF}

{$DEFINE DEBUGMODE}
{$DEFINE LOGGING}              // Turns on logging
{.$DEFINE DEBUGLOG}             // Turns on detail debug logging
{.$DEFINE SHAREWARE}            // Turns on nags, registration
{.$DEFINE RUSSIAN}              // Turns on some russian language specific features
{.$DEFINE COMPATMODE}           // Compatibility with changing file formats mode
{.$DEFINE GENERATE_CLEAN_INI}   // Generate a clean .ini file

{$DEFINE USED_VIRTUAL_TREEVIEW}   // VCL helper takes in account that TVirtualTreeview component is being used

{$IFDEF FPC}
{$ENDIF}

{$DEFINE USEVAMPYRE}              // Use Vampyre Imaging library
