# AutoCAD Point Exporter (lsp)

AutoCAD Point Exporter is an AutoLISP utility designed for AutoCAD users to efficiently export selected points to CSV or text files and generate a coordinate table with customizable prefix codes and numbering. 

## Features

- Export selected points to CSV or text files.
- Customizable file type selection (CSV or text).
- Save file with a browse dialog.
- Customizable horizontal scale and prefix codes.
- Automatic point numbering with user-defined start number.
- Generate an AutoCAD point for each selected coordinate.
- Draw a coordinates table in AutoCAD.
- Create a dedicated layer with a timestamp to isolate extracted points and their text.

## Installation

1. Download the `AutoCAD-Point-Exporter.lsp` file from the repository.
2. Load the LISP file in AutoCAD using the `APPLOAD` command or by adding it to your startup suite.

## Usage

1. Load the LISP file in AutoCAD.
2. Type the command `PT` in the command line.
3. Follow the prompts:

    - Select the file type (CSV or text).
    - Choose the location and file name to save the exported file.
    - Enter the horizontal scale (e.g., 1).
    - Enter the prefix code (e.g., "PT").
    - Enter the start number (e.g., 1).
    - Select the points to export. For each point:
        - An AutoCAD point is created.
        - The point number is incremented and displayed.
    - Press Enter to finish selecting points.
    - Specify the upper left corner of the coordinates table.

4. When the LISP starts, it will create a new layer named `STAKEOUT_YYYYMMDD` (e.g., `STAKEOUT_2460501`), isolating the extracted points and their text. This layer naming convention helps in using the LISP multiple times without conflicts.

## Example

Here's a step-by-step example of how to use the utility:

1. Type `PT` in the command line.
2. When prompted, select `CSV` as the file type.
3. Use the browse dialog to save the file as `points.csv`.
4. Enter `1` for the horizontal scale.
5. Enter `PT` as the prefix code.
6. Enter `1` as the start number.
7. Select the desired points in the drawing. Each point will be numbered incrementally starting from 1.
8. Press Enter to finish selecting points.
9. Specify the upper left corner of the coordinates table.

## Contributing

Contributions are welcome! Please fork the repository and submit pull requests for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For any questions or suggestions, please open an issue or contact the repository owner.
