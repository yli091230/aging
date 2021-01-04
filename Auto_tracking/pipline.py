#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Dec 23 13:59:01 2020

@author: yang
"""


import open_nd2
import track_img
import numpy as np
from tifffile import imsave
from skimage.registration import phase_cross_correlation

#need to change the bbox to 
all_dent_y = []
dent_y = []
fov_stack = open_nd2.load_stack()
all_masks = np.zeros((200,256,512),'uint16')
for i in range(0,200):
    print('Processing frame ',i)
    phase = fov_stack[i,0,:,:] #this will change the value of fov_stack
    if i == 0:
        first_mothers = track_img.get_dent(phase)
        dent_y = first_mothers[-1]
        all_masks[i,:,:] = first_mothers[0]
        pre_phase = phase
    else:
        ##for debug
        # pre_phase[int(dent_y)-2:int(dent_y)+2,:] = 255
        # plt.imshow(pre_phase)
        # plt.show()
        
        drift = phase_cross_correlation(pre_phase,phase)
        dent_y = dent_y - drift[0][0]
        mothers_info = track_img.get_mother_mask(phase,dent_y)
        all_masks[i,:,:] = mothers_info[0]
        
        pre_phase = phase
    all_dent_y.append(dent_y)
        
        
imsave('/mnt/d/mask_RCNN/stack_new3.tif',all_masks)

all_phase = fov_stack[0:100,0,:,:]
new = np.dstack((all_masks,all_phase,all_masks))
imsave('/mnt/d/mask_RCNN/stack_pm.tif',new)
