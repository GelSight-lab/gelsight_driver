#!/usr/local/bin/python
# encoding: utf-8
# File Name: optical_flow.py
# Author: Shaoxiong (Shawn) Wang
# Create Time: 2017/11/15 16:24
# TODO:
#    Add annotation

import cv2
import numpy as np
import numpy.matlib
import time

# cap = cv2.VideoCapture("../data/CD0011-a3.mp4") # choose to read from video or camera
cap = cv2.VideoCapture(0)
fourcc = cv2.VideoWriter_fourcc('M','J','P','G')
col = 320
row = 240
out = cv2.VideoWriter('flow.avi',fourcc, 8.0, (col*1,row*2)) # The fps depends on CPU


x0 = np.matlib.repmat(np.arange(row), col, 1).T
y0 = np.matlib.repmat(np.arange(col), row, 1)

x = np.zeros_like(x0).astype(int)
y = np.zeros_like(y0).astype(int)

def add_flow(x, y, flow):
    dx = np.round_(x + x0).astype(int)
    dy = np.round_(y + y0).astype(int)
    dx[dx>=row] = row - 1
    dx[dx<0] = 0
    dy[dy>=col] = col - 1
    dy[dy<0] = 0
    ds = np.reshape(flow[np.reshape(dx, -1), np.reshape(dy, -1)], (row, col, -1))
    nx = x + ds[:, :, 0]
    ny = y + ds[:, :, 1]
    return nx, ny

def flow2color(flow, K=15):
    mag, ang = cv2.cartToPolar(-flow[...,1], flow[...,0])
    hsv[...,0] = ang*180/np.pi/2
    mag = mag.astype(float) * K * 960 / col
    
    mag[mag>255] = 255
    hsv[...,0] = ang*180/np.pi/2
    hsv[...,2] = mag
    bgr = cv2.cvtColor(hsv,cv2.COLOR_HSV2BGR)

    return bgr

time.sleep(1)
ret, frame1 = cap.read()
frame1 = cv2.resize(frame1, (col, row))
prvs = cv2.cvtColor(frame1,cv2.COLOR_BGR2GRAY)
f0 = cv2.cvtColor(frame1,cv2.COLOR_BGR2GRAY)
hsv = np.zeros_like(frame1)
hsv[...,1] = 255
flow_sum = np.zeros((row, col, 2))
count = 0

reset_threshold_error = 0.3
reset_threshold_mean = 2



def draw(img, flow, scale=5.0):
    for i in range(20, row, 15):
        for j in range(20, col, 15):
            d = (flow[i, j] * scale).astype(int)
            cv2.arrowedLine(img, (j, i), (j+d[0], i+d[1]), (0, 255, 255))


while(1):
    count += 1
    try:
        ret, frame2 = cap.read()
        frame2 = cv2.resize(frame2, (col, row))
        next = cv2.cvtColor(frame2,cv2.COLOR_BGR2GRAY)
    except:
        break

    flow = cv2.calcOpticalFlowFarneback(f0,next, None, 0.5, 3, int(180 * col / 960), 5, 5, 1.2, 0)
    bgr0 = flow2color(flow)

    flow_2 = cv2.calcOpticalFlowFarneback(prvs,next, None, 0.5, 3, int(180 * col / 960), 5, 5, 1.2, 0)
    bgr2 = flow2color(flow_2, K=100)

    nx, ny = add_flow(x, y, flow_2)
    nx = nx
    ny = ny
    error = (np.mean(np.abs(nx - flow[:,:,0])) + np.mean(np.abs(ny - flow[:,:,1]))) / 2.0
    mean = (np.mean(np.abs(flow[:,:,0])) + np.mean(np.abs(flow[:,:,1]))) / 2.0

    if error < reset_threshold_error or mean < reset_threshold_mean:
        x = flow[:,:,0]
        y = flow[:,:,1]
    else:
        x, y = nx, ny

    # x, y = add_flow(x, y, flow_2)
    flow_sum[:,:,0] = x
    flow_sum[:,:,1] = y
    bgr  = flow2color(flow_sum)


    frame3 = np.copy(frame2)
    frame4 = np.copy(frame2)
    draw(frame2, flow_2, 10)
    draw(frame3, flow_sum, 5)
    draw(frame4, flow, 5)

    # bgr = np.vstack([np.hstack([frame2, frame4, frame3]), np.hstack([bgr2, bgr0, bgr])])
    bgr = np.vstack([np.hstack([frame3]), np.hstack([bgr])])
    cv2.imshow('frame2',bgr)
    
    k = cv2.waitKey(30) & 0xff
    out.write(bgr)
    if k == 27:
        break
    elif k == ord('s'):
        cv2.imwrite('opticalfb.png',frame2)
        cv2.imwrite('opticalhsv.png',bgr)
    prvs = next

cap.release()
cv2.destroyAllWindows()
