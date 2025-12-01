######################################################################################################################
# Halder, S. S., Lalonde, J. F., & de Charette, R. (2019).
# Physics-Based Rendering for Improving Robustness to Rain. IEEE/CVF International Conference on Computer Vision
#
# From: Computer Vision Group, RITS team, Inria
# License: MIT
######################################################################################################################

import os
import cv2

from dataset import Dataset


class Cityscapes(Dataset):
    sequences = ['leftImg8bit/train', 'leftImg8bit/val']
    data = {"*": ["depth", "fog_transmittance", "rain_diff"], "leftImg8bit/val": ["rain_diff"]}

    def __init__(self, original_dir, output_dir, sequences=None):
        if sequences is None:
            sequences = Cityscapes.sequences

        super().__init__("cityscapes", original_dir, output_dir, sequences, Cityscapes.data)

    def transform_original_image(self, img):
        return cv2.resize(img, (1024, 512), cv2.INTER_CUBIC)  # Downscale original image
