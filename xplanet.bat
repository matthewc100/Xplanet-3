:: Here are some example commands for xplanet.  See the Readme files
:: for more details.  Uncomment each command by removing the "::" at
:: the beginning of the line.  Experiment to find a setup you like.  If
:: you get an error telling you you don't have permission to write the
:: desktop file, use the -tmpdir option like this
:: xplanet.exe -tmpdir .
:: This will write the desktop image in the current folder.

:: Show the earth from above latitude 0, longitude 0.
::
:: xplanet.exe

:: Show the daylit hemisphere and exit.
::
:: xplanet.exe -origin sun -num_times 1

:: Pick a random place around the world with a label and city markers,
:: update every 600 seconds, and run without keeping a DOS window
:: open.  Be careful when using -fork, as you can easily have many
:: xplanet processes running at the same time.  Use the task manager to
:: stop xplanet.
::
:: xplanet.exe -random -label -config earth_markers -wait 600 -fork

:: The earth from above Los Angeles with markers and a label.  Use the
:: Arial Italic font that comes with Windows.  Print diagnostic
:: information about what the program is doing.
::
:: xplanet.exe -lat 34 -lon -118 -label -config earth_markers -searchdir C:\WINNT\FONTS -font ARIALI.TTF -fontsize 18 -verb 3

:: A Mercator projection, centered on the daylit hemisphere.
:: xplanet.exe -projection mercator -origin sun

:: Show both hemispheres (one day, one night).
:: xplanet.exe -projection hemi -origin sun

:: Show a Mollweide projection centered on the nightside hemisphere
:: and no stars.
::
:: xplanet.exe -projection moll -origin -sun -starfreq 0

:: Look at the earth and moon from a random planet.  The earth's
:: radius is 20% of the screen height, and each body is magnified by a
:: factor of 20 (see the magnify option in the moon_orbit configuration
:: file).
::
:: xplanet.exe -origin major -config moon_orbit -radius 20 

:: Show Saturn from Cassini, using Cassini's spice kernels and JPL's
:: DE405 ephemeris.  The appropriate SPICE kernel files (listed in
:: xplanet\spice\cassini.krn) can be obtained from
:: ftp://naif.jpl.nasa.gov/pub/naif/CASSINI/kernels/spk and belong in
:: the xplanet\spice folder.  The ephemeris file unxp2000.405 is from
:: ftp://ssd.jpl.nasa.gov/pub/eph/export/unix and belongs in the
:: xplanet\ephemeris folder
::
:: xplanet.exe -fontsize 24 -label -ephemeris unxp2000.405 -spice_file cassini -target saturn -origin naif-82 -fov 10 -north orbit

:: Show the earth from a random planet or the moon and quit after drawing 
:: once.  The start /min minimizes the DOS window.
:: 
start /min xplanet.exe -fontsize 20 -label -body earth  -radius 40 -north orbit -num_times 1 -config xp.conf

start /min xplanet.exe --random -label -config "C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\xplanet\config\xp.conf" -wait 600 -fork
