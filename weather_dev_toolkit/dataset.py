######################################################################################################################
# Halder, S. S., Lalonde, J. F., & de Charette, R. (2019).
# Physics-Based Rendering for Improving Robustness to Rain. IEEE/CVF International Conference on Computer Vision
#
# From: Computer Vision Group, RITS team, Inria
# License: MIT
######################################################################################################################

import os
import urllib.request
import hashlib
import numpy as np
import cv2
import glob
import shutil
from tqdm import tqdm
from zipfile import ZipFile


class Dataset:
    HTTP_PATH = "https://www.rocq.inria.fr/rits_files/computer-vision/weather-augment/"

    def __init__(self, name, original_dir, output_dir, sequences, data):
        self.original_name = name
        self.name = "weather_"+self.original_name
        self.original_dir = original_dir
        self.output_dir = output_dir
        self.sequences = sequences
        self.data = data
        self.checksums_link = Dataset.HTTP_PATH + "{}_checksums.txt".format(self.name)
        self.downloaded_directory = os.path.join(output_dir, "downloaded")
        self.datasets_directory = os.path.join(self.output_dir, "weather_datasets")

        self.links = []
        for sequence in self.sequences:
            sequence_data = self.data[sequence] if sequence in self.data.keys() else self.data["*"]
            sequence = sequence.replace("/", "_")
            print(sequence_data)
            for d in sequence_data:
                self.links.append(Dataset.HTTP_PATH + "{}_{}_{}.zip".format(self.name, sequence, d))

        print("Verifying {} integrity... {}".format(self.original_name, original_dir), end="")
        for sequence in self.sequences:
            if not os.path.isdir(original_dir):
                raise NotADirectoryError("Original *{}* dataset directory doesn't exist: {}".format(self.original_name, original_dir))
            if not os.path.isdir(os.path.join(original_dir, sequence)):
                raise NotADirectoryError("Original *{}* dataset file structure invalid. Please use correct file structure, directory %{}_root%/{} is missing. Or restrict sequences (--sequence).".format(self.original_name, self.original_name, sequence))
        print(" [OK]")


    def _extract(self, archive, directory_to_extract):
        with ZipFile(file=archive) as zip_file:
            for file in tqdm(iterable=zip_file.namelist(), total=len(zip_file.namelist()), desc="       Extracting: " + os.path.basename(archive)):
                zip_file.extract(member=file, path=directory_to_extract)

    class DownloadProgressBar(tqdm):
        def update_to(self, b=1, bsize=1, tsize=None):
            if tsize is not None:
                self.total = tsize
            self.update(b * bsize - self.n)

    def _download_url(self, url, output_path):
        with self.DownloadProgressBar(unit='B', unit_scale=True,
                                 miniters=1, desc="     Downloading: " + url.split('/')[-1]) as t:
            urllib.request.urlretrieve(url, filename=output_path, reporthook=t.update_to)

    def _sha256sum(self, filename, blocksize=65536):
        hash_sha256 = hashlib.sha256()
        with tqdm(total=os.stat(filename).st_size, desc="       Calculating checksum: " + os.path.basename(filename), unit='B', unit_scale=True, unit_divisor=1024) as pbar:
            with open(filename, "rb") as f:
                block = 1
                while block:
                    block = f.read(blocksize)
                    if block:
                        pbar.update(len(block))
                        hash_sha256.update(block)

        return hash_sha256.hexdigest()

    def download_and_extract_all(self, auto_remove=True):
        os.makedirs(self.downloaded_directory, exist_ok=True)
        os.makedirs(self.datasets_directory, exist_ok=True)

        # Get Checksums
        checksum_file_name = os.path.join(self.downloaded_directory, self.checksums_link.split('/')[-1])
        self._download_url(self.checksums_link, checksum_file_name)

        self.checksums = {}
        with open(checksum_file_name, 'r') as f:
            for line in f:
                value, key = line.split()
                self.checksums[key] = value

        for url_idx, url in enumerate(self.links):
            print("     {}, download [{}/{}]".format(self.name, url_idx + 1, len(self.links)))
            self.download_and_extract(url, auto_remove)

        if auto_remove:
            os.remove(checksum_file_name)
            if len(os.listdir(self.downloaded_directory)) == 0:
                os.rmdir(self.downloaded_directory)

    def download_and_extract(self, url, auto_remove=True):
        downloaded_file_name = url.split('/')[-1]
        path_to_download = os.path.join(self.downloaded_directory, downloaded_file_name)

        download_needed = True

        # Redownload this file only if the checksum is invalid
        if os.path.isfile(path_to_download):
            sha256sum = self._sha256sum(path_to_download)
            if downloaded_file_name in self.checksums and self.checksums[downloaded_file_name] == sha256sum:
                print("\nUsing pre-downloaded file")
                download_needed = False
            else:
                print("\nSha256sum is invalid: {}. Will re-download".format(downloaded_file_name))

        if download_needed:
            self._download_url(url, path_to_download)

        self._extract(path_to_download, self.datasets_directory)
        
        if auto_remove:
            os.remove(path_to_download)

    def transform_original_image(self, img):
        raise NotImplementedError

    def generate_fog(self):
        for seq_idx, sequence in enumerate(self.sequences):
            sequence_data = self.data[sequence] if sequence in self.data.keys() else self.data["*"]
            if "fog_transmittance" not in sequence_data:
                print(sequence+", No fog data in this sequence.")
                continue

            for_transmission_dir = os.path.join(self.datasets_directory, self.name, sequence, "fog_transmittance")

            if not os.path.isdir(for_transmission_dir):
                raise NotADirectoryError("fog_transmittance folder doesn't exist")

            vmax_list = os.listdir(for_transmission_dir)

            fog_dir = os.path.join(self.datasets_directory, self.name, sequence, "fog")

            for vmax_idx, vmax in enumerate(vmax_list):
                print("     {}, Sequence [{}/{}], Fog vmax {} [{}/{}]".format(self.name, seq_idx+1, len(self.sequences), vmax, vmax_idx+1, len(vmax_list)))
                files = glob.glob(os.path.join(for_transmission_dir, vmax, "**/*.png"), recursive=True)
                for fog_transmittance_path in tqdm(files, desc="        {}, Fog, {}, {}".format(self.name, vmax, sequence)):
                    relative_path_to_filename = fog_transmittance_path.replace(os.path.join(for_transmission_dir, vmax) + "/", "")
                    filename = os.path.basename(relative_path_to_filename)
                    sub_folders = relative_path_to_filename.replace(filename, "")

                    original_file_path = os.path.join(self.original_dir, sequence, sub_folders, filename)
                    if not os.path.isfile(original_file_path):
                        print("File {} doesn't exist".format(original_file_path))
                        continue

                    img_clear = cv2.imread(original_file_path)
                    img_clear = self.transform_original_image(img_clear)
                    fog_output_dir = os.path.join(fog_dir, vmax, sub_folders)

                    os.makedirs(fog_output_dir, exist_ok=True)

                    fog_transmittance = cv2.imread(fog_transmittance_path, cv2.IMREAD_UNCHANGED) / 255.

                    LInf = np.array([200, 200, 200])  # Atmosphere chromacity

                    direct_trans_noise = img_clear * fog_transmittance
                    airlight_noise = LInf * (1 - fog_transmittance)
                    img_fog = direct_trans_noise + airlight_noise
                    img_fog = np.asarray(img_fog, dtype=np.uint8)

                    cv2.imwrite(os.path.join(fog_output_dir, filename), img_fog)

    def generate_rain(self):
        sequence_data = self.data["*"]
        if "rain_diff" in sequence_data:
            self.generate_rain_from_diff()
        elif "rain" in sequence_data:
            return  # Nothing to do
        else:
            raise NotImplementedError

    def generate_rain_from_diff(self):
        for seq_idx, sequence in enumerate(self.sequences):
            rain_levels_dir = os.path.join(self.datasets_directory, self.name, sequence, "rain_diff")

            if not os.path.isdir(rain_levels_dir):
                rain_levels_dir = os.path.join(self.datasets_directory, self.name, sequence, "rain")
                if os.path.isdir(rain_levels_dir):
                    print("     Rain seems already generated in ({}). Skipping...".format(rain_levels_dir))
                    continue
                else:
                    raise NotADirectoryError("rain_diff folder doesn't exist")

            levels_list = os.listdir(rain_levels_dir)

            rain_dir = os.path.join(self.datasets_directory, self.name, sequence, "rain")

            for rain_idx, rain_level in enumerate(levels_list):
                print("     {}, Sequence [{}/{}], Rain {} [{}/{}]".format(self.name, seq_idx+1, len(self.sequences), rain_level, rain_idx+1, len(levels_list)))
                files = glob.glob(os.path.join(rain_levels_dir, rain_level, "rainy_image", "**/*.png"), recursive=True)
                for rain_diff_path in tqdm(files, desc="        {}, Rain, {}, {}".format(self.name, rain_level, sequence)):
                    relative_path_to_filename = rain_diff_path.replace(os.path.join(rain_levels_dir, rain_level, "rainy_image") + "/", "")

                    filename = os.path.basename(relative_path_to_filename)
                    sub_folders = relative_path_to_filename.replace(filename, "")

                    rainy_image_output_dir = os.path.join(rain_dir, rain_level, "rainy_image", sub_folders)
                    rain_mask_output_dir = os.path.join(rain_dir, rain_level, "rain_mask", sub_folders)

                    original_file_path = os.path.join(self.original_dir, sequence, sub_folders, filename)

                    os.makedirs(rainy_image_output_dir, exist_ok=True)

                    os.makedirs(rain_mask_output_dir, exist_ok=True)

                    shutil.copyfile(os.path.join(rain_levels_dir, rain_level, "rain_mask", sub_folders, filename),
                                    os.path.join(rain_mask_output_dir, filename))
                    self._apply_diff(original_file_path, rain_diff_path, os.path.join(rainy_image_output_dir, filename))

        for sequence in self.sequences:
            rain_levels_dir = os.path.join(self.datasets_directory, self.name, sequence, "rain_diff")

            shutil.rmtree(rain_levels_dir, ignore_errors=True)

    # Apply differential image
    def _apply_diff(self, raw_file, diff_file, output_file):
        # Read images
        clear_image = cv2.imread(raw_file)
        diff_image = cv2.imread(diff_file, cv2.IMREAD_UNCHANGED)
        clear_image = self.transform_original_image(clear_image)

        # Generate augmented image
        clear_image = clear_image.astype(np.uint16)
        diff_image = diff_image.astype(np.uint16)
        augmented_image = (diff_image - 255).astype(np.int16) + clear_image

        cv2.imwrite(output_file, augmented_image.astype(np.uint8))