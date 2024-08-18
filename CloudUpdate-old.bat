@echo off
setlocal

:: Full path to Perl executable
set PERL_EXEC=C:\Strawberry\perl\bin\perl.exe

:: Path to the Perl script
set SCRIPT_PATH="C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\xplanet\config\scripts\Totalmarker2.6.1a.pl"

:: Log file for capturing errors
set LOG_FILE="C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\xplanet\config\scripts\script_error.log"

:: Run the Perl script with the -clouds option and log any errors
%PERL_EXEC% %SCRIPT_PATH% -clouds 2>> %LOG_FILE%

endlocal
