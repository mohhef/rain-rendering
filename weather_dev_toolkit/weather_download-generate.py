######################################################################################################################
# This file will download and generate foggy and rainy images of Kitti and Cityscapes datasets
# Usage:
#       python weather_download-generate.py [all|kitti|cityscapes] --kitti_root %PATH% --cityscapes_root %PATH%
#
# Example:
#       python weather_download-generate.py all --kitti_root /datasets/Kitti --cityscapes_root /datasets/cityscapes
#   Or:
#       python weather_download-generate.py kitti --kitti_root /datasets/Kitti
#   Or:
#       python weather_download-generate.py cityscapes --cityscapes_root /datasets/cityscapes
#
# Use python weather_download-generate.py [all|kitti|cityscapes] -h for more information
######################################################################################################################
# Halder, S. S., Lalonde, J. F., & de Charette, R. (2019).
# Physics-Based Rendering for Improving Robustness to Rain. IEEE/CVF International Conference on Computer Vision
#
# From: Computer Vision Group, RITS team, Inria
# License: MIT
#
# News 2022-08-01: Fixed a download bug and added cityscapes validation set (rain only)
######################################################################################################################

import options
from kitti import Kitti
from cityscapes import Cityscapes


def main(args):
    if args.dataset == "cityscapes":
        dataset_list = [Cityscapes(args.cityscapes_root, args.output_dir, args.sequence)]
    elif args.dataset == "kitti":
        dataset_list = [Kitti(args.kitti_root, args.output_dir, args.sequence)]
    else:
        dataset_list = [Cityscapes(args.cityscapes_root, args.output_dir),
                        Kitti(args.kitti_root, args.output_dir)]

    for i, dataset in enumerate(dataset_list):
        print("Dataset {} [{}/{}]".format(dataset.name, i+1, len(dataset_list)))
        dataset.download_and_extract_all()

        if 'rain' in args.weather:
            print(" {}, Rain".format(dataset.name))
            dataset.generate_rain()

        if 'fog' in args.weather:
            print(" {}, Fog".format(dataset.name))
            dataset.generate_fog()

    print("[DONE]")
    print("Check folder: {}".format(dataset_list[0].datasets_directory))

if __name__ == '__main__':
    main(options.parse())
