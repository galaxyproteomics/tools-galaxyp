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

	for cell_type, coords_list in coords_by_cell_type.items():
		if coords_list:
			img = np.ones((dim_plt[1], dim_plt[0], 3), dtype="uint8") * 255

			all_coords = []
			for feature in coords_list:
				for polygon in feature:
					# Multiple sub_polygons in LMD data
					for sub_poly in polygon if isinstance(polygon[0][0], list) else [polygon]:
						pts = np.array(sub_poly, dtype=np.float32).reshape(-1, 2)
						pts = pts.astype(np.int32)

						# Get filled pixel coordinates
						if args.fill:
							temp_img = np.ones((dim_plt[1], dim_plt[0]), dtype="uint8") * 255
							cv2.fillPoly(temp_img, [pts], color=0)
							filled_coords = np.column_stack(np.where(temp_img == 0))
							all_coords.extend(filled_coords[:, [1, 0]])  # Swap columns to get (x, y)
							cv2.fillPoly(img, [pts], color=0)
						else:
							cv2.polylines(img, [pts], isClosed=True, color=(0, 0, 0), thickness=1)
							all_coords.extend(pts)

			all_coords = np.array(all_coords)
			coords_df = pd.DataFrame(all_coords, columns=['x', 'y'], dtype=int)
			coords_df.to_csv("{}_{}.txt".format(tma_name, cell_type), sep='\t', index=False)

			# Generate image for visualization if --img is specified
			if args.img:
				cv2.imwrite("{}_{}.png".format(tma_name, cell_type), img)


if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="Split ROI coordinates of QuPath TMA annotation by cell type (classification)")
	parser.add_argument("--qupath_roi", default=False, help="Input QuPath annotation (GeoJSON file)")
	parser.add_argument("--fill", action="store_true", required=False,help="Fill pixels in ROIs (order of coordinates will be lost)")
	parser.add_argument('--version', action='version', version='%(prog)s 0.3.2')
	parser.add_argument("--all", action="store_true", required=False, help="Extracts all ROIs")
	parser.add_argument("--img", action="store_true", required=False, help="Generates image of ROIs")
	args = parser.parse_args()

	if args.qupath_roi:
		split_qupath_roi(args.qupath_roi)
