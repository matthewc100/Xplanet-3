###############################################################
# 29 September 2024
# Revised by Matt Coblentz
#
# Original module design by Michael Dear
# 
# Why revise this code?
# The orignal code did not make use of the LibXML module.  Using LibXML seemed to be a
# much simpler approach to maintaining the code as we can now simply look for an
# element within the feed and extract it.  Also, the file handling needed to be updated
# and the variables needed to be scoped appropriately, once the original script was
# modularized to improve overall maintainability.  
#
# General processing flow
    # XML Parsing:
        # We use XML::LibXML to parse an XML file. The findnodes('//info') call locates all <info> elements in the document.
        # For each <info>, we extract the volcano name using the XPath ./eventCode[valueName="Volcano Name"]/value.  Using
        # XPath queries after registering the namespace makes this very easy to maintain.  If the namespace changes,
        # the code will adapt to the changed name.  If the <eventCode><VolcanoName><Value> schema changes, then we'd have to
        # update the namespace (ns) query, but that's pretty simple.  
        # We extract the latitude and longitude from the <circle> element using a regex pattern that looks for two 
        # floating-point numbers (latitude and longitude).

    # Why Switch to $xpc (XPath Context)?
        # XML::LibXML::XPathContext ($xpc) is specifically designed to handle namespaces in XPath queries. When XML documents 
        # use namespaces, simply calling findnodes() or findvalue() on the document or node (like $info->findnodes()) will not 
        # account for the namespaces unless the context is explicitly provided.
    # Why is $xpc Necessary for Correct Extraction?
        # Namespace-Aware Queries:
            # In an XML document with namespaces, every element belongs to a specific namespace. When querying such an XML document, 
            # the XPath expression needs to specify the namespace prefix.
            # XML::LibXML::XPathContext allows you to register a namespace with a prefix (in this case, ns), and ensures that all your 
            # XPath queries are run within that namespace context.
    # Namespace Registration:
        # When you create a new XPath context with $xpc = XML::LibXML::XPathContext->new($doc), you associate the entire XML document 
        # with a context that understands namespaces.
        # Using $xpc->registerNs('ns', $namespace_uri) registers the namespace for use in XPath queries. Once registered, XPath 
        # queries that reference ns: will be mapped to the correct namespace.
    # How XPath Queries Work with $xpc:
        # The findvalue() and findnodes() methods of $xpc know how to match elements that are within the registered namespace, and 
        # by using the registered prefix (ns:), you ensure that the correct elements are matched.
        # Without $xpc, the document or individual elements ($info->findnodes()) would not know which namespace the elements belong 
        # to, and the query would fail.
    # Namespace-Sensitive Queries: 
        # Once the namespace is registered in $xpc, your XPath queries can target elements using the ns: 
        # prefix, which ensures that your query is namespace-sensitive.

    # Writing to the Output File:
        # For each volcano instance, three lines are printed to the output file with different colors and symbol sizes, 
        # following your required format.
            # Note: after a lot of trial and error, I gave up trying to deliberately pass the file handle as a glob and just passed 
            # the file handle directly, which worked.  
    # Handling Geo-coordinates: 
        # The circle element typically contains a string of the form "-6.1370,155.1960 0". The regex extracts the 
        # latitude and longitude, ignoring the optional distance (0).cd
    # Error Handling:
        # The program includes basic error handling to ensure that the XML file is parsed correctly and that the output file can be written.
# Other items:
    # Selecting the First <circle> Element:
        # We now specifically extract the first circle element using XPath ./area/circle[1]. 
        # This ensures that we only process the first instance, ignoring any additional circles.
    # Handling Circle Element:
        # The regex has been slightly modified to match the WGS 84 coordinate pair (latitude,longitude) 
        # followed by a radius in kilometers (e.g., "-6.1370,155.1960 0").  
        # The radius is not used in this case, but we ensure it's properly handled in the matching logic.
#
# Michael's original script allowed for additional volcano metadata which is no longer in the
# XML file.  I have removed that option.  
# 
# Work remaining to be done:
# Michael originally allowed for additional images and symbols for the output marker file.  
# That work needs to be re-incorporated here.  

package VolcanoXML;
use strict;
use warnings;
use XML::LibXML;
use LWP::UserAgent;  # Add this module to fetch the XML from a URL
use Exporter 'import';
our @EXPORT_OK = qw(process_volcano_data check_volcano_data);

use Globals qw($volcano_marker_file $volcanosettings);

########################################################
#  CONFIGURATION DATA
#  The location of the volcano data is in an XML file defined below
########################################################
# The volcano location URL is now handled internally within the module
my $volcano_location = "https://volcano.si.edu/news/WeeklyVolcanoCAP.xml";

# Process the volcano data from the XML location and write to the marker file
sub process_volcano_data {
    # Create a user agent to fetch the XML data from the URL
    my $ua = LWP::UserAgent->new();
    $ua->timeout(15);  # Set a timeout for the request

    # Fetch the XML data from the URL
    my $response = $ua->get($volcano_location);

    # Check if the request was successful
    if ($response->is_success) {
        my $xml_content = $response->decoded_content;

        # Create a new XML::LibXML parser object and parse the XML content
        my $parser = XML::LibXML->new();
        my $doc = $parser->load_xml(string => $xml_content);  # Load XML from the string

        # Dynamically extract the namespace from the root element
        my $root_element = $doc->documentElement();
        my $namespace_uri = $root_element->namespaceURI();

        # Register the namespace dynamically with a prefix (e.g., 'ns')
        my $xpc = XML::LibXML::XPathContext->new($doc);
        $xpc->registerNs('ns', $namespace_uri);  # Register the detected namespace

        # Find all <ns:info> nodes (use the namespace prefix 'ns')
        my @info_nodes = $xpc->findnodes('//ns:info');

#        foreach my $info (@info_nodes) {
#            # Extract the volcano name
#            my $volcano_name = $xpc->findvalue('./ns:eventCode[ns:valueName="Volcano Name"]/ns:value', $info);
#                            
#            # Extract the geo-coordinates
#            my $geo_circle = $xpc->findvalue('./ns:area/ns:circle[1]', $info); 
#        }

        # Open the volcano marker file for writing
        open(my $VOLCANO_FH, '>', $volcano_marker_file) 
            or die "Cannot open $volcano_marker_file: $!";

        # Pass the filehandle (VOLCANO_FH) to Label::file_header for writing the header.
        Label::file_header($volcano_marker_file, $VOLCANO_FH);  # Pass filehandle directly, not as a glob
        
        # Iterate over each <info> element in the XML file
        foreach my $info ($xpc->findnodes('//ns:info')) {  # Ensure to use $xpc with the correct namespace      

            # Extract the volcano name using the namespace prefix
            my $volcano_name = $xpc->findvalue('./ns:eventCode[ns:valueName="Volcano Name"]/ns:value', $info);      

            # Extract the first geo-coordinates (latitude and longitude) from the first <ns:circle> element
            my $geo_circle = $xpc->findvalue('./ns:area/ns:circle[1]', $info);  # Only grab the first circle element        

            # Check if the circle has valid coordinates (WGS 84 coordinate pair followed by radius)
            if ($geo_circle =~ /^(-?\d+\.\d+),(-?\d+\.\d+)\s+\d+/) {
                my $latitude  = $1;  # Extracted latitude
                my $longitude = $2;  # Extracted longitude      

                # Format latitude and longitude with two decimal places
                $latitude  = sprintf("% 7.2f", $latitude);
                $longitude = sprintf("% 7.2f", $longitude);
                
                # Output the required lines in the marker file
                print $VOLCANO_FH "$latitude  $longitude \"\" color=$volcanosettings->{'VolcanoCircleColorInner'} symbolsize=$volcanosettings->{'VolcanoCircleSizeInner'}\n";
                print $VOLCANO_FH "$latitude  $longitude \"\" color=$volcanosettings->{'VolcanoCircleColorMiddle'} symbolsize=$volcanosettings->{'VolcanoCircleSizeMiddle'}\n";
                print $VOLCANO_FH "$latitude  $longitude \"$volcano_name\" color=$volcanosettings->{'VolcanoCircleColorOuter'} symbolsize=$volcanosettings->{'VolcanoCircleSizeOuter'} align=$volcanosettings->{'VolcanoNameAlign'}\n";
            }
        }
        
        # Close the marker file
        close($VOLCANO_FH) or die "Cannot close $volcano_marker_file: $!";
        print "Volcano marker file updated: $volcano_marker_file\n";
    } else {
        # If the request fails, print an error message and exit
        die "Failed to fetch XML from $volcano_location: " . $response->status_line;
    }
}

# Check whether the volcano data is up to date
sub check_volcano_data {
    my $MaxDownloadFrequencyHours = 24;

    # Check if the volcano marker file exists and its age
    if (-f $volcano_marker_file) {
        my @Stats = stat($volcano_marker_file);
        my $FileAge = (time() - $Stats[9]);

        # If the file is up to date, return false (no need to update)
        if ($FileAge < 60 * 60 * $MaxDownloadFrequencyHours) {
            print "Volcano data is up to date!\n";
            return 0;
        }
    }

    # If the file doesn't exist or is outdated, return true (needs updating)
    return 1;
}

1; # End of the module