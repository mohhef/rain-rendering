"""Dynamic config for SLAMWeatherBench KITTI rain rendering."""
import os

def resolve_paths(params):
    # Use symlink path (relative to rain-rendering directory)
    # Symlink at data/source/slamweatherbench -> actual dataset
    dataset_root = "data/source/slamweatherbench"
    sequence = "04"

    params.sequences = [sequence]

    # Set paths for all cameras (image_2, and optionally image_3 for stereo)
    cameras = ['image_2', 'image_3']
    image_paths = []
    depth_paths = []

    for camera in cameras:
        image_paths.append(os.path.join(dataset_root, camera))
        depth_paths.append(os.path.join(dataset_root, f"{camera}_depth"))

    params.images = {sequence: image_paths}
    params.depth = {sequence: depth_paths}

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
