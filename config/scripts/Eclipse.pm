package Eclipse;
use strict;
use warnings;
use Exporter 'import';
use Globals qw  (
    $eclipse_arc_file
    $eclipse_data_file
    $eclipse_location
    $eclipse_marker_file
    @eclipsedata
    @eclipsetrack
    @eclipserefined
    $settings
);

our @EXPORT_OK = qw(
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

sub get_eclipsedata() {
    my $counter = 0;
    my $file  = "SEpath.html";
    my @eclipsedatatmp;
    my $eclipseoverride;
    my $tsn;
    print "Please Wait Building Eclipse Database. This could take a minute.\n.";
    my $eclipsetxt  = get_webpage($eclipse_location.$file);
    if ($eclipsetxt =~ /FAILED/ ) {
        $eclipseoverride = 1;
    } else {
        open (MF, ">$eclipse_data_file");
        $tsn = localtime(time);
        print MF "#\n# Last Updated: $tsn\n#\n";
        print MF "[DATA]\n";
        
        foreach (split(/<TR>/,$eclipsetxt)) {
            s/^\s+//;
            s/\s+$//;
            s/\s+/ /g;
            s/<TD>/ /g;
            s/<\/A>//g;
            s/<A HREF="//g;
            s/">//g;
            s/path//g;
            s/map//g;
            
            my ($a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $a10) = split " ";
            if ($a1 =~ /\d\d\d\d/) {
                my $year = $a1;
                my $monthtxt = $a2;
                my $monthnum = num_of_month($monthtxt);
                my $dayofmonth = $a3;
                my $type = $a4;
                $type = sprintf("%-7s",$type);
                my $saros = $a6;
                my $eclmag = $a7;
                my $duration = $a8;
                my $path = $a10;
                substr($path, 2, 0) = 'path';
                my $time_now = time;
                my $secsperday = 86400;
                my $time_state = timelocal(59,59,23,$dayofmonth,$monthnum,$year);
                
                if ($time_state < $time_now) {
                    # Do nothing
                } else {
                    print ".";
                    print MF "$dayofmonth, $monthtxt, $year, $type, $saros, $eclmag, $duration, CRUDE\n";
                    push @eclipsedatatmp, {'path' => $path};
                    $counter++;
                }
            }
        }
    }
    
    my $recounter = 0;
    
    print "\nBuilt Index $counter Entries, Starting to fill data sets.\n";
    while ($recounter < $counter) {
        $eclipsetxt  =  get_webpage($eclipse_location.$eclipsedatatmp[$recounter]->{'path'});
        
        if ($eclipsetxt =~ /FAILED/) {
            return $eclipsetxt;
        } else {
            print MF "[TRACK,$recounter]\n";
            
            foreach (split(/\d\dm\d\d.\ds/,$eclipsetxt)) {
                s/^\s+//;
                s/\s+$//;
                s/\s+/ /g;
                
                my ($a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $a10, $a11, $a12, $a13, $a14) = split " ";
                
                if ($a1 =~ /\d\d:\d\d/) {
                    my ($hour,$min) = split ":",$a1;
                    my ($tmp,$tmp1) = split '\.',$a3;
                    my $tmp2 = substr($tmp1,-1,1);
                    chop $tmp1;
                    
                    if ($tmp1 >= 5) {$tmp++;}
                    my $northlat = $a2.'.'.$tmp.$tmp2;
                    ($tmp,$tmp1) = split '\.',$a5;
                    $tmp2 = substr($tmp1,-1,1);
                    chop $tmp1;
                    
                    if ($tmp1 >= 5) {$tmp++;}
                    my $northlong = $a4.'.'.$tmp.$tmp2;
                    ($tmp,$tmp1) = split '\.',$a7;
                    $tmp2 = substr($tmp1,-1,1);
                    chop $tmp1;
                    
                    if ($tmp1 >= 5) {$tmp++;}
                    my $southlat = $a6.'.'.$tmp.$tmp2;
                    ($tmp,$tmp1) = split '\.',$a9;
                    $tmp2 = substr($tmp1,-1,1);
                    chop $tmp1;
                    
                    if ($tmp1 >= 5) {$tmp++;}
                    my $southlong = $a8.'.'.$tmp.$tmp2;
                    ($tmp,$tmp1) = split '\.',$a11;
                    $tmp2 = substr($tmp1,-1,1);
                    chop $tmp1;
                    
                    if ($tmp1 >= 5) {$tmp++;}
                    my $centrallat = $a10.'.'.$tmp.$tmp2;
                    ($tmp,$tmp1) = split '\.',$a13;
                    $tmp2 = substr($tmp1,-1,1);
                    chop $tmp1;
                    
                    if ($tmp1 >= 5) {$tmp++;}
                    my $centrallong = $a12.'.'.$tmp.$tmp2;
                    my $sign;
                    
                    if($northlat =~ /(\d+\.\d+)([NS])/) {
                        ($northlat,$sign)=($1,$2);
                        $northlat *= -1 if $sign =~ /s/i;
                    }
                    $northlat *= 1;
                    $northlat = sprintf("% 6.2f",$northlat);
                    
                    if($northlong =~ /(\d+\.\d+)([WE])/) {
                        ($northlong,$sign)=($1,$2);
                        $northlong *= -1 if $sign =~ /w/i;
                    }
                    $northlong *= 1;
                    $northlong = sprintf("% 6.2f",$northlong);
                    
                    if($southlat =~ /(\d+\.\d+)([NS])/) {
                        ($southlat,$sign)=($1,$2);
                        $southlat *= -1 if $sign =~ /s/i;
                    }
                    $southlat *= 1;
                    $southlat = sprintf("% 6.2f",$southlat);
                    
                    if($southlong =~ /(\d+\.\d+)([WE])/) {
                        ($southlong,$sign)=($1,$2);
                        $southlong *= -1 if $sign =~ /w/i;
                    }
                    $southlong *= 1;
                    $southlong = sprintf("% 6.2f",$southlong);
                    
                    if($centrallat =~ /(\d+\.\d+)([NS])/) {
                        ($centrallat,$sign)=($1,$2);
                        $centrallat *= -1 if $sign =~ /s/i;
                    }
                    $centrallat *= 1;
                    $centrallat = sprintf("% 6.2f",$centrallat);
                    
                    if($centrallong =~ /(\d+\.\d+)([WE])/) {
                        ($centrallong,$sign)=($1,$2);
                        $centrallong *= -1 if $sign =~ /w/i;
                    }
                    $centrallong *= 1;
                    $centrallong = sprintf("% 6.2f",$centrallong);
                    
                    print ".";
                    printf MF "%03d,%02d:%02d, $northlat, $northlong, $centrallat, $centrallong, $southlat, $southlong,\n",$recounter,$hour,$min;
                }
            }
        }
        print "\nFilled Data Set #$recounter\n";
        
        $recounter++;
    }
    
    close MF;
}

sub readineclipseindex () {
    open (MF, "<$eclipse_data_file");
    my $datatype;
    my $counter = 0;
    my @eclipsedata;
    
    while (<MF>) {
        foreach (split "\n" ) {
            my ($data1, $data2, $data3, $data4, $data5, $data6, $data7, $data8) = split ",";
            if ($data1 =~ /DATA/) {
                $datatype = 'DATA';
            }
            elsif ($data1 =~ /TRACK/) {
                $datatype = 'TRACK';
            }
            elsif ($data1 =~ /#/) {
                $datatype = 'COMMENT';
            }
            else {}
            
            if ($datatype eq 'COMMENT') {}
            
            if ($datatype eq 'DATA') {
                if ($data1 =~ /DATA/) {}
                else {
                    push @eclipsedata, {
                        'dayofmonth'     => $data1,
                        'monthtxt'       => $data2,
                        'year'           => $data3,
                        'type'           => $data4,
                        'saros'          => $data5,
                        'eclmag'         => $data6,
                        'duration'       => $data7,
                        'detail'         => $data8,
                    };
                    #print "$data1, $data2, $data3, $data4, $data5, $data6, $data7, $data8\n";
                    
                    $counter++;
                }
            }
        }
    }
    
    close MF;
    return $counter;
}

sub readineclipsetrack () {
    my($dataset) = @_;
    open (MF, "<$eclipse_data_file");
    my $datatype;
    my $counter = 0;
    my @eclipsetrack;
    
    while (<MF>) {
        foreach (split "\n" ) {
            my ($data1, $data2, $data3, $data4, $data5, $data6, $data7, $data8) = split ",";
            if ($data1 =~ /DATA/) {
                $datatype = 'DATA';
            }
            elsif ($data1 =~ /TRACK/) {
                $datatype = 'TRACK';
            }
            elsif ($data1 =~ /#/) {
                $datatype = 'COMMENT';
            }
            
            if ($datatype eq 'COMMENT') {};
            if ($datatype eq 'DATA') {}
            if ($datatype eq 'TRACK') {
                $dataset = sprintf("%03d",$dataset);
                #print "$data1, $dataset\n";
                if ($data1 eq $dataset) {
                    if ($data1 =~ /TRACK/) {}
                    else {
                        my ($hour, $min) = split ":",$data2;
                        
                        push @eclipsetrack, {
                            'hour'           => $hour,
                            'minute'         => $min,
                            'nlat'           => $data3,
                            'nlong'          => $data4,
                            'slat'           => $data7,
                            'slong'          => $data8,
                            'clat'           => $data5,
                            'clong'          => $data6,
                        };
                        #print "$counter: $hour:$min, $data3, $data4, $data5, $data6, $data7, $data8\n";
                        
                        $counter++;
                    }
                }
            }
        }
    }
    
    close MF;
    return $counter;
}

sub datacurrent () {
    my ($counter) = @_;
    my $notice = $settings->{'EclipseNotifyTimeHours'}*3600;
    my $recounter = 0;
    my $monthnum;
    my $next_eclipse;
    my $time_now;
    my @eclipsedata;
    my $result;
    
    while ($recounter < $counter) {
        $monthnum = num_of_month($eclipsedata[$recounter]->{'monthtxt'});
        $next_eclipse = timelocal(59,59,23,$eclipsedata[$recounter]->{'dayofmonth'},$monthnum,$eclipsedata[$recounter]->{'year'});
        $time_now = time;
        
        if ($time_now < $next_eclipse) {
            $result = $next_eclipse-$time_now;
            
            if (($next_eclipse-$time_now) < $notice ) {
                return $recounter;
            }
            else {
                # CHANGE THIS VALUE AFTER TESTING!
                return 'NONE';
            }
        }
        
        
        $recounter++;
    }
}

sub writeouteclipsemarker() {
    my ($counter) = @_;
    my $recounter = 1;
    my @eclipsetrack;
    
    if ($counter =~ /FAILED/) {}
    else {
        my $openfile = 'Eclipse';
        open (MF, ">$eclipse_marker_file");
        &file_header($openfile);
        printf MF "$eclipsetrack[1]->{'clat'}$eclipsetrack[1]->{'clong'} \"%02d:%02d\" color=Grey align=left\n",$eclipsetrack[1]->{'hour'}, $eclipsetrack[1]->{'minute'};
        printf MF "$eclipsetrack[($counter-1)]->{'clat'}$eclipsetrack[($counter-1)]->{'clong'} \"%02d:%02d\" color=Grey align=right\n",$eclipsetrack[($counter-1)]->{'hour'}, $eclipsetrack[($counter-1)]->{'minute'};

        while ($recounter < $counter) {
            if ($eclipsetrack[$recounter]->{'minute'} =~ /[240]0/) {
                printf MF "$eclipsetrack[$recounter]->{'clat'}$eclipsetrack[($recounter)]->{'clong'} \"%02d:%02d\" color=Grey align=top symbolsize=4\n",$eclipsetrack[($recounter)]->{'hour'}, $eclipsetrack[($recounter)]->{'minute'};
                $recounter++;
            }
            
            $recounter++;
        }
    }
    
    close MF;
}

sub writeouteclipsearcboarder () {
    my ($counter) = @_;
    my $recounter = 1;
    my @eclipsetrack;
    
    if ($counter =~ /FAILED/) {}
    else {
        my $openfile = 'Eclipse';
        open (MF, ">>$eclipse_arc_file");
        print MF "\n\n# Northern Limit Track\n";
        
        while  ($recounter < $counter) {
            if (($recounter+1) != $counter) {
                print MF "$eclipsetrack[$recounter]->{'nlat'}$eclipsetrack[$recounter]->{'nlong'}$eclipsetrack[$recounter+1]->{'nlat'}$eclipsetrack[$recounter+1]->{'nlong'} color=Grey spacing=0.2\n";
            }
            $recounter++
        }
        
        $recounter  = 1;
        print MF "\n\n# Southern Limit Track\n";
        while  ($recounter < $counter) {
            if (($recounter+1) != $counter) {
                print MF "$eclipsetrack[$recounter]->{'slat'}$eclipsetrack[$recounter]->{'slong'}$eclipsetrack[$recounter+1]->{'slat'}$eclipsetrack[$recounter+1]->{'slong'} color=Grey spacing=0.2\n";
            }
            $recounter++
        }
        close MF;
    }
}

sub writeouteclipsearccenter () {
    my ($counter) = @_;
    my $recounter = 1;
    my @eclipsetrack;
    
    if ($counter =~ /FAILED/) {}
    else {
        my $openfile = 'Eclipse';
        open (MF, ">$eclipse_arc_file");
        &file_header($openfile);
        print MF "# Central Track\n";
        
        while  ($recounter < $counter) {
            if (($recounter+1) != $counter) {
                print MF "$eclipsetrack[$recounter]->{'clat'}$eclipsetrack[$recounter]->{'clong'}$eclipsetrack[$recounter+1]->{'clat'}$eclipsetrack[$recounter+1]->{'clong'} color=Black spacing=0.2\n";
            }
            $recounter++;
        }
        close MF;
    }
}

sub writeouteclipsefilesnone() {
    open (MF, ">$eclipse_marker_file");
    my $openfile = 'Eclipse';
    &file_header($openfile);
    close MF;
    open (MF, ">$eclipse_arc_file");
    &file_header($openfile);
    close MF;
}

sub writeouteclipselabel() {
    my ($record_number,$track_number,$countdown) = @_;
    $countdown *= 1;
    my $answer;
    my @eclipsetrack;
    my @eclipsedata;
    my $minutes;
    $answer = ($countdown / 3600 );
    my ($hours,$ignore) = split('\.',$answer);
    $countdown = ($countdown-($hours*3600));
    $answer = ($countdown / 60 );
    ($minutes,$ignore) = split('\.',$answer);
    #print "countdown = $countdown, hours = $hours, min = $min\n";
    my $biggestlat = $eclipsetrack[1]->{'clat'};
    my $smallestlat = $eclipsetrack[1]->{'clat'};
    my $biggestlong = $eclipsetrack[1]->{'clong'};
    my $smallestlong = $eclipsetrack[1]->{'clong'};
    my $counter = 2;
    
    while ($counter < ($track_number+1)) {
        if ($biggestlat < $eclipsetrack[$counter]->{'clat'}) {
            $biggestlat = $eclipsetrack[$counter]->{'clat'};
        }
        if ($smallestlat > $eclipsetrack[$counter]->{'clat'}) {
            $smallestlat = $eclipsetrack[$counter]->{'clat'};
        }
        if ($biggestlong < $eclipsetrack[$counter]->{'clong'}) {
            $biggestlong = $eclipsetrack[$counter]->{'clong'};
        }
        if ($smallestlong > $eclipsetrack[$counter]->{'clong'}) {
            $smallestlong = $eclipsetrack[$counter]->{'clong'};
        }
        $counter++;
    }
    
    my $lat = ($biggestlat + $smallestlat) / 2;
    my $long = ($biggestlong + $smallestlong) / 2;
    
    open(MF, ">>$eclipse_marker_file");
    printf MF "\n\n-55 1 \"A$eclipsedata[$record_number]->{'type'} Eclipse will be occuring in $hours hours and $minutes minutes, starting at $eclipsedata[$record_number]->{'dayofmonth'} $eclipsedata[$record_number]->{'monthtxt'} $eclipsedata[$record_number]->{'year'} %02d:%02d GMT\" color=White image=none position=pixel\n",$eclipsetrack[1]->{'hour'},$eclipsetrack[1]->{'minute'};
    print MF "-45 1 \"To view this the best loaction is Latitude $lat ,Longitude $long,\" color=White image=none position=pixel\n";
    print MF "-35 1 \"The Eclipse Track has been put on the map, and will remain until the eclipse has passed.\" color=White image=none position=pixel\n";
    close MF;
}

sub refinedata() {
    my ($record_number) = @_;
    my $counter = 0;
    my $recounter = 0;
    my $linecounter = 0;
    my $datac = 0;
    my $flag = 0;
    my $updatefile = "http://www.wizabit.eclipse.co.uk/xplanet/files/local/update.data";
    my $updateddata = get_webpage($updatefile);
    my $updatedata;
    my @eclipserefined;
    my @eclipsetempfile =();
    my @eclipsedata;

    
    if ($updatedata =~ /FAILED/) {}
    else {
        foreach (split "\n",$updateddata) {
            my ($t1,$t2,$nlat,$nlong,$clat,$clong,$slat,$slong) = split ",";
            
            if ($t1 =~ /(\d\d)(\w\w\w)(\d\d\d\d)/) {
                my ($day,$month,$year) = ($1,$2,$3);
                my ($hour,$minute) = split ":",$t2;
                
                $clong = sprintf("% 6.2f",$clong);
                $clat = sprintf("% 6.2f",$clat);
                $slong = sprintf("% 6.2f",$slong);
                $slat = sprintf("% 6.2f",$slat);
                $nlong = sprintf("% 6.2f",$nlong);
                $nlat = sprintf("% 6.2f",$nlat);
                
                push @eclipserefined, {
                    'day'       => $day,
                    'month'     => $month,
                    'year'      => $year,
                    'hour'      => $hour,
                    'minute'    => $minute,
                    'nlat'      => $nlat,
                    'nlong'     => $nlong,
                    'clat'      => $clat,
                    'clong'     => $clong,
                    'slat'      => $slat,
                    'slong'     => $slong,
                };
                $counter++;
            }
        }
        
        open (MF, "<$eclipse_data_file");
        while (<MF>) {
            foreach (split "\n",) {
                my ($data1,$data2,$data3,$data4,$data5,$data6,$data7,$data8) = split ",";
                @eclipsetempfile = ();
                
                push @eclipsetempfile, {
                    'element1'        => $data1,
                    'element2'        => $data2,
                    'element3'        => $data3,
                    'element4'        => $data4,
                    'element5'        => $data5,
                    'element6'        => $data6,
                    'element7'        => $data7,
                    'element8'        => $data8,
                };
                $recounter++;
            }
        }
        close MF;
        
        substr($eclipsedata[$record_number]->{'monthtxt'},0,1) = "";
        substr($eclipsedata[$record_number]->{'year'},0,1) = "";
        #print "$eclipserefined[0]->{'day'}:$eclipsedata[$record_number]->{'dayofmonth'} and $eclipserefined[0]->{'month'}:$eclipsedata[$record_number]->{'monthtxt'} and $eclipserefined[0]->{'year'}:$eclipsedata[$record_number]->{'year'}";
        
        if ($eclipserefined[0] -> {'day'} eq $eclipsedata[$record_number] -> {'dayofmonth'} && $eclipserefined[0] -> {'month'} eq $eclipsedata[$record_number] -> {'monthtxt'} && $eclipserefined[0] -> {'year'} eq $eclipsedata[$record_number] -> {'year'}) {
            open (MF, ">$eclipse_data_file");
            my $tsn = localtime(time);
            print MF "\#\n\# Last Updated: $tsn\n\#\n";
            $eclipsedata[$record_number]->{'detail'} = 'INT';
            
            while ($linecounter < $recounter) {
                if ($eclipsetempfile[$linecounter]->{'element1'} =~ /\#/) {
                    $flag = 2;
                }
                
                if ($eclipsetempfile[$linecounter]->{'element1'} =~ /\[DATA/) {
                    $flag = 3;
                }
                
                if ($eclipsetempfile[$linecounter]->{'element1'} =~ /\[TRACK/) {
                    my ($tmp1,$tmp2) = split "]",$eclipsetempfile[$linecounter]->{'element2'};
                    chop $tmp2;
                    chop $tmp2;
                    
                    if ($tmp1 eq $record_number) {
                        $flag = 1;
                    }
                    else {
                        $flag = 5;
                    }
                }
                
                if ($flag eq 0) {
                    print MF "$eclipsetempfile[$linecounter]->{'element1'},$eclipsetempfile[$linecounter]->{'element2'},$eclipsetempfile[$linecounter]->{'element3'},$eclipsetempfile[$linecounter]->{'element4'},$eclipsetempfile[$linecounter]->{'element5'},$eclipsetempfile[$linecounter]->{'element6'},$eclipsetempfile[$linecounter]->{'element7'},$eclipsetempfile[$linecounter]->{'element8'}\n";
                }
                elsif ($flag eq 1) {
                    print MF "$eclipsetempfile[$linecounter]->{'element1'},$eclipsetempfile[$linecounter]->{'element2'}\n";
                    
                    while ($datac < $counter) {
                        printf MF "%03d,$eclipserefined[$datac]->{'hour'}:$eclipserefined[$datac]->{'minute'}, $eclipserefined[$datac]->{'nlat'}, $eclipserefined[$datac]->{'nlong'}, $eclipserefined[$datac]->{'clat'}, $eclipserefined[$datac]->{'clong'}, $eclipserefined[$datac]->{'slat'}, $eclipserefined[$datac]->{'slong'}\n",$record_number;
                        $datac++;
                    }
                    $flag = 2;
                }
                elsif ($flag eq 2) {}
                elsif ($flag eq 4) {
                    substr($eclipsetempfile[$linecounter]->{'element2'},0,1) = "";
                    substr($eclipsetempfile[$linecounter]->{'element3'},0,1) = "";
                    if ($eclipserefined[0]->{'day'} eq $eclipsetempfile[$linecounter]->{'element1'} && $eclipserefined[0]->{'month'} eq $eclipsetempfile[$linecounter]->{'element2'} && $eclipserefined[0]->{'year'} eq $eclipsetempfile[$linecounter]->{'element3'}) {
                        print MF "$eclipsetempfile[$linecounter]->{'element1'},$eclipsetempfile[$linecounter]->{'element2'},$eclipsetempfile[$linecounter]->{'element3'},$eclipsetempfile[$linecounter]->{'element4'},$eclipsetempfile[$linecounter]->{'element5'},$eclipsetempfile[$linecounter]->{'element6'},$eclipsetempfile[$linecounter]->{'element7'}, INTER\n";
                    }
                    else {
                        print MF "$eclipsetempfile[$linecounter]->{'element1'},$eclipsetempfile[$linecounter]->{'element2'},$eclipsetempfile[$linecounter]->{'element3'},$eclipsetempfile[$linecounter]->{'element4'},$eclipsetempfile[$linecounter]->{'element5'},$eclipsetempfile[$linecounter]->{'element6'},$eclipsetempfile[$linecounter]->{'element7'},$eclipsetempfile[$linecounter]->{'element8'}\n";
                    }
                }
                elsif ($flag eq 3) {
                    print MF "$eclipsetempfile[$linecounter]->{'element1'}\n";
                    $flag = 4;
                }
                elsif ($flag eq 5) {
                    print MF "$eclipsetempfile[$linecounter]->{'element1'}$eclipsetempfile[$linecounter]->{'element2'}\n";
                    $flag = 0;
                }
                
                $linecounter++;
            }
        }
        close MF;
    }
}

1; # End of the module with a true value