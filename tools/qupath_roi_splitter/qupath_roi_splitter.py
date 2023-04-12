import argparse

import cv2
import geojson
import numpy as np
import pandas as pd


def draw_poly(input_df, input_img, col=(0, 0, 0)):
    s = np.array(input_df)
    output_img = cv2.fillPoly(input_img, pts=np.int32([s]), color=col)
    return output_img


def split_qupath_roi(in_roi):
    with open(in_roi) as file:
        qupath_roi = geojson.load(file)

    # HE dimensions
    dim_plt = [qupath_roi["dim"]["width"], qupath_roi["dim"]["height"]]

    tma_name = qupath_roi["name"]
    cell_types = [ct.rsplit(" - ", 1)[-1] for ct in qupath_roi["featureNames"]]

    # create numpy array with white background
    img = np.zeros((dim_plt[1], dim_plt[0], 3), dtype="uint8")
    img.fill(255)

    for cell_type in cell_types:
        for i, roi in enumerate(qupath_roi["features"]):
            if roi["properties"]["classification"]["name"] == cell_type:
                if len(roi["geometry"]["coordinates"]) == 1:
                    # Polygon w/o holes
                    img = draw_poly(roi["geometry"]["coordinates"][0], img)
                else:
                    first_roi = True
                    for sub_roi in roi["geometry"]["coordinates"]:
                        # Polygon with holes
                        if not isinstance(sub_roi[0][0], list):
                            if first_roi:
                                img = draw_poly(sub_roi, img)
                                first_roi = False
                            else:
                                # holes in ROI
                                img = draw_poly(sub_roi, img, col=(255, 255, 255))
                        else:
                            # MultiPolygon with holes
                            for sub_coord in sub_roi:
                                if first_roi:
                                    img = draw_poly(sub_coord, img)
                                    first_roi = False
                                else:
                                    # holes in ROI
                                    img = draw_poly(sub_coord, img, col=(255, 255, 255))

        # get all black pixel
        coords_arr = np.column_stack(np.where(img == (0, 0, 0)))

        # remove duplicated rows
        coords_arr_xy = coords_arr[coords_arr[:, 2] == 0]

        # remove last column
        coords_arr_xy = np.delete(coords_arr_xy, 2, axis=1)

        # to pandas and rename columns to x and y
        coords_df = pd.DataFrame(coords_arr_xy, columns=['x', 'y'])

        # drop duplicates
        coords_df = coords_df.drop_duplicates(
            subset=['x', 'y'],
            keep='last').reset_index(drop=True)

        coords_df.to_csv("{}_{}.txt".format(tma_name, cell_type), sep='\t', index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Split ROI coordinates of QuPath TMA annotation by cell type (classfication)")
    parser.add_argument("--qupath_roi", default=False, help="Input QuPath annotation (GeoJSON file)")
    parser.add_argument('--version', action='version', version='%(prog)s 0.1.0')
    args = parser.parse_args()

    if args.qupath_roi:
        split_qupath_roi(args.qupath_roi)
