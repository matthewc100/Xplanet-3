:: When echo is turned off, the command prompt doesn't appear in the Command Prompt window.
@ECHO OFF

:: Change the directory to the main Xplanet folder
cd C:\Users\mcoblent\xplanet-1.3.0

:: Set the command line variables to point at the correct files
SET config_file="C:\Users\mcoblent\xplanet-1.3.0\xplanet\config\xp.conf"

:: Pick a random place around the world with a label and city markers,
:: update every 600 seconds, and run without keeping a DOS window
:: open.  Be careful when using -fork, as you can easily have many
:: xplanet processes running at the same time.  Use the task manager to
:: stop xplanet.

xplanet.exe -random -label -config "C:\Users\mcoblent\xplanet-1.3.0\xplanet\config\xp.conf" -num_times 1
