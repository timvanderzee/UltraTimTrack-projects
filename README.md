# UltraTimTrack fascicle tracking algorithm
The simplest way to download UltraTimTrack is to clone the required Github repositories within Matlab. For details on how to use Git in Matlab, please refer to this link: https://de.mathworks.com/help/matlab/matlab_prog/use-git-in-matlab.html.

Once you are ready to use Git in Matlab, please follow these steps.

Within Matlab:
1.	Navigate to the path you would like to clone the UltraTimTrack repository to
2.	Run the following line of code:

!git clone https://github.com/timvanderzee/UltraTimTrack.git

4.	Navigate to the UltraTimTrack folder
5.	Run the following line of code:

!git clone https://github.com/timvanderzee/ultrasound-automated-algorithm.git

These steps should download the required repositories for UltraTimTrack to run successfully. However, also ensure that UltraTimTrack and its subfolders are added to the Matlab path before running UltraTimTrack.m, which is located in the main UltraTimTrack folder.

To load UltraTimTrack’s graphical user interface (GUI), do the following within Matlab:

•	Either open UltraTimTrack.m and go to the Editor tab and click "Run", or simply type in "UltraTimTrack" into the command window

To track a video, you need to use UltraTimTrack’s GUI and follow these steps:
1.	Load a desired image sequence by either clicking "File" then "Open video file" or by typing "Ctrl+N", then choose the image sequence that should be tracked
2.	For TimTrack to correctly define the superficial (upper) and deep (lower) aponeuroses around the fascicles of interest, it might be necessary to change the location and size of one or both boxes around the superficial or deep aponeuroses by clicking and dragging on the box or its corner, respectively. Ensure that only one aponeurosis sits in the middle of the designated box (note: blue = superficial aponeurosis; green = deep aponeurosis) and ensure that this aponeurosis does not move outside the box during the image sequence, and ideally that another aponeurosis does not enter the box during the image sequence
3.	It is recommended that the default values in the "Settings" column are not manually changed the first time that the GUI is run, unless the image depth is obviously wrong
4.	To define one fascicle and the aponeuroses within the user-defined blue and green boxes, click "Define fascicle". If the fascicle is defined incorrectly because the most superficial (i.e. upper) part of the fascicle is towards the left of the image (Fig. 1), then click "Clear", click the checkbox "Flip image" under “Optional” settings, and then click "Define fascicle" again (Fig. 2). This step is required because the Hough transform works in the first quadrant of the cartesian axes definition, as you can see in Figure 1. ![Incorrect_range](https://github.com/user-attachments/assets/a86454eb-1b92-4ca3-98a1-2275143370da)
Following, the same example flipped and "Define fascicle" re-run. 
![Flip_correct](https://github.com/user-attachments/assets/ecfddefd-4f84-4e45-839b-336998c9c571)

5.	Once the user agrees with the fascicle and aponeuroses that are defined, this fascicle can be tracked by clicking "Process all”.
6.	The user will then be prompted to run parallel processing to speed up TimTrack, which can be opted for with "Yes", or skipped with "No". Clicking cancel may cause the GUI to stop running due to an error, so if this occurs then repeat step 5 and subsequently click "Yes" or "No". To run parallel processing without being prompted, simply click the checkbox next to "Parallel processing" under “Optional” settings before clicking "Process all".
7.	After TimTrack, UltraTrack, and UltraTimTrack have finished processing, which is indicated by the absence of a wait bar, and provided that there is no error message within Matlab’s command window, the GUI will plot the fascicle lengths and fascicle angles estimated from each image of the image sequence. To check the fascicle tracking at a given frame, either the slider below the currently-displayed image can be dragged to the desired image number or the desired image number can be typed directly into the white box next to the slider. However, the best way to visually inspect the fascicle tracking is to navigate to the first image and then to click the play ">" button, which will show each ultrasound image from the entire image sequence with the tracked fascicle and aponeuroses overlaid
8.	Following steps 5-7, it is recommended the "Process noise covariance parameter" is manually changed and the fascicle tracking reinspected by repeating step 7. Decreasing the value towards 0 will favour UltraTrack's outputs, whereas increasing the value towards infinity will favour TimTrack's outputs.  Ensure that enter is pressed after the desired value is typed into this box
9.	Following steps 5-8, other parameters can also be manually changed, including the value for the "Cut-off frequency" and the value for the "Measurement noise covariance x-coordinate sup. attachment"  (see manuscript). If these values are changed, the user should first inspect the fascicle length and angle plots, and if there are substantial deviations from a previous plot, then step 7 should be repeated
10.	The feature points used for optical flow estimation by UltraTrack can also be changed by changing the ROI type from “Hough – local” to “Hough – global” (see manuscript).  

### (Optional) To process multiple videos in a folder using UltraTimTrack’s batch mode, follow these steps:

1. **Load a video in that folder** in the target folder by clicking **"File" → "Open video or image file"**, or pressing **"Ctrl+N"**, and selecting one of the videos that should be processed.

2. **Resize the rectangles** that define the superficial (blue) and deep (green) aponeuroses, as well as the yellow box surrounding the region of interest (ROI).  
   Ensure that:
   - The aponeuroses are properly aligned within the blue and green rectangles.
   - The entire fascicle and relevant structures are included in the yellow ROI box.
   - These rectangles are appropriate for all videos in the folder.

3. Once satisfied with the ROI setup, click the **menu bar item "Save ROI"** to store the defined ROI boxes into a file named `manualROI.mat`.  
   This file will be saved in the main UltraTimTrack directory, and is required for batch processing.

4. Click **"Process folder"** to begin batch processing.  
   The software will:
   - Prompt you to select the folder containing all videos to be tracked.
   - Load the saved `manualROI.mat`.
   - Automatically apply the same ROI setup to each video.
   - Track fascicles using TimTrack and UltraTrack.
   - Display results after completion.

## Additional information

### Fascicle definition
Changing the "# stationary frames" value will affect how the fascicle and aponeuroses on the first frame are defined and it is recommended that each image sequence has a steady-state passive or active force with no muscle length change for the number of frames that is input. If the muscle constantly changes length due to changes in passive or active force, then this value should be left at 1.

### Image sequence cropping
If the user would like to start tracking at a different part of the image sequence (note that only forward tracking is currently supported), then simply select the image that should be tracked first by using the slider or by typing the image number directly into the box next to the slider. Then click the top left button in the “Control panel” settings "Cut before". This will result in images before the currently-selected image not being tracked and the fascicle and aponeuroses will be defined for this image first and then tracked forwards after “Process all” is clicked (i.e. step 5). Images at the end of the image sequence can be omitted from tracking by going to the last image of interest and then clicking the top right button in the “Control panel” settings "Cut after". It is recommended that "Cut before" and "Cut after" are only clicked once or the GUI might not be able to save the tracked data. If either button is clicked more than once, then it is then recommended that the image sequence is reloaded (i.e. step 1) before it is cropped again.

### Telemed ultrasound systems
For users of [Telemed ultrasound systems](https://www.telemedultrasound.com/en/home/), we strongly recommend saving ultrasound image sequences (i.e., videos) in the .tvd file format. This is because the system may have an inconsistent sample rate; however, the timestamp of each frame, along with other information such as image resolution, is saved within the .tvd file.  You can find the [main script](https://github.com/timvanderzee/UltraTimTrack/tree/main/functions/ConvertTVD) and instructions for converting .tvd files into ".mat + .mp4" inside this repository/functions/ConvertTVD. The .mp4 file format also saves significant memory (approximately five times less) compared to .tvd; whilst the .mat file contains all the timestamps and image resolutions. UltraTimTrack automatically reads these parameters if the .mp4 and .mat files share the same name and are located in the same folder.

### Dependencies
UltraTimTrack requires the following MATLAB toolboxes:

•	Computer Vision Toolbox

•	Image Processing Toolbox

•	Parallel Computing Toolbox

•	Signal Processing Toolbox


