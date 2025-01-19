Globals Module Debugging Utility
Overview
The Globals.pm module includes a debugging utility, debug_print_modules, designed to print all registered modules and their settings in a readable format. This tool is invaluable for troubleshooting and verifying that settings from the .ini file are correctly loaded and assigned during initialization.

Features
Clear Output:

Prints each registered module and its associated settings in a well-structured format.
Adds visual separators for better readability.
Reusability:

Can be called from any script that imports Globals.pm.
Customizable:

Can be extended to filter or print specific modules based on future requirements.
Example Usage
Import the Utility
To use the debugging utility in a script, import debug_print_modules from Globals.pm:

perl
Copy code
use Globals qw(debug_print_modules);
Call the Utility
Invoke debug_print_modules after initializing the directory settings:

perl
Copy code
# Initialize and load settings
Globals::initialize_xplanet_dir();
Globals::get_directory_settings();

# Debug registered modules and their settings
Globals::debug_print_modules();
Example Output
When called, the utility will print all modules and their settings. For example:

plaintext
Copy code
========== Registered Modules and Settings ==========
Module: storms
  color.ok => SkyBlue
  color.warn => Blue
  color.error => DarkBlue
  update_interval => 86400

Module: fire
  color.ok => Green
  color.warn => Yellow
  color.error => Red
  update_interval => 43200

Module: eclipse
  eclipse_notify_time_hours => 48
  eclipse_on_off => Off

=====================================================
When to Use
During Module Development:

Verify that settings from the .ini file are correctly parsed and loaded into %Globals::modules.
Troubleshooting:

Debug unexpected behavior related to module initialization or configuration.
How to Extend
The debug_print_modules utility is designed for flexibility. Here are a few ways it can be extended:

Filter Modules:

Modify the function to only print settings for specific modules, e.g., storms or fire.
Conditional Debugging:

Add a parameter to control verbosity or limit the output.
Example for filtering specific modules:

perl
Copy code
sub debug_print_modules {
    my @modules_to_print = qw(storms fire);  # Specify modules to include
    print "\n========== Registered Modules and Settings ==========\n";
    foreach my $module (@modules_to_print) {
        next unless exists $modules{$module};
        print "Module: $module\n";
        foreach my $key (keys %{$modules{$module}}) {
            print "  $key => $modules{$module}{$key}\n";
        }
        print "\n";
    }
    print "=====================================================\n";
}
Future Enhancements
Dynamic Filters:

Accept command-line arguments to specify which modules to debug.
Enable advanced debugging features like exporting to a file.
Integration with Logging:

Redirect output to a log file for long-running scripts.