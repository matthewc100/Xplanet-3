-arc_file
Specify an arc file to be plotted against the background stars.  Each
line in the file must have the following syntax:

dec1 ra1 dec2 ra2

where declination is in degrees and right ascension is in hours.  Thissd
option has no effect if -projection is specified.

-arc_spacing spacing
When drawing an arc, draw line segments that are spacing degrees
apart.  The default is 0.1 degrees.  Line segments shorter than
spacing will not be drawn.

-arc_thickness thickness
Specify the thickness of arcs.  The default is 1 pixel.  When drawing
arcs on a planet using the arc_file option in the configuration file,
use the arc_thickness option there too.

-background background_file
Use background_file as the background image, with the planet to be
superimposed upon it.  A color may also be supplied (e.g. -background
"navy blue" or -background 0xff00ff).

-base_magnitude magnitude
A star of the specified magnitude will have a pixel brightness of 1.
The default value is 10.  Stars will be drawn more brightly if this
number is larger.

-body body
Render an image of the specified planet or satellite.  Valid values
for body are sun, mercury, venus, earth, moon, mars, phobos, deimos,
jupiter, io, europa, ganymede, callisto, saturn, mimas, enceladus,
tethys, dione, rhea, titan, hyperion, iapetus, phoebe, uranus,
miranda, ariel, umbriel, titania, oberon, neptune, triton, nereid,
pluto, charon, random, and major.

The field of view can also be centered on a satellite location using
"naif" or "norad", along with the satellite id.  For example, "-body
naif-82" will center the field of view on NAIF ID -82, which is the
Cassini orbiter.  Xplanet must be compiled with SPICE support and the
required kernels must be present.  See the README in the spice
subdirectory for more details.  Using "-body norad20580" will center
the field of view on NORAD ID 20580, which is the Hubble Space
Telescope.  The appropriate TLE files must be present in this case.
See the README in the satellites subdirectory for more information.

Using "path" will center the field of view on the direction of motion
of the origin.  This direction is relative to the direction of motion
of the body specified by -path_relative_to.

Earth is the default body.  This option is the same as -target.

-center +x+y
Place the center of the rendered body at pixel coordinates (x, y).
The upper left corner of the screen is at (0,0). Either x or y may be
negative.  The default value is the center of the screen.

-color color
Set the color for the label.  The default is "red".  Any color in the
rgb.txt file may be used.  Colors may also be specified by RGB hex
values; for example -color 0xff and -color blue mean the same thing,
as do -color 0xff0000 and -color red.

-config config_file
Use the configuration file config_file.  The format of config_file is
described in README.config.  See the description of -searchdir to see
where xplanet looks in order to find the configuration file.

-create_scattering_tables scattering_file
Create lookup tables for Rayleigh scattering.  See the README in the
scattering directory for more information.

-date YYYYMMDD.HHMMSS
Use the date specified instead of the current local time.  The date is
assumed to be GMT.

-date_format string
Specify the format for the date/time label.  This format string is
passed to strftime(3).  The default is "%c %Z", which shows the date,
time, and time zone in the locale's appropriate date and time
representation.

-dynamic_origin file
Specify an observer location.  The location is relative to the body
specified with -origin (by default, this is the Sun).  The last line
of the file must be of the form
YYYYMMDD.HHMMSS range lat lon localtime
For example,
19951207.120000     10.328   -3.018   97.709    9.595
The specified time is ignored and the current time is used.  The range
is in planetary radii, and lat and lon are in degrees.  Localtime (in
hours) is optional, but if present, it will be used in place of the
longitude.  Only the last line of the file is used.  This file may be
updated between renderings using a script executed with the
-prev_command or -post_command options.

-ephemeris_file filename
Specify a JPL digital ephemeris file (DE200, DE405, or DE406) to use
for computing planetary positions.  Xplanet uses Bill Gray's code
(http://www.projectpluto.com/jpl_eph.htm), which reads both big and
little endian binary files.  The ephemeris files found at
ftp://ssd.jpl.nasa.gov/pub/eph/export/unix are big endian files, but
you do not need to do any additional byte-swapping to use them.  See
the description of -searchdir to see where xplanet looks in order to
find the ephemeris file.

-font fontname 
Set the font for the label.  Only TrueType fonts are supported.  If
the -pango option is used, fontname is taken to be the font family
name (e.g. "Arial").

-fontsize size 
Specify the point size.  The default is 12.

-fork
Detach from the controlling terminal.  This is useful on MS Windows to
run xplanet from a batch file without having to keep a DOS window
open.  Be careful when using this option; it's easy to have multiple
processes running at the same time without knowing it - check the Task
Manager.  On unix systems this is pretty much the same as running
xplanet in the background.

-fov
Specify the field of view, in degrees.  This option and the -radius
option are mutually exclusive.  This option has no effect if the
-projection option is used.

-geometry string
Specify the image geometry using the standard X window geometry
syntax, [<width>{xX}<height>][{+-}<xoffset>{+-}<yoffset>]
(e.g. 256x256-10+10 puts a window 256x256 pixels in size 10 pixels
away from the right side and 10 pixels below the top of the root
window).  The root window outside of the image will be black.  This
option may be used with -window or -output.

-glare radius 
Draw a glare around the sun with with a radius of the specified value
larger than the sun.  The default value is 28.

-gmtlabel
Same as the -label option, but show GMT instead of local time.

-grs_longitude lon
The longitude of Jupiter's Great Red Spot (GRS).  A typical value is
94 degrees.  If this option is specified, longitudes on Jupiter will
be calculated in System II coordinates.  By default, longitudes are
calculated in System III coordinates.  When using this option, use an
image map for Jupiter where the center of the GRS is at the pixel 0
column, or the left side of the image.

-hibernate seconds
After the screen has been idle for the specified number of seconds,
xplanet will sleep.  This option requires xplanet to have been
compiled with the X Screensaver extension.

-idlewait seconds
Don't run Xplanet unless the screen has been idle for the specified
number of seconds.  This option requires xplanet to have been compiled
with the X Screensaver extension.

-interpolate_origin_file
This option is only useful in conjunction with -origin_file.  It
computes the observer position at the current time by interpolating
between values specified in the origin file.  This is useful if you
have spacecraft positions tabulated in an origin file, but want a real
time view.

-jdate Julian date
Use the specified Julian date instead of the current local time.

-label
Display a label in the upper right corner.

-labelpos
Specify the location of the label using the standard X window geometry
syntax.  The default position is "-15+15", or 15 pixels to the left
and below the top right corner of the display.  This option implies
-label. 

-label_altitude
Display the altitude above the surface instead of distance from the
body center in the label.

-label_body body
Use the specified body to calculate the sub-observer, sub-solar, and
illumination values in the label.  This is useful with the -separation
option. 

-label_string
Specify the text of the first line of the label.  By default, it says
something like "Looking at Earth".  Any instances of %t will be
replaced by the target name, and any instances of %o will be replaced
by the origin name.

-latitude latitude
Render the target body as seen from above the specified latitude (in
degrees).  The default value is 0.  

-light_time
Account for the time it takes for light to travel from the target body
to the observer.  The default is to ignore the effects of light time.

-localtime localtime
Place the observer above the longitude where the local time is the
specified value.  0 is midnight and 12 is noon.

-log_magstep step
Increase the brightness of a star by 10^step for each integer decrease
in magnitude.  The default value is 0.4.  This means that a star of
magnitude 2 is 10^0.4 (about 2.5) times brighter than a star of
magnitude 3.  A larger number makes stars brighter.

-longitude longitude 
Place the observer above the specified longitude (in degrees).
Longitude is positive going east, negative going west (for the earth
and moon), so for example Los Angeles is at -118 or 242.  The default
value is 0.

-make_cloud_maps
If there is an entry in the config file for cloud_map, xplanet will
output a day and night image with clouds overlaid and then exit.  The
images will be created in the directory specified by -tmpdir, or in
the current directory if -tmpdir is not used.  The names of the output
images default to day_clouds.jpg and night_clouds.jpg, but may be
changed by the -output option.  If "-output filename.extension" is
specified, the output images will be named "day_filename.extension"
and "night_filename.extension".  The dimensions of the output images
are the same as the day image.

-marker_file
Specify a file containing user defined marker data to display against
the background stars. The format of each line is generally
declination, right ascension, string, as in the example below:

-16.7161 6.7525 "Sirius"

For additional options which may be specified, see the marker_file
entry in README.config.  This option has no effect if -projection is
specified.  This option is not meant for city markers; for that use
the marker_file option in the configuration file.

-markerbounds filename
Write coordinates of the bounding box for each marker to filename.
This might be useful if you're using xplanet to make imagemaps for web
pages.  Each line looks like:

204,312 277,324 Los Angeles

where the coordinates are for the upper left and lower right corners
of the box.  This file gets rewritten every time xplanet renders its
image.

-north north_type 
This option rotates the image so that the top points to north_type.
Valid values for north_type are:

body:        body's north pole
galactic:    galactic north pole
orbit:       body's orbital north pole (perpendicular to the orbit plane)
path:        origin's velocity vector  (also see -path_relative_to option)
separation:  perpendicular to the line of sight and the
             target-separation target line (see -separation option)

The default value is "body".

-num_times num_times
Run num_times before exiting.  The default is to run indefinitely.

-origin body
Place the observer at the center of the specified body.  Valid values
are the same as for -target.  In addition, "above", "below", or
"system" may be specified.  Using "above" or "below" centers the view
on the body's primary and the field of view is large enough to show
the body's orbit.  Using "system" places the observer at the center of
a random body in the same system as the target body.  Two bodies are
in the same system if one of the following is true:

 1) target and origin have same primary
 2) target is origin's primary
 3) origin is target's primary

If the body name is preceded by a dash, the observer is placed on the
opposite side of the target from the specified body at a distance
equal to the distance between the target and body.  For example,
-target earth -origin sun places the observer at the center of the
sun.  If -target earth -origin -sun is used, the observer is placed on
a line connecting the centers of the earth and sun at a distance of 1
AU farther from the sun than the earth.

-origin_file origin_file
Specify a list of observer positions in origin_file.  The positions
are relative to the body specified with -origin (by default, this is
the Sun).  Each line should be of the form
YYYYMMDD.HHMMSS range lat lon localtime
For example,
19951207.120000     10.328   -3.018   97.709    9.595
Range is in planetary radii, and lat and lon are in degrees.  The date
is the only required value.  If the localtime (in hours) is supplied,
it will be used in place of the longitude.  For each line in the
origin file, the observer is placed at the specified position,
relative to the body specified with -origin.  This option is useful
for showing spacecraft flybys or orbiting around a planet.  Any line
with a # in the first column is ignored.

-output filename
Output to a file instead of rendering to a window.  The file format is
taken from the extension. Currently .gif, .jpg, .ppm, .png, and .tiff
images can be created, if xplanet has been compiled with the
appropriate libraries.  The image size defaults to 512 by 512 pixels
but this may be changed by the -geometry flag.  If used with the
-num_times option, each output file will be numbered sequentially.

-output_map filename
Output the intermediate rectangular map that is created in the process
of rendering the final image.  It will have the same dimensions as the
default day map.

-output_start_index index
Start numbering output files at index.  The default is 0.

-pango
Use the Pango (http://www.pango.org) library for rendering
internationalized text. Pango uses Unicode for all of its encoding,
and will eventually support output in all the worlds major languages.
If xplanet has not been compiled with this library this option will be
ignored.  There appear to be memory leaks in the pango library, so I
don't recommend letting xplanet run indefinitely with this option.

-path_relative_to body
Only used with -north path or -target path.  The origin's velocity
vector is calculated relative to the specified body.  By default, this
is the Sun.

-post_command command
-prev_command command
Run command either before or after each time xplanet renders an image.
On MS Windows, you may need to use unix-style paths.  For example:
xplanet.exe -prev_command ./prev.bat

-print_ephemeris
Print the heliocentric rectangular equatorial coordinates (J2000) for
each body xplanet knows about, and then exit.

-projection projection_type
The projection type may be one of ancient, azimuthal, bonne,
equal_area, gnomonic, hemisphere, icosagnomonic, lambert, mercator,
mollweide, orthographic, peters, polyconic, rectangular, or tsc.  The
default is no projection.  Multiple bodies will not be shown if this
option is specified, although shadows will still be drawn.

-proj_param value
Pass additional parameters for some projections.  The only projections
that use this option at present are the Bonne, Gnomonic, and Mercator
projections.  The Bonne projection is conformal at the specified
latitude.  Higher values lead to a thinner heart shape.  The default
is 50 degrees.  The Gnomonic and Mercator projections use the
specified latitude as the boundaries of the projection.  The defaults
are 45 and 80 degrees, respectively.  This option may be used more
than once for future projections that require additional parameters.
Only the first value is used at present.

-quality quality
This option is only used when creating JPEG images.  The quality can
range from 0 to 100.  The default value is 80.

-radius radius 
Specify the radius of the globe as a percent of the screen height.
The default value is 45% of the screen height.  When drawing Saturn,
the radius value applies to the radius of the outer ring.

-random
Place the observer above a random latitude and longitude.

-range range
Render the globe as seen from a distance of range from the planet's
center, in units of the planetary radius.  The default value is 1000.
Note that if you use very close ranges the field of view of the screen
can be greater than 180 degrees!  If you want an "up close" image use
the -radius option.

-rotate angle 
Rotate the globe by angle degrees counterclockwise so that north (as
defined by the -north argument) isn't at the top.  The default value
is 0.  My friends in the Southern Hemisphere can use -rotate 180 to
make the earth look like it should!  For non-orthographic projections,
the globe is rotated and then projected, if that helps you visualize
what to expect.

-save_desktop_file
On Microsoft Windows and Mac OS X, xplanet creates an intermediate
image file which is used to set the desktop.  This file will be
created in the -tmpdir directory.  By default, this image is removed
after the desktop has been set.  Specifying this option will leave the
file in place.

-searchdir directory
Any files used by xplanet should be placed in one of the following
directories depending on its type: "arcs", "config", "ephemeris",
"fonts", "images", "markers", "origin", "satellites", or "stars".  By
default, xplanet will look for a file in the following order:
The current directory
searchdir
subdirectories of searchdir
subdirectories of xplanet (if it exists in the current directory)
subdirectories of ${HOME}/.xplanet on X11
subdirectories of ${HOME}/Library/Xplanet on Mac OS X
subdirectories of DATADIR/xplanet
DATADIR is set at compile time and defaults to /usr/local/share.

-separation body:dist
Place the observer at a location where the target body and the
separation body are dist degrees apart.  For example "-target earth
-separation moon:-3" means place the observer at a location where the
moon appears 3 degrees to the left of the earth. 

-spice_ephemeris index
Use SPICE kernels to compute the position of the named body.  The
index is the naif ID code (e.g. 599 for Jupiter).  The -spice_file
option must be used to supply the names of the kernel files.  This
option may be used more than once for different bodies.

-spice_file spice_file
Specify a file containing a list of objects to display.  A file
containing a list of SPICE kernels to read named spice_file.krn must exist
along with spice_file.  See the README in the "spice" subdirectory for
more information.

-starfreq frequency
Fraction of background pixels that will be colored white.  The default
value is 0.001.  This option is only meaningful with the azimuthal,
mollweide, orthographic, and peters projections.

-starmap starmap
Use starmap to draw the background stars.  This file should be a text
file where each line has the following format:
Declination, Right Ascension, Magnitude
where Declination is in decimal degrees and Right Ascension is in
decimal hours.  For example, the entry for Sirius is
-16.7161  6.7525 -1.46
See the description of -searchdir to see where xplanet looks in order
to find the star map.

-target target
Same as -body.

-tt
Use terrestrial time instead of universal time.  The two differ
slightly due to the non-uniform rotation of the earth.  The default is
to use universal time.

-timewarp
As in xearth, scale the apparent rate at which time progresses by
factor.  The default is 1.

-tmpdir tmpdir
Specify a directory that xplanet will use to place images created
using -make_cloud_maps.  On Microsoft Windows, xplanet will write
a bitmap file called xplanet.bmp to the specified directory.  The
default is the result of the GetWindowsDirectory call (C:\WINDOWS on
Win95).  On Mac OS X, xplanet will create an intermediate PNG file in
order to set the background.  The default value is /tmp.  On Windows
and Mac OS X, the intermediate file will be removed unless the
-save_desktop_file option is specified.

-transparency
Update the background pixmap for transparent Eterms and aterms.  This
option only works under X11.

-transpng filename
Same as the -output option, except set the background to be
transparent when writing a PNG file.  

-utclabel
Same as -gmtlabel.

-verbosity level
level      output
< 0        only fatal error messages
0          non-fatal warning messages
1          basic information         
2          basic diagnostics         
3          more detailed diagnostics 
4          very detailed diagnostics 
The default value is 0.

-version
Display current version information, along with a list of compile-time
options that xplanet supports.

-vroot
Render the image to the virtual root window.  Some window managers use
one big window that sits over the real root window as their background
window.  Xscreensaver uses a virtual root window to cover the screen
as well.

-wait wait
Update every wait seconds.

-window
Render the image to its own X window.  The size defaults to 512 by 512
pixels but this may be set by the -geometry flag.

-window-id ID
When using the X11 windowing system, draw to the window with the
specified ID. 

-window_title title
Set the window's title to title.  This option implies -window.

-XID ID
Same as -window-id.

-xscreensaver
Same as -vroot.
