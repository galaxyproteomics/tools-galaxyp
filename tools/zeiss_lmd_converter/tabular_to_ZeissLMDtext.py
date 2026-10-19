import argparse
from pathlib import Path

from shapely.geometry import Polygon


COLORS = ("black", "green", "red", "blue")


def color_for_name(input_name, color_mappings):
    """Match mapping text against the dataset name or collection identifier, ignoring case."""
    selected_color = None
    for match_text, color in color_mappings:
        match_text = match_text.strip()
        if not match_text:
            raise ValueError("Color mapping text must not be empty")
        if color not in COLORS:
            raise ValueError(f"Unsupported color '{color}'; choose from {', '.join(COLORS)}")
        if match_text.casefold() in input_name.casefold():
            if selected_color is not None and selected_color != color:
                raise ValueError(f"Conflicting color mappings match '{input_name}'")
            selected_color = color
    return selected_color or "black"


def tabular_to_text(input_file, text_file, color="black"):
    """
    Converts tabular coordinate data from Galaxy into a formatted text file which is readable for the LMD.

    This function reads tabular data from an input file, processes it to form a closed polygon, calculates the area
    of the polygon, and writes the formatted information to an output text file.

    Parameters:
    input_file (str): Path to the input file containing tabular coordinate data.
                      The file should have a header and each line should contain x and y coordinates separated by a tab.
    text_file (str): Path to the output text file where the formatted information will be written.
    color (str): Zeiss color to assign to the ROI.

    The output text file will contain:
    - Header information
    - A section with metadata including version, date, and time
    - A section with details of the polygon including type, color, thickness, number, cutshot, area, comment,
      and coordinates.
    """
    coordinates = []
    with open(input_file, 'r') as f:
        next(f)  # Skip the header
        for line in f:
            x, y = map(float, line.strip().split('\t'))
            coordinates.append([x, y])

    coordinates.append(coordinates[0])  # Close the polygon by repeating the first point as the last point
    area = Polygon(coordinates).area

    with open(text_file, 'w') as f:
        f.write("PALMRobo Elements\n")
        f.write("Version:\tV 4.6.0.4\n")
        f.write("Date, Time:\t13.02.2024\t16:06:32\n")
        f.write("\nMICROMETER\nElements :\n\nType\tColor\tThickness\tNo\tCutShot\tArea\tComment\tCoordinates\n\n")
        f.write(f"Freehand\t{color}\t0\t7\t0,0\t{area}\tROI imported from tabular data\n")

        for i in range(0, len(coordinates), 5):
            for j in range(5):
                if i + j < len(coordinates):
                    x, y = coordinates[i + j]
                    f.write(f"\t{x},{y}")
            f.write("\n.")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Convert tabular coordinate data into a formatted text file")
    parser.add_argument('--input', type=str, required=True, help='Path to the input tabular file')
    parser.add_argument('--output', type=str, required=True, help='Path to the output text file')
    parser.add_argument('--input-name', help='Galaxy dataset name or collection element identifier (defaults to the input filename)')
    parser.add_argument('--color-map', nargs=2, action='append', default=[], metavar=('TEXT', 'COLOR'),
                        help='Color to use when TEXT occurs in the input name (may be repeated without a limit)')
    args = parser.parse_args()

    try:
        color = color_for_name(args.input_name or Path(args.input).name, args.color_map)
    except ValueError as exc:
        parser.error(str(exc))

    tabular_to_text(args.input, args.output, color)
