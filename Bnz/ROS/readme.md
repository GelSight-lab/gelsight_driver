# Raw input
Create the catkin workspace (reference: http://wiki.ros.org/catkin/Tutorials/create_a_workspace)

Install libuvc_camera (http://wiki.ros.org/libuvc_camera)

Create Gelsight package:
```
catkin_create_pkg gelsight std_msgs rospy roscpp
catkin_make
```

Copy GelSight_Bridge_Basic.py to catkin_ws/src/gelsight/src/; create catkin_ws/src/gelsight/launch/ and, copy gelsight_driver.launch to catkin/src/gelsight/launch/.

Build:
```
catkin_make
```

Launch:
```
roslaunch gelsight gelsight_driver.launch
```

The gelsight images can be viewed in topic /gelsight/image_raw 
for example:
```
rosrun image_view image_view image:=/gelsight/image_raw
```

# Marker tracker
uncomment the line in __main__ function: test_showMarker()

```
rosrun GelSight GelSight_Bridge_Basic.py
```

The images with marker can be viewed in topic /gelsight/MarkerMotion
```
rosrun image_view image_view image:=/gelsight/MarkerMotion
```
