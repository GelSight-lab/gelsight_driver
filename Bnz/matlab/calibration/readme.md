
# Calibration README

## Usage:

### 1. Create a folder (e.g. cali_180110) containing: 
	frame0.jpg 
	Im\_\*.jpg 

The frame0 is the blank GelSight image without any touch. The Im_*.jpg is the GelSight image with a ball pressing on it. This is to build up the lookup table from RGB to gradients. More images on different areas will make the lookup table more precise.

### 2. Calculate the Pixmm parameter, which represents how much millimeters one pixel is corresponding to. 

Use a caliper to press multiple times on the GelSight and counting the corresponding pixels in GelSight images. After calculation, it should be placed in calibration.m.

### 3. Run the calibration.m to select circle ranges.

It will pop out interactive window to select the circle to cover the ball. It’s already calculated by program. The user should use keyboard input to make it more precise. 

### Keyboard command: 

* +/- keys: enlarge/shrink the circle
* up/down/left/right arrow keys: move the circle
* ESC: next image.
