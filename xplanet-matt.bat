:: When echo is turned off, the command prompt doesn't appear in the Command Prompt window.
@ECHO OFF

:: Change the directory to the main Xplanet folder
cd C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\xplanet-3

:: Set the command line variables to point at the correct files
SET config_file="C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\Xplanet-3\config\xp.conf"

:: Pick a random place around the world with a label and city markers,
:: update every 600 seconds, and run without keeping a DOS window
:: open.  Be careful when using -fork, as you can easily have many
:: xplanet processes running at the same time.  Use the task manager to
:: stop xplanet.

xplanet.exe -random -label -config "C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\Xplanet-3\config\xp.conf" -num_times 1 -arc_file "C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\Xplanet-3\markers\Tectonic_plates" -random -label -label_string "Earth from random viewpoint"
