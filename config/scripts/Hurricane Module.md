# **HURRICANE MODULE**

---

### Summary of Identified Steps

#### **1. Parse Current Storm List**
- **Goal**: Fetch the list of active storms (designators) from the Navy or other authoritative sources.
- **Sources**:
  - `stormlist.current`: Provides active storm designators (e.g., `AL192024`, `WP252024`).
  - `ftp_sector_file`: Links designators (e.g., `19L`) to storm names (e.g., `Sara`).
- **Output**: Map each designator to its basin, storm number, year, and name (if available).

---

#### **2. Map Data Sources to Designators**
- **Goal**: Determine which data source (JTWC or NHC/CPHC) corresponds to each storm.
- **Sources**:
  - **NHC/CPHC**:
    - Atlantic (`AL`), Eastern Pacific (`EP`), Central Pacific (`CP`).
    - Use `https://www.nhc.noaa.gov/storm_graphics/api/{designator}_TRACK_latest.kmz`.
  - **JTWC**:
    - Western Pacific (`WP`), North Indian Ocean (`IO`), Southern Hemisphere (`SH`), Australian Basin (`AU`).
    - Use `https://www.metoc.navy.mil/jtwc/products/{basin}{storm_number}{abbreviated_year}.kmz`.
- **Output**: Construct URLs for fetching KMZ files based on storm designators.

---

#### **3. Download and Parse KMZ Files**
- **Goal**: Extract storm data (historical and predicted paths) from KMZ files.
- **Steps**:
  1. **Download KMZ**:
     - Use `LWP::UserAgent` to fetch the KMZ file from its constructed URL.
  2. **Extract KML**:
     - Use `Archive::Zip` to extract the embedded `doc.kml` file.
  3. **Parse KML**:
     - Use `XML::LibXML` to parse storm positions, timestamps, and intensities.

---

#### **4. Generate Marker and Arc Files**
- **Goal**: Write historical and predicted storm data to their respective files.
- **Outputs**:
  - **Marker File**: Historical path.
    ```plaintext
    <latitude> <longitude> "Storm Name - Time" color=<color> symbolsize=<size>
    ```
  - **Arc File**: Predicted path.
    ```plaintext
    lat1 lon1 lat2 lon2 color={R, G, B} spacing=0.1 thickness=2
    ```

---

### Pseudo-Code for Each Step

#### Step 1: Parse Current Storm List
```perl
# Fetch the storm list
my $storm_list_url = 'https://www.nrlmry.navy.mil/atcf_web/docs/current_storms/stormlist.current';
my $storm_list_content = get($storm_list_url);

# Parse storm designators and link to names
my @storm_designators = $storm_list_content =~ /\b([a-z]{2}\d{2}\d{4})\b/gi;

# Map designators to basins and names
foreach my $designator (@storm_designators) {
    my ($basin, $storm_number, $year) = $designator =~ /([a-z]{2})(\d{2})(\d{4})/i;
    my $source = determine_source($basin);  # Determine if JTWC or NHC
    my $storm_name = lookup_storm_name($designator);  # Optional, link designator to name
    print "Designator: $designator, Name: $storm_name, Source: $source\n";
}
```

---

#### Step 2: Construct Data Source URLs
```perl
sub construct_kmz_url {
    my ($basin, $storm_number, $year, $source) = @_;
    if ($source eq 'JTWC') {
        my $abbreviated_year = substr($year, -2);  # Use abbreviated year for JTWC
        return "https://www.metoc.navy.mil/jtwc/products/${basin}${storm_number}${abbreviated_year}.kmz";
    } elsif ($source eq 'NHC') {
        return "https://www.nhc.noaa.gov/storm_graphics/api/${basin}${storm_number}${year}_TRACK_latest.kmz";
    }
    return undef;  # Return undefined if no source is matched
}
```

---

#### Step 3: Download and Parse KMZ Files
```perl
sub parse_kmz {
    my ($kmz_url, $output_dir) = @_;
    my $ua = LWP::UserAgent->new;

    # Download the KMZ file
    my $response = $ua->get($kmz_url, ':content_file' => "$output_dir/temp.kmz");
    die "Failed to download KMZ from $kmz_url: " . $response->status_line unless $response->is_success;

    # Extract the KML content
    my $zip = Archive::Zip->new("$output_dir/temp.kmz");
    my $kml_content = $zip->contents('doc.kml');
    die "Failed to extract doc.kml from $kmz_url" unless defined $kml_content;

    # Parse the KML file
    my $parser = XML::LibXML->new();
    my $doc = $parser->load_xml(string => $kml_content);

    foreach my $placemark ($doc->findnodes('//Placemark')) {
        my $timestamp = $placemark->findvalue('.//TimeStamp/when');
        my $coordinates = $placemark->findvalue('.//Point/coordinates');
        print "Timestamp: $timestamp, Coordinates: $coordinates\n";
    }
}
```

---

#### Step 4: Generate Marker and Arc Files
```perl
# Historical Path
open(my $marker_fh, '>', $marker_file);
foreach my $point (@historical_points) {
    printf $marker_fh "%7.2f %7.2f \"%s - %s\" color=Yellow symbolsize=5\n",
        $point->{lat}, $point->{lon}, $storm_name, $point->{timestamp};
}
close($marker_fh);

# Predicted Path
open(my $arc_fh, '>', $arc_file);
for (my $i = 0; $i < $#predicted_points; $i++) {
    printf $arc_fh "%7.2f %7.2f %7.2f %7.2f color={0, 255, 0} spacing=0.1 thickness=2\n",
        $predicted_points[$i]{lat}, $predicted_points[$i]{lon},
        $predicted_points[$i+1]{lat}, $predicted_points[$i+1]{lon};
}
close($arc_fh);
```

---

### Next Steps and JTWC Data Source

1. **Validate Current Workflow**:
   - Test parsing and output generation for sample storms.

2. **Incorporate JTWC Data**:
   - Use the JTWC KMZ files (e.g., `https://www.metoc.navy.mil/jtwc/products/wp2524.kmz`) to expand global coverage.

3. **Refine Basin Mapping**:
   - Ensure all basins (e.g., SH, WP, IO) are correctly mapped to JTWC or NHC sources.

4. **Integrate Additional Data**:
   - Add robustness to handle overlapping regions and edge cases.

---

