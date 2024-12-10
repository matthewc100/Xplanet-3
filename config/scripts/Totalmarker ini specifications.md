---

# Configuration File Specification (`.ini`)

This document describes the structure and requirements of the configuration file used in the program. Adhering to this specification ensures consistent behavior and easy integration of new modules.

---

## **General Structure**
The configuration file follows the standard `.ini` format and is divided into **sections**, each identified by a section header in square brackets (`[SECTION]`). Each section contains key-value pairs (`key=value`) that define specific settings.

### **Key Features**
1. **Section Headers:** Specify the context or module associated with the settings (e.g., `[CLOUDS]`, `[QUAKES]`).
2. **Key-Value Pairs:** Each setting is defined as a key-value pair, separated by an equals sign (`=`).
3. **Comments:** Lines starting with `#` are ignored and can be used for documentation or explanation.

---

## **General Guidelines**
- **Case Sensitivity:** Section headers and keys are case-insensitive. Internally, they are normalized to lowercase.
- **Whitespace:** Leading and trailing whitespace around keys and values is trimmed automatically.
- **Default Values:** Ensure all required keys have valid values. Missing or invalid keys may result in warnings or fallback defaults.
- **Quoted Values:** Strings can be quoted (e.g., `"value"`) or unquoted. Quotation marks are removed during parsing.

---

## **Sections and Keys**

### **[CLOUDS]**
Settings related to cloud image updates.

| **Key**                     | **Description**                                                  | **Example**                                    |
|-----------------------------|------------------------------------------------------------------|-----------------------------------------------|
| `cloudremoteimagename`      | Name of the remote cloud image file.                            | `clouds-8192.jpg`                             |
| `cloudlocalimagename`       | Name of the local cloud image file.                             | `clouds-8192.jpg`                             |
| `usefreecloudimage`         | Whether to use a free cloud image source. (`Yes` or `No`)       | `No`                                          |
| `subcribedtoxplanetclouds`  | Whether subscribed to Xplanet's premium cloud service.          | `Yes`                                         |
| `cloudusername`             | Username for cloud image service.                               | `XP100-EFD5M-SEW3F-GW3PV`                     |
| `cloudpassword`             | Password for cloud image service.                               | `v5mmVrDRgTJ5`                                |
| `directdownload`            | Direct URL to the cloud image file.                             | `https://secure.xericdesign.com/xplanet/...`  |
| `maxdownloadfrequencyhours` | Minimum time (in hours) between cloud updates.                  | `6`                                           |

---

### **[QUAKES]**
Settings related to earthquake markers.

| **Key**                     | **Description**                                                  | **Example** |
|-----------------------------|------------------------------------------------------------------|-------------|
| `quakedetailcolormin`       | Color for the smallest earthquake details.                      | `Green`     |
| `quakedetailcolorint`       | Color for intermediate earthquake details.                      | `Yellow`    |
| `quakedetailcolormax`       | Color for the largest earthquake details.                       | `Red`       |
| `quakeminimumsize`          | Minimum size of earthquake markers.                             | `5.0`       |
| `quakereportingduration`    | Duration to include earthquakes in the report (`Day`, `Week`).  | `Week`      |

---

### **[VOLCANOES]**
Settings related to volcano markers.

| **Key**                     | **Description**                                                  | **Example** |
|-----------------------------|------------------------------------------------------------------|-------------|
| `volcanocirclesizeinner`    | Size of the inner volcano circle.                               | `4`         |
| `volcanocirclesizemiddle`   | Size of the middle volcano circle.                              | `8`         |
| `volcanocirclesizeouter`    | Size of the outer volcano circle.                               | `12`        |
| `volcanonameonoff`          | Whether volcano names are displayed.                           | `On`        |

---

### **[NORAD]**
Settings related to satellite tracking.

| **Key**                     | **Description**                                                  | **Example**           |
|-----------------------------|------------------------------------------------------------------|-----------------------|
| `noradissimage`             | Image file for the ISS.                                         | `iss_transparent.png` |
| `noradissonoff`             | Whether to display the ISS marker.                             | `On`                  |
| `noradhstonoff`             | Whether to display the Hubble Space Telescope marker.          | `On`                  |

---

### **[LABELUPDATE]**
Settings related to marker label updates.

| **Key**                     | **Description**                                                  | **Example** |
|-----------------------------|------------------------------------------------------------------|-------------|
| `labelonoff`                | Whether labels are enabled.                                     | `On`        |
| `labelcolorok`              | Color for "OK" labels.                                          | `Green`     |

---

### **[MISC]**
Miscellaneous settings.

| **Key**                     | **Description**                                                  | **Example** |
|-----------------------------|------------------------------------------------------------------|-------------|
| `miscxplanetversion1orbetter` | Whether using Xplanet version 1 or higher.                     | `Yes`       |

---

## **Error Handling**
- **Missing Keys:** Default values may be used, but warnings will be logged.
- **Invalid Keys:** Keys not matching any known section or module will be ignored with a warning.

---

## **Future Updates**
To add support for new modules or sections:
1. Add a new `[SECTION]` in the `.ini` file.
2. Define the required keys and values under the section.
3. Update the `get_settings` subroutine to handle the new section.

---
