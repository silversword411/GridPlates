# GridPlates

A customizable 3D printable baseplate system based on the excellent [Gridfinity system](https://gridfinity.xyz/) by Zach Freedman.

## Features

- **Customizable dimensions**: Enter your desired size in mm or as Gridfinity units (42mm grid)
- **Multi-plate printing**: Automatically splits large baseplates across multiple print bed sizes
- **Flexible grid system**: Supports full and half-width grid units
- **Build plate compatibility**: Supports various printer sizes (A1 Mini, X1/P1/A1, Large format)
- **Advanced customization**: Offset positioning, corner rounding, locking tabs, and more

## Quick Start

1. **Set your dimensions**:
   ```openscad
   Width = 325;  // Your desired width in mm
   Depth = 275;  // Your desired depth in mm
   ```

2. **Select build plate size**:
   ```openscad
   Build_Plate_Size = 236; // Standard X1/P1/A1 size
   ```

3. **Configure options** as needed (clearance, tabs, magnets, etc.)

4. **Render and export** your baseplate pieces

## Build Plate Sizes

| Printer Type | Size (mm) | Setting |
|--------------|-----------|---------|
| A1 Mini | 180 | `Build_Plate_Size = 180` |
| X1/P1/A1 Standard | 236-238 | `Build_Plate_Size = 236` |
| Large Format | 350+ | `Build_Plate_Size = 350` |

## License

See `LICENSE` file for licensing information.

## Version History

- **v1.0** (7/5/2025): Initial release of GridPlates fork with automatic plate splitting and enhanced customization options