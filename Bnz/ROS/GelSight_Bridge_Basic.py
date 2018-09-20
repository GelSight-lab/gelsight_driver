#! /usr/bin/env python

'''
Basic functions for processing GelSight images. Including saving images, calculating and displaying marker motions, detect contact.
Before calling the classes, 'GelSight_driver' should be launched, which publish '/gelsight/image_raw' topic for the images from the camera

Wenzhen Yuan (yuanwenzhen@gmail.com)  Feb, 2017
'''

import rospy
import cv2
from cv_bridge import CvBridge, CvBridgeError
from sensor_msgs.msg import Image
import time
import numpy as np
import os

class GelSight_Img(object):

	def loc_markerArea(self):
		'''match the area of the markers; work for the Bnz GelSight'''
		MarkerThresh=-30
		I=self.img.astype(np.double)-self.f0
		self.MarkerMask = np.amax(I,2)<MarkerThresh

	def displayIm(self):
		disIm=self.img
		markerCenter=np.around(self.flowcenter[:,0:2]).astype(np.int16)
		for i in range(self.MarkerCount):
			if self.markerU[i]!=0:
				cv2.line(disIm,(markerCenter[i,0], markerCenter[i,1]), \
					(int(self.flowcenter[i,0]+self.markerU[i]*self.showScale), int(self.flowcenter[i,1]+self.markerV[i]*self.showScale)),\
					(0, 255, 255),2)
		self.pub.publish(self.bridge.cv2_to_imgmsg(disIm, "bgr8"))

	def find_markers(self):
		self.loc_markerArea()
		areaThresh1=50
		areaThresh2=400
		MarkerCenter=np.empty([0, 3])

		contours=cv2.findContours(self.MarkerMask.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
		if len(contours[0])<25:  # if too little markers, then give up
			self.MarkerAvailable=False
			return MarkerCenter

		for contour in contours[0]:
			AreaCount=cv2.contourArea(contour)
			if AreaCount>areaThresh1 and AreaCount<areaThresh2:
				t=cv2.moments(contour)
				MarkerCenter=np.append(MarkerCenter,[[t['m10']/t['m00'], t['m01']/t['m00'], AreaCount]],axis=0)

		# 0:x 1:y
		return MarkerCenter

	def cal_marker_center_motion(self, MarkerCenter):
		Nt=len(MarkerCenter)
		no_seq2=np.zeros(Nt)
		center_now=np.zeros([self.MarkerCount, 3])
		for i in range(Nt):
			dif=np.abs(MarkerCenter[i,0]-self.marker_last[:,0])+np.abs(MarkerCenter[i,1]-self.marker_last[:,1])
			no_seq2[i]=np.argmin(dif*(100+np.abs(MarkerCenter[i,2]-self.flowcenter[:,2])))

		for i in range(self.MarkerCount):
			dif=np.abs(MarkerCenter[:,0]-self.marker_last[i,0])+np.abs(MarkerCenter[:,1]-self.marker_last[i,1])
			t=dif*(100+np.abs(MarkerCenter[:,2]-self.flowcenter[i,2]))
			a=np.amin(t)/100
			b=np.argmin(t)
			if self.flowcenter[i,2]<a:   # for small area
				self.markerU[i]=0
				self.markerV[i]=0
				center_now[i]=self.flowcenter[i]
			elif i==no_seq2[b]:
				self.markerU[i]=MarkerCenter[b,0]-self.flowcenter[i,0]
				self.markerV[i]=MarkerCenter[b,1]-self.flowcenter[i,1]
				center_now[i]=MarkerCenter[b]
			else:
				self.markerU[i]=0
				self.markerV[i]=0
				center_now[i]=self.flowcenter[i]
		return center_now

	def update_markerMotion(self, img=None):
		if img is not None:
			self.img=img
		MarkerCenter=self.find_markers()
		self.marker_last=self.cal_marker_center_motion(MarkerCenter)
		if self.IsDisplay:
			# publish image
			self.displayIm()

	def iniMarkerPos(self):
		# set the current marker position as the initial positions of the markers
		self.flowcenter=self.marker_last

	def start_display_markerIm(self):
		self.IsDisplay=True
	def stop_display_markerIm(self):
		self.IsDisplay=False

	def detect_contact(self, img=None, ColorThresh=1):
		if not self.calMarker_on:
			self.update_markerMotion(img)

		isContact=False

		# contact detection based on color
		diffim=np.int16(self.img)-self.f0
		self.contactmap=diffim.max(axis=2)-diffim.min(axis=2)
		countnum=np.logical_and(self.contactmap>10, diffim.max(axis=2)>0).sum()

		if countnum>self.touchthresh*ColorThresh:  # there is touch
			isContact=True
			# print "Contact--Color Detected"

		# contact detection based on marker motion
		motion=np.abs(self.markerU)+np.abs(self.markerV)
		MotionNum=(motion>self.touchMarkerMovThresh*np.sqrt(ColorThresh)).sum()
		if MotionNum>self.touchMarkerNumThresh:
			isContact=True
			# print "Contact--Marker Detected"

		return isContact, countnum

	def ini_contactDetect(self):

		diffim=np.int16(self.img)-self.f0
		maxim=diffim.max(axis=2)
		contactmap=maxim-diffim.min(axis=2)
		countnum=np.logical_and(contactmap>10, maxim>0).sum()
		# print countnum

		contactmap[contactmap<10]=0
		contactmap[maxim<=0]=0
		cv2.imwrite('iniContact.png', contactmap)

		self.touchthresh=round((countnum+1500)*1.0)
		# self.touchMarkerMovThresh=0.6
		self.touchMarkerMovThresh=1
		self.touchMarkerNumThresh=20

	def reinit(self, frame, frame0=None):
		self.img=frame   #current frame
		if frame0 is not None:
			self.f0=frame0   # frame0 is the low
		else:
			self.f0=np.int16(cv2.GaussianBlur(self.img, (101,101), 50))
		self.ini_contactDetect()


		# for markers
		self.flowcenter=self.find_markers()  # center of all the markers; x,y
		self.marker_last=self.flowcenter
		self.MarkerCount=len(self.flowcenter)
		self.markerSlipInited=False
		self.markerU=np.zeros(self.MarkerCount)	# X motion of all the markers. 0 if the marker is not found
		self.markerV=np.zeros(self.MarkerCount)	# Y motion of all the markers. 0 if the marker is not found

	def __init__(self, frame, frame0=None):
		self.reinit(frame, frame0)

		self.bridge = CvBridge()
		self.contactmap=np.zeros([480, 640])

		# initialte marker locations
		self.MarkerAvailable=True   # whether the markers are found
		self.calMarker_on=False

		# paremeters for display
		self.IsDisplay=False   #whether to publish the marker motion image
		self.showScale=8
		self.pub = rospy.Publisher('/gelsight/MarkerMotion', Image, queue_size=2)



class GelSight_Bridge(object):
	def save_iniImg(self):
		img=rospy.wait_for_message(self.topic, Image)
		self.ini_img=self.bridge.imgmsg_to_cv2(img, "bgr8")
		self.frame0=np.int16(cv2.GaussianBlur(self.ini_img, (101,101), 50))

	def __init__(self):
		self.bridge = CvBridge()
		self.img = np.zeros((100,100,3))
		self.writepath='/home/robot/catkin_ws/data/'+time.strftime("%y%m%d")+'/'
		self.writecount=0
		self.topic = '/gelsight/image_raw'
		self.save_iniImg()

		self.sub_IncomeIm=rospy.Subscriber(self.topic, Image,  self.callback_incomeIm)
		self.sub_IncomeIm.unregister()
		self.sub_IncomeIm_working=False

		self.saveim_on=False
		self.touchtest_on=False
		self.calMarker_on=False
		self.isContact=False
		self.callbackCount=0
		self.startContactDetectFlag=False

		self.args=None
		self.contactFunc=None
		self.contact_Thresh=1
		self.touchtestInied=False
		self.savename='Im'
		self.img_record = np.zeros((480,640,3,500),dtype = np.uint8)
		self.t = 0
		self.trial = 0

		# detect marker motion
		self.GelSightIm=GelSight_Img(self.ini_img, self.frame0)


	def show_MarkerImg(self):
		self.GelSightIm.start_display_markerIm()
	def stop_show_MarkerImg(self):
		self.GelSightIm.stop_display_markerIm()
	def start_calMarker(self):
		if not self.calMarker_on:
			self.calMarker_on=True
			self.calMarker_on+=1
			self.GelSightIm.calMarker_on=True
			self.sub_IncomeIm=rospy.Subscriber(self.topic, Image,  self.callback_incomeIm, queue_size=1)
	def stop_calMarker(self):
		if self.calMarker_on:
			self.calMarker_on=False
			self.GelSightIm.calMarker_on=False
			self.calMarker_on-=1
			if self.callbackCount<=0:
				self.callbackCount=0
				self.sub_IncomeIm.unregister()

	def callback_saveim(self, data):
		img=self.bridge.imgmsg_to_cv2(data, "bgr8")
		now=rospy.get_rostime()
		filename=self.savename+'_'+str(self.writecount)+'_'+str(int(now.secs%1e5*1e2+now.nsecs/1e7))+'.jpg'
		cv2.imwrite(self.writepath+filename, img)
		self.writecount+=1

	def start_saveIm(self, savename='Im'):
		'''start the raw GelSight image to save the frames, with the preflix name savename'''
		self.writecount=0
		self.savename=savename
		self.sub_saveim=rospy.Subscriber(self.topic, Image,  self.callback_saveim)


	def stop_saveIm(self):
		self.sub_saveim.unregister()

	def stop_contactDetect(self):
		if self.touchtest_on:
			self.touchtestInied=False
			self.touchtest_on=False
			self.callbackCount-=1
			if self.callbackCount<=0:
				self.callbackCount=0
				self.sub_IncomeIm.unregister()

	def start_contactDetect(self, contactfunc=None, contact_Thresh=1):
		self.contactFunc=contactfunc
		self.contact_Thresh=contact_Thresh
		self.isContact=False
		self.startContactDetectFlag=True
		if not self.touchtest_on:
			self.touchtest_on=True
			self.callbackCount+=1
			self.sub_IncomeIm=rospy.Subscriber(self.topic, Image,  self.callback_incomeIm, queue_size=1)

	def Change_SaveDir(self,dir):
		if dir==None or type(dir)!=str:
			print 'Error: a destination directory should be given'
			return
		self.writepath=dir
		if not os.path.isdir(self.writepath):
				os.mkdir(self.writepath)
				print 'folder made'

	def callback_incomeIm(self,data):
		self.img=self.bridge.imgmsg_to_cv2(data, "bgr8")

		if self.startContactDetectFlag:
			self.startContactDetectFlag=False
			self.ini_img=self.img
			self.frame0=np.int16(cv2.GaussianBlur(self.ini_img, (101,101), 50))
			self.GelSightIm.reinit(self.img, self.frame0)
			self.touchtestInied=True

		# calculate marker motion; MUST BE THE FIRST
		if self.calMarker_on:
			self.GelSightIm.update_markerMotion(self.img)

		# detecting contact
		if self.touchtest_on and self.touchtestInied:
			self.isContact, k=self.GelSightIm.detect_contact(self.img, self.contact_Thresh)
			if self.isContact:
				if self.contactFunc is not None:
					self.contactFunc()


############# Test Functions #################
def test_saveRawIm(savefolder=None, savename=None):
	'''save the raw images from GelSight. save folder is the writing path; savename is the preflix of the images. The last 7 digits in the file names are the timestemp of the image, in the form of XXXXX.XX s'''
	if savename is None: 
		savename='GelIm'
	if savefolder is None:
		savefolder='/home/robot/Documents/GelSight_Rec/'

	rospy.init_node('MarkerDisplay')
	GelSight=GelSight_Bridge()
	GelSight.Change_SaveDir(savefolder)
	print 'start saving GelSight images'
	GelSight.start_saveIm(savename)
	time.sleep(10)
	print 'finish saving images'
	GelSight.stop_saveIm()


def test_showMarker():
	rospy.init_node('MarkerDisplay')
	GelSight=GelSight_Bridge()
	print "ini done"
	GelSight.show_MarkerImg()
	GelSight.start_calMarker()

	# to display the marker motion image, you could simply use image_viewer to subscribe to '/gelsight/MarkerMotion'
	rospy.spin()

def test_ContactDetect():
	''' We are using the color change and marker motion to detect contact. Note that for different sensors, the threshold for the color detection may differ. Please contact Wenzhen for details about adjusting the parameters'''
	ContactThresh=1.5  # the higher the threshold is, the harder for the sensor to decide contact
	def ContactFunc():
		print '!!!!!In Contact'

	rospy.init_node('MarkerDisplay')
	GelSight=GelSight_Bridge()
	GelSight.start_contactDetect(ContactFunc, ContactThresh)
	time.sleep(10)
	GelSight.stop_contactDetect()


if __name__ == '__main__':
	# test_saveRawIm()
	# test_showMarker()
	test_ContactDetect()
