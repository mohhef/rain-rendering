# Weather Dev-Toolkit


This tool allows easy download of the Weather Kitti and Weather Cityscapes datasets, generated with [Halder et al, 2019].

## Usage
Use the **weather_download-generate.py** script for seamless download of the Kitti/Cityscapes weather augmented dataset, as well as post-processed depth.  
Weather Kitti has 3 set of data (object detection and 2 sequences) and Weather Cityscapes has 1 set (training set).

To download all Weather Kitti + Weather Cityscapes:  
`weather_download-generate.py all --kitti_root %PATH% cityscapes --cityscapes_root %PATH%`

To download all Weather Kitti:  
`weather_download-generate.py kitti --kitti_root %PATH%`

To download all Weather Cityscapes:  
`weather_download-generate.py cityscapes --cityscapes_root %PATH%`


It is possible to select the weather conditions with `-weather fog` or `-weather fog`.  
Or select a specific sequence with `-sequence XXX`.

### Pre-requisite
The script requires to have the original Kitti/Cityscapes prior to running the script (download them from original datasets website).
You must preserve original Kitti/Cityscapes file structure, and pass root folder as `--kitti_root` or `--cityscapes_root` parameter.

File structure expected in kitti_root:  
*  data_object/training/image_2  
*  2011_09_26/2011_09_26_drive_0032_sync/image_02/data  
*  2011_09_26/2011_09_26_drive_0056_sync/image_02/data  

For Cityscapes the file structure in cityscapes_root is expected:  
*  leftImg8bit/train  

Note: relative path correspond to the -sequence parameter.

## Citation
```
@inproceedings{halder2019physics,
   title={Physics-Based Rendering for Improving Robustness to Rain},
   author={Halder, Shirsendu Sukanta and Lalonde, Jean-Fran{\c{c}}ois and de Charette, Raoul},
   booktitle={IEEE/CVF International Conference on Computer Vision},
   year={2019}
}
```

## Troubleshooting
For any help, you may email Raoul de Charette (raoul.de-charette@inria.fr)