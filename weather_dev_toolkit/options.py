######################################################################################################################
# Halder, S. S., Lalonde, J. F., & de Charette, R. (2019).
# Physics-Based Rendering for Improving Robustness to Rain. IEEE/CVF International Conference on Computer Vision
#
# From: Computer Vision Group, RITS team, Inria
# License: MIT
######################################################################################################################

import os
from argparse import ArgumentParser
from kitti import Kitti
from cityscapes import Cityscapes

file_dir = os.path.dirname(__file__)  # the directory that options.py resides in


def parse():
    parser = ArgumentParser()
    subparsers = parser.add_subparsers(dest="dataset")
    subparsers.required = True

    # All
    all_subparser = subparsers.add_parser('all', help='Actions for all datasets')
    all_subparser.add_argument("--cityscapes_root", type=str, help="Original Cityscapes path", required=True)
    all_subparser.add_argument("--kitti_root", type=str, help="Original Kitti path", required=True)
    all_subparser.add_argument("--output_dir", type=str, default=os.path.join(file_dir, "../"))
    all_subparser.add_argument("--weather", nargs='+', choices=['rain', 'fog'], default=['rain', 'fog'])

    # Cityscapes
    cityscapes_subparser = subparsers.add_parser('cityscapes', help='Actions for Cityscapes')
    cityscapes_subparser.add_argument("--cityscapes_root", type=str, help="Original cityscapes path", required=True)
    cityscapes_subparser.add_argument("--output_dir", type=str, default=os.path.join(file_dir, "../"))
    cityscapes_subparser.add_argument("--weather", nargs='+', choices=['rain', 'fog'], default=['rain', 'fog'])
    cityscapes_subparser.add_argument("--sequence", nargs='+', choices=Cityscapes.sequences, default=Cityscapes.sequences)

    # Kitti
    kitti_subparser = subparsers.add_parser('kitti', help='Actions for Kitti')
    kitti_subparser.add_argument("--kitti_root", type=str, help="Original Kitti path", required=True)
    kitti_subparser.add_argument("--output_dir", type=str, default=os.path.join(file_dir, "../"))
    kitti_subparser.add_argument("--weather", nargs='+', choices=['rain', 'fog'], default=['rain', 'fog'])
    kitti_subparser.add_argument("--sequence", nargs='+', choices=Kitti.sequences, default=Kitti.sequences)


    return parser.parse_args()
