set fpcfile=test.dpr

set fpccmd=%FPC_HOME%\bin\i386-win32\fpc.exe -dDEBUG
set fpcoptions=-Fu.. -Fu../.. -Fi.. -Fi../..
set fpcoptions=%fpcoptions% -FEbin -FUtemp
rem set fpcoptions=%fpcoptions% -Sa

%fpccmd% %fpcoptions% %fpcfile%

if %ERRORLEVEL% NEQ 0 GOTO End
bin\test.exe
:End