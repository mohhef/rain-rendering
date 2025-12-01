######################################################################################################################
# This file will generate foggy and rainy images of Kitti and Cityscapes datasets
# Usage:
#       python weather_generate.py [all|kitti|cityscapes] --kitti_root %PATH% --cityscapes_root %PATH%
#
# Example:
#       python weather_generate.py all --kitti_root /datasets/Kitti --cityscapes_root /datasets/cityscapes
#   Or:
#       python weather_generate.py kitti --kitti_root /datasets/Kitti
#   Or:
#       python weather_generate.py cityscapes --cityscapes_root /datasets/cityscapes
#
# Use python weather_generate.py [all|kitti|cityscapes] -h for more information
######################################################################################################################
# Halder, S. S., Lalonde, J. F., & de Charette, R. (2019).
# Physics-Based Rendering for Improving Robustness to Rain. IEEE/CVF International Conference on Computer Vision
#
# From: Computer Vision Group, RITS team, Inria
# License: MIT
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

        if 'rain' in args.weather:
            print(" {}, Rain".format(dataset.name))
            dataset.generate_rain()

        if 'fog' in args.weather:
            print(" {}, Fog".format(dataset.name))
            dataset.generate_fog()


if __name__ == '__main__':
    main(options.parse())
