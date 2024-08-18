@echo off
REM Enable delayed expansion to handle paths with spaces
setlocal enabledelayedexpansion

REM Set up custom Perl module installation directory
set "PERL_MM_OPT=INSTALL_BASE=C:\Users\%USERNAME%\perl5"

REM Ensure Strawberry Perl's bin directory is included in the PATH
if not defined PATH (
    set "PATH=C:\Strawberry\perl\bin"
) else (
    if "!PATH:C:\Strawberry\perl\bin;=!" == "!PATH!" (
        set "PATH=C:\Strawberry\perl\bin;!PATH!"
    )
)

REM Update PATH environment variable to include the custom Perl bin directory
if defined PATH (
    set "PATH=C:\Users\%USERNAME%\perl5\bin;!PATH!"
) else (
    set "PATH=C:\Users\%USERNAME%\perl5\bin"
)

REM Update PERL5LIB environment variable to include the custom Perl library directory
if defined PERL5LIB (
    set "PERL5LIB=C:\Users\%USERNAME%\perl5\lib\perl5;!PERL5LIB!"
) else (
    set "PERL5LIB=C:\Users\%USERNAME%\perl5\lib\perl5"
)

REM Update PERL_LOCAL_LIB_ROOT environment variable
if defined PERL_LOCAL_LIB_ROOT (
    set "PERL_LOCAL_LIB_ROOT=C:\Users\%USERNAME%\perl5;!PERL_LOCAL_LIB_ROOT!"
) else (
    set "PERL_LOCAL_LIB_ROOT=C:\Users\%USERNAME%\perl5"
)

REM Set PERL_MB_OPT environment variable
set "PERL_MB_OPT=--install_base \"C:\Users\%USERNAME%\perl5\""

REM Set XPLANET_BIN and XPLANET_HOME environment variables
set "XPLANET_BIN=C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\"
set "XPLANET_HOME=C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\xplanet"

REM Update XPLANET related environment variables
set "XPLANET_CONFIG=!XPLANET_HOME!\config"
set "XPLANET_PROJECTION=ORTHOGRAPHIC"
set "XPLANET_GEOMETRY=2560x1440"
set "XPLANET_LONGITUDE=100"
set "XPLANET_LATITUDE="
set "XPLANET_TMPDIR=!XPLANET_HOME!"

REM Set date and time for output file
for /f "tokens=2 delims== " %%I in ('date /t') do set TODAY=%%I
for /f "tokens=1 delims== " %%I in ('time /t') do set TIME=%%I
set "XPLANET_OUTPUT=!XPLANET_HOME!\images\output_!TODAY!-!TIME!.jpg"

REM Set EARTH_MAP_PRE environment variable
set "EARTH_MAP_PRE=world\world"
REM set "EARTH_MAP_PRE=world.topo\world.topo"
REM set "EARTH_MAP_PRE=world.topo.bathy\world.topo.bathy"

echo PATH set to "!PATH!"
echo PERL5LIB set to "!PERL5LIB!"
echo PERL_LOCAL_LIB_ROOT set to "!PERL_LOCAL_LIB_ROOT!"
echo PERL_MB_OPT set to "!PERL_MB_OPT!"
echo XPLANET_BIN set to "!XPLANET_BIN!"
echo XPLANET_HOME set to "!XPLANET_HOME!"
echo XPLANET_CONFIG set to "!XPLANET_CONFIG!"
echo XPLANET_PROJECTION set to "!XPLANET_PROJECTION!"
echo XPLANET_GEOMETRY set to "!XPLANET_GEOMETRY!"
echo XPLANET_LONGITUDE set to "!XPLANET_LONGITUDE!"
echo XPLANET_LATITUDE set to "!XPLANET_LATITUDE!"
echo XPLANET_TMPDIR set to "!XPLANET_TMPDIR!"
echo XPLANET_OUTPUT set to "!XPLANET_OUTPUT!"
echo EARTH_MAP_PRE set to "!EARTH_MAP_PRE!"

endlocal
