set fpcfile=testfpc.pas

set fpccmd=%FPC_HOME%\bin\i386-win32\fpc.exe
set fpcoptions=-Fu.. -Fu../.. -Fi.. -Fi../..
set fpcoptions=%fpcoptions% -FEbin -FUtemp

%fpccmd% %fpcoptions% %fpcfile%
