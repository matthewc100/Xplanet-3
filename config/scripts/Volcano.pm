package Volcano;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    WriteoutVolcano
    get_volcanodata
    volcanodata_checked
);

use Globals qw($volcano_marker_file $volcano_location get_webpage);

sub WriteoutVolcano {
    my ($counter) = @_;
    my $recounter = 0;
    my $volcanosettings;
    my @volcanodata;
    my $locations;

    if ($counter !~ /FAILED/) {
        my $openfile = 'Volcano';
        open (MF, ">$volcano_marker_file");
        &file_header($openfile);

        while ($recounter < $counter) {
            my $long = $volcanodata[$recounter]->{'long'};
            my $lat = $volcanodata[$recounter]->{'lat'};
            my $name = $volcanodata[$recounter]->{'name'};
            my $elev = $volcanodata[$recounter]->{'elev'};

            $lat  = sprintf("% 7.2f", $lat);
            $long = sprintf("% 7.2f", $long);
            print MF "$lat $long \"\" color=$volcanosettings->{'VolcanoCircleColorInner'} symbolsize=$volcanosettings->{'VolcanoCircleSizeInner'}\n";
            print MF "$lat $long \"\" color=$volcanosettings->{'VolcanoCircleColorMiddle'} symbolsize=$volcanosettings->{'VolcanoCircleSizeMiddle'}\n";

            if ($volcanosettings->{'VolcanoNameOnOff'} =~ /On/) {
                if ($volcanosettings->{'VolcanoImageList'} =~ /\w/) {
                    print MF "$lat $long \"$name\" align=$volcanosettings->{'VolcanoNameAlign'} color=$volcanosettings->{'VolcanoNameColor'} image=$volcanosettings->{'VolcanoImageList'} ";

                    if ($volcanosettings->{'VolcanoImageTransparent'} =~ /\d/) {
                        print MF "transparent=$volcanosettings->{'VolcanoImageTransparent'}";
                    }
                } else {
                    print MF "$lat $long \"$name\" color=$volcanosettings->{'VolcanoCircleColorOuter'} symbolsize=$volcanosettings->{'VolcanoCircleSizeOuter'} align=$volcanosettings->{'VolcanoNameAlign'}";
                }
            } else {
                print MF "$lat $long \"\" color=$volcanosettings->{'VolcanoCircleColorOuter'} symbolsize=$volcanosettings->{'VolcanoCircleSizeOuter'}";
            }
            print MF "\n";

            if ($volcanosettings->{'VolcanoDetailList'} =~ /\w/) {
                my $tmp1 = $volcanosettings->{'VolcanoDetailList'};

                $tmp1 =~ s/<lat>/$lat/g;
                $tmp1 =~ s/<long>/$long/g;
                $tmp1 =~ s/<elevation>/$elev/g;
                $tmp1 =~ s/<elev>/$elev/g;
                $tmp1 =~ s/<name>/$name/g;
                $tmp1 =~ s/<location>/$locations/g;
                print MF "$lat $long \"$tmp1\" color=$volcanosettings->{'VolcanoDetailColor'} align=$volcanosettings->{'VolcanoDetailAlign'} image=none\n";
            }

            $recounter++;
        }

        close MF;
    }
}

sub get_volcanodata {
    my $flag = 1;
    my $MaxDownloadFrequencyHours = 24;
    my $MaxRetries = 3;
    my $volcanodata_file = "$volcano_marker_file";

    if (-f $volcanodata_file) {
        my @Stats = stat($volcanodata_file);
        my $FileAge = (time() - $Stats[9]);
        my $FileSize = $Stats[7];

        if ($FileAge < 60 * 60 * $MaxDownloadFrequencyHours) {
            print "Volcano data is up to date!\n";
            $flag = 0;
        }
    }

    if ($flag != 0) {
        $flag = volcanodata_checked();
    } else {
        $flag = "what";
    }

    return $flag;
}

sub volcanodata_checked {
    my $volcanotxt;
    my $counter = 0;
    my $detail;
    my $elev;
    my @volcanodata;

    $volcanotxt = get_webpage($volcano_location);

    if ($volcanotxt !~ /FAILED/) {
        $volcanotxt =~ s/[\r\n]+//g;

        foreach (split("<info>", $volcanotxt)) {
            chomp;

            if (/.*\<valueName\>Volcano Name\<\/valueName\>\<value\>([A-Z,\s]+)\<\/value\>.*\<areaDesc\>([A-Z,\-,\s]+)\<\/areaDesc\>\<circle\>([\d\-\.]+),([\d\-\.]+).[\d\-\.]+\<\/circle\>.*/i) {
                my ($name, $area, $lat, $long) = ($1, $2, $3, $4);

                $elev = "UNKNOWN";

                if ($detail =~ /(\d+\.\d+)&deg;([NS])/) {
                    my $sign;
                    ($lat, $sign) = ($1, $2);
                    $lat *= ($sign =~ /s/i) ? -1 : 1;
                }

                if ($detail =~ /(\d+\.\d+)&deg;([EW])/) {
                    my $sign;
                    ($long, $sign) = ($1, $2);
                    $long *= ($sign =~ /w/i) ? -1 : 1;
                }

                if ($detail =~ /(\d+\.\d+)\x{00B0}([NS])/) {
                    my $sign;
                    ($lat, $sign) = ($1, $2);
                    $lat *= ($sign =~ /s/i) ? -1 : 1;
                }

                if ($detail =~ /(\d+\.\d+)&#176([NS])/) {
                    my $sign;
                    ($lat, $sign) = ($1, $2);
                    $lat *= ($sign =~ /s/i) ? -1 : 1;
                }

                if ($detail =~ /(\d+\.\d+)\x{00B0}([EW])/) {
                    my $sign;
                    ($long, $sign) = ($1, $2);
                    $long *= ($sign =~ /w/i) ? -1 : 1;
                }

                if ($detail =~ /(\d+\.\d+)&#176([EW])/) {
                    my $sign;
                    ($long, $sign) = ($1, $2);
                    $long *= ($sign =~ /w/i) ? -1 : 1;
                }

                if ($detail =~ /summit elev\..*?([\d,]+)/) {
                    $elev = $1;
                    $elev =~ s/\D//;
                    $elev *= 1;
                }

                $name =~ s/\&(.).*?\;/lc($1)/eg;
                $name = lc($name);
                $name =~ s/\b(\w)/uc($1)/eg;

                if ($name !~ /Additional/) {
                    push @volcanodata, {
                        'lat' => $lat,
                        'long' => $long,
                        'name' => $name,
                        'elev' => $elev,
                        'location' => $area,
                    };
                    $counter++;
                }
            }
        }

        print "  Updated volcano information\n";
        return $counter;
    } else {
        print "  WARNING... unable to access or download updated volcano information\n";
        return $volcanotxt;
    }
}

1; # End of the module
