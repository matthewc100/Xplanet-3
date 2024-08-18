package Hurricane;
use strict;
use warnings;
use Globals qw(
    $storm_past_location
    $storm_future_location
    $storm_base_location
    $hurricane_arc_file
    $hurricane_marker_file
);

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

sub get_hurricanearcdata {
    my ($hurricane_counter) = @_;
    my $recounter = 0;
    my $forcounter = 0;
    my $actcounter = 0;
    my $storm_track;
    my $temp_chop;
    my @hurricanedata;
    my @hurricanearcdataact;
    my @hurricanearcdatafor;
    my $sign;
    
    if ($hurricane_counter != 'FAILED') {
        while ($recounter < $hurricane_counter) {
            my $storm_past = get_webpage($storm_past_location.$hurricanedata[$recounter]->{'year'}."/".$hurricanedata[$recounter]->{'loc'}."/".$hurricanedata[$recounter]->{'code'}."/trackfile.txt");
            
            if ($storm_track !~ /FAILED/) {
                foreach (split("\n",$storm_past)) {
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
                        
                        push @hurricanearcdataact, {
                            'num'   => $recounter,
                            'lat'   => $lat,
                            'long'  => $long,
                            'name'  => $name,
                        };
                        
                        $actcounter++;
                    }
                }
            }
            
            $recounter++;
        }
        
        $recounter = 0;
        while ($recounter < $hurricane_counter) {
            $temp_chop = chop($hurricanedata[$recounter]->{'code'});
            $temp_chop = $storm_future_location.$hurricanedata[$recounter]->{'ocean'}.$hurricanedata[$recounter]->{'code'}.$hurricanedata[$recounter]->{'year'}.".tcw\n";
            $storm_track = get_webpage($temp_chop);
            
            if ($storm_track !~ /FAILED/) {
                foreach (split("\n",$storm_track)) {
                    if (/(T\d{3})\s(\d{3,4}\w)\s(\d{3,4}\w)\s\d{3}/) {
                        my($time,$lat,$long)=($1,$2,$3);
                        
                        if ($lat =~ /(\d+)([NS])/) {
                            ($lat,$sign)=($1,$2);
                            $lat *= -1 if $sign =~ /s/i;
                        }
                        $lat *= 0.1;
                        
                        if ($long =~ /(\d+)([WE])/) {
                            ($long,$sign)=($1,$2);
                            $long *= -1 if $sign =~ /w/i;
                        }
                        $long *= 0.1;
                        
                        push @hurricanearcdatafor, {
                            'num'   => $recounter,
                            'lat'   => $lat,
                            'long'  => $long,
                        };
                        
                        $forcounter++;
                    }
                }
            }
        
        $recounter++;
        }
        
        print "  Updated storm arc information\n";
    }
    else {
        $actcounter = 'FAILED';
        $forcounter = 'FAILED';
        print "  WARNING... unable to access or download updated storm arc information\n";
    }
    
    return $actcounter,$forcounter;
}

sub WriteoutHurricaneArc {
    my ($numhur,$numact,$numfor) = @_;
    my $counter = 0;
    my $recounter = 0;
    my $stormsettings;
    my @hurricanearcdataact;
    my @hurricanearcdatafor;
    
    if ($numhur =~ /FAILED/) {}
    elsif ($numact =~ /FAILED/) {}
    elsif ($numfor =~ /FAILED/) {}
    else {
        my $openfile = "Hurricane Arc File";
        
        open (MF, ">$hurricane_arc_file");
        &file_header($openfile);
        print MF "#\n#Thanks to Hans Ecke <http://hans.ecke.ws/xplanet> for his idea of using GreatArcs to put in the storm tracks\n\n";
        if ($stormsettings->{'StormTrackOnOff'} =~ /On/) {
            while ($counter < $numact) {
                if ($hurricanearcdataact[$counter]->{'num'} ne $hurricanearcdataact[($counter+1)]->{'num'}) {
                    $recounter++;
                    print MF "\# $hurricanearcdataact[$counter]->{'name'}\n\n";
                }
                elsif ($hurricanearcdataact[$counter]->{'num'} eq $hurricanearcdataact[($counter+1)]->{'num'}) {
                    if ( ($hurricanearcdataact[$counter]->{'lat'} -  $hurricanearcdataact[$counter+1]->{'lat'} > 10) || ($hurricanearcdataact[$counter]->{'lat'} -  $hurricanearcdataact[$counter+1]->{'lat'} < -10) || ($hurricanearcdataact[$counter]->{'long'} -  $hurricanearcdataact[$counter+1]->{'long'} > 10) || ($hurricanearcdataact[$counter]->{'long'} -  $hurricanearcdataact[$counter+1]->{'long'} < -10)) {
                    }
                    else {
                        printf MF "%.1f %.1f %.1f %.1f color=$stormsettings->{'StormColorTrackReal'}\n", $hurricanearcdataact[$counter]->{'lat'}, $hurricanearcdataact[$counter]->{'long'}, $hurricanearcdataact[($counter+1)]->{'lat'}, $hurricanearcdataact[($counter+1)]->{'long'};
                    }
                }
                else {
                    print MF "\n\n";
                }
                
                $counter++;
            }
            
            $counter = 0;
            $recounter = 0;
            while ($counter < $numfor) {
                if ($hurricanearcdatafor[$counter]->{'num'} ne $hurricanearcdatafor[($counter-1)]->{'num'}) {
                    $recounter++;
                }
                
                if ($hurricanearcdatafor[$counter]->{'num'} eq $hurricanearcdatafor[($counter+1)]->{'num'}) {
                    printf MF "%.1f %.1f %.1f %.1f color=$stormsettings->{'StormColorTrackPrediction'}\n", $hurricanearcdatafor[$counter]->{'lat'}, $hurricanearcdatafor[$counter]->{'long'}, $hurricanearcdatafor[($counter+1)]->{'lat'}, $hurricanearcdatafor[($counter+1)]->{'long'};
                }
                else {
                    print MF "\n\n";
                }
                
                $counter++;
            }
        }
    
    close MF;
    }
}

sub WriteoutHurricane {
    my ($hurricane_counter) = @_;
    my $recounter = 0;
    my $lat;
    my $long;
    my @hurricanedata;
    my $type;
    my $name;
    my $speed;
    my $file;
    my $stormsettings;
    
    if ($hurricane_counter !~ /FAILED/) {
        my $openfile = 'Hurricane';
        
        open (MF, ">$hurricane_marker_file");
        &file_header($openfile);
        while ($recounter < $hurricane_counter) {
            $type = $hurricanedata[$recounter]->{'type'};
            $lat = $hurricanedata[$recounter]->{'lat'};
            $lat  = sprintf("% 7.2f",$lat);
            $long = $hurricanedata[$recounter]->{'long'};
            $long = sprintf("% 7.2f",$long);
            $name = $hurricanedata[$recounter]->{'name'};
            $speed = $hurricanedata[$recounter]->{'speed'};
            $speed = sprintf("% 3.0f",$speed);
            $file = $hurricanedata[$recounter]->{'file'};
            $file = sprintf("%-17s",'"'.$file.'"');
            
            if ($stormsettings->{'StormNameOnOff'} =~ /On/) {
                print MF "$lat $long \"$name\" align=$stormsettings->{'StormAlignName'} color=$stormsettings->{'StormColorName'}";
                
                if ($stormsettings->{'StormImageList'} =~ /\w/) {
                    print MF " image=$stormsettings->{'StormImageList'}";
                    
                    if ($stormsettings->{'StormImageTransparent'} =~ /\w/) {
                        print MF " transparent=$stormsettings->{'StormImageTransparent'}";
                    }
                }
                print MF "\n";
            }
            
            if ($stormsettings->{'StormDetailList'} =~ /\w/) {
                my $tmp1 = $stormsettings->{'StormDetailList'};
                
                $tmp1 =~ s/<lat>/$lat/g;
                $tmp1 =~ s/<long>/$long/g;
                $tmp1 =~ s/<type>/$type/g;
                $tmp1 =~ s/<name>/$name/g;
                $tmp1 =~ s/<speed>/$speed/g;
                print MF "$lat $long \"$tmp1\" align=$stormsettings->{'StormAlignDetail'} color=$stormsettings->{'StormColorDetail'}";
            }
            
            if ($stormsettings->{'StormImageList'} =~ /\w/) {
                print MF " image=$stormsettings->{'StormImageList'}";
                if ($stormsettings->{'StormImageTransparent'} =~ /\w/) {
                    print MF " transparent=$stormsettings->{'StormImageTransparent'}";
                }
            }
            
            print MF "\n";
            $recounter++;
        }
        
        close MF;
    }
}

1; # End of the module
