# Norad.pm
package Norad;
use strict;
use warnings;
use Globals qw($noradsettings $isstle_file $iss_file $xplanet_satellites_dir $iss_location $hst_location $sts_location $other_locations1 $xplanet_images_dir get_webpage);

use Exporter 'import';
our @EXPORT_OK = qw(get_noraddata norad_checked update_file);

sub get_noraddata {
    my $flag = 1;
    my $MaxDownloadFrequencyHours = 12;
    my $MaxRetries = 3;
    my $tlefile = "$isstle_file";
    
    # Get file details
    if (-f $tlefile) {
        my @Stats = stat($tlefile);
        my $FileAge = (time() - $Stats[9]);
        my $FileSize = $Stats[7];
        
        # Check if file is already up to date
        if ($FileAge < 60 * 60 * $MaxDownloadFrequencyHours) {
            print "TLEs are up to date!\n";
            $flag = 3;
        }
    }
    
    if ($flag != 3) {
        $flag = norad_checked();
    } else {
        $flag = "what";
    }
    
    return $flag;
}

sub norad_checked {
    if ($noradsettings->{'NoradFileName'} =~ /\w+/) {
        $isstle_file = "$xplanet_satellites_dir/$noradsettings->{'NoradFileName'}.tle";
        $iss_file = "$xplanet_satellites_dir/$noradsettings->{'NoradFileName'}";
    }
    
    my $counter = 0;
    my $isstxt = get_webpage($iss_location);
    my $hsttxt = get_webpage($hst_location);
    my $ststxt = get_webpage($sts_location);
    my $otherlocations1txt = get_webpage($other_locations1);
    
    if ($isstxt eq 'FAILED') {
        return "FAILED";
    } else {
        open my $mf, '>', $isstle_file or die "Cannot open $isstle_file: $!";
        foreach (split("\n", $isstxt), split("\n", $hsttxt), split("\n", $otherlocations1txt)) {
            print $mf "$_\n";
        }
        if ($ststxt !~ /</) {
            foreach (split("\n", $ststxt)) {
                print $mf "$_\n";
            }
        }
        close $mf;
        
        open $mf, '>', $iss_file or die "Cannot open $iss_file: $!";
        my $TLEline = 0;
        my ($stsyes, $soyuzyes, $unknown) = (0, 0, 0);
        
        if ($ststxt !~ /</) {
            foreach (split("\n", $ststxt)) {
                my @values = split;
                if ($TLEline == 3) { $TLEline = 0; }
                if ($TLEline == 0) {
                    if ($values[0] =~ /STS/) { $stsyes = 1; }
                    elsif ($values[0] =~ /HST|ISS/) { $unknown = 0; }
                    elsif ($values[0] =~ /SOYUZ/) { $soyuzyes = 1; }
                    else { $unknown = 1; }
                }
                
                if ($stsyes && $TLEline == 2) {
                    my $file = $xplanet_images_dir . '/' . $noradsettings->{'NoradStsImage'};
                    -e $file || update_file('STS');
                    if ($noradsettings->{'NoradStsOnOff'} =~ /On/) {
                        print $mf "$values[1] \"$noradsettings->{'NoradStsText'}\" image=$noradsettings->{'NoradStsImage'} $noradsettings->{'NoradStsDetail'}\n";
                    }
                    $stsyes = 0;
                } elsif ($unknown && $TLEline == 2) {
                    my $file = $xplanet_images_dir . '/' . $noradsettings->{'NoradSatImage'};
                    -e $file || update_file('SAT');
                    if ($noradsettings->{'NoradSatOnOff'} =~ /On/) {
                        print $mf "$values[1] \"$noradsettings->{'NoradSatText'}\" image=$noradsettings->{'NoradSatImage'} $noradsettings->{'NoradSatDetail'}\n";
                    }
                    $unknown = 0;
                }
                
                $TLEline++;
            }
        }
        
        if ($isstxt !~ /</) {
            foreach (split("\n", $isstxt)) {
                my @values = split;
                if ($TLEline == 3) { $TLEline = 0; }
                if ($TLEline == 0 && $values[0] =~ /SOYUZ/) { $soyuzyes = 1; }
                if ($soyuzyes && $TLEline == 2) {
                    my $file = $xplanet_images_dir . '/' . $noradsettings->{'NoradSoyuzImage'};
                    -e $file || update_file('SOYUZ');
                    if ($noradsettings->{'NoradSoyuzOnOff'} =~ /On/) {
                        print $mf "$values[1] \"$noradsettings->{'NoradSoyuzText'}\" image=$noradsettings->{'NoradSoyuzImage'} $noradsettings->{'NoradSoyuzDetail'}\n";
                    }
                    $soyuzyes = 0;
                }
                $TLEline++;
            }
        }
        
        my $file = $xplanet_images_dir . '/' . $noradsettings->{'NoradIssImage'};
        -e $file || update_file('ISS');
        if ($noradsettings->{'NoradIssOnOff'} =~ /On/) {
            print $mf "25544 \"$noradsettings->{'NoradIssText'}\" image=$noradsettings->{'NoradIssImage'} $noradsettings->{'NoradIssDetail'}\n";
        }
        
        $file = $xplanet_images_dir . '/' . $noradsettings->{'NoradHstImage'};
        -e $file || update_file('HST');
        if ($noradsettings->{'NoradHstOnOff'} =~ /On/) {
            print $mf "20580 \"$noradsettings->{'NoradHstText'}\" image=$noradsettings->{'NoradHstImage'} $noradsettings->{'NoradHstDetail'}\n";
        }
        
        if ($noradsettings->{'NoradMiscOnOff'} =~ /On/) {
            my @tmp = split " ", $noradsettings->{'NoradTleNumbers'};
            for my $num (@tmp) {
                if ($num =~ /\d{5}/) {
                    print $mf "$num \"\" image=$num.gif $noradsettings->{'NoradMiscDetail'}\n";
                }
            }
        }
        
        close $mf;
        return "1";
    }
    return "what";
}

sub update_file {
    my ($type) = @_;
    if ($type eq 'ISS') {
        $noradsettings->{'NoradIssImage'} = 'iss.png';
    } elsif ($type eq 'HST') {
        $noradsettings->{'NoradHstImage'} = 'hst.png';
    } elsif ($type eq 'STS') {
        $noradsettings->{'NoradStsImage'} = 'sts.png';
    } elsif ($type eq 'SAT') {
        $noradsettings->{'NoradSatImage'} = 'sat.png';
    } elsif ($type eq 'SOYUZ') {
        $noradsettings->{'NoradSoyuzImage'} = 'soyuz.png';
    }
    
    my $file = $xplanet_images_dir . '/' . $noradsettings->{"Norad${type}Image"};
    -e $file || get_file($noradsettings->{"Norad${type}Image"});
}

1;
