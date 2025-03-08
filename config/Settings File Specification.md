# **Settings File Specification (`.ini`)**

This document describes the structure and requirements of the configuration file used in the **Totalmarker** program.  Adhering to this specification ensures consistent behavior and easy integration of new modules.

------

## **General Structure**

The settings file follows the **standard `.ini` format** and is divided into **sections**, each identified by a section header in square brackets (`[SECTION]`).
 Each section contains **key-value pairs (`key=value`)** that define specific settings.

### **Key Features**

1. **Section Headers**: Specify the context or module associated with the settings (e.g., `[CLOUDS]`, `[QUAKES]`).
2. **Key-Value Pairs**: Each setting is defined as a key-value pair, separated by an equals sign (`=`).
3. **Case Insensitivity**: Section headers and keys are case-insensitive.
4. **Default Values**: Missing or invalid keys may result in warnings or fallback defaults.
5. **Comments**: Lines starting with `#` are ignored and can be used for documentation.

------

## **Sections and Keys**

### **[LABELS]**

**Manages label positioning, colors, and update frequencies.**

| **Key**       | **Description**                                     | **Example**                                 |
| ------------- | --------------------------------------------------- | ------------------------------------------- |
| `labelsonoff` | Whether label display is enabled (`1=On`, `0=Off`). | `1`                                         |
| `modules`     | Comma-separated list of modules that use labels.    | `Earthquake,Volcano,Storm,NORAD,Cloud,Fire` |

#### **Module-Specific Settings (Defined under `[LABELS]`)**

Each **module's** settings include **position, colors, and update intervals**:

| **Key**                    | **Description**                                         | **Example** |
| -------------------------- | ------------------------------------------------------- | ----------- |
| `<Module>.position`        | X, Y coordinates of label placement.                    | `-68,-13`   |
| `<Module>.color.ok`        | Color for normal status.                                | `Green`     |
| `<Module>.color.warn`      | Color for warning status.                               | `Yellow`    |
| `<Module>.color.error`     | Color for error status.                                 | `Red`       |
| `<Module>.update_interval` | Update frequency (seconds) **(New Standard Location)**. | `86400`     |

✔ **💡 Why store update intervals here?**
 **Update frequency settings** are standardized under `[LABELS]` because they **apply to multiple modules** (e.g., `Earthquake.update_interval` applies to earthquake updates globally).

------

### **[LABELUPDATE]**

**Controls label file integrity and warnings.**

| **Key**                        | **Description**                                          | **Example**        |
| ------------------------------ | -------------------------------------------------------- | ------------------ |
| `labelupdateonoff`             | Whether label updates are enabled (`1=On`, `0=Off`).     | `1`                |
| `enable_label_integrity_check` | Ensures the `updatelabel` file is valid (`ON` or `OFF`). | `ON`               |
| `LabelWarning<Module>`         | Time before a module's data is considered outdated.      | `604800` (Volcano) |

✔ **💡 Integrity checking belongs in `[LABELUPDATE]` because it ensures file validity during updates.**

------

### **[INSTALLATION DIRECTORY]**

**Defines where Xplanet is installed.**

| **Key**       | **Description**               | **Example**            |
| ------------- | ----------------------------- | ---------------------- |
| `xplanet_dir` | Path to Xplanet installation. | `C:\Xplanet\Xplanet-3` |

------

### **[CLOUDS]**

**Settings related to cloud image updates.**

| **Key**                     | **Description**                                        | **Example**                          |
| --------------------------- | ------------------------------------------------------ | ------------------------------------ |
| `cloudremoteimagename`      | Name of the remote cloud image file.                   | `clouds-8192.jpg`                    |
| `cloudlocalimagename`       | Name of the local cloud image file.                    | `clouds-8192.jpg`                    |
| `usefreecloudimage`         | Whether to use a free cloud image (`Yes` or `No`).     | `No`                                 |
| `subcribedtoxplanetclouds`  | Whether subscribed to Xplanet's premium cloud service. | `Yes`                                |
| `directdownload`            | Direct URL to the cloud image file.                    | `https://secure.xericdesign.com/...` |
| `maxdownloadfrequencyhours` | Minimum time (in hours) between cloud updates.         | `6`                                  |

***Cloud Image Download Credentials***

Cloud download credentials are not stored in `totalmarker.ini`. Instead, they are retrieved from `CloudMap.cfg`, which contains:

- username
- password
- site_link
- dest_file_name

Why? This ensures secure storage of credentials outside version-controlled configuration files.

- 📌 See CloudMap-template.cfg for an example configuration.

------

### **[QUAKES]**

**Controls earthquake markers and updates.**

| **Key**                  | **Description**                              | **Example** |
| ------------------------ | -------------------------------------------- | ----------- |
| `quakedetailcolormin`    | Color for the smallest earthquakes.          | `Green`     |
| `quakedetailcolorint`    | Color for moderate earthquakes.              | `Yellow`    |
| `quakedetailcolormax`    | Color for the largest earthquakes.           | `Red`       |
| `quakeminimumsize`       | Minimum magnitude for displayed earthquakes. | `5.0`       |
| `quakereportingduration` | Reporting period (`Day`, `Week`, `Month`).   | `Week`      |
| `quakepixelmax`          | Maximum pixel size for earthquake symbols.   | `85`        |

------

### **[FIRES]**

**Controls fire data updates and marker appearance.**

| **Key**                | **Description**                                     | **Example**                      |
| ---------------------- | --------------------------------------------------- | -------------------------------- |
| `firesonoff`           | Whether fire tracking is enabled (`1=On`, `0=Off`). | `1`                              |
| `fire.data.url`        | URL for fire data CSV.                              | `https://firms.modaps.eosdis...` |
| `confidence.threshold` | Minimum confidence level for fire events.           | `80`                             |
| `temp.min`             | Minimum temperature threshold for fires.            | `300`                            |
| `temp.max`             | Maximum temperature threshold for fires.            | `500`                            |
| `fire.marker.file`     | File name for fire markers.                         | `firedataout`                    |

------

### **[NORAD]**

**Settings related to satellite tracking.**

| **Key**           | **Description**                                       | **Example**           |
| ----------------- | ----------------------------------------------------- | --------------------- |
| `noradissimage`   | Image file for the ISS.                               | `iss_transparent.png` |
| `noradissonoff`   | Whether to display the ISS marker.                    | `On`                  |
| `noradhstonoff`   | Whether to display the Hubble Space Telescope marker. | `On`                  |
| `noradtlenumbers` | List of NORAD catalog numbers to track.               | `25544, 20580`        |

------

### **[STORMS]**

**Settings related to storm tracking.**

| **Key**             | **Description**                                      | **Example** |
| ------------------- | ---------------------------------------------------- | ----------- |
| `stormsonoff`       | Whether storm tracking is enabled (`1=On`, `0=Off`). | `0`         |
| `stormcolorname`    | Color for storm names.                               | `SkyBlue`   |
| `stormtrackdisplay` | Whether to show storm tracks.                        | `Off`       |

------

### **[ECLIPSES]**

**Settings related to eclipse notifications.**

| **Key**                  | **Description**                      | **Example** |
| ------------------------ | ------------------------------------ | ----------- |
| `eclipsesonoff`          | Whether eclipse tracking is enabled. | `0`         |
| `eclipsenotify`          | Whether to notify about eclipses.    | `On`        |
| `eclipsenotifytimehours` | Number of hours before notifying.    | `48`        |

------

### **[MISC]**

**Miscellaneous settings.**

| **Key**                       | **Description**                           | **Example** |
| ----------------------------- | ----------------------------------------- | ----------- |
| `eastereggsurprises`          | Enable hidden features (`1=On`, `0=Off`). | `1`         |
| `miscxplanetversion1orbetter` | Use Xplanet version 1 or better.          | `Yes`       |

------

## **Error Handling**

- **Missing Keys**: Default values may be used, but warnings will be logged.
- **Invalid Keys**: Keys not matching any known section or module will be ignored with a warning.

------

### **🔧 Updated Settings File Specification (`.ini`)**

*Updated 7 March 2025*

This update incorporates: ✔ **All existing sections from `totalmarker.ini`.**
 ✔ **Clarification on update frequency placement** (i.e., `[LABELS]` contains `update_interval` settings).
 ✔ **New setting `enable_label_integrity_check=ON` under `[LABELUPDATE]`.**
 ✔ **Case-insensitive evaluation for boolean settings (`ON`/`OFF`).**



*6 March 2025*

Initial creation

------

# 
