######################################################################################################################
# Halder, S. S., Lalonde, J. F., & de Charette, R. (2019).
# Physics-Based Rendering for Improving Robustness to Rain. IEEE/CVF International Conference on Computer Vision
#
# From: Computer Vision Group, RITS team, Inria
# License: MIT
######################################################################################################################

import os

from dataset import Dataset


class Kitti(Dataset):
    sequences = ['data_object/training/image_2', 'raw_data/2011_09_26/2011_09_26_drive_0032_sync/image_02/data', 'raw_data/2011_09_26/2011_09_26_drive_0056_sync/image_02/data']
    data = {"*": ["depth", "fog_transmittance", "rain"]}

    def __init__(self, original_dir, output_dir, sequences=None):
        if sequences is None:
            sequences = Kitti.sequences

        super().__init__("kitti", original_dir, output_dir, sequences, Kitti.data)

    def transform_original_image(self, img):
        # Crop-center original image
        cropx, cropy = 1216, 352
        y, x, _ = img.shape
        startx = x // 2 - (cropx // 2)
        starty = y // 2 - (cropy // 2)
        return img[starty:starty + cropy, startx:startx + cropx]
