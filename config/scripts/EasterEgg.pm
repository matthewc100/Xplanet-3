package EasterEgg;
use strict;
use warnings;
use Exporter 'import';
use Globals qw(
    $label_file 
    $xplanet_images_dir
);  # Import required global variables from Globals.pm

our @EXPORT_OK = qw(easteregg);

sub easteregg () {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
    my ($thisday, $thismonth, $start_lat, $start_long, $lat_diff, $long_diff, $journey, $latinc, $longinc, $slatloc, $slongloc);
    
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    $thisday = (qw(Sun Mon Tues Wed Thurs Fri Sat))[$wday];
    $thismonth = (qw(Jan Feb March April May June July Aug Sept Oct Nov Dec))[$mon];

    # Check if it's December (11) and 23rd day
    if ($mon == 11 && $mday == 23) {
        my $santa_image_file = "$xplanet_images_dir/santa.png";

        # Check if the santa.png image exists
        if (!-e $santa_image_file) {
            die "Santa image not found at $santa_image_file!";
        }

        open (MF, ">>", $label_file) or die "Cannot open label file $label_file: $!";

            
        # Simplified logic for routing
        if ($hour >= 11 && $hour <= 23) {
            $start_lat = 90;
            $start_long = 180;  # Start at North Pole

                if ($hour == 11) {
                    $start_lat = 90;
                    $start_long = 180;
                    $lat_diff = -131;
                    $long_diff = -6;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Wellington -> Sydney
                elsif ($hour == 12) {
                    $start_lat = -41;
                    $start_long = 175;
                    $lat_diff = 7;
                    $long_diff = -23;
                    $journey = 120;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                elsif ($hour == 13) {
                    $start_lat = -41;
                    $start_long = 175;
                    $lat_diff = 7;
                    $long_diff = -23;
                    $journey = 120;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + (($min+60)*$latinc);
                    $slongloc = $start_long + (($min+60)*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Sydney -> Tokyo
                elsif ($hour == 14) {
                    $start_lat = -34;
                    $start_long = 151;
                    $lat_diff = 70;
                    $long_diff = -11;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Tokyo -> Hong Kong
                elsif ($hour == 15) {
                    $start_lat = 36;
                    $start_long = 140;
                    $lat_diff = -13;
                    $long_diff = -26;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Hong Kong -> Bangkok
                elsif ($hour == 16) {
                    $start_lat = 22;
                    $start_long = 114;
                    $lat_diff = -8;
                    $long_diff = -14;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Bangkok -> Calcutta
                elsif ($hour == 17) {
                    $start_lat = 14;
                    $start_long = 101;
                    $lat_diff = 9;
                    $long_diff = -12;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Calcutta -> Karachi
                elsif ($hour == 18) {
                    $start_lat = 23;
                    $start_long = 88;
                    $lat_diff = 2;
                    $long_diff = -21;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Karachi -> Victoria
                elsif ($hour == 19) {
                    $start_lat = 25;
                    $start_long = 67;
                    $lat_diff = -29;
                    $long_diff = -12;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Victoria -> Moscow
                elsif ($hour == 20) {
                    $start_lat = -4;
                    $start_long = 55;
                    $lat_diff = 60;
                    $long_diff = -18;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Moscow -> JoBerg
                elsif ($hour == 21) {
                    $start_lat = 55;
                    $start_long = 38;
                    $lat_diff = -82;
                    $long_diff = -10;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route JoBerg -> Berlin
                elsif ($hour == 22) {
                    $start_lat = -26;
                    $start_long = 28;
                    $lat_diff = 79;
                    $long_diff = -15;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Berlin -> London
                elsif ($hour == 23) {
                    $start_lat = 53;
                    $start_long = 13;
                    $lat_diff = -1;
                    $long_diff = -13;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
        }
        
        if ($mday == 24) {
            open (MF, ">>$label_file") or die "Cannot open label file $label_file: $!";
            my $start_lat;
            my $start_long;
            my $lat_diff;
            my $long_diff;
            my $journey;
            my $latinc;
            my $longinc;
            my $santa_image_file = "$xplanet_images_dir/santa.png";
            my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
            if (!-e $santa_image_file) {
                die "Santa image not found at $santa_image_file!";
            }
            
            if ($hour < 12 ) {
                #Route London -> Azores
                if ($hour == 0) {
                    $start_lat = 52;
                    $start_long = 0;
                    $lat_diff = -13;
                    $long_diff = -29;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Azores -> South Georgia
                elsif ($hour == 1) {
                    $start_lat = 39;
                    $start_long = -29;
                    $lat_diff = -93;
                    $long_diff = -8;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route South Georgia -> Rio
                elsif ($hour == 2) {
                    $start_lat = -55;
                    $start_long = -37;
                    $lat_diff = 32;
                    $long_diff = -6;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Rio -> Stanley
                elsif ($hour == 3) {
                    $start_lat = -23;
                    $start_long = -43;
                    $lat_diff = -29;
                    $long_diff = -17;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Stanley -> New York
                elsif ($hour == 4) {
                    $start_lat = -52;
                    $start_long = -60;
                    $lat_diff = 92;
                    $long_diff = -14;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route New York -> Birmingham
                elsif ($hour == 5) {
                    $start_lat = 40;
                    $start_long = -74;
                    $lat_diff = -7;
                    $long_diff = -13;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Birmingham -> Calgary
                elsif ($hour == 6) {
                    $start_lat = 34;
                    $start_long = -87;
                    $lat_diff = 18;
                    $long_diff = -27;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Calgary -> Los Angeles
                elsif ($hour == 7) {
                    $start_lat = 51;
                    $start_long = -114;
                    $lat_diff = -17;
                    $long_diff = -4;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Los Angles -> Sitka
                elsif ($hour == 8) {
                    $start_lat = 34;
                    $start_long = -118;
                    $lat_diff = 23;
                    $long_diff = 17;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Sitka -> Honolulu
                elsif ($hour == 9) {
                    $start_lat = 57;
                    $start_long = -135;
                    $lat_diff = -36;
                    $long_diff = -23;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Hawaii -> Midway Islands
                elsif ($hour == 10) {
                    $start_lat = 21;
                    $start_long = -157;
                    $lat_diff = 7;
                    $long_diff = -20;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
                #Route Midway Islands -> North Pole
                elsif ($hour == 11) {
                    $start_lat = 28;
                    $start_long = -177;
                    $lat_diff = 62;
                    $long_diff = -2.5;
                    $journey = 60;
                    $latinc = $lat_diff / $journey;
                    $longinc = $long_diff / $journey;
                    $slatloc = $start_lat + ($min*$latinc);
                    $slongloc = $start_long + ($min*$longinc);
                    print MF "$slatloc $slongloc \"\" image=santa.png transparent={0,0,0}\n";
                }
            }
        }
    }
    close (MF);
}

1;  # Return true value to indicate successful module loading