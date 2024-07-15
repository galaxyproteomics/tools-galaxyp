import argparse
import cv2
import geojson
import numpy as np
import pandas as pd


def collect_coords(input_coords, feature_index, coord_index=0):
    coords_with_index = []
    for coord in input_coords:
        coords_with_index.append((coord[0], coord[1], feature_index, coord_index))
        coord_index += 1
    return coords_with_index


def collect_roi_coords(input_roi, feature_index):
    all_coords = []
    if len(input_roi["geometry"]["coordinates"]) == 1:
        # Polygon w/o holes
        all_coords.extend(collect_coords(input_roi["geometry"]["coordinates"][0], feature_index))
    else:
        coord_index = 0
        for sub_roi in input_roi["geometry"]["coordinates"]:
            # Polygon with holes or MultiPolygon
            if not isinstance(sub_roi[0][0], list):
                all_coords.extend(collect_coords(sub_roi, feature_index, coord_index))
                coord_index += len(sub_roi)
            else:
                # MultiPolygon with holes
                for sub_coord in sub_roi:
                    all_coords.extend(collect_coords(sub_coord, feature_index, coord_index))
                    coord_index += len(sub_coord)
    return all_coords


def split_qupath_roi(in_roi):
    with open(in_roi) as file:
        qupath_roi = geojson.load(file)

    # HE dimensions
    dim_plt = [int(qupath_roi["dim"]["width"]), int(qupath_roi["dim"]["height"])]

    tma_name = qupath_roi["name"]
    cell_types = [ct.rsplit(" - ", 1)[-1] for ct in qupath_roi["featureNames"]]

    coords_by_cell_type = {ct: [] for ct in cell_types}
    coords_by_cell_type['all'] = []  # For storing all coordinates if args.all is True

    for feature_index, roi in enumerate(qupath_roi["features"]):
        feature_coords = collect_roi_coords(roi, feature_index)

        if args.all:
            coords_by_cell_type['all'].extend(feature_coords)
        elif "classification" in roi["properties"]:
            cell_type = roi["properties"]["classification"]["name"]
            if cell_type in cell_types:
                coords_by_cell_type[cell_type].extend(feature_coords)

    for cell_type, coords in coords_by_cell_type.items():
        if coords:
            # Generate image (white background)
            img = np.ones((dim_plt[1], dim_plt[0]), dtype="uint8") * 255

            # Convert to numpy array and ensure integer coordinates
            coords_arr = np.array(coords).astype(int)

            # Sort by feature_index first, then by coord_index
            coords_arr = coords_arr[np.lexsort((coords_arr[:, 3], coords_arr[:, 2]))]

            # Get filled pixel coordinates
            if args.fill:
                filled_coords = np.column_stack(np.where(img == 0))
                all_coords = np.unique(np.vstack((coords_arr[:, :2], filled_coords[:, ::-1])), axis=0)
            else:
                all_coords = coords_arr[:, :2]

            # Save all coordinates to CSV
            coords_df = pd.DataFrame(all_coords, columns=['x', 'y'], dtype=int)
            coords_df.to_csv("{}_{}.txt".format(tma_name, cell_type), sep='\t', index=False)

            # Generate image for visualization if --img is specified
            if args.img:
                # Group coordinates by feature_index
                features = {}
                for x, y, feature_index, coord_index in coords_arr:
                    if feature_index not in features:
                        features[feature_index] = []
                    features[feature_index].append((x, y))

                # Draw each feature separately
                for feature_coords in features.values():
                    pts = np.array(feature_coords, dtype=np.int32)
                    if args.fill:
                        cv2.fillPoly(img, [pts], color=0)  # Black fill
                    else:
                        cv2.polylines(img, [pts], isClosed=True, color=0, thickness=1)  # Black outline

                cv2.imwrite("{}_{}.png".format(tma_name, cell_type), img)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Split ROI coordinates of QuPath TMA annotation by cell type (classification)")
    parser.add_argument("--qupath_roi", default=False, help="Input QuPath annotation (GeoJSON file)")
    parser.add_argument("--fill", action="store_true", required=False, help="Fill pixels in ROIs (order of coordinates will be lost)")
    parser.add_argument('--version', action='version', version='%(prog)s 0.3.0')
    parser.add_argument("--all", action="store_true", required=False, help="Extracts all ROIs")
    parser.add_argument("--img", action="store_true", required=False, help="Generates image of ROIs")
    args = parser.parse_args()

    if args.qupath_roi:
        split_qupath_roi(args.qupath_roi)
