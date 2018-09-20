function [himage, hquiver]=displayMarkerandFrame(ha, frame, MarkerMotion)
% given the axis' handle, display the current frame and the marker
% displacemetn field in the same axis. Return the handles of the displayed
% image and the quiver field
% input MarkerMotion is the structure to record the markers' motion

showscale=18;
set(ha,'NextPlot','add');
himage=imshow( frame/255, 'Parent', ha);
hquiver=quiver(ha,MarkerMotion.flowcenter(:,2),MarkerMotion.flowcenter(:,1),...
    MarkerMotion.u'*showscale,MarkerMotion.v'*showscale,...
    'Color','y','LineWidth',2,'AutoScale','off');
