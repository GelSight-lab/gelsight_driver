# Tips for using GelSight in MATLAB
1. Download the Image Acquisition App

2. Download the Image Acquisition App: OS Generic Video Interface
In MATLAB console type:
```
supportPackageInstaller
```

To make sure that you have the apps necessary to run GelSight on MATLAB, in console, type:
```
imaqhwinfo
```
You should see:
```
InstalledAdaptors: {'winvideo'}
```
Finally, check using Image Acquisition app and select the 'default' option from Logitech HD Webcam C310.


# GelSight Bnz matlab functions


## video\_record:
A UI-interface for recording GelSight videos

## video\_record\_per\_press:
A UI-interface for recording each press

## calibration:
Build up lookup table for 3D reconstruction

## reconstruction:
3D reconstuction based on fast poisson

## track markers:
Track the markers on the sensor
