import argparse

from shapely.geometry import Polygon


def tabular_to_text(input_file, text_file):
    """
    Converts tabular coordinate data from Galaxy into a formatted text file which is readable for the LMD.

    This function reads tabular data from an input file, processes it to form a closed polygon, calculates the area
    of the polygon, and writes the formatted information to an output text file.

    Parameters:
    input_file (str): Path to the input file containing tabular coordinate data.
                      The file should have a header and each line should contain x and y coordinates separated by a tab.
    text_file (str): Path to the output text file where the formatted information will be written.

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
        f.write(f"Freehand\tgreen\t0\t7\t0,0\t{area}\tROI imported from tabular data\n")

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
    args = parser.parse_args()

    tabular_to_text(args.input, args.output)
