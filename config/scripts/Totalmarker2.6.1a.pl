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
use POSIX;
use Cwd;
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

# Declare options hash for Getopt::Std
my %opts;

# Parse command-line options
getopts('d', \%opts);

# Enable debugging if -d or --debug is passed
our $DEBUG = $opts{'d'} ? 1 : 0;

# Debugging: Print confirmation if debugging is enabled
print "Debugging enabled.\n" if $DEBUG;

# Adjust this path to where the module files are located
use lib 'C:\Users\mcoblent\OneDrive\Xplanet\xplanet-1.3.0\Xplanet-3\config\scripts';  

use Exporter 'import';
#our @EXPORT_OK = qw(get_file);

use Globals qw(
    $settings
    $xplanet_dir
    $settings_ini_file
    $xplanet_markers_dir
    $xplanet_arcs_dir
    $xplanet_satellites_dir
    $xplanet_images_dir
    $xplanet_config_dir
    debug_print_modules

    set_pversion
    update_directories

    $quakesettings 
    $quake_marker_file 
    @quakedata 

    $labelsettings

    $noradsettings

    $volcanosettings 
    $volcano_marker_file
   
    $stormsettings 
 
    $cloudsettings 

    $eclipse_data_file
    $eclipse_marker_file
    $eclipse_arc_file

    $xplanet_images_dir
    );

use Storm;
use Label;
use CloudUpdate qw(
    cloud_update
    );

use Norad qw(
    process_satellites
    );

use Earthquake qw(
    WriteoutQuake 
    get_quakedata
    );

use VolcanoXML qw(
    process_volcano_data
    );

use Eclipse qw(
    readineclipseindex
    readineclipsetrack
    datacurrent
    writeouteclipsemarker
    writeouteclipsearcboarder
    writeouteclipsearccenter
    writeouteclipsefilesnone
    writeouteclipselabel
    refinedata
    );

use EasterEgg qw(easteregg
    ); 

use Fires;

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
    # CollapsedSubs: get_webpage  get_program_version  changelog_print  file_header  Hurricane::get_hurricane_data_count  
    # Volcano::get_volcanodata Volcano::WriteoutVolcano  
    # update_file  get_eclipsedata  readineclipseindex  readineclipsetrack  datacurrent  writeouteclipsemarker  writeouteclipsearcboarder  
    # writeouteclipsearccenter  writeouteclipsefilesnone  writeouteclipselabel  refinedata  get_settings  easteregg
    $0 = $^X unless ($^X =~ m%(^|[/\\])(perl)|(perl.exe)$%i );
}

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
my $quake_on_off;
my $volcano_on_off;
my $norad_on_off;
my $clouds_on_off;
my $hurricane_on_off;
my $xplanetversion;

# Initialize $xplanet_dir and dependent directories
Globals::initialize_xplanet_dir();

# Call the subroutine to initialize directory and file paths
Globals::get_directory_settings();
#
# Test that locations exist and can be written to.
#
# Validate critical directories and files
-d $xplanet_markers_dir || die("Could not find xplanet markers directory: $xplanet_markers_dir\n");
-r $xplanet_markers_dir || die("Cannot read from xplanet markers directory: $xplanet_markers_dir\n");
-w $xplanet_markers_dir || die("Cannot write to xplanet markers directory: $xplanet_markers_dir\n");

-e $settings_ini_file || die("Configuration file missing: $settings_ini_file\n");

#-e $eclipse_data_file   || &install("eclipsfile");

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


my $volcano_location_RSS_24H = "https://earthquake.usgs.gov/eqcenter/recenteqsww/catalogs/caprss1days2.5.xml";

my $ua = LWP::UserAgent->new();
$ua->env_proxy();
$ua->agent("Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 9.1)");

# Please note if you are using Windows and Active Perl you must \\ your directories not just use \
# where xplanet is installed
#
# where the label marker file will be written to
# Main Script: Sets $label_file and passes it to Globals.pm using set_label_file($label_file);.
# Globals.pm: Receives the value of $label_file and stores it as a global variable.
# Label.pm: Uses $label_file as expected, with the value set in the main script.
# Summary
#   Global Declaration: Declare $label_file using our in the main script.
#   Setter Function: Use a setter function in Globals.pm to pass the value of $label_file.
#   Call the Setter: After setting $label_file in the main script, call the setter to pass its value to Globals.pm.

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
# Allows simple update to Totalmarker should regex & location change.
#
my $readfile="totalmarker.upd";
#if ( (-e $readfile) && (-r $readfile) ) {
#    &get_xml_update;
#}

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

sub get_webpage {
    my ($URL) = @_;
    my $req = HTTP::Request->new(GET => $URL);
    my $res = $ua->request($req);
    
    # Check if the request was successful
    if ($res->is_success) {
        return $res->decoded_content;  # Use decoded_content for proper encoding
    } else {
        # Log the error with a detailed message
        warn "Failed to fetch $URL: " . $res->status_line;
        return undef;  # Explicitly return undef on failure
    }
}

sub command_line {
    $quake_on_off = 0;
    $update_label = 0;
    $volcano_on_off = 0;
    $norad_on_off = 0;
    $clouds_on_off = 0;
    $hurricane_on_off = 0;

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
            $xplanetversion = &get_program_version;
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


sub boundschecking() {
    my ($value) = @_;
    
    if ($value >= 1) {$value = 1;}
    # if ($value == 0) {$value = FAILED;}
    
    return ($value);
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
            print MF "\#\n\#VOLCANO\n\#\nVolcano.Circle.Size.Inner=4\nVolcano.Circle.Size.Middle=8\nVolcano.Circle.Size.Outer=12\nVolcano.Circle.Color.Inner=Yellow\nVolcano.Circle.Color.Middle=Red\nVolcano.Circle.Color.Outer=Brown\nVolcanoNameOnOff=On\nVolcanoNameColor=Brown\nVolcano.Name.Align=Below\nVolcanoImageList=\nVolcanoImageTransparent=\nVolcanoDetailList=\nVolcanoDetailAlign=\nVolcanoDetailColor=\n";
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
            my ($pversion,$prevision) = ($1,$2);
            
            $pversion *= 1;
            if ($pversion < 0.93) {
                print "The Version of Xplanet won't support Earthquakes, please Upgrade to 0.93d or better\n";
            }
            elsif ($pversion = 0.93) {
                if (ord($prevision) < ord('d')) {
                    print "The Version of Xplanet won't support Earthquakes, please Upgrade to 0.93d or better\n";
                }
            }
            elsif ($pversion < 0.95 ) {
                &install_marker($oldversionnumber,$flag);
            }
            else {
                &install_marker($newversionnumber,$flag);
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
            open (MF, "<$settings_ini_file");
            while (<MF>) {
                foreach (split "\n") {
                    if ($_ =~ /Config File Written by/) {
                        my ($tmp1, $tmp2, $tmp3, $tmp4, $tmp5, $tmp6, $tmp7) = split " ";
                        
                        $oldversion = $tmp7;
                    }
                }
                
                close MF;
                &changelog_print ($oldversion);
            }
        }
    }
    
    my $installed = 1;
}

sub update_ini_file() {
    my $volcanosettings;
    my $stormsettings;
    my $labelsettings;
    my $cloudsettings;
    my @volcanodata;

    Globals::get_settings();
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

sub process_modules {
    my ($module_flags_ref) = @_;  # Accept @module_flags as a reference
    my %module_map = (
        'clouds'    => sub { CloudUpdate::cloud_update() },
        'volcanoes' => sub { VolcanoXML::process_volcano_data() },
        'storms'    => sub { Storm::fetch_and_process_storms() },
        'quakes'    => sub { Earthquake::get_quakedata() },
        'norad'     => sub {
            my $satellite_file = "$xplanet_satellites_dir\\Norad";
            my $output_tle_file = "$xplanet_satellites_dir\\Norad.tle";
            my $marker_file = "$xplanet_satellites_dir\\Norad_marker.txt";
            Norad::process_satellites($satellite_file, $output_tle_file, $marker_file);
        },
        'fires'     => sub { Fires::run() },
        # Pass @module_flags for label logic
        'labelupdate' => sub { Label::WriteoutLabel(@$module_flags_ref, 0) },
    );

    foreach my $module (sort keys %Globals::modules) {
        my ($onoff_key) = grep { /onoff$/i } keys %{ $Globals::modules{$module} };

        if ($onoff_key && $Globals::modules{$module}{$onoff_key} == 1) {
            print "Processing module: $module\n";

            if (exists $module_map{$module}) {
                $module_map{$module}->();
            } else {
                warn "No subroutine mapped for module: $module\n";
            }
        } else {
            print "Module: $module, On/Off: Undefined or Inactive\n";
        }
    }
}




sub collect_module_flags {
    my @flags;  # Array to store the normalized on/off flags for all modules

    # Loop through all modules in %Globals::modules
    foreach my $module (sort keys %Globals::modules) {
        # Debugging: Print the module being processed
        print "Processing module: $module\n" if $DEBUG;

        # Check if the module contains any key that matches /onoff$/i
        my ($onoff_key) = grep { /onoff$/i } keys %{ $Globals::modules{$module} };

        if ($onoff_key) {
            # Normalize the value: "On" => 1, "Off" => 0, undefined => 0
            my $onoff_value = $Globals::modules{$module}{$onoff_key} // 0;
            $onoff_value = ($onoff_value =~ /^(1|On)$/i) ? 1 : 0;

            # Debugging: Print the normalized onoff value
            print "  Found onoff key ($onoff_key): $onoff_value\n" if $DEBUG;

            # Push the normalized value to the flags array
            push @flags, $onoff_value;
        } else {
            # Debugging: Module does not have an onoff key
            print "  No onoff key for module: $module\n" if $DEBUG;
        }
    }

    # Debugging: Print the final collected flags
    print "Final collected module flags: " . join(", ", @flags) . "\n" if $DEBUG;

    # Return the array of normalized on/off flags
    return @flags;
}





$hurricane_on_off = 0;
$volcano_on_off = 0;
$quake_on_off = 0;
$clouds_on_off = 0;
$norad_on_off = 0;
my $hurricane_record_number = 0;
my $volcano_record_number = 0;
my $quake_record_number = 0;
my $norad_record_number = 0;
my $cloud_record_number = 0;
my $eclipseoverride = 0;
# my $labelsettings;
my $label_on_off;
my $eclipse_on_off;
my $EasterEgg_on_off;
my @eclipsetrack;
my @eclipsedata;
my @eclipserefined;
my $installed=0;

&command_line();
my @settings;


Globals::get_directory_settings;
# Debugging the modules section as we refactor Globals.pm
print "Main script line 1248 checking Global modules: \n" if $DEBUG;
print %Globals::modules, "\n" if $DEBUG;
print "Main script line 1319 - debugging modules after returning to main \n" if $DEBUG;
Globals::debug_print_modules() if $DEBUG;
print "\n" if $DEBUG;

# Updated logic for eclipse override
if ($eclipseoverride eq 1) {
    $Globals::modules{'eclipses'}{'EclipseOnOff'} = 'Off';
}


# Initialize the on/off status for label updates
$label_on_off = ($Globals::modules{'labelupdate'}{'LabelOnOff'} // '') =~ /On/ ? 1 : 0;

# Collect the on/off flags for all modules dynamically
my @module_flags = collect_module_flags();

# Debugging: Print the collected module flags
print "Main script: Collected module flags: " . join(", ", @module_flags) . "\n" if $DEBUG;

# Check if no module is active
if (!grep { $_ == 1 } @module_flags && $update_label != 1 && $installed != 1) {
    print "No active modules. Calling get_it_right_lamer.\n";
    &get_it_right_lamer;
} else {
    print "Modules are active. Proceeding to process modules.\n";

    # Pass @module_flags to process_modules
    process_modules(\@module_flags);

    # Update labels if the label module is enabled
    if ($label_on_off == 1) {
        Label::WriteoutLabel(@module_flags, 0);  # Routine update
    }

    # Perform forced label updates if requested
    if ($update_label == 1) {
        Label::WriteoutLabel(@module_flags, 1);  # Forced update
    }
}