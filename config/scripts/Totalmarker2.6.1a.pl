####################################
# ORIGINALLY WRITTEN BY MICHAEL DEAR
# 
# Modified by Matthew Coblentz 
# 18 August 2024
# Original effort by Michael Dear gratefully acknowledged as this would not
# be possible otherwise.  
# 
# Major driver for this effort is the intent to move major funtionality into
# Perl modules rather than local subroutines, modernize external file
# fetching, and use of STRICT and WARNINGS requires specific code cleanup in 
# main script.
####################################

#! /usr/bin/perl
use strict;
use warnings;
use FindBin qw($Script $Bin);
use LWP::UserAgent;
use LWP::Simple;
use Time::Local;
use HTTP::Response;
use HTTP::Cookies; 
use HTTP::Request; 
use File::Copy;
use File::Spec;
use File::Basename;
use Getopt::Std;
use POSIX;
use Cwd;

# Adjust this path to where the module files are located
use lib 'C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\Xplanet-3\config\scripts';  


# use Hurricane;
# use Label;
use CloudUpdate qw(
    cloud_update
    );
#use Norad qw(
#    get_noraddata 
#    norad_checked 
#    update_file
#    );#

use Earthquake qw(
    drawcircle 
    max_model 
    max_min_model 
    standard_model 
    colourisetext 
    colourisemag 
    WriteoutQuake 
    get_Correct_quake_Feed 
    get_quakedata
    );
#use Volcano qw(
#    WriteoutVolcano
#    get_volcanodata
#    );
#use Eclipse qw(
#    readineclipseindex
#    readineclipsetrack
#    datacurrent
#    writeouteclipsemarker
#    writeouteclipsearcboarder
#    writeouteclipsearccenter
#    writeouteclipsefilesnone
#    writeouteclipselabel
#    refinedata
#    );
#use EasterEgg qw(easteregg
#    ); 
use Globals qw(
    $quakesettings 
    $settings

    $quake_marker_file 
    @quakedata 
    $quake_location 
    set_quake_marker_file 
    set_quakedata 
    set_quake_location 

    $noradsettings
    set_quake_marker_file
    $xplanet_images_dir
    );

# use Globals qw(
#    $quakesettings 
#     


#     
#    $isstle_file 
#    $iss_file 
#    $xplanet_satellites_dir 
#    $iss_location 
#    $hst_location 
#    $sts_location 
#    $other_locations1 
#    $xplanet_images_dir

#    set_pversion#

#    $volcano_marker_file
#    $volcano_location
#    );

#perl2exe_include "Bzip2.pm";
#perl2exe_include "FileSpec.pm";

#perl2exe_include "C:/Perl2exe/v11/pm/FileSpec.pm";
#perl2exe_include "C:/Perl2exe/v11/pm/Bzip2.pm";
#perl2exe_include "C:/Perl2exe/v11/pm/FindBin.pm";


# Breakdown of this section's intent
# BEGIN { ... }: 
#
#   The BEGIN block ensures that the code inside it is executed during the compilation phase, before any other code in 
#   the script runs. 
#
# $^X:
#   $^X is a special Perl variable that holds the name of the Perl binary being used to run the script. 
#   This is usually something like perl or perl.exe. 
#
# $0:
#   $0 is a special Perl variable that holds the name of the file containing the Perl script being executed.
#
# $^X =~ m%(^|[/\\])(perl)|(perl.exe)$%i:
#   This regular expression checks whether $^X ends with perl or perl.exe. The i at the end of the regex makes it 
#   case-insensitive.
#
#   (^|[/\\]): This part ensures that perl or perl.exe appears either at the beginning of the string or is preceded by a 
#   forward slash (/) or backslash (\), which are common directory separators.
#
# $0 = $^X unless ...:
#   This line sets $0 (the name of the script) to $^X (the name of the Perl interpreter) unless $^X already matches the 
#   regex pattern. In other words, it changes the script's name to the Perl interpreter's name unless the interpreter's 
#   name is already something like perl or perl.exe.
# 
# Purpose
#   The purpose of this line is to set the script name ($0) to the name of the Perl interpreter ($^X) unless the 
#   interpreter is already named perl or perl.exe. This can be useful in scenarios where the script might be running 
#   under a different Perl interpreter or under a different name, and you want to standardize it to use the interpreter's 
#   name.
#
# Example Scenario
#   If the script is executed with a non-standard Perl interpreter, such as my_perl, this line will set $0 to my_perl. 
#   However, if the interpreter is the standard perl or perl.exe, $0 remains unchanged.
#
# Summary
#   The line effectively changes the script's name to the Perl interpreter's name unless the interpreter is already a 
#   common name (perl or perl.exe). This can be a useful way to ensure consistency in how the script identifies itself, 
#   especially in environments where multiple Perl interpreters are used.
BEGIN {
    # CollapsedSubs: get_webpage  get_program_version  changelog_print  file_header  Hurricane::get_hurricane_data_count  WriteoutVolcano  get_volcanodata  
    # update_file  get_eclipsedata  readineclipseindex  readineclipsetrack  datacurrent  writeouteclipsemarker  writeouteclipsearcboarder  
    #writeouteclipsearccenter  writeouteclipsefilesnone  writeouteclipselabel  refinedata  get_settings  easteregg
    $0 = $^X unless ($^X =~ m%(^|[/\\])(perl)|(perl.exe)$%i );
}

#use Mozilla::CA;

our $VERSION="2.6.1";
our $Client = "Client Edition";
our $Script = "TotalMarker";

################################################################################################
#
#
#        Configuaration section.  Please Check these variables and adjust
#
#
################################################################################################
#
# Declaring variables before they are used...
#
# Declare the variables used for updating labels
my $update_earth = 0;        # Set to the appropriate value
my $update_norad = 0;        # Set to the appropriate value
my $update_cloud = 0;        # Set to the appropriate value
my $update_hurricane = 0;    # Set to the appropriate value
my $update_volcano = 0;      # Set to the appropriate value
my $update_label = 0;        # Set to the appropriate value
#
# Orgininal Location of the downloads
#
my $quake_location = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_week.csv";
my $storm_base_location = "https://www.nrlmry.navy.mil/tcdat/sectors/ftp_sector_file";
my $storm_past_location = "https://www.nrlmry.navy.mil/archdat/test/kml/TC/";
my $storm_future_location = "https://www.nrlmry.navy.mil/atcf_web/docs/current_storms/";
my $iss_location = "https://www.celestrak.com/NORAD/elements/stations.txt";
my $other_locations1 = "https://www.celestrak.com/NORAD/elements/science.txt";
my $hst_location = "https://www.celestrak.com/NORAD/elements/tdrss.txt";
my $sts_location = "https://www.celestrak.com/NORAD/elements/sts.txt";
my $sts_dates = "https://www.seds.org/~spider/shuttle/shu-sche.html";
my $backup_sat_location= "https://www.idb.com.au/joomla/index.php";
#my $volcano_location = "https://www.volcano.si.edu/bgvn.cfm";
#my $volcano_location = "https://www.volcano.si.edu/news/WeeklyVolcanoCAP.xml";
my $volcano_location = "https://volcano.si.edu/news/WeeklyVolcanoCAP.xml";
my $eclipse_location = "https://sunearth.gsfc.nasa.gov/eclipse/SEpath/";
my $refined_eclipse_data = "https://www.wizabit.eclipse.co.uk/xplanet/files/local/update.data";
#my $cloud_image_base = "https://xplanetclouds.com/free/coral/";
my $cloud_image_base = "https://secure.xericdesign.com/xplanet/clouds/4096";

# Example usage of CloudUpdate module
my $cloud_image_url = "http://secure.xericdesign.com/xplanet/clouds/8192/clouds-8192.jpg";
# my $cloud_username = "XP100-EFD5M-SEW3F-GW3PV";
# my $cloud_password = "v5mmVrDRgTJ5";
my $cloud_file_name = "clouds-8192.jpeg";

my $volcano_location_RSS_24H = "https://earthquake.usgs.gov/eqcenter/recenteqsww/catalogs/caprss1days2.5.xml";


# my $quake_location_CSV_24H_SIG = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_day.csv";
# my $quake_location_CSV_24H_45 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_day.csv";
# my $quake_location_CSV_24H_25 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.csv";
# my $quake_location_CSV_24H_10 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/1.0_day.csv";
# my $quake_location_CSV_24H_ALL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.csv";

# my $quake_location_CSV_7D_SIG = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_week.csv";
# my $quake_location_CSV_7D_45 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_week.csv";
# my $quake_location_CSV_7D_25 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_week.csv";
# my $quake_location_CSV_7D_10 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/1.0_week.csv";
# my $quake_location_CSV_7D_ALL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_week.csv";

# my $quake_location_CSV_30D_SIG = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_month.csv";
# my $quake_location_CSV_30D_45 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_month.csv";
# my $quake_location_CSV_30D_25 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.csv";
# my $quake_location_CSV_30D_10 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/1.0_month.csv";
# my $quake_location_CSV_30D_ALL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv";

my $ua = LWP::UserAgent->new();
$ua->env_proxy();
$ua->agent("Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 9.1)");

# Please note if you are using Windows and Active Perl you must \\ your directories not just use \
# where xplanet is installed
#
# Directory Layout
#
my $ENV;
# my $xplanet_dir = $ENV{'XPLANET_DIR'} || "/usr/X11R6/share/xplanet";
my $xplanet_dir = $ENV{'XPLANET_DIR'} || "C:\\Users\\mcoblent\\onedrive\\xplanet\\xplanet-1.3.0\\xplanet-3";

# where the xplanet marker files are
my $xplanet_markers_dir = $ENV{'XPLANET_MARKERS_DIR'} || "$xplanet_dir\\markers";

# where the xplanet greatarc files are
my $xplanet_arcs_dir = $ENV{'XPLANET_ARC_DIR'} || "$xplanet_dir\\arcs";

# where the satellites info files are
my $xplanet_satellites_dir = $ENV{'XPLANET_SATELLITES_DIR'} || "$xplanet_dir\\satellites";

# where the image files are
my $xplanet_images_dir = $ENV{'XPLANET_IMAGE_DIR'} || "$xplanet_dir\\images";

# where the config files are
my $xplanet_config_dir = $ENV{'XPLANET_CONFIG_DIR'} || "$xplanet_dir\\config";

#
# File Locations
#
# where the quake marker will be written to
my $quake_marker_file = " $xplanet_markers_dir\\quake";

# add $quake_marker_file to the Globals module
# Set the value of $quake_marker_file using the setter function
set_quake_marker_file($quake_marker_file);

# where the volcano marker will be written to
my $volcano_marker_file = " $xplanet_markers_dir\\volcano";

# where the hurricane marker will be written to
my $hurricane_marker_file = " $xplanet_markers_dir\\storm";

# where the hurricane tracking will be written to
my $hurricane_arc_file = " $xplanet_arcs_dir\\storm";

# where the iss file will be written to
my $iss_file = "$xplanet_satellites_dir\\tm";

#where the iss.tle will be written to
my $isstle_file = "$xplanet_satellites_dir\\tm.tle";

#where the iss.tle will be written to
my $label_file = "$xplanet_markers_dir\\updatelabel";

#where the eclipse marker file will be written to
my $eclipse_marker_file = "$xplanet_markers_dir\\eclipse";

#where the eclipse arc file will be written to
my $eclipse_arc_file = "$xplanet_arcs_dir\\eclipse";

#where the eclipse data file will be written to
my $eclipse_data_file = "$xplanet_config_dir\\totalmarker.dat";

#where the settings are stored
my $settings_ini_file = "$xplanet_config_dir\\totalmarker.ini";

#where the old settings were stored
my $settings_old_ini_file = "$xplanet_dir\\totalmarker.ini";

#where the old dat files was stored
my $eclipse_old_data_file = "$xplanet_dir\\totalmarker.dat";

#where cloud batch file is
my $cloudbatch = "$xplanet_dir\\updateclouds.bat";

#Where WinXplanetbg stores its settings
my $winXPlanetBG = "$xplanet_dir\\winXPlanetBG.ini";

#Where the backup is stored
my $winxplanetbgbackup = "xplanet_config_dir\\winXPlanetBG.ini";

#
# Test that locations exist and can be written to.
#
-d $xplanet_dir         || die("Could not find xplanet installation directory $xplanet_dir\n");
-r $xplanet_dir         || die("Could not read from xplanet installation directory $xplanet_dir\n");
-w $xplanet_dir         || die("Could not write to xplanet installation directory $xplanet_dir\n");
-e $eclipse_data_file   || &install("eclipsfile");
-e $settings_ini_file   || &install("configfile");

-d $xplanet_markers_dir || die("Could not find xplanet markers directory $xplanet_markers_dir\n");
-r $xplanet_markers_dir || die("Could not read from xplanet markers directory $xplanet_markers_dir\n");
-w $xplanet_markers_dir || die("Could not write to xplanet markers directory $xplanet_markers_dir\n");

-d $xplanet_arcs_dir || die("Could not find xplanet arcs directory $xplanet_arcs_dir\n");
-r $xplanet_arcs_dir || die("Could not read from xplanet arcs directory $xplanet_arcs_dir\n");
-w $xplanet_arcs_dir || die("Could not write to xplanet arcs directory $xplanet_arcs_dir\n");

-d $xplanet_satellites_dir || die("Could not find xplanet satellites directory $xplanet_satellites_dir\n");
-r $xplanet_satellites_dir || die("Could not read from xplanet satellites directory $xplanet_satellites_dir\n");
-w $xplanet_satellites_dir || die("Could not write to xplanet satellites directory $xplanet_satellites_dir\n");

-d $xplanet_images_dir || die("Could not find xplanet images directory $xplanet_images_dir\n");
-r $xplanet_images_dir || die("Could not read xplanet from images directory $xplanet_images_dir\n");
-w $xplanet_images_dir || die("Could not write xplanet to images directory $xplanet_images_dir\n");

#
# Allows simple update to Totalmarker should regex & location change.
#
my $readfile="totalmarker.upd";
if ( (-e $readfile) && (-r $readfile) ) {
    &get_xml_update;
}

# I think this should be removed.  Test first.  
# Example usage of Earthquake module
# Earthquake::get_Correct_quake_Feed($quakesettings);
# my $counter = Earthquake::get_quakedata($quakesettings);
# Earthquake::WriteoutQuake($counter, $quakesettings);

###############################
# Reset this section to the following section when using Hurricane.pm
###############################
#my $hurricane_counter = &get_hurricane_data_count();
# my ($actcounter, $forcounter) = &get_hurricanearcdata($counter);
# &WriteoutHurricane($counter);
# &WriteoutHurricaneArc($counter, $actcounter, $forcounter);

###############################
# this is the module calling section
###############################
#my $hurricane_counter = Hurricane::get_hurricane_data_count();
#my ($actcounter, $forcounter) = Hurricane::get_hurricanearcdata($hurricane_counter);
#Hurricane::WriteoutHurricane($hurricane_counter);
#Hurricane::WriteoutHurricaneArc($hurricane_counter, $actcounter, $forcounter);

# Label update code
# Label::WriteoutLabel($update_earth, $update_norad, $update_cloud, $update_hurricane, $update_volcano, $update_label);

sub get_webpage($) {
    my ($URL)=@_;
    my $req = HTTP::Request->new(GET => $URL);
    my $res = $ua->request($req);
    
    return $res->content || return 'FAILED';
}

sub command_line {
    my $quake_on_off = 0;
    my $update_label = 0;
    my $volcano_on_off = 0;
    my $norad_on_off = 0;
    my $clouds_on_off = 0;
    my $hurricane_on_off = 0;

    while (@ARGV) {
        my $result = shift @ARGV;
        if ($result eq "-earthquake") { 
            $quake_on_off = 1; 
        } elsif ($result eq "-Label" || $result eq "-label") { 
            $update_label = 1; 
        } elsif ($result eq "-Earthquake" || $result eq "-Quake" || $result eq "-quake") { 
            $quake_on_off = 1; 
        } elsif ($result eq "-Volcano" || $result eq "-volcano") { 
            $volcano_on_off = 1; 
        } elsif ($result eq "-NORAD" || $result eq "-Norad" || $result eq "-norad") { 
            $norad_on_off = 1; 
        } elsif ($result eq "-Clouds" || $result eq "-Cloud" || $result eq "-clouds" || $result eq "-cloud") { 
            $clouds_on_off = 2; 
        } elsif ($result eq "-Clouddone" || $result eq "-Cloudsdone" || $result eq "-clouddone" || $result eq "-cloudsdone") { 
            $clouds_on_off = 1; 
        } elsif ($result eq "-Hurricane" || $result eq "-Storm" || $result eq "-hurricane" || $result eq "-storm") { 
            $hurricane_on_off = 1; 
        } elsif ($result eq "-version" || $result eq "-Version") { 
            my $xplanetversion = &get_program_version;
            print "$Script $Client $VERSION\nXplanet Version $xplanetversion\nMichael Dear    10th Feb 2004\nhttp://www.wizabit.eclipse.co.uk/xplanet\n";
            exit 1;
        } elsif ($result eq "-update" || $result eq "-Update") { 
            &update_ini_file; 
            exit 1; 
        } elsif ($result eq "-install" || $result eq "-Install") { 
            $result = shift @ARGV;
            if ($result =~ /'storm'/ || $result =~ /'hurricane'/ || $result =~ /storm/ || $result =~ /hurricane/) { 
                &install('storm');
            } elsif ($result =~ /'quake'/ || $result =~ /quake/) { 
                &install('quake'); 
            } elsif ($result =~ /'norad'/ || $result =~ /norad/) { 
                &install('norad'); 
            } elsif ($result =~ /'cloud'/ || $result =~ /cloud/) { 
                &install('cloud'); 
            } elsif ($result =~ /'volcano'/ || $result =~ /volcano/) { 
                &install('volcano'); 
            } elsif ($result =~ /'eclipse'/ || $result =~ /eclipse/) { 
                &install('eclipse'); 
            } elsif ($result =~ /'UpdateLabel'/ || $result =~ /'updatelabel'/ || $result =~ /UpdateLabel/ || $result =~ /updatelabel/) { 
                &install('updatelabel'); 
            } elsif ($result =~ /'TotalMarker'/ || $result =~ /'totalmarker'/ || $result =~ /TotalMarker/ || $result =~ /totalmarker/) { 
                &install('totalmarker'); 
            } elsif ($result =~ /'ChangeLog'/ || $result =~ /'Changelog'/ || $result =~ /'changelog'/ || $result =~ /changeLog/) { 
                &changelog_print('all'); 
            } else {
                &get_it_right_install();
            }
        } else {
            &get_it_right_lamer();
        }
    }
}


sub get_program_version {
    my $programversion = `xplanet --version`;
    foreach (split("\n", $programversion)) {
        if (/Xplanet/) {
            s/\s+//g;  # Remove all spaces
            s/Xplanet//g;  # Remove the string "Xplanet"
            return $_;
        }
    }
    return "Unknown version";  # Default return value if "Xplanet" is not found
}

sub changelog_print () {
    my $oldversion = @_;
    #header
    print "Present Version is $VERSION. Installed settings file version is $oldversion\n";
    print "This is the Changelog from versions $oldversion to $VERSION\n";
    #changelog
    my $flag = 99999;
    if ($oldversion =~ /1/)         {$flag = 1;}
    if ($oldversion =~ /1.03.1/)    {$flag = 1;}
    if ($oldversion =~ /1.03.2/)    {$flag = 2;}
    if ($oldversion =~ /1.03.3/)    {$flag = 3;}
    if ($oldversion =~ /1.03.4/)    {$flag = 4;}
    if ($oldversion =~ /2.5.0/)     {$flag = 5;}
    if ($oldversion =~ /2.5.1/)     {$flag = 6;}
    if ($oldversion =~ /2.5.2/)     {$flag = 7;}
    if ($oldversion =~ /2.5.6/)     {$flag = 8;}
    if ($oldversion =~ /3.0.0/)     {$flag = 9;}
    if ($oldversion =~ /all/)       {$flag = 6;}
    if ($flag == 1) {
        print"\n *1.03.2\n";
        print"  Added a Satellite file name option. i.e. NoradFileName=tm (*)\n";
        print"  Added a Eclipse notification in hours. i.e. EclipseNotifyTimeHours=48 (*)\n";
        print"  Fixed the after event notification for Eclipses\n";
        print"  Added a version Option. -version\n";
        print"  Added an install option to update files and setup it self up\n";
        print"  Made it so that it knows about XplanetNG\n";
        print"  Moved the settings and data files to /config for use with XplanetNG\n";
        print"  Fixed a Earthquake bug that would not show some Earthquakes\n";
        print"  If the data fails to give a magnitude 0.0 will show and a circle of 4 is drawn\n";
        if ($VERSION =~ /1.03.2/) {$flag = 99999;}
    }
    if ($flag <= 2) {
        print"\n *1.03.2\n";
        print"  Symbolsize has changed for version 0.95 and above Earthquakes circles work as\n before Volcano need changing to 2,4,6 in ini file\nAdded an option to download the cloud image.\n";
        if ($VERSION =~ /1.03.3/) {$flag = 99999;}
    }
    if ($flag <= 3) {
        print"\n *2.04.1\n";
        print"  Fixed Labels\nAdded a modem option for labelupdate\nChanged version to internal version numbering.\nDefaults to downloading TLE of Science Orbits";
        if ($VERSION =~ /1.03.4/) {$flag = 99999;}
    }
    if ($flag <= 4) {
        print"\n *2.04.2\n";
        print"  Fixed miss labeled QuakeMinSize to QuakeMinimumSize\nAdded the Option for Soyuz\nAdded a flag of Xplanet version.\n ";
        if ($VERSION =~ /1.03.5/) {$flag = 99999;}
    }
    if ($flag <= 5) {
        print"\n *2.5.0\n";
        print"  Versions changed to match internal CVS\nInternal chages made and setup for Xplanet 1.0 or better";
        if ($VERSION =~ /1.03.6/) {$flag = 99999;}
    }
    if ($flag <= 6) {
        print"\n *2.5.1\n";
        print"  USGS changed pages, a rewrite of the quake data to get it working again.\nFixed minor bugs in quake and storm details.";
        if ($VERSION =~ /1.03.7/) {$flag = 99999;}
    }
    if ($flag <= 7) {
        print"\n *2.5.2\n";
        print"  Fixed Storms not working over to new website.\n";
        if ($VERSION =~ /1.03.7/) {$flag = 99999;}
    }
    if ($flag <= 8) {
        print"\n *2.5.6\n";
        print"  Fixed Storms and Earthquakes not working over to new website.\n";
        if ($VERSION =~ /1.03.7/) {$flag = 99999;}
        print"\n *2.5.7\n";
        print"  Fixed Storms Track added a difference check as source data was wrong, sorted by ignoring data that is +/- 5 f last reported postiion for past data.\n";
    }
    if ($flag <= 9) {
        print"\n 3.0.0\n";
        print"  Using RSS where possable\n";
        print"  Moved to new platform\n";
        if ($VERSION =~ /1.03.7/) {$flag = 99999;}
    }
    #ending
    print"\nThe items with a (*) by them are accessible if you allow totalmarker to update its files. To add the extra settings to TotalMarker please run:\n\"TotalMarker -install totalmarker patch\" without the quotes.\n";
    print"\nTo see the entire log please type \n\"TotalMarker -install totalmarker |more\" with out the quotes.\n";
    print"\nVersion: $VERSION         Home: http://www.wizabit.eclipse.co.uk/xplanet";
    exit 1;
    die;
}

sub get_it_right_install {
    print <<EOM;
$Script: download and create marker files to be used with xplanet.
THIS IS IN BETA BACKUP YOUR WINXPLANETBG.INI FILE BEFORE USING.
 The install section will accept the following options
* $Script -install Quake   This will install Earthquakes into WinXplanetBG.
* $Script -install Storm   This will install Storms into WinXplanetBG.
* $Script -install Norad   This will install Satellitess into WinXplanetBG.
* $Script -install Volcano This will install Volcanos into WinXplanetBG.
* $Script -install Clouds  This will install Clouds into WinXplanetBG.
* $Script -install Eclipse This will install Eclipses into WinXplanetBG.
* $Script -install UpdateLabel This will install updatelabel into WinXplanetBG.
* $Script -install TotalMarker See Below.

Please Note:  Updating only works if you have WinXplanetBG. The Rest of you
can work it out for yourselves :P

* Install $Script.
As more options are added to each version, this will add the extra options
to the config file, so you can change them if you wish, they will default
to no changes from the past operations, if you do nothing, or don't
run this option.

Version: $VERSION         Home: http://www.wizabit.eclipse.co.uk/xplanet
EOM
    exit 1;
    
}

sub get_it_right_lamer {
    print <<EOM;
$Script: download and create marker files to be used with xplanet.

This script is driven by the command line, the options are as follows
* $Script -Quake      This will write the Earthquake marker file.
* $Script -Storm      This will write the Storm marker and arc files.
* $Script -Norad      This will write the ISS and ISS.TLE files.
* $Script -Volcano    This will write the Volcano marker file.
* $Script -Clouds     This will download the latest cloud image.

Eclipses and Updatelabel are controlled from the ini file.
If you are using an old totalmarker then run totalmarker -update

Options are set from the ini file.  This is created the first time the
file is run.  Please note it does require an Internet connection for
the first run, as it builds a database for the eclipses.

Then add the following to your xplanets config file under earths section
* -markerfile quake                                For Earthquakes
* -markerfile volcano                              For Volcanos
* -satfile tm (unless changed in the settings file)For Satellites
* -markerfile storm -greatarcfile storm            For Storms
* -markerfile updatelabel                          For UpdateLabel
* -markerfile eclipse -greatarcfile eclipse        For Eclipse

Version: $VERSION         Home: http://www.wizabit.eclipse.co.uk/xplanet
EOM
    exit 1;
}

# Return codes of 200 to 299 are "success" in HTTP-speak
sub IndicatesSuccess () {
    my $Response = shift();
    if ($Response =~ /2\d\d/)   {return(1);}
    else                        {return(0);}
}

# Returns the name of an internet resource which can provide the clouds image
sub GetRandomMirror() {
    # Populate a list of mirrors
    my @Mirrors;
    if (my $cloudsettings->{'CloudMirrorA'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorA'}";}
    if (my $cloudsettings->{'CloudMirrorB'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorB'}";}
    if (my $cloudsettings->{'CloudMirrorC'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorC'}";}
    if (my $cloudsettings->{'CloudMirrorD'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorD'}";}
    if (my $cloudsettings->{'CloudMirrorE'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorE'}";}
    if (my $cloudsettings->{'CloudMirrorF'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorF'}";}
    if (my $cloudsettings->{'CloudMirrorG'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorG'}";}
    if (my $cloudsettings->{'CloudMirrorH'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorH'}";}
    if (my $cloudsettings->{'CloudMirrorI'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorI'}";}
    if (my $cloudsettings->{'CloudMirrorJ'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorJ'}";}
    if (my $cloudsettings->{'CloudMirrorK'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorK'}";}
    if (my $cloudsettings->{'CloudMirrorL'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorL'}";}
    if (my $cloudsettings->{'CloudMirrorM'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorM'}";}
    if (my $cloudsettings->{'CloudMirrorN'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorN'}";}
    
    # Return one at random
    return $Mirrors[rand scalar(@Mirrors)];
}

# $browser->credentials(
#     #http://www.xplanetclouds.com/clouds/4096/clouds_clouds_4096.jpg
#     #http://www.xplanetclouds.com/clouds/4096/clouds_clouds_2048.jpg
#     '$site:80',
#     'www.xplanetclouds.com',
#     'maxsendq' => 'wh0tugot'
# );

# sub get_store () {
#     my ($file)=@_;
#     my $gif_URL="http://www.wizabit.eclipse.co.uk/xplanet/files/local/images/$file";
#     my ($name,$ext) = split '\.',$file,2;
#     my $outfile= "$xplanet_images_dir/$file";
#
#     $content = get_webpage($gif_URL );
#     if ($content eq undef) {}
#     else {
#         open(IMAGE,">$outfile")
#         binmode IMAGE;
#         print IMAGE $content;
#         close (IMAGE);
#     }
# }

#sub file_header($) {
#    my ($openfile) = @_;
#    print MF "# This $openfile marker file created by $Script - $Client version $VERSION\n";
#    print MF "# For more information read the top of the $Script file or go to\n";
#    print MF "# http://www.wizabit.eclipse.co.uk/xplanet\n";
#    my $tsn = localtime(time);
#    print MF "# Last Updated: $tsn\n#\n";
#}


sub get_file() {
    my ($file)=@_;
    my $gif_URL="http://www.wizabit.eclipse.co.uk/xplanet/files/local/images/$file";
    my ($name,$ext) = split '\.',$file,2;
    my $outfile= "$xplanet_images_dir/$file";
    
    my $content = get_webpage($gif_URL );
    
    if ($content eq undef) {}
    else {
        open(IMAGE,">$outfile");
        binmode IMAGE;
        print IMAGE $content;
        close (IMAGE);
    }
}


sub make_directory() {
    my ($target)=@_;
    
    -f $target && return 0;
    -d $target && return 1;
    
    my ($volume,$directories,$file) = File::Spec->splitpath( $target );
    $directories = File::Spec->catfile($directories,$file);
    $file="";
    
    my @dirs = File::Spec->splitdir( $directories );
    my @these_dirs = ();
    
    foreach(@dirs) {
        push @these_dirs,$_;
        my $dir = File::Spec->catpath( $volume, File::Spec->catfile( @these_dirs, $file), $file);
        
        if (!-d $dir) {
            print "Making Directory $dir\n";
            mkdir($dir) || return 0;
        }
    }
    
    return 1;
}

#sub num_of_month($) {
#    my ($text_month) = @_;
#    if ($text_month =~ /Jan/)   {return 0;}
#    if ($text_month =~ /Feb/)   {return 1;}
#    if ($text_month =~ /March/) {return 2;}
#    if ($text_month =~ /April/) {return 3;}
#    if ($text_month =~ /May/)   {return 4;}
#    if ($text_month =~ /June/)  {return 5;}
#    if ($text_month =~ /July/)  {return 6;}
#    if ($text_month =~ /Aug/)   {return 7;}
#    if ($text_month =~ /Sept/)  {return 8;}
#    if ($text_month =~ /Oct/)   {return 9;}
#    if ($text_month =~ /Nov/)   {return 10;}
#    if ($text_month =~ /Dec/)   {return 11;}
#}

sub boundschecking() {
    my ($value) = @_;
    
    if ($value >= 1) {$value = 1;}
    # if ($value == 0) {$value = FAILED;}
    
    return ($value);
}


#my $storm_base_location = "http://www.nrlmry.navy.mil/tcdat/sectors/ftp_sector_file";
#my $storm_past_location = "http://www.nrlmry.navy.mil/archdat/test/kml/TC/2011/ATL/12L/trackfile.txt";
#my $storm_future_location = "http://www.nrlmry.navy.mil/atcf_web/docs/current_storms/al122011.tcw";

sub get_hurricane_data_count {
    my $hurricane_counter = 0;
    my $hurricanetxt;
    my $sign;
    my $year;
    my $type;
    my $ocean;
    my $file;
    my $hurricanetotallist;
    my @hurricanearcdataact;
    my @hurricanearcdatafor;
    my @hurricanedata;
    
    $hurricanetotallist = get_webpage($storm_base_location);
    
    if ($hurricanetxt !~ /FAILED/) {
        foreach (split("\n",$hurricanetotallist)) {
            if (/([\d\w]+)\s(\w+)\s(\d+)\s(\d+)\s+([\d\-\.NS]+)\s+([\d\-\.EW]+)\s(\w+)\s+(\d+)\s+(\d+)/) {
                my($code,$name,$date,$time,$lat,$long,$location,$speed,$detail)=($1,$2,$3,$4,$5,$6,$7,$8,$9);
                if ($lat =~ /(\d+\.\d+)([NS])/) {
                    ($lat,$sign)=($1,$2);
                    $lat *= -1 if $sign =~ /s/i;
                }
                $lat *= 1;
                
                if ($long =~ /(\d+\.\d+)([WE])/) {
                    ($long,$sign)=($1,$2);
                    $long *= -1 if $sign =~ /w/i;
                }
                $long *= 1;
                $speed =~ s/^0+//;
                
                if ($name =~ /INVEST/) {
                    $type = "DEP";
                    $name = $code;
                }
                else {
                    $type = "STO";
                }
                
                $year = "20".substr $date,0,2;
                
                if ($location =~ /ATL/) {
                    $ocean = "al";
                }
                elsif ($location =~ /WPAC/) {
                    $ocean = "wp";
                }
                elsif ($location =~ /EPAC/) {
                    $ocean = "ep";
                }
                elsif ($location =~ /CPAC/) {
                    $ocean = "cp";
                }
                
                push @hurricanedata, {
                    'type'  => $type,
                    'file'  => $file,
                    'name'  => $name,
                    'lat'   => $lat,
                    'long'  => $long,
                    'speed' => $speed,
                    'code'  => $code,
                    'year'  => $year,
                    'ocean' => $ocean,
                    'loc'   => $location,
                };
            }
            
            $hurricane_counter++;
        }
        
        if ($hurricane_counter == 0) {
            print "  ERROR (-1)?... Unable to parse storm information\n";
            return -1;
        }
        else {
            print "  Updated storm information\n";
            return $hurricane_counter;
        }
    }
    else {
        print "  WARNING... unable to access or download updated storm information\n";
        return $hurricanetxt;
    }
}


sub install_marker() {
    my ($version,$type) = @_;
    my @inilines;
    my @inivalue;
    my $oldversionnumber;
    my $newversionnumber;

    
    print "install_marker\nVersion = $version\nType = $type\n";
    open (MF, "<$winXPlanetBG");
    
    my $counter = 1;
    my $recounter = 1;
    
    #read in ini file
    while (<MF>)  {
        s/\n//;
        ($inilines[$counter], $inivalue[$counter]) = split ("=");
        $counter ++;
    }
    
    close (MF);
    
    #write out backup file.
    open (MF, ">$winxplanetbgbackup");
    while ($recounter < $counter) {
        print MF "$inilines[$counter]=$inivalue[$counter]\n";
        $recounter++;
    }
    
    $recounter = 1;
    if ($type =~ /cloud/) {
        open (MF, ">$cloudbatch");
        print MF "\@echo off\ntotalmarker.exe -clouds\n";
        close MF;
        
        while ($recounter < $counter) {
            #Execute File after download=1
            #File after download=C:\Xplanet\updateclouds.bat
            if ($inilines[$recounter] =~ /Execute File after download/) {
                $inivalue[$recounter] = 1;
            }
            
            if ($inilines[$recounter] =~ /File after download/) {
                $inivalue[$recounter] = $cloudbatch;
            }
            
            $recounter++;
        }
        
        $recounter = 1;
    }
    elsif ($version <= $oldversionnumber) {
        print "old version\n";
    }
    else {
        print "The New version isn't out of beta and isn't supported here yet.\n";
    }
    
    open (MF, ">$winXPlanetBG");
    $recounter = 1;
    
    #Write the new .ini file
    while ($recounter < $counter) {
        print MF "$inilines[$recounter]=$inivalue[$recounter]\n";
        $recounter++;
    }
}

sub install() {
    my ($flag) =@_;
    
    my $oldversionnumber = 0.94;
    my $newversionnumber = 0.95;
    if ($flag =~ /eclipsfile/) {
        my $test = &make_directory($xplanet_config_dir);
        
        if ($test == 0) {
            print "Can't write settings file, directory xplanet/config does exist and can't be created.\n";
            exit 1;
            die;
        }
        
        if (-e $eclipse_old_data_file) {
            copy ("$eclipse_old_data_file","$eclipse_data_file");
            unlink $eclipse_old_data_file;
        }
        else {
            &get_eclipsedata;
        }
        
        &get_it_right_lamer;
    }
    elsif ($flag =~ /configfile/) {
        my $test = &make_directory($xplanet_config_dir);
        
        if ($test == 0) {
            print "Can't write settings file, directory xplanet/config does exist and can't be created.\n";
            exit 1;
            die;
        }
        
        if (-e $settings_old_ini_file) {
            copy ("$settings_old_ini_file","$settings_ini_file");
            unlink $settings_old_ini_file;
        }
        else {
            print "\nInstalling Files Needed to Run\n";
            open (MF, ">$settings_ini_file");
            print MF "\#Totalmarker ini file\n\#\n\#Leaving the options blank will make the option unused.\n\#See http://www.wizabit.eclipse.co.uk/xplanet/pages/TotalMarker.html for details of this file\n#Config File Written by TotalMarker version $VERSION\n";
            print MF "\#\n\#QUAKE\n\#\nQuakeDetailColorMin=Green\nQuakeDetailColorInt=Yellow\nQuakeDetailColorMax=Red\nQuakeDetailAlign=Above\nQuakeCircleColor=Multi\nQuakePixelMax=\nQuakePixelMin=\nQuakePixelFactor=1\nQuakeImageList=\nQuakeImageTransparent=\nQuakeDetailList=<mag>\nQuakeDetailColor=Multi\nQuakeMinimumSize=0\n";
            print MF "\#\n\#VOLCANO\n\#\nVolcanoCircleSizeInner=4\nVolcanoCircleSizeMiddle=8\nVolcanoCircleSizeOuter=12\nVolcanoCircleColorInner=Yellow\nVolcanoCircleColorMiddle=Red\nVolcanoCircleColorOuter=Brown\nVolcanoNameOnOff=On\nVolcanoNameColor=Brown\nVolcanoNameAlign=Below\nVolcanoImageList=\nVolcanoImageTransparent=\nVolcanoDetailList=\nVolcanoDetailAlign=\nVolcanoDetailColor=\n";
            print MF "\#\n#STORMS\n\#\nStormColorTrackReal=Blue\nStormColorTrackPrediction=SkyBlue\nStormNameOnOff=On\nStormColorName=SkyBlue\nStormAlignName=Above\nStormDetailList=<type>\nStormColorDetail=SkyBlue\nStormAlignDetail=Below\nStormImageList=\nStormImageTransparent=\nStormTrackOnOff=On\n";
            print MF "\#\n\#ECLIPSE\n\#\nEclipseOnOff=On\nEclipseNotifyOnOff=On\nEclipseNotifyTimeHours=48\n";
            print MF "\#\n\#NORAD\n\#\nNoradIssImage=iss.png\nNoradIssText=\nNoradIssDetail=transparent={0,0,0} trail={orbit,-5,0,5} color=yellow altcirc=0 trail={orbit,-10,0,5}\nNoradIssOnOff=On\nNoradHstImage=hst.png\nNoradHstText=\nNoradHstDetail=transparent={0,0,0}\nNoradHstOnOff=On\nNoradSoyuzImage=Soyuz.png\nNoradSoyuzText=\nNoradSoyuzDetail=transparent={0,0,0}\nNoradSoyuzOnOff=On\nNoradStsImage=sts.png\nNoradStsText=\nNoradStsDetail=transparent={0,0,0}\nNoradStsOnOff=On\nNoradSatImage=sat.png\nNoradSatText=\nNoradSatDetail=transparent={0,0,0}\nNoradSatOnOff=On\nNoradMiscOnOff=Off\nNoradTleNumbers=\nNoradMiscDetail=\nNoradFileName=tm\n";
            print MF "\#\n\#LABELUPDATE\n\#\nLabelOnOff=On\nLabelWarningQuake=84600\nLabelWarningVolcano=604800\nLabelWarningStorm=86400\nLabelWarningNorad=604800\nLabelWarningCloud=21600\nLabelColorOk=Green\nLabelColorWarn=Yellow\nLabelColorError=Red\n";
            close MF;
            &update_ini_file;
            print "Done!\n";
        }
        
        &get_it_right_lamer;
    }
    elsif ($flag =~ /storm/) {
        my $xplanetversion = &get_program_version();
        
        if ($xplanetversion =~ /(\d.\d\d)(\w)/) {
            my ($pversion,$prevision) = ($1,$2);
            
            $pversion *= 1;
            if ($pversion < 0.95) {
                &install_marker($oldversionnumber,$flag);
            }
            else {
                &install_marker($newversionnumber,$flag);
            }
            
            print "Storm\nXplanet Version = $pversion, Revision = $prevision:\n";
        }
    }
    elsif ($flag =~ /quake/) {
        my $xplanetversion = &get_program_version();
    
        if ($xplanetversion =~ /(\d.\d\d)(\w)/) {
            my ($pversion, $prevision) = ($1, $2);
        
            $pversion *= 1;
            if ($pversion < 0.93) {
             print "The Version of Xplanet won't support Earthquakes, please Upgrade to 0.93d or better\n";
            }
            elsif ($pversion == 0.93) {
                if (ord($prevision) < ord('d')) {
                    print "The Version of Xplanet won't support Earthquakes, please Upgrade to 0.93d or better\n";
                }
            }
            elsif ($pversion < 0.95) {
                &install_marker($oldversionnumber, $flag);
            }
            else {
                &install_marker($newversionnumber, $flag);
            }
        
            print "Earthquakes\nXplanet Version = $pversion, Revision = $prevision:\n";
        }
    }
    elsif ($flag =~ /norad/) {
        my $xplanetversion = &get_program_version();
        
        if ($xplanetversion =~ /(\d.\d\d)(\w)/) {
            my ($pversion,$prevision) = ($1,$2);
            
            $pversion *= 1;
            if ($pversion < 0.95) {
                &install_marker($oldversionnumber,$flag);
            }
            else {
                &install_marker($newversionnumber,$flag);
            }
            
            print "NORAD\nXplanet Version = $pversion, Revision = $prevision:\n";
        }
    }
    elsif ($flag =~ /cloud/) {
        if (-e $winXPlanetBG) {
            &install_marker($newversionnumber,$flag);
        }
        else {
            print "winXPlanetBG not Found\nStopping\nTo Install Clouds winXPlanetBG must be installed\n";
            exit 1;
            die;
        }
        
        print "Clouds\n";
    }
    elsif ($flag =~ /volcano/) {
        my $xplanetversion = &get_program_version();
        
        if ($xplanetversion =~ /(\d.\d\d)(\w)/) {
            my ($pversion,$prevision) = ($1,$2);
            
            $pversion *= 1;
            if ($pversion < 0.95) {
                &install_marker($oldversionnumber,$flag);
            }
            else {
                &install_marker($newversionnumber,$flag);
            }
            
            print "Volcano\nXplanet Version = $pversion, Revision = $prevision:\n";
        }
    }
    elsif ($flag =~ /eclipse/) {
        my $xplanetversion = &get_program_version();
        
        if ($xplanetversion =~ /(\d.\d\d)(\w)/) {
            my ($pversion,$prevision) = ($1,$2);
            
            $pversion *= 1;
            if ($pversion < 0.95) {
                &install_marker($oldversionnumber,$flag);
            }
            else {
                &install_marker($newversionnumber,$flag);
            }
            
            print "Eclipse\nXplanet Version = $pversion, Revision = $prevision:\n";
        }
    }
    elsif ($flag =~ /updatelabel/) {
        my $xplanetversion = &get_program_version();
        
        if ($xplanetversion =~ /(\d.\d\d)(\w)/) {
            my ($pversion,$prevision) = ($1,$2);
            
            $pversion *= 1;
            if ($pversion < 0.95) {
                &install_marker($oldversionnumber,$flag);
            }
            else {
                &install_marker($newversionnumber,$flag);
            }
            
            print "UpdateLabel\nXplanet Version = $pversion, Revision = $prevision:\n";
        }
    }
    elsif ($flag =~ /totalmarker/) {
        my $oldversion = "1.03.1";
        my $xplanetversion = &get_program_version();
        my $result = shift @ARGV;
        
        if ($result =~ /Update/ || $result =~ /update/ || $result =~ /patch/ || $result =~ /Patch/) {
            print "Updating TotalMarker Settings to $VERSION settings.\n";
            print "xplanet = $xplanetversion\;totalmarker\n";
            &update_ini_file;
        }
        else {
    open (MF, "<$settings_ini_file") or die "Could not open file '$settings_ini_file' $!";
    while (<MF>) {
        foreach (split "\n") {
            if ($_ =~ /Config File Written by/) {
                my ($tmp1, $tmp2, $tmp3, $tmp4, $tmp5, $tmp6, $tmp7) = split " ";
                $oldversion = $tmp7;
            }
        }
    }
    close(MF);
    }
    
    my $installed = 1;
}

sub update_ini_file() {
    my $volcanosettings;
    my $stormsettings;
    my $labelsettings;
    my $cloudsettings;
    my @volcanodata;

    &get_settings;
    print "\nUpgrading Totalmarker.ini File to Latest Version.\n";
    open (MF, ">$settings_ini_file");
    print MF "\#Totalmarker ini file\n\#\n\#Leaving the options blank will make the option unused.\n\#See http://www.wizabit.eclipse.co.uk/xplanet/pages/TotalMarker.html for details of this file\n#Config File Written by TotalMarker version $VERSION\n";
    
    # QUAKE
    print MF "\#\n\#QUAKE\n\#\nQuakeDetailColorMin=";
    if ($quakesettings->{'QuakeDetailColorMin'} =~ /\w/)                        {print MF "$quakesettings->{'QuakeDetailColorMin'}";}
    else {print MF "Green";}
    
    print MF "\nQuakeDetailColorInt=";
    if ($quakesettings->{'QuakeDetailColorInt'} =~ /\w/)                        {print MF "$quakesettings->{'QuakeDetailColorInt'}";}
    else {print MF "Yellow";}
    
    print MF "\nQuakeDetailColorMax=";
    if ($quakesettings->{'QuakeDetailColorMax'} =~ /\w/)                        {print MF "$quakesettings->{'QuakeDetailColorMax'}";}
    else {print MF "Red";}
    
    print MF "\nQuakeDetailAlign=";
    if ($quakesettings->{'QuakeDetailAlign'} =~ /\w/)                           {print MF "$quakesettings->{'QuakeDetailAlign'}";}
    else {print MF "Above";}
    
    print MF "\nQuakeCircleColor=";
    if ($quakesettings->{'QuakeCircleColor'} =~ /\w/)                           {print MF "$quakesettings->{'QuakeCircleColor'}";}
    else {print MF "Multi";}
    
    print MF "\nQuakePixelMax=";
    if ($quakesettings->{'QuakePixelMax'} =~ /\w/)                              {print MF "$quakesettings->{'QuakePixelMax'}";}
    else {print MF "";}
    
    print MF "\nQuakePixelMin=";
    if ($quakesettings->{'QuakePixelMin'} =~ /\w/)                              {print MF "$quakesettings->{'QuakePixelMin'}";}
    else {print MF "";}
    
    print MF "\nQuakePixelFactor=";
    if ($quakesettings->{'QuakePixelFactor'} =~ /\w/)                           {print MF "$quakesettings->{'QuakePixelFactor'}";}
    else {print MF "1";}
    
    print MF "\nQuakeImageList=";
    if ($quakesettings->{'QuakeImageList'} =~ /\w/)                             {print MF "$quakesettings->{'QuakeImageList'}";}
    else {print MF "";}
    
    print MF "\nQuakeImageTransparent=";
    if ($quakesettings->{'QuakeImageTransparent'} =~ /\w/)                      {print MF "$quakesettings->{'QuakeImageTransparent'}";}
    else {print MF "";}
    
    print MF "\nQuakeDetailList=";
    if ($quakesettings->{'QuakeDetailList'} =~ /\w/)                            {print MF "$quakesettings->{'QuakeDetailList'}";}
    else {print MF "<mag>";}
    
    print MF "\nQuakeDetailColor=";
    if ($quakesettings->{'QuakeDetailColour'} =~ /\w/)                          {print MF "$quakesettings->{'QuakeDetailColour'}";}
    else {print MF "Multi";}
    
    print MF "\nQuakeMinimumSize=";
    if ($quakesettings->{'QuakeMinimumSize'} =~ /\w/)                           {print MF "$quakesettings->{'QuakeMinimumSize'}";}
    else {print MF "0";}
    
    print MF "\nQuakeReportingDuration=";
    if ($quakesettings->{'QuakeReportingDuration'} =~ /\w/)                     {print MF "$quakesettings->{'QuakeReportingDuration'}";}
    else {print MF "Week";}
    
    print MF "\nQuakeReportingSize=";
    if ($quakesettings->{'QuakeReportingSize'} =~ /\w/)                         {print MF "$quakesettings->{'QuakeReportingSize'}";}
    else {print MF "All";}
    
    print MF "\nQuakeFade=";
    if ($quakesettings->{'QuakeFade'} =~ /\w/)                                  {print MF "$quakesettings->{'QuakeFade'}";}
    else {print MF "On";}
    
    # VOLCANO
    print MF "\n\#\n\#VOLCANO\n\#";
    
    print MF "\nVolcanoCircleSizeInner=";
    if ($volcanosettings->{'VolcanoCircleSizeInner'} =~ /\w/)                   {print MF "$volcanosettings->{'VolcanoCircleSizeInner'}";}
    else {print MF "4";}
    
    print MF "\nVolcanoCircleSizeMiddle=";
    if ($volcanosettings->{'VolcanoCircleSizeMiddle'} =~ /\w/)                  {print MF "$volcanosettings->{'VolcanoCircleSizeMiddle'}";}
    else {print MF "8";}
    
    print MF "\nVolcanoCircleSizeOuter=";
    if ($volcanosettings->{'VolcanoCircleSizeOuter'} =~ /\w/)                   {print MF "$volcanosettings->{'VolcanoCircleSizeOuter'}";}
    else {print MF "12";}
    
    print MF "\nVolcanoCircleColorInner=";
    if ($volcanosettings->{'VolcanoCircleColorInner'} =~ /\w/)                  {print MF "$volcanosettings->{'VolcanoCircleColorInner'}";}
    else {print MF "Yellow";}
    
    print MF "\nVolcanoCircleColorMiddle=";
    if ($volcanosettings->{'VolcanoCircleColorMiddle'} =~ /\w/)                 {print MF "$volcanosettings->{'VolcanoCircleColorMiddle'}";}
    else {print MF "Red";}
    
    print MF "\nVolcanoCircleColorOuter=";
    if ($volcanosettings->{'VolcanoCircleColorOuter'} =~ /\w/)                  {print MF "$volcanosettings->{'VolcanoCircleColorOuter'}";}
    else {print MF "Brown";}
    
    print MF "\nVolcanoNameOnOff=";
    if ($volcanosettings->{'VolcanoNameOnOff'} =~ /\w/)                         {print MF "$volcanosettings->{'VolcanoNameOnOff'}";}
    else {print MF "On";}
    
    print MF "\nVolcanoNameColor=";
    if ($volcanosettings->{'VolcanoNameColor'} =~ /\w/)                         {print MF "$volcanosettings->{'VolcanoNameColor'}";}
    else {print MF "Brown";}
    
    print MF "\nVolcanoNameAlign=";
    if ($volcanosettings->{'VolcanoNameAlign'} =~ /\w/)                         {print MF "$volcanosettings->{'VolcanoNameAlign'}";}
    else {print MF "Below";}
    
    print MF "\nVolcanoImageList=";
    if ($volcanosettings->{'VolcanoImageList'} =~ /\w/)                         {print MF "$volcanosettings->{'VolcanoImageList'}";}
    else {print MF "";}
    
    print MF "\nVolcanoImageTransparent=";
    if ($volcanosettings->{'VolcanoImageTransparent'} =~ /\w/)                  {print MF "$volcanosettings->{'VolcanoImageTransparent'}";}
    else {print MF "";}
    
    print MF "\nVolcanoDetailList=";
    if ($volcanosettings->{'VolcanoDetailList'} =~ /\w/)                        {print MF "$volcanosettings->{'VolcanoDetailList'}";}
    else {print MF "";}
    
    print MF "\nVolcanoDetailAlign=";
    if ($volcanosettings->{'VolcanoDetailAlign'} =~ /\w/)                       {print MF "$volcanosettings->{'VolcanoDetailAlign'}";}
    else {print MF "";}
    
    print MF "\nVolcanoDetailColor=";
    if ($volcanosettings->{'VolcanoDetailColor'} =~ /\w/)                       {print MF "$volcanosettings->{'VolcanoDetailColor'}";}
    else {print MF "";}

    # STORMS    
    print MF "\n\#\n#STORMS\n\#";
    
    print MF "\nStormColorTrackReal=";
    if ($stormsettings->{'StormColorTrackReal'} =~ /\w/)                        {print MF "$stormsettings->{'StormColorTrackReal'}";}
    else {print MF "Blue";}
    
    print MF "\nStormColorTrackPrediction=";
    if ($stormsettings->{'StormColorTrackPrediction'} =~ /\w/)                  {print MF "$stormsettings->{'StormColorTrackPrediction'}";}
    else {print MF "SkyBlue";}
    
    print MF "\nStormNameOnOff=";
    if ($stormsettings->{'StormNameOnOff'} =~ /\w/)                             {print MF "$stormsettings->{'StormNameOnOff'}";}
    else {print MF "On";}
    
    print MF "\nStormColorName=";
    if ($stormsettings->{'StormColorName'} =~ /\w/)                             {print MF "$stormsettings->{'StormColorName'}";}
    else {print MF "SkyBlue";}
    
    print MF "\nStormAlignName=";
    if ($stormsettings->{'StormAlignName'} =~ /\w/)                             {print MF "$stormsettings->{'StormAlignName'}";}
    else {print MF "Above";}
    
    print MF "\nStormAlignDetail=";
    if ($stormsettings->{'StormAlignDetail'} =~ /\w/)                           {print MF "$stormsettings->{'StormAlignDetail'}";}
    else {print MF "Below";}
    
    print MF "\nStormDetailList=";
    if ($stormsettings->{'StormDetailList'} =~ /\w/)                            {print MF "$stormsettings->{'StormDetailList'}";}
    else {print MF "<type>";}
    
    print MF "\nStormColorDetail=";
    if ($stormsettings->{'StormColorDetail'} =~ /\w/)                           {print MF "$stormsettings->{'StormColorDetail'}";}
    else {print MF "SkyBlue";}
    
    print MF "\nStormImageList=";
    if ($stormsettings->{'StormImageList'} =~ /\w/)                             {print MF "$stormsettings->{'StormImageList'}";}
    else {print MF "";}
    
    print MF "\nStormImageTransparent=";
    if ($stormsettings->{'StormImageTransparent'} =~ /\w/)                      {print MF "$stormsettings->{'StormImageTransparent'}";}
    else {print MF "";}
    
    print MF "\nStormTrackOnOff=";
    if ($stormsettings->{'StormTrackOnOff'} =~ /\w/)                            {print MF "$stormsettings->{'StormTrackOnOff'}";}
    else {print MF "On";}
    
    # ECLIPSE
    print MF "\n\#\n\#ECLIPSE\n\#";
    
    print MF "\nEclipseOnOff=";
    if ($settings->{'EclipseOnOff'} =~ /\w/)                                    {print MF "$settings->{'EclipseOnOff'}";}
    else {print MF "On";}
    
    print MF "\nEclipseNotifyOnOff=";
    if ($settings->{'EclipseNotifyOnOff'} =~ /\w/)                              {print MF "$settings->{'EclipseNotifyOnOff'}";}
    else {print MF "On";}
    
    print MF "\nEclipseNotifyTimeHours=";
    if ($settings->{'EclipseNotifyTimeHours'} =~ /\w/)                          {print MF "$settings->{'EclipseNotifyTimeHours'}";}
    else {print MF "48";}
    
    # NORAD
    print MF "\n\#\n\#NORAD\n\#";
    
    print MF "\nNoradIssImage=";
    if ($noradsettings->{'NoradIssImage'} =~ /\w/)                              {print MF "$noradsettings->{'NoradIssImage'}";}
    else {print MF "iss.png";}
    
    print MF "\nNoradIssText=";
    if ($noradsettings->{'NoradIssText'} =~ /\w/)                               {print MF "$noradsettings->{'NoradIssText'}";}
    else {print MF "";}
    
    print MF "\nNoradIssDetail=";
    if ($noradsettings->{'NoradIssDetail'} =~ /\w/)                             {print MF "$noradsettings->{'NoradIssDetail'}";}
    else {print MF "transparent={0,0,0} trail={orbit,-5,0,5} color=yellow altcirc=0 trail={orbit,-10,0,5}";}
    
    print MF "\nNoradIssOnOff=";
    if ($noradsettings->{'NoradIssOnOff'} =~ /\w/)                              {print MF "$noradsettings->{'NoradIssOnOff'}";}
    else {print MF "On";}
    
    print MF "\nNoradHstImage=";
    if ($noradsettings->{'NoradHstImage'} =~ /\w/)                              {print MF "$noradsettings->{'NoradHstImage'}";}
    else {print MF "hst.png";}
    
    print MF "\nNoradHstText=";
    if ($noradsettings->{'NoradHstText'} =~ /\w/)                               {print MF "$noradsettings->{'NoradHstText'}";}
    else {print MF "";}
    
    print MF "\nNoradHstDetail=";
    if ($noradsettings->{'NoradHstDetail'} =~ /\w/)                             {print MF "$noradsettings->{'NoradHstDetail'}";}
    else {print MF "transparent={0,0,0}";}
    
    print MF "\nNoradHstOnOff=";
    if ($noradsettings->{'NoradHstOnOff'} =~ /\w/)                              {print MF "$noradsettings->{'NoradHstOnOff'}";}
    else {print MF "On";}

    print MF "\nNoradSoyuzImage=";
    if ($noradsettings->{'NoradSoyuzImage'} =~ /\w/)                            {print MF "$noradsettings->{'NoradSoyuzImage'}";}
    else {print MF "soyuz.png";}
    
    print MF "\nNoradSoyuzText=";
    if ($noradsettings->{'NoradSoyuzText'} =~ /\w/)                             {print MF "$noradsettings->{'NoradSoyuzText'}";}
    else {print MF "";}
    
    print MF "\nNoradSoyuzDetail=";
    if ($noradsettings->{'NoradSoyuzDetail'} =~ /\w/)                           {print MF "$noradsettings->{'NoradSoyuzDetail'}";}
    else {print MF "transparent={0,0,0}";}
    
    print MF "\nNoradSoyuzOnOff=";
    if ($noradsettings->{'NoradSoyuzOnOff'} =~ /\w/)                            {print MF "$noradsettings->{'NoradSoyuzOnOff'}";}
    else {print MF "On";}
    
    print MF "\nNoradStsImage=";
    if ($noradsettings->{'NoradStsImage'} =~ /\w/)                              {print MF "$noradsettings->{'NoradStsImage'}";}
    else {print MF "sts.png";}
    
    print MF "\nNoradStsText=";
    if ($noradsettings->{'NoradStsText'} =~ /\w/)                               {print MF "$noradsettings->{'NoradStsText'}";}
    else {print MF "";}
    
    print MF "\nNoradStsDetail=";
    if ($noradsettings->{'NoradStsDetail'} =~ /\w/)                             {print MF "$noradsettings->{'NoradStsDetail'}";}
    else {print MF "transparent={0,0,0}";}
    
    print MF "\nNoradStsOnOff=";
    if ($noradsettings->{'NoradStsOnOff'} =~ /\w/)                              {print MF "$noradsettings->{'NoradStsOnOff'}";}
    else {print MF "On";}
    
    print MF "\nNoradSatImage=";
    if ($noradsettings->{'NoradSatImage'} =~ /\w/)                              {print MF "$noradsettings->{'NoradSatImage'}";}
    else {print MF "sts.png";}
    
    print MF "\nNoradSatText=";
    if ($noradsettings->{'NoradSatText'} =~ /\w/)                               {print MF "$noradsettings->{'NoradSatText'}";}
    else {print MF "";}
    
    print MF "\nNoradSatDetail=";
    if ($noradsettings->{'NoradSatDetail'} =~ /\w/)                             {print MF "$noradsettings->{'NoradSatDetail'}";}
    else {print MF "transparent={0,0,0}";}
    
    print MF "\nNoradSatOnOff=";
    if ($noradsettings->{'NoradSatOnOff'} =~ /\w/)                              {print MF "$noradsettings->{'NoradSatOnOff'}";}
    else {print MF "On";}
    
    print MF "\nNoradMiscOnOff=";
    if ($noradsettings->{'NoradMiscOnOff'} =~ /\w/)                             {print MF "$noradsettings->{'NoradMiscOnOff'}";}
    else {print MF "Off";}
    
    print MF "\nNoradTleNumbers=";
    if ($noradsettings->{'NoradTleNumbers'} =~ /\w/)                            {print MF "$noradsettings->{'NoradTleNumbers'}";}
    else {print MF "";}
    
    print MF "\nNoradMiscDetail=";
    if ($noradsettings->{'NoradMiscDetail'} =~ /\w/)                            {print MF "$noradsettings->{'NoradMiscDetail'}";}
    else {print MF "";}
    
    print MF "\nNoradFileName=";
    if ($noradsettings->{'NoradFileName'} =~ /\w/)                              {print MF "$noradsettings->{'NoradFileName'}";}
    else {print MF "tm";}
    
    # LABEL
    print MF "\n\#\n\#LABELUPDATE\n\#";
    
    print MF "\nLabelOnOff=";
    if ($labelsettings->{'LabelOnOff'} =~ /\w/)                                 {print MF "$labelsettings->{'LabelOnOff'}";}
    else {print MF "On";}
    
    print MF "\nLabelWarningQuake=";
    if ($labelsettings->{'LabelWarningQuake'} =~ /\w/)                          {print MF "$labelsettings->{'LabelWarningQuake'}";}
    else {print MF "84600";}
    
    print MF "\nLabelWarningVolcano=";
    if ($labelsettings->{'LabelWarningVolcano'} =~ /\w/)                        {print MF "$labelsettings->{'LabelWarningVolcano'}";}
    else {print MF "604800";}
    
    print MF "\nLabelWarningStorm=";
    if ($labelsettings->{'LabelWarningStorm'} =~ /\w/)                          {print MF "$labelsettings->{'LabelWarningStorm'}";}
    else {print MF "84600";}
    
    print MF "\nLabelWarningNorad=";
    if ($labelsettings->{'LabelWarningNorad'} =~ /\w/)                          {print MF "$labelsettings->{'LabelWarningNorad'}";}
    else {print MF "604800";}
    
    print MF "\nLabelWarningCloud=";
    if ($labelsettings->{'LabelWarningCloud'} =~ /\w/)                          {print MF "$labelsettings->{'LabelWarningCloud'}";}
    else {print MF "21600";}
    
    print MF "\nLabelColorOk=";
    if ($labelsettings->{'LabelColorOk'} =~ /\w/)                               {print MF "$labelsettings->{'LabelColorOk'}";}
    else {print MF "Green";}
    
    print MF "\nLabelColorWarn=";
    if ($labelsettings->{'LabelColorWarn'} =~ /\w/)                             {print MF "$labelsettings->{'LabelColorWarn'}";}
    else {print MF "Yellow";}
    
    print MF "\nLabelColorError=";
    if ($labelsettings->{'LabelColorError'} =~ /\w/)                            {print MF "$labelsettings->{'LabelColorError'}";}
    else {print MF "Red";}	
    
    # CLOUDS
    print MF "\n\#\n\#CLOUDS\n\#";
    
    print MF "\nCloudRemoteImageName=";
    if ($cloudsettings->{'CloudRemoteImageName'} =~ /\w/)                       {print MF "$cloudsettings->{'CloudRemoteImageName'}";}
    else {print MF "clouds_2048.jpg";}
    
    print MF "\nCloudLocalImageName=";
    if ($cloudsettings->{'CloudLocalImageName'} =~ /\w/)                        {print MF "$cloudsettings->{'CloudLocalImageName'}";}
    else {print MF "clouds_2048.jpg";}
    
    print MF "\nUseFreeCloudImage=";
    if ($cloudsettings->{'UseFreeCloudImage'} =~ /\w/)                          {print MF "$cloudsettings->{'UseFreeCloudImage'}";}
    else {print MF "Yes";}
    
    print MF "\nSubcribedToXplanetClouds=";
    if ($cloudsettings->{'SubcribedToXplanetClouds'} =~ /\w/)                   {print MF "$cloudsettings->{'SubcribedToXplanetClouds'}";}
    else {print MF "No";}
    
    print MF "\nUsername=";
    if ($cloudsettings->{'Username'} =~ /\w/)                                   {print MF "$cloudsettings->{'Username'}";}
    else {print MF "";}
    
    print MF "\nPassword=";
    if ($cloudsettings->{'Password'} =~ /\w/)                                   {print MF "$cloudsettings->{'Password'}";}
    else {print MF "";}
    
    print MF "\nDirectDownload=";
    if ($cloudsettings->{'DirectDownload'} =~ /\w/)                             {print MF "$cloudsettings->{'DirectDownload'}";}
    else {print MF "";}
    
    # MISC	
    print MF "\n\#\n\#MISC\n\#";
    
    print MF "\nEasterEggSurprises=";
    if ($settings->{'EasterEggSurprises'} =~ /\w/)                               {print MF "settings->{'EasterEggSurprises'}";}
    else {print MF "1";}
    
    print MF "\nMiscXplanetVersion1OrBetter=";
    if ($settings->{'XplanetVersion'} =~ /\w/)                                  {print MF "$settings->{'XplanetVersion'}";}
    else {print MF "Yes";}
    
    close MF;
    print "Ini File updated to lastest version.\n";
}



sub get_settings () {
    my $volcanosettings;
    my $stormsettings;
    my $labelsettings;
    my $cloudsettings;
    my $mon;
    my $mday;

    open (MF, "<$settings_ini_file");
    while (<MF>) {
        foreach (split "\n") {
            my ($setting,$result) = split "=",$_,2;
            s/([a-z])([A-Z])/$1:$2/g;
            my ($data1,$tmp1) = split ":",$_,2;
            #print "Setting = $setting, Result = $result, Data1 = $data1, Tmp1 = $tmp1\n";
            
            if ($data1 =~ /Quake/) {
                if ($setting =~ /QuakeDetailColorMin/) {$quakesettings->{'QuakeDetailColorMin'} = $result;}
                elsif ($setting =~ /QuakeDetailColorInt/) {$quakesettings->{'QuakeDetailColorInt'} = $result;}
                elsif ($setting =~ /QuakeDetailColorMax/) {$quakesettings->{'QuakeDetailColorMax'} = $result;}
                elsif ($setting =~ /QuakeDetailAlign/) {$quakesettings->{'QuakeDetailAlign'} = $result;}
                elsif ($setting =~ /QuakeCircleColor/) {$quakesettings->{'QuakeCircleColor'} = $result;}
                elsif ($setting =~ /QuakePixelMax/) {$quakesettings->{'QuakePixelMax'} = $result;}
                elsif ($setting =~ /QuakePixelMin/) {$quakesettings->{'QuakePixelMin'} = $result;}
                elsif ($setting =~ /QuakePixelFactor/) {$quakesettings->{'QuakePixelFactor'} = $result;}
                elsif ($setting =~ /QuakeImageTransparent/) {$quakesettings->{'QuakeImageTransparent'} = $result;}
                elsif ($setting =~ /QuakeImageList/) {$quakesettings->{'QuakeImageList'} = $result;}
                elsif ($setting =~ /QuakeDetailColor/) {$quakesettings->{'QuakeDetailColor'} = $result;}
                elsif ($setting =~ /QuakeDetailList/) {$quakesettings->{'QuakeDetailList'} = $result;}
                elsif ($setting =~ /QuakeMinimumSize/) {$quakesettings->{'QuakeMinimumSize'} = $result;}
                elsif ($setting =~ /QuakeReportingDuration/) {$quakesettings->{'QuakeReportingDuration'} = $result;}
                elsif ($setting =~ /QuakeReportingSize/) {$quakesettings->{'QuakeReportingSize'} = $result;}
                elsif ($setting =~ /QuakeFade/) {$quakesettings->{'QuakeFade'} = $result;}						
            }
            
            if ($data1 =~ /Volcano/) {
                if ($setting =~ /VolcanoCircleSizeInner/) {$volcanosettings->{'VolcanoCircleSizeInner'} = $result;}
                elsif ($setting =~ /VolcanoCircleSizeMiddle/) {$volcanosettings->{'VolcanoCircleSizeMiddle'} = $result;}
                elsif ($setting =~ /VolcanoCircleSizeOuter/) {$volcanosettings->{'VolcanoCircleSizeOuter'} = $result;}
                elsif ($setting =~ /VolcanoCircleColorInner/) {$volcanosettings->{'VolcanoCircleColorInner'} = $result;}
                elsif ($setting =~ /VolcanoCircleColorMiddle/) {$volcanosettings->{'VolcanoCircleColorMiddle'} = $result;}
                elsif ($setting =~ /VolcanoCircleColorOuter/) {$volcanosettings->{'VolcanoCircleColorOuter'} = $result;}
                elsif ($setting =~ /VolcanoNameOnOff/) {$volcanosettings->{'VolcanoNameOnOff'} = $result;}
                elsif ($setting =~ /VolcanoNameColor/) {$volcanosettings->{'VolcanoNameColor'} = $result;}
                elsif ($setting =~ /VolcanoNameAlign/) {$volcanosettings->{'VolcanoNameAlign'} = $result;}
                elsif ($setting =~ /VolcanoImageTransparent/) {$volcanosettings->{'VolcanoImageTransparent'} = $result;}
                elsif ($setting =~ /VolcanoImageList/) {$volcanosettings->{'VolcanoImageList'} = $result;}
                elsif ($setting =~ /VolcanoDetailAlign/) {$volcanosettings->{'VolcanoDetailAlign'} = $result;}
                elsif ($setting =~ /VolcanoDetailList/) {$volcanosettings->{'VolcanoDetailList'} = $result;}
                elsif ($setting =~ /VolcanoDetailColor/) {$volcanosettings->{'VolcanoDetailColor'} = $result;}
            }
            
            if ($data1 =~ /Storm/) {
                if ($setting =~ /StormColorTrackReal/) {$stormsettings->{'StormColorTrackReal'} = $result;}
                elsif ($setting =~ /StormColorTrackPrediction/) {$stormsettings->{'StormColorTrackPrediction'} = $result;}
                elsif ($setting =~ /StormColorName/) {$stormsettings->{'StormColorName'} = $result;}
                elsif ($setting =~ /StormColorDetail/) {$stormsettings->{'StormColorDetail'} = $result;}
                elsif ($setting =~ /StormAlignName/) {$stormsettings->{'StormAlignName'} = $result;}
                elsif ($setting =~ /StormAlignDetail/) {$stormsettings->{'StormAlignDetail'} = $result;}
                elsif ($setting =~ /StormImageTransparent/) {$stormsettings->{'StormImageTransparent'} = $result;}
                elsif ($setting =~ /StormImageList/) {$stormsettings->{'StormImageList'} = $result;}
                elsif ($setting =~ /StormDetailAlign/) {$stormsettings->{'StormDetailAlign'} = $result;}
                elsif ($setting =~ /StormDetailList/) {$stormsettings->{'StormDetailList'} = $result;}
                elsif ($setting =~ /StormTrackOnOff/) {$stormsettings->{'StormTrackOnOff'} = $result;}
                elsif ($setting =~ /StormNameOnOff/) {$stormsettings->{'StormNameOnOff'} = $result;}
            }
            
            if ($data1 =~ /Eclipse/) {
                if ($setting =~ /EclipseOnOff/) {$settings->{'EclipseOnOff'} = $result;}
                elsif ($setting =~ /EclipseNotifyOnOff/) {$settings->{'EclipseNotifyOnOff'} = $result;}
                elsif ($setting =~ /EclipseNotifyTimeHours/) {$settings->{'EclipseNotifyTimeHours'} = $result;}
            }
            
            if ($data1 =~ /Norad/) {
                if ($setting =~ /NoradIssImage/) {$noradsettings->{'NoradIssImage'} = $result;}
                elsif ($setting =~ /NoradIssText/) {$noradsettings->{'NoradIssText'} = $result;}
                elsif ($setting =~ /NoradIssDetail/) {$noradsettings->{'NoradIssDetail'} = $result;}
                elsif ($setting =~ /NoradIssOnOff/) {$noradsettings->{'NoradIssOnOff'} = $result;}
                elsif ($setting =~ /NoradHstImage/) {$noradsettings->{'NoradHstImage'} = $result;}
                elsif ($setting =~ /NoradHstText/) {$noradsettings->{'NoradHstText'} = $result;}
                elsif ($setting =~ /NoradHstDetail/) {$noradsettings->{'NoradHstDetail'} = $result;}
                elsif ($setting =~ /NoradHstOnOff/) {$noradsettings->{'NoradHstOnOff'} = $result;}
                elsif ($setting =~ /NoradSoyuzImage/) {$noradsettings->{'NoradSoyuzImage'} = $result;}
                elsif ($setting =~ /NoradSoyuzText/) {$noradsettings->{'NoradSoyuzText'} = $result;}
                elsif ($setting =~ /NoradSoyuzDetail/) {$noradsettings->{'NoradSoyuzDetail'} = $result;}
                elsif ($setting =~ /NoradSoyuzOnOff/) {$noradsettings->{'NoradSoyuzOnOff'} = $result;}
                elsif ($setting =~ /NoradStsImage/) {$noradsettings->{'NoradStsImage'} = $result;}
                elsif ($setting =~ /NoradStsText/) {$noradsettings->{'NoradStsText'} = $result;}
                elsif ($setting =~ /NoradStsDetail/) {$noradsettings->{'NoradStsDetail'} = $result;}
                elsif ($setting =~ /NoradStsOnOff/) {$noradsettings->{'NoradStsOnOff'} = $result;}
                elsif ($setting =~ /NoradSatImage/) {$noradsettings->{'NoradSatImage'} = $result;}
                elsif ($setting =~ /NoradSatText/) {$noradsettings->{'NoradSatText'} = $result;}
                elsif ($setting =~ /NoradSatDetail/) {$noradsettings->{'NoradSatDetail'} = $result;}
                elsif ($setting =~ /NoradSatOnOff/) {$noradsettings->{'NoradSatOnOff'} = $result;}
                elsif ($setting =~ /NoradTleNumbers/) {$noradsettings->{'NoradTleNumbers'} = $result;}
                elsif ($setting =~ /NoradMiscOnOff/) {$noradsettings->{'NoradMiscOnOff'} = $result;}
                elsif ($setting =~ /NoradMiscDetail/) {$noradsettings->{'NoradMiscDetail'} = $result;}
                elsif ($setting =~ /NoradFileName/) {$noradsettings->{'NoradFileName'} = $result;}
            }
            
            if ($data1 =~ /Label/) {
                if ($setting =~ /LabelWarningQuake/) {$labelsettings->{'LabelWarningQuake'} = $result;}
                elsif ($setting =~ /LabelWarningVolcano/) {$labelsettings->{'LabelWarningVolcano'} = $result;}
                elsif ($setting =~ /LabelWarningStorm/) {$labelsettings->{'LabelWarningStorm'} = $result;}
                elsif ($setting =~ /LabelWarningNorad/) {$labelsettings->{'LabelWarningNorad'} = $result;}
                elsif ($setting =~ /LabelWarningCloud/) {$labelsettings->{'LabelWarningCloud'} = $result;}
                elsif ($setting =~ /LabelColorOk/) {$labelsettings->{'LabelColorOk'} = $result;}
                elsif ($setting =~ /LabelColorWarn/) {$labelsettings->{'LabelColorWarn'} = $result;}
                elsif ($setting =~ /LabelColorError/) {$labelsettings->{'LabelColorError'} = $result;}
                elsif ($setting =~ /LabelOnOff/) {$labelsettings->{'LabelOnOff'} = $result;}
            }
            
            if ($data1 =~ /Easter/) {
                if ($setting =~ /EasterEggSurprises/) {$settings->{'EasterEggSurprises'} = $result;}
            }
            
            if ($data1 =~ /Misc/) {
                if ($setting =~ /MiscXplanetVersion1OrBetter/) {$settings->{'XplanetVersion'} = $result;}
            }
            
            if ($data1 =~ /Cloud/) {
                if ($setting =~ /CloudRemoteImageName/) {$cloudsettings->{'CloudRemoteImageName'} = $result;}
                elsif ($setting =~ /CloudLocalImageName/) {$cloudsettings->{'CloudLocalImageName'} = $result;}
                elsif ($setting =~ /UseFreeCloudImage/) {$cloudsettings->{'UseFreeCloudImage'} = $result;}
                elsif ($setting =~ /SubcribedToXplanetClouds/) {$cloudsettings->{'SubcribedToXplanetClouds'} = $result;}
                elsif ($setting =~ /CloudUsername/) {$cloudsettings->{'Username'} = $result;}
                elsif ($setting =~ /CloudPassword/) {$cloudsettings->{'Password'} = $result;}
                elsif ($setting =~ /DirectDownload/) {$cloudsettings->{'DirectDownload'} = $result;}
            }
        }
    }
    
    close MF;
}


my $hurricane_on_off = 0;
my $volcano_on_off = 0;
my $quake_on_off = 0;
my $clouds_on_off = 0;
my $norad_on_off = 0;
my $update_label = 0;
my $hurricane_record_number = 0;
my $volcano_record_number = 0;
my $quake_record_number = 0;
my $norad_record_number = 0;
my $cloud_record_number = 0;
my $eclipseoverride;
my $labelsettings;
my $label_on_off;
my $eclipse_on_off;
my $EasterEgg_on_off;
my @eclipsetrack;
my @eclipsedata;
my @eclipserefined;
my $installed;


&command_line();
my @settings;

&get_settings;
if ($eclipseoverride eq 1) {
    $settings->{'EclipseOnOff'} = 'Off';
}

if ($labelsettings->{'LabelOnOff'} =~ /On/) {
    $label_on_off = 1;
}
else {$label_on_off = 0;}

if ($settings->{'EclipseOnOff'} =~ /On/) {
    $eclipse_on_off = 1;
}
else {$eclipse_on_off = 0;}

if ($settings->{'EasterEggSurprises'} =~ /Off/) {
    $EasterEgg_on_off = 0;
}
else {$EasterEgg_on_off = 1;}

if ($clouds_on_off != 2 && $clouds_on_off != 1 && $volcano_on_off != 1 && $hurricane_on_off != 1 && $quake_on_off != 1 && $norad_on_off != 1 && $update_label != 1 && $installed != 1) {
    &get_it_right_lamer;
}
else {
    if ($clouds_on_off == 1) {
        $cloud_record_number = 1;
    }
    elsif ($clouds_on_off == 2) {
        CloudUpdate::cloud_update($cloud_image_url, $cloud_file_name, $xplanet_images_dir);  # Call cloud_update from the CloudUpdate module;
        $cloud_record_number = 1;
    }
    
    if ($hurricane_on_off == 1) {
        my @hurricanedata;
        my @hurricanearcdatafor;
        my @hurricanearcdataact;
        
        $hurricane_record_number = Hurricane::get_hurricane_data_count();
        Hurricane::WriteoutHurricane($hurricane_record_number);
        
        my ($actcounter, $forcounter) = Hurricane::get_hurricanearcdata($hurricane_record_number);
        Hurricane::WriteoutHurricaneArc($hurricane_record_number, $actcounter, $forcounter);
    }
    
    if ($quake_on_off == 1) {
        my @quakedata;
        
        $quake_record_number = earthquake::get_quakedata();
        earthquake::WriteoutQuake($quake_record_number);
    }
    
    if ($norad_on_off == 1) {
        my @stsdata;
        my @hstdata;
        my @issdata;
        my @ststimetable;
        
        $norad_record_number = get_noraddata();
    }
    
    if ($volcano_on_off == 1) {
        my @volcanodata;
        
        $volcano_record_number = get_volcanodata();
        if ($volcano_record_number !~ /what/) {
            &WriteoutVolcano($volcano_record_number); 
        }
    }
    
    if ($label_on_off == 1) {
        &WriteoutLabel($quake_record_number, $norad_record_number, $cloud_record_number, $hurricane_record_number, $volcano_record_number, 0);
    }
    
    if ($update_label == 1) {
        &WriteoutLabel($quake_record_number, $norad_record_number, $cloud_record_number, $hurricane_record_number, $volcano_record_number, 1);
    }
    
    if ($eclipse_on_off == 1) {
        my @eclipsedata;
        my @eclipsetrack;
        my $eclipse_record_number = readineclipseindex();
        my $active_eclipse_number = &datacurrent($eclipse_record_number);
        
        if ($active_eclipse_number !~ /NONE/ || $active_eclipse_number !~ /\d/) {
            $active_eclipse_number = "NONE";
        }
        #print "Eclipse Record Number = $eclipse_record_number\nActive Eclipse Number = $active_eclipse_number\n";
        
        if ($active_eclipse_number !~ /NONE/) {
            if ($eclipsedata[$active_eclipse_number]->{'detail'} =~ /CRUDE/) {
                my @eclipserefined;
                &refinedata($active_eclipse_number);
            }
            
            my $track_number = &readineclipsetrack($active_eclipse_number);
            
            &writeouteclipsearccenter($track_number);
            &writeouteclipsemarker($track_number);
            
            my $next_eclipse = timegm(0, $eclipsetrack[1]->{'minute'}, $eclipsetrack[1]->{'hour'}, $eclipsedata[$active_eclipse_number]->{'dayofmonth'}, num_of_month($eclipsedata[$active_eclipse_number]->{'monthtxt'}), $eclipsedata[$active_eclipse_number]->{'year'});
            my $time_now = time;
            my $countdown = ($next_eclipse - $time_now);
            #print "$countdown\n";
            
            if ($countdown > 0) {
                &writeouteclipsearcboarder($track_number);
            }
            
            if ($settings->{'EclipseNotifyOnOff'} =~ /On/) {
                &writeouteclipselabel($active_eclipse_number, $track_number, $countdown);
            }
        }
        else {
            &writeouteclipsefilesnone();
        }
        
        if ($EasterEgg_on_off !~ /0/ && $label_on_off == 1) {
            easteregg();
        }
    }
}
}

#print "ON OFF = $volcano_on_off Volcano Record Number = $volcano_record_number \nON OFF = $quake_on_off Quake Record Number = $quake_record_number\nON OFF = $hurricane_on_off Hurricane Record Number = $hurricane_record_number\nON OFF = $clouds_on_off Cloud Record Number = $cloud_record_number\nON OFF = $norad_on_off NORAD Record Number = $norad_record_number\nON OFF = $label_on_off Label\nON OFF = $eclipse_on_off Eclipse\n";
