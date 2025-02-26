1️⃣ Overview
The Label System in Xplanet is responsible for generating updatelabel, a marker file that provides real-time status updates on active modules. It dynamically reads module positions, colors, and status flags from the .ini file.

Key Components:

Label.pm (Processes and writes the updatelabel marker file.)
Globals.pm (Parses .ini settings, ensuring they are correctly mapped.)
totalmarker2.6.1a.pl (Main script that manages module execution.)
2️⃣ Assumptions & Rules
📝 .ini File Structure
The .ini file defines active modules and their settings.
Modules are listed under [LABELS] with:
Position Settings: <Module>.position = x,y
Status Colors:
ini
Copy
Edit
Label.Color.Ok = Green
Label.Color.Warn = Yellow
Label.Color.Error = Red
Update Frequency (if applicable): <Module>.update_interval = <seconds>
🔍 Module Name Matching
Module names are case-sensitive in Perl, but not in .ini parsing.
To avoid mismatches, module names are lowercased in Globals.pm.
📍 Position Handling
Each module must have a .position entry.
If a position is missing or empty, the system defaults to -100, -100.
Positions are stored as (x, y) coordinates.
📢 Status Handling
Each module reports one of three statuses:

Status	Color	Meaning
OK	Green	Module is up to date.
Warn	Yellow	Module is active but data may be outdated.
Error	Red	Module failed or has no data.
🛠 Debugging & Logging
$DEBUG is a global flag that enables verbose output.
Module registration & matching are logged during execution.
3️⃣ How Label.pm Works
🔄 Process Flow
1️⃣ Reads Globals.pm for module settings.
2️⃣ Extracts .position values and normalizes names.
3️⃣ Checks which modules are active.
4️⃣ Assigns default positions for missing modules.
5️⃣ Writes output to updatelabel in marker format.

📌 Example Output (updatelabel)
arduino
Copy
Edit
# This is the header for UpdateLabel
# Original idea by Michael Dear
# Revamped by Matt Coblentz October 2024
# Updated 25-Feb-2025 21:03
# 
-113 -13 "Storm information updated" color=Green image=none position=pixel
-83 -13 "NORAD information updated" color=Green image=none position=pixel
-68 -13 "Earthquake information updated" color=Green image=none position=pixel
-143 -13 "Fire information updated" color=Green image=none position=pixel
-98 -13 "Cloud information updated" color=Green image=none position=pixel
-128 -13 "Volcano information updated" color=Green image=none position=pixel
4️⃣ Future Improvements
🚀 Possible Next Steps: ✅ Add timestamps to updatelabel for last updated times.
✅ Allow custom messages per module.
✅ Improve error recovery for missing .position values.

📌 Final Notes
This document provides a reference for future developers working on the Label System.
All logic is now debug-friendly and modular, making future expansions much easier! 🚀

