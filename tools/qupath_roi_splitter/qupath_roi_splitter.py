import argparse

import cv2
import geojson
import numpy as np
import pandas as pd
from roi_plot import filled_coordinates, plot_bounds, polygon_arrays, render_roi_image


def collect_coords(input_coords, feature_index, coord_index=0):
    coords_with_index = []
    for coord in input_coords:
        coords_with_index.append((coord[0], coord[1], feature_index, coord_index))
        coord_index += 1
    return coords_with_index


def collect_roi_coords(input_roi):
    coords = input_roi["geometry"]["coordinates"]

    def process_coords(coord_list):
        if isinstance(coord_list[0], (int, float)):
            return [coord_list]
        elif all(isinstance(c, list) for c in coord_list):
            return coord_list
        else:
            return [coord_list]

    if isinstance(coords[0][0], list):
        return [process_coords(sub_coords) for sub_coords in coords]
    else:
        return [process_coords(coords)]


def split_qupath_roi(in_roi):
    with open(in_roi) as file:
        qupath_roi = geojson.load(file)

    # HE dimensions
    dim_plt = [int(qupath_roi["dim"]["width"]), int(qupath_roi["dim"]["height"])]
    tma_name = qupath_roi["name"]

    if "featureNames" in qupath_roi:
        cell_types = [ct.rsplit(" - ", 1)[-1] for ct in qupath_roi["featureNames"]]
    else:
        cell_types = ["all"]

    coords_by_cell_type = {ct: [] for ct in cell_types}
    if "all" not in coords_by_cell_type:
        coords_by_cell_type["all"] = []

    for roi in qupath_roi["features"]:
        feature_coords = collect_roi_coords(roi)

        if args.all or "classification" not in roi["properties"]:
            coords_by_cell_type["all"].append(feature_coords)
        elif "classification" in roi["properties"]:
            cell_type = roi["properties"]["classification"]["name"]
            if cell_type in cell_types:
                coords_by_cell_type[cell_type].append(feature_coords)

    polygons_by_cell_type = {
        cell_type: polygon_arrays(coords_list)
        for cell_type, coords_list in coords_by_cell_type.items()
    }
    all_polygons = [pts for polygons in polygons_by_cell_type.values() for pts in polygons]
    bounds = plot_bounds(all_polygons, *dim_plt) if args.img and all_polygons else None

    for cell_type, polygons in polygons_by_cell_type.items():
        if polygons:

            all_coords = []
            for pts in polygons:
                # Get filled pixel coordinates
                if args.fill:
                    all_coords.extend(filled_coordinates(pts, *dim_plt))
                else:
                    all_coords.extend(pts)

            all_coords = np.array(all_coords)
            coords_df = pd.DataFrame(all_coords, columns=['x', 'y'], dtype=int)
            coords_df.to_csv("{}_{}.txt".format(tma_name, cell_type), sep='\t', index=False)

            # Generate image for visualization if --img is specified
            if args.img:
                cv2.imwrite("{}_{}.png".format(tma_name, cell_type), render_roi_image(polygons, bounds, args.fill))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Split ROI coordinates of QuPath TMA annotation by cell type (classification)")
    parser.add_argument("--qupath_roi", default=False, help="Input QuPath annotation (GeoJSON file)")
    parser.add_argument("--fill", action="store_true", required=False, help="Fill pixels in ROIs (order of coordinates will be lost)")
    parser.add_argument('--version', action='version', version='%(prog)s 0.3.3')
    parser.add_argument("--all", action="store_true", required=False, help="Extracts all ROIs")
    parser.add_argument("--img", action="store_true", required=False, help="Generates image of ROIs")
    args = parser.parse_args()

    if args.qupath_roi:
        split_qupath_roi(args.qupath_roi)
