package Label;
use strict;
use warnings;
use Globals qw($label_file);

sub WriteoutLabel {
    my ($update_earth, $update_norad, $update_cloud, $update_hurricane, $update_volcano, $update_label) = @_;
    my $labelsettings;
    my @Yco_ords;
    my @Xco_ords;
    my @text1;
    my @text2;
    my @text3;
    my @text4;
    my @weekday;
    my @monthday;
    my @monthlet;
    my @yeartime;
    my @colour;
    my @image;
    my @position;
    my $sec;
    my $min;
    my $hour;
    my $year;
    my $mday;
    my $mon;
    my $wday;
    my $yday;
    my $isdst;
    my $thisday;
    my $thismonth;
    my $time_now;
    my $openfile;
    my $labellocate;

    # Update flags
    $update_earth = $update_earth >= 1 ? 1 : 0;
    $update_norad = $update_norad >= 1 ? 1 : 0;
    $update_cloud = $update_cloud >= 1 ? 1 : 0;
    $update_hurricane = $update_hurricane >= 1 ? 1 : ($update_hurricane == -1 ? 1 : 0);
    $update_volcano = $update_volcano >= 1 ? 1 : 0;
    if ($update_label >= 1) {
        $update_earth = $update_norad = $update_cloud = $update_hurricane = $update_volcano = 0;
    }

    my $counter = 0;
    my $ok_color = $labelsettings->{'LabelColorOk'};
    my $warn_color = $labelsettings->{'LabelColorWarn'};
    my $failed_color = $labelsettings->{'LabelColorError'};

    open(MF, "<$label_file") or die "Cannot open $label_file: $!";
    while (<MF>) {
        (
            $Yco_ords[$counter], $Xco_ords[$counter], $text1[$counter], $text2[$counter], 
            $text3[$counter], $text4[$counter], $weekday[$counter], $monthday[$counter], 
            $monthlet[$counter], $yeartime[$counter], $colour[$counter], $image[$counter], 
            $position[$counter]
        ) = split(" ");
        $counter++;
    }
    close(MF);

    my %warning_length = (
        quake        => $labelsettings->{'LabelWarningQuake'} * 1,
        cloud        => $labelsettings->{'LabelWarningCloud'} * 1,
        norad        => $labelsettings->{'LabelWarningNorad'} * 1,
        hurricane    => $labelsettings->{'LabelWarningStorm'} * 1,
        volcano      => $labelsettings->{'LabelWarningVolcano'} * 1,
        quakeerror   => $labelsettings->{'LabelWarningQuake'} * 2,
        clouderror   => $labelsettings->{'LabelWarningCloud'} * 2,
        noraderror   => $labelsettings->{'LabelWarningNorad'} * 2,
        hurricaneerror => $labelsettings->{'LabelWarningStorm'} * 2,
        volcanoerror => $labelsettings->{'LabelWarningVolcano'} * 2,
    );

    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    $thisday = (qw(Sun Mon Tues Wed Thurs Fri Sat))[$wday];
    $thismonth = (qw(Jan Feb March April May June July Aug Sept Oct Nov Dec))[$mon];
    $year += 1900;
    $time_now = time;

    open(MF, ">$label_file") or die "Cannot open $label_file: $!";
    $openfile = 'UpdateLabel';
    &file_header($openfile);

    my $recounter = 0;

    while ($recounter != $counter) {
        if ($update_earth && $text1[$recounter] =~ /Earthquake/) {
            process_update(\*MF, $update_earth, 'quake', $ok_color, $warn_color, $failed_color, 
                           $Yco_ords[$recounter], $Xco_ords[$recounter], $text1[$recounter], 
                           $text2[$recounter], $text3[$recounter], $text4[$recounter], 
                           $weekday[$recounter], $monthday[$recounter], $monthlet[$recounter], 
                           $yeartime[$recounter], $colour[$recounter], $image[$recounter], 
                           $position[$recounter], \%warning_length, $wday);
            $update_earth = 0;
        } elsif ($update_norad && $text1[$recounter] =~ /NORAD/) {
            process_update(\*MF, $update_norad, 'norad', $ok_color, $warn_color, $failed_color, 
                           $Yco_ords[$recounter], $Xco_ords[$recounter], $text1[$recounter], 
                           $text2[$recounter], $text3[$recounter], $text4[$recounter], 
                           $weekday[$recounter], $monthday[$recounter], $monthlet[$recounter], 
                           $yeartime[$recounter], $colour[$recounter], $image[$recounter], 
                           $position[$recounter], \%warning_length, $wday);
            $update_norad = 0;
        } elsif ($update_cloud && $text1[$recounter] =~ /Cloud/) {
            process_update(\*MF, $update_cloud, 'cloud', $ok_color, $warn_color, $failed_color, 
                           $Yco_ords[$recounter], $Xco_ords[$recounter], $text1[$recounter], 
                           $text2[$recounter], $text3[$recounter], $text4[$recounter], 
                           $weekday[$recounter], $monthday[$recounter], $monthlet[$recounter], 
                           $yeartime[$recounter], $colour[$recounter], $image[$recounter], 
                           $position[$recounter], \%warning_length, $wday);
            $update_cloud = 0;
        } elsif ($update_hurricane && $text1[$recounter] =~ /Storm/) {
            process_update(\*MF, $update_hurricane, 'hurricane', $ok_color, $warn_color, $failed_color, 
                           $Yco_ords[$recounter], $Xco_ords[$recounter], $text1[$recounter], 
                           $text2[$recounter], $text3[$recounter], $text4[$recounter], 
                           $weekday[$recounter], $monthday[$recounter], $monthlet[$recounter], 
                           $yeartime[$recounter], $colour[$recounter], $image[$recounter], 
                           $position[$recounter], \%warning_length, $wday);
            $update_hurricane = 0;
        } elsif ($update_volcano && $text1[$recounter] =~ /Volcano/) {
            process_update(\*MF, $update_volcano, 'volcano', $ok_color, $warn_color, $failed_color, 
                           $Yco_ords[$recounter], $Xco_ords[$recounter], $text1[$recounter], 
                           $text2[$recounter], $text3[$recounter], $text4[$recounter], 
                           $weekday[$recounter], $monthday[$recounter], $monthlet[$recounter], 
                           $yeartime[$recounter], $colour[$recounter], $image[$recounter], 
                           $position[$recounter], \%warning_length, $wday);
            $update_volcano = 0;
        } elsif ($Yco_ords[$recounter] =~ /-\d\d/ && $text3[$recounter] =~ /Last/ && $text4[$recounter] =~ /Updated/) {
            process_last_update(\*MF, \%warning_length, $ok_color, $warn_color, $failed_color, 
                                $time_now, $Yco_ords[$recounter], $Xco_ords[$recounter], 
                                $text1[$recounter], $text2[$recounter], $text3[$recounter], 
                                $text4[$recounter], $weekday[$recounter], $monthday[$recounter], 
                                $monthlet[$recounter], $yeartime[$recounter], $colour[$recounter], 
                                $image[$recounter], $position[$recounter]);
        }
        $recounter++;
    }
    close(MF);
}

sub process_update {
    my ($fh, $update_status, $type, $ok_color, $warn_color, $failed_color, 
        $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
        $monthlet, $yeartime, $colour, $image, $position, $warning_length, $wday) = @_;

    print $fh "$Yco $Xco \"$text1 Information Last Updated";
    substr($yeartime, -1, 1, "");  # Replace the last character with an empty string

    if ($update_status eq 'FAILED' && $colour =~ /$ok_color/) {
        print $fh " $weekday $monthday $monthlet $yeartime\" color=$warn_color";
    } elsif ($update_status eq 'FAILED' && $colour =~ /$warn_color/) {
        my $mon = num_of_month($monthlet);
        chomp $yeartime;
        my ($year_part, $min, $sec) = split(":", $yeartime, 3);
        my ($year, $hour) = split(",", $year_part, 2);
        $year -= 1900;
        my $time_state = timelocal($sec, $min, $hour, $monthday, $mon, $year);
        my $time_difference = time() - $time_state;  # Replace $time_now with current time

        if ($time_difference < $warning_length->[0]->{$type}) {
            print $fh " $weekday $monthday $monthlet $yeartime\" color=$warn_color";
        } else {
            print $fh " $weekday $monthday $monthlet $yeartime\" color=$failed_color";
        }
    } elsif ($update_status eq 'FAILED') {
        print $fh " $weekday $monthday $monthlet $yeartime\" color=$failed_color";
    } else {
        my ($sec, $min, $hour, $mday, $mon, $current_year) = localtime();
        $current_year += 1900;
        my $thisday = (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday];
        my $thismonth = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];
        printf $fh " $thisday $mday $thismonth $current_year,%02d:%02d:%02d\" color=$ok_color", $hour, $min, $sec;
    }
    print $fh " image=none position=pixel\n";
}

sub process_last_update {
    my ($fh, $warning_length, $ok_color, $warn_color, $failed_color, 
        $time_now, $Yco, $Xco, $text1, $text2, $text3, $text4, 
        $weekday, $monthday, $monthlet, $yeartime, $colour, $image, $position) = @_;

    my $mon = num_of_month($monthlet);
    chomp $yeartime;
    my ($year_part, $min, $sec) = split(":", $yeartime, 3);
    my ($year, $hour) = split(",", $year_part, 2);
    $year -= 1900;
    my $time_state = timelocal($sec, $min, $hour, $monthday, $mon, $year);
    my $time_difference = $time_now - $time_state;

    if ($text1 =~ /Earthquake/) {
        update_time_status($fh, 'quake', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
                           $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /Cloud/) {
        update_time_status($fh, 'cloud', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
                           $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /NORAD/) {
        update_time_status($fh, 'norad', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
                           $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /Storm/) {
        update_time_status($fh, 'hurricane', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
                           $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /Volcano/) {
        update_time_status($fh, 'volcano', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
                           $monthlet, $yeartime, $colour, $image, $position);
    }
}

sub update_time_status {
    my ($fh, $type, $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
        $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
        $monthlet, $yeartime, $colour, $image, $position) = @_;

    print $fh "$Yco $Xco \"$text1\" ";
    print $fh "$text2 ";
    print $fh "$text3 ";
    print $fh "$text4 ";
    print $fh "$weekday ";
    print $fh "$monthday ";
    print $fh "$monthlet ";
    print $fh "$yeartime\" ";
    
    if ($time_difference < $warning_length->{$type}) {
        print $fh "color=$ok_color";
    } elsif ($time_difference < $warning_length->{"${type}error"}) {
        print $fh "color=$warn_color";
    } else {
        print $fh "color=$failed_color";
    }
    print $fh " image=$image position=$position\n";
}

sub num_of_month {
    my ($month) = @_;
    my %months = (
        Jan => 0,  Feb => 1,  Mar => 2,  Apr => 3,  May => 4,  Jun => 5,
        Jul => 6,  Aug => 7,  Sep => 8,  Oct => 9,  Nov => 10, Dec => 11
    );
    return $months{$month};
}

sub file_header {
    my ($openfile) = @_;
    print MF "# File: $openfile\n";
    print MF "# Generated by script\n";
}

1; # End of the module
