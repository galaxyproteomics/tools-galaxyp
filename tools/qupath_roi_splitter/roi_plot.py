"""Render a readable ROI plot using the original QuPath pixel coordinates."""

import math

import cv2
import numpy as np


def polygon_arrays(coords_list):
    """Return polygon vertices in the same order and precision as the TXT export."""
    polygons = []
    for feature in coords_list:
        for polygon in feature:
            for sub_poly in polygon if isinstance(polygon[0][0], list) else [polygon]:
                polygons.append(np.array(sub_poly, dtype=np.float32).reshape(-1, 2).astype(np.int32))
    return polygons


def filled_coordinates(pts, width, height):
    """Rasterize only a polygon's visible bounding box into original X/Y pixels."""
    x, y, box_width, box_height = cv2.boundingRect(pts)
    x0, y0 = max(x, 0), max(y, 0)
    x1, y1 = min(x + box_width, width), min(y + box_height, height)
    if x0 >= x1 or y0 >= y1:
        return np.empty((0, 2), dtype=np.int32)
    mask = np.full((y1 - y0, x1 - x0), 255, dtype=np.uint8)
    shifted_pts = pts - np.array([x0, y0], dtype=np.int32)
    cv2.fillPoly(mask, [shifted_pts], color=0)
    rows, columns = np.where(mask == 0)
    return np.column_stack((columns + x0, rows + y0))


def plot_bounds(polygons, width, height):
    """Use one padded crop for every classification in an input file."""
    points = np.concatenate(polygons)
    low = points.min(axis=0)
    high = points.max(axis=0)
    span = high - low
    padding = np.maximum(50, np.ceil(span * 0.05)).astype(int)
    left, top = np.clip(low - padding, 0, [width - 1, height - 1])
    right, bottom = np.clip(high + padding, 0, [width - 1, height - 1])
    return int(left), int(top), int(right), int(bottom)


def _tick_step(span):
    raw = max(span / 6, 1)
    power = 10 ** math.floor(math.log10(raw))
    return next((factor * power for factor in (1, 2, 5, 10) if factor * power >= raw))


def render_roi_image(polygons, bounds, fill):
    """Draw ROIs, a coordinate grid, and labeled X/Y axes."""
    left, top, right, bottom = bounds
    scale = min(4.0, 2000 / max(right - left, bottom - top, 1))
    plot_width = max(1, round((right - left) * scale) + 1)
    plot_height = max(1, round((bottom - top) * scale) + 1)
    margin_left, margin_top, margin_right, margin_bottom = 110, 40, 30, 85
    x0, y0 = margin_left, margin_top
    x1, y1 = x0 + plot_width - 1, y0 + plot_height - 1
    image = np.full((y1 + margin_bottom + 1, x1 + margin_right + 1, 3), 255, dtype=np.uint8)

    mapped = []
    for pts in polygons:
        screen_pts = np.rint((pts - [left, top]) * scale).astype(np.int32)
        screen_pts += [x0, y0]
        mapped.append(screen_pts)
        if fill:
            # A lighter fill keeps the thick black outline visible.
            cv2.fillPoly(image, [screen_pts], color=(180, 180, 180))

    font = cv2.FONT_HERSHEY_SIMPLEX
    for axis, lo, hi, origin in ((0, left, right, x0), (1, top, bottom, y0)):
        step = _tick_step(hi - lo)
        tick = math.ceil(lo / step) * step
        while tick <= hi:
            pos = origin + round((tick - lo) * scale)
            if axis == 0:
                line = image[y0:y1 + 1, pos]
            else:
                line = image[pos, x0:x1 + 1]
            line[:] = np.where(line < 128, 100, 220).astype(np.uint8)
            label = str(tick)
            (text_width, _), _ = cv2.getTextSize(label, font, 0.5, 1)
            if axis == 0:
                cv2.line(image, (pos, y1), (pos, y1 + 6), (0, 0, 0), 1)
                cv2.putText(image, label, (pos - text_width // 2, y1 + 25), font, 0.5, (0, 0, 0), 1, cv2.LINE_AA)
            else:
                cv2.line(image, (x0 - 6, pos), (x0, pos), (0, 0, 0), 1)
                cv2.putText(image, label, (x0 - text_width - 12, pos + 5), font, 0.5, (0, 0, 0), 1, cv2.LINE_AA)
            tick += step

    for pts in mapped:
        cv2.polylines(image, [pts], isClosed=True, color=(0, 0, 0), thickness=3)

    cv2.rectangle(image, (x0, y0), (x1, y1), (0, 0, 0), 1)
    x_label = "X (px)"
    (label_width, _), _ = cv2.getTextSize(x_label, font, 0.7, 2)
    cv2.putText(image, x_label, ((x0 + x1 - label_width) // 2, y1 + 60), font, 0.7, (0, 0, 0), 2, cv2.LINE_AA)
    cv2.putText(image, "Y (px, down)", (8, 25), font, 0.6, (0, 0, 0), 1, cv2.LINE_AA)
    return image
