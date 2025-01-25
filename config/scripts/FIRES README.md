---

# Fires.pm Module

## Overview
The `Fires.pm` module processes global fire data, generates an `xplanet` marker file, and updates the status label. This module uses dynamic settings configured in the `.ini` file for flexibility and maintainability.

---

## Configuration

To use the `Fires.pm` module, ensure the following settings are added to the `.ini` file under the `[FIRES]` section:

```ini
[FIRES]
fire.data.url=https://firms.modaps.eosdis.nasa.gov/data/active_fire/modis-c6.1/csv/MODIS_C6_1_Global_24h.csv
confidence.threshold=80
temp.min=300
temp.max=500
fire.marker.file=firedataout
```

### Configuration Parameters
- **`fire.data.url`**:
  - URL to the `.csv` file containing global fire data.
  - Example: `https://firms.modaps.eosdis.nasa.gov/.../MODIS_C6_1_Global_24h.csv`

- **`confidence.threshold`**:
  - Minimum confidence level for filtering fire data.
  - Default: `80`.

- **`temp.min`** and **`temp.max`**:
  - Temperature range for filtering fire data.
  - Example: `temp.min=300`, `temp.max=500`.

- **`fire.marker.file`**:
  - Name of the marker file to be generated.
  - Default: `firedataout`.

---

## Features

1. **Data Download**:
   - Downloads fire data from the specified `fire.data.url` to a `.csv` file in the markers directory.

2. **Data Filtering**:
   - Filters data based on `confidence.threshold`, `temp.min`, and `temp.max`.

3. **Marker File Generation**:
   - Creates an `xplanet` marker file containing formatted fire data entries.

4. **Label Update**:
   - Updates the status label using `Label.pm`.

---

## Usage

The `Fires.pm` module is integrated into the system and runs automatically. To test the module independently:

```perl
use Fires;

# Run the Fires module
Fires::run();
```

---

## Marker File Format

The generated marker file follows this format:
```
latitude longitude "" color={255,color_value,0} symbolsize=1
```

- **`latitude`**: Latitude of the fire.
- **`longitude`**: Longitude of the fire.
- **`color_value`**: Dynamically calculated based on temperature.
- **`symbolsize`**: Size of the marker symbol (default: `1`).

---

## Testing

### Prerequisites
1. Ensure the `[FIRES]` section exists in the `.ini` file.
2. Verify that the fire data URL points to a valid `.csv` file.

### Test Cases
1. **Download Verification**:
   - Confirm that the `.csv` file is downloaded to the markers directory.

2. **Data Filtering**:
   - Test different combinations of `confidence.threshold`, `temp.min`, and `temp.max` to ensure proper filtering.

3. **Marker File Generation**:
   - Verify that the marker file contains correctly formatted entries.

4. **Error Handling**:
   - Test scenarios where the `.csv` file is missing or invalid.
   - Ensure the module provides clear error messages.

---

## Example Outputs

### Debug Output (During Download)
```
Downloading fire data from https://firms.modaps.eosdis.nasa.gov/.../MODIS_C6_1_Global_24h.csv...
Fire data downloaded successfully to C:\path\to\firedata.csv
```

### Marker File Example
```
34.56 -120.34 "" color={255,180,0} symbolsize=1
35.67 -121.45 "" color={255,200,0} symbolsize=1
```

---

## Future Enhancements
1. **Dynamic Symbol Sizes**:
   - Allow symbol size to be dynamically calculated based on temperature or confidence level.

2. **Custom Colors**:
   - Add `.ini` settings for specifying color ranges for different temperature bands.

3. **Additional Filtering**:
   - Allow filtering based on other attributes (e.g., satellite source).

---