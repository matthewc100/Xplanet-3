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
use LWP::UserAgent;
use File::stat;  # Required for file timestamps
use Exporter 'import';

our @EXPORT_OK = qw(process_volcano_data);

# Reference the global $DEBUG variable from the main script
use vars qw($DEBUG);

use Globals qw(
    $volcano_marker_file
    %modules
    $volcanosettings
    convert_to_epoch
);

# Define the XML data source
my $volcano_location = "https://volcano.si.edu/news/WeeklyVolcanoCAP.xml";

sub process_volcano_data {
    # Retrieve update interval from the .ini file
    my $update_interval = $Globals::modules{'labels'}{'Volcano.update_interval'};  

    # If update interval is missing, warn and set default
    unless (defined $update_interval && $update_interval =~ /^\d+$/) {
        warn "⚠️ VolcanoXML::process_volcano_data - Warning: Volcano.update_interval not found or invalid in .ini! Using default: 86400 seconds (24h).\n";
        $update_interval = 86400;  # Default: 24 hours
    }

    # Check last modification time of the volcano marker file
    if (-f $volcano_marker_file) {
        my $last_update_time = (stat($volcano_marker_file))->mtime;
        my $time_elapsed = time() - $last_update_time;

        # Skip update if it's not time yet
        if ($time_elapsed < $update_interval) {
            my $next_update_in = $update_interval - $time_elapsed;
            print "VolcanoXML::process_volcano_data - Volcano update skipped: Next update allowed in $next_update_in seconds.\n";
            return;
        }
    }

    # Proceed with fetching volcano data
    my $ua = LWP::UserAgent->new();
    $ua->timeout(15);

    my $response = $ua->get($volcano_location);

    if ($response->is_success) {
        my $xml_content = $response->decoded_content;
        my $parser = XML::LibXML->new();
        my $doc = $parser->load_xml(string => $xml_content);
        my $root_element = $doc->documentElement();
        my $namespace_uri = $root_element->namespaceURI();

        my $xpc = XML::LibXML::XPathContext->new($doc);
        $xpc->registerNs('ns', $namespace_uri);
        my @info_nodes = $xpc->findnodes('//ns:info');

        open(my $VOLCANO_FH, '>', $volcano_marker_file) or die "Cannot open $volcano_marker_file: $!";
        Label::file_header($volcano_marker_file, $VOLCANO_FH);

        foreach my $info ($xpc->findnodes('//ns:info')) {
            my $volcano_name = $xpc->findvalue('./ns:eventCode[ns:valueName="Volcano Name"]/ns:value', $info);
            my $geo_circle = $xpc->findvalue('./ns:area/ns:circle[1]', $info);

            if ($geo_circle =~ /^(-?\d+\.\d+),(-?\d+\.\d+)\s+\d+/) {
                my ($latitude, $longitude) = ($1, $2);
                $latitude  = sprintf("% 7.2f", $latitude);
                $longitude = sprintf("% 7.2f", $longitude);

                my $inner_color  = $Globals::modules{'volcanoes'}{'Volcano.Circle.Color.Inner'} // 'Yellow';
                my $inner_size   = $Globals::modules{'volcanoes'}{'Volcano.Circle.Size.Inner'}  // 4;
                my $middle_color = $Globals::modules{'volcanoes'}{'Volcano.Circle.Color.Middle'} // 'Red';
                my $middle_size  = $Globals::modules{'volcanoes'}{'Volcano.Circle.Size.Middle'} // 8;
                my $outer_color  = $Globals::modules{'volcanoes'}{'Volcano.Circle.Color.Outer'} // 'Brown';
                my $outer_size   = $Globals::modules{'volcanoes'}{'Volcano.Circle.Size.Outer'}  // 12;
                my $align        = $Globals::modules{'volcanoes'}{'Volcano.Name.Align'}        // 'Below';

                print $VOLCANO_FH "$latitude  $longitude \"\" color=$inner_color symbolsize=$inner_size\n";
                print $VOLCANO_FH "$latitude  $longitude \"\" color=$middle_color symbolsize=$middle_size\n";
                print $VOLCANO_FH "$latitude  $longitude \"$volcano_name\" color=$outer_color symbolsize=$outer_size align=$align\n";
            }
        }

        close($VOLCANO_FH) or die "Cannot close $volcano_marker_file: $!";
        print "Volcano marker file updated: $volcano_marker_file\n";
    } else {
        die "Failed to fetch XML from $volcano_location: " . $response->status_line;
    }
}

1;  # End of module
