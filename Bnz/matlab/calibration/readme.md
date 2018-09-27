
# Calibration README

## Usage

### 1. Create a folder (e.g. cali_180110) containing: 
	frame0.jpg 
	Im_*.jpg 

The frame0 is the blank GelSight image without any touch. The Im_*.jpg is the GelSight image with a ball pressing on it. This is to build up the lookup table from RGB to gradients. About 10 images on different areas will usually be sufficient.

### 2. Calculate the Pixmm parameter, which represents how much millimeters one pixel is corresponding to. 

Use a caliper to press multiple times on the GelSight and counting the corresponding pixels in GelSight images. After calculation, update the `Pixmm` in calibration.m, eg.

	Pixmm=0.03026

### 3. Run the calibration.m to select circle ranges.

It will pop out interactive window to select the circle to cover the ball. It’s already calculated by program. The user should use keyboard input to make it more precise. 

Keyboard command: 

	* +/-: enlarge/shrink the circle
	* up/down/left/right: move the circle
	* ESC: next image
