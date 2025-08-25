# GridPlates

A customizable 3D printable baseplate system based on the excellent [Gridfinity system](https://gridfinity.xyz/) by Zach Freedman.

## Features

- **Customizable dimensions**: Enter your desired size in mm or as Gridfinity units (42mm grid)
- **Multi-plate 3MF Export**: Automatically splits large baseplates into separate objects within a single 3MF file for easy printing.
- **Flexible grid system**: Supports full and half-width grid units
- **Build plate compatibility**: Supports various printer sizes (A1 Mini, X1/P1/A1, Large format)
- **Automatic Numbering**: Each panel is automatically numbered on the bottom for easy assembly.
- **Advanced customization**: Offset positioning, corner rounding, locking tabs, and more

## Quick Start

1.  **Open the `.scad` file** in [OpenSCAD](https://openscad.org/).
2.  **Set your dimensions**:
    ```openscad
    Width_in_mm = 325;  // Your desired width in mm
    Depth_in_mm = 275;  // Your desired depth in mm
    ```
3.  **Select your build plate size**:
    ```openscad
    Build_Plate_Size = 236; // Standard X1/P1/A1 size
    ```
4.  **Configure options** as needed (clearance, tabs, numbering, etc.). The script will show you a preview of the final assembled layout.
5.  **Follow the instructions below** to export a single 3MF file containing all your baseplate pieces.

## How to Export a Multi-Plate 3MF File

The script generates a single 3MF file that contains all the panels as separate objects. When you import this file into a modern slicer (like OrcaSlicer or Bambu Studio), it will recognize each panel individually, allowing you to automatically arrange them across multiple build plates.

Follow these steps precisely for a successful export.

### Step 1: One-Time Setup in OpenSCAD

You only need to do this once. This setting is required for OpenSCAD to export each panel as a distinct object within the 3MF file.

1.  In the OpenSCAD top menu, go to **Edit -> Preferences**.
2.  Navigate to the **Features** tab.
3.  Find and **check the box** next to **`lazy-union`**.
4.  Click **OK**.

### Step 2: Generate and Export the 3MF File

1.  In the script, find the `[Export Options]` section.
2.  Change `Enable_3MF_Export_Mode` from `false` to `true`:
    ```openscad
    Enable_3MF_Export_Mode = true;
    ```
3.  **Render the model by pressing F6**.
    - You will see all the panels piled on top of each other at the center. **This is the correct preview for 3MF export mode.**
4.  Go to **File -> Export -> Export as 3MF...** and save your file.

### Step 3: Import the 3MF into Your Slicer

1.  Open OrcaSlicer, Bambu Studio, or another modern slicer.
2.  Import the `.3mf` file you just saved.
3.  A dialog box will appear asking: **"Load these files as a single object with multiple parts?"**. Click **YES**.
4.  All panels will appear stacked on the first build plate. Click the **Arrange** button in the top toolbar.

Your slicer will now automatically arrange the panels, creating as many new plates as needed to fit all the parts.

## Build Plate Sizes

| Printer Type | Size (mm) | Setting |
|---|---|---|
| A1 Mini | 180 | `Build_Plate_Size = 180` |
| X1/P1/A1 Standard | 236-238 | `Build_Plate_Size = 236` |
| Large Format | 350+ | `Build_Plate_Size = 350` |

## License

See `LICENSE` file for licensing information.