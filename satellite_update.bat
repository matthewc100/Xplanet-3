::
@echo off

:: Get the latest orbital elements from celestrak.com:
wget -O "C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\xplanet\satellites\iss.tle" http://www.celestrak.com/NORAD/elements/stations.txt

:: Update the label
cd C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\xplanet\config\scripts
perl Totalmarker2.6.1a.pl -label

