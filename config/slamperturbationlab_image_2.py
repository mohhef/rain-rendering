"""Dynamic config for SLAMPerturbationLab KITTI rain rendering - image_2."""
import os

def resolve_paths(params):
    # Use symlink path (relative to rain-rendering directory)
    # Symlink at data/source/slamperturbationlab -> actual dataset
    dataset_root = "data/source/slamperturbationlab"
    sequence = "04"

    params.sequences = [sequence]

    # Set paths for specific camera
    params.images = {sequence: os.path.join(dataset_root, "image_2")}
    params.depth = {sequence: os.path.join(dataset_root, "image_2_depth")}

    # Use calib file if exists
    calib_file = os.path.join(dataset_root, "calib.txt")
    if os.path.exists(calib_file):
        params.calib = {sequence: calib_file}
    else:
        params.calib = {sequence: None}

    return params

def settings():
    settings = {}

    # Camera intrinsic parameters (KITTI-like defaults)
    settings["cam_hz"] = 10
    settings["cam_CCD_WH"] = [1242, 375]
    settings["cam_CCD_pixsize"] = 4.65
    settings["cam_WH"] = [1242, 375]
    settings["cam_focal"] = 6
    settings["cam_gain"] = 20
    settings["cam_f_number"] = 6.0
    settings["cam_focus_plane"] = 6.0
    settings["cam_exposure"] = 2

    # Camera extrinsic parameters
    settings["cam_pos"] = [1.5, 1.5, 0.3]
    settings["cam_lookat"] = [1.5, 1.5, -1.]
    settings["cam_up"] = [0., 1., 0.]

    # Sequence-wise settings
    settings["sequences"] = {}
    settings["sequences"]["04"] = {}
    settings["sequences"]["04"]["sim_mode"] = "normal"
    settings["sequences"]["04"]["sim_duration"] = 100  # Long enough for sequence

    return settings
