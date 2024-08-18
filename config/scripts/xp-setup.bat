@echo off

echo "Setting home directory structure and linking cloud and marker files"
cd "%XPLANET_HOME%"
mkdir "-p" "{arcs,images,logs,markers,satellites,output}"
$XPLANET_CONFIG/scripts/xplanet.sh "earth"
cd "%XPLANET_HOME%\images"
ln "-s" "%XPLANET_CONFIG%\images\clouds\clouds-8192.jpeg" "clouds-8192.jpeg"
ln "-s" "%XPLANET_CONFIG%\images\lights\earth_lights_4800.tiff" "lights.tiff"
ln "-s" "%XPLANET_CONFIG%\images\bump\gebco_08_rev_elev_21600x10800.png" "bump.png"
ln "-s" "%XPLANET_CONFIG%\images\specular\specular.png" "specular.png"

@echo off

echo "Configuring Xplanet"
echo "-e" "################################################################################
  Xplanet, on its own, is installed and configured. The rest of the setup,
  and only with your approval, will update the marker files and the cloud image
  in addition to automating the script execution to keep everything up to date.
  
  Step 1) Installs a necessary PERL module for Totalmarker to work and updates
          the marker files.

          Additionally, you can configure Totalmarker by editing
          %XPLANET_CONFIG%/totalmarker.ini

  Step 2) Keeping the cloud image up to date requires a paid subscription to
          Xeric Designs: https://www.xericdesign.com/xplanet.php

          Subscribers need to update 'CloudUsername' and 'CloudPassword' in
          %XPLANET_CONFIG%/totalmarker.ini

  Step 3) Automates Xplanet so that it loads on login and keeps the marker
          files up to date.

  You will be prompted to continue at each step."
echo "################################################################################"
echo "Step 1) Press any key to continue or Control-C to exit..."
read "-k1" "-s"

@echo off
setlocal EnableDelayedExpansion

cd "%XPLANET_HOME%\markers"
SET _INTERPOLATION_0=
FOR /f "delims=" %%a in ('(brew --prefix)') DO (SET "_INTERPOLATION_0=!_INTERPOLATION_0! %%a")
SET _INTERPOLATION_1=
FOR /f "delims=" %%a in ('(brew --prefix)') DO (SET "_INTERPOLATION_1=!_INTERPOLATION_1! %%a")
COPY  "!_INTERPOLATION_1:~1!\share\xplanet\markers\earth" "earth"
echo "Prepare marker files with Totalmarker"
cd "!XPLANET_HOME!"
SET "!XPLANET_HOME!TMPL_LOC=!XPLANET_CONFIG!\scripts\Totalmarker2.6.1.pl"
ln "-s" "!TMPL_LOC!" "!TM!"

# Important we get this right now
IF NOT "-L" "%TM%" (
  echo "ERROR! Xplanet environment setup failed"
  echo "  Link to Totalmarker script doesn't point to anything... check and rerun"
  exit "1"
)
echo "Installing PERL module"
export "PERL_MM_USE_DEFAULT=1"
cpan "Mozilla::CA" REM UNKNOWN: {"type":"Redirect","op":{"text":">","type":"great"},"file":{"text":"/dev/null","type":"Word"}}
IF NOT "-L" "%XPLANET_CONFIG%\totalmarker.ini" (
  echo "Running Totalmarker for the first (and second time)"
  /usr/bin/perl "%TM%" REM UNKNOWN: {"type":"Redirect","op":{"text":">","type":"great"},"file":{"text":"/dev/null","type":"Word"}}
  /usr/bin/perl "%TM%" REM UNKNOWN: {"type":"Redirect","op":{"text":">","type":"great"},"file":{"text":"/dev/null","type":"Word"}}
  sed "-i" "" "s/clouds_2048.jpg/clouds-4096.jpg/" "%XPLANET_CONFIG%\totalmarker.ini"
  sed "-i" "" "s/Username/CloudUsername/" "%XPLANET_CONFIG%\totalmarker.ini"
  sed "-i" "" "s/Password/CloudPassword/" "%XPLANET_CONFIG%\totalmarker.ini"
)
echo "Updating markers"
/usr/bin/perl "%TM%" "-Volcano"
/usr/bin/perl "%TM%" "-Storm"
/usr/bin/perl "%TM%" "-Quake"

*********************************************************************************
* PLISTS line did not translate                                                 *
*********************************************************************************

open "-e" "%XPLANET_CONFIG%\totalmarker.ini"
echo "-e" "################################################################################
********************************************************************************
  Now is a good time to review and edit Totalmarker's initialization file at
  %XPLANET_CONFIG%/totalmarker.ini

  You may want to change QuakeMinimumSize

  Subscribers to Xeric Designs cloud service need to update 'CloudUsername' and
  'CloudPassword' credentials now before moving on
********************************************************************************"

lines 75 on not translated
