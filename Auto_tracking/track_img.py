#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec 12 09:04:08 2020

@author: yang
"""

import os
import sys
import numpy as np


ROOT_DIR = os.path.abspath("/mnt/d/mask_RCNN/Mask_RCNN/")
sys.path.append(ROOT_DIR)
# Directory to save logs and trained model
MODEL_DIR = os.path.join(ROOT_DIR, "logs")

from samples.yeast import yeast
import mrcnn.model as modellib
# from mrcnn.model import log

config=yeast.YeastConfig()

# from keras.preprocessing.image import load_img
# from keras.preprocessing.image import img_to_array
model = modellib.MaskRCNN(mode="inference",model_dir=MODEL_DIR, config=config)
model_path='/mnt/d/mask_RCNN/Mask_RCNN/samples/yeast20201030.h5'
model.load_weights(model_path, by_name=True)

import cv2 as cv
# from skimage.measure import label, regionprops, regionprops_table
import pandas as pd
from sklearn.cluster import MeanShift
# from sklearn.preprocessing import StandardScaler
# from sklearn.preprocessing import normalize

# #use phase image to predict mask
# phase = fov_stack[0,0,:,:]
# phase = cv.merge([phase,phase,phase])
# phase = (np.array(phase/256)).astype('uint8')
# result= model.detect([phase])
# #bbox[y0,x0,y1,x1] mg[y0:y1, x0:x1]
# mrcnn_pre = result[0]




    #add a seperate step to identify mother cells?


def get_mask(phase):
    """Get the precited mask, then use Meanshift to decide 
    cluster size incase of empty trap
    """
    phase = cv.merge([phase,phase,phase])
    phase = (np.array(phase/256)).astype('uint8')
    result= model.detect([phase])
#bbox[y0,x0,y1,x1] mg[y0:y1, x0:x1]
    mrcnn_pre = result[0]
    
    
    
    mask_n = mrcnn_pre['masks'].shape[-1]
    #create a table that contains coordinate of all masks for clustering
    index = range(0,mask_n)
    columns = ['y0','x0','y1','x1']
    bbox = pd.DataFrame(mrcnn_pre['rois'],columns=columns)
    #may not need index here
    bbox['mask_id'] = index
    bbox = bbox.set_index('mask_id')
    bbox['x_mean'] = bbox[['x0','x1']].mean(axis=1)
    bbox['y_mean'] = bbox[['y0','y1']].mean(axis=1)
    bbox = bbox.sort_values(by='x_mean')
    ##preprocessing the data doesn't help clustring
    # scaler = StandardScaler()
    # bbox_scaled = scaler.fit_transform(bbox)
    # bbox_normalized = normalize(bbox_scaled)
    # bbox_normalized = pd.DataFrame(bbox_scaled)
    
    # #cluster masks to 6 groups, idealy masks will grouped by trap_n
    # kmeans = KMeans(6)
    # kmeans.fit(bbox)
    #Use Meanshift to decide cluster size incase of empty trap
    #Can retrain the model when get enough data
    meanshift = MeanShift(bandwidth=90).fit(bbox)
    
    #check the number of cluster, for debugging
    # group_n = meanshift.labels_.max()
    
    #add predicted results as a new column
    bbox['group_n'] = meanshift.labels_
    
    return bbox, mrcnn_pre
    
    
    

    
        
def get_first_mask(phase):
    """
    Get mask for mother cells,
    If cluster equals to 6, get the cell with lowest y_mean but above the dent
    elseif cluster more than 6, remove cells the have a small y_mean
    elseif cluster less than 6, caculate the x_mean distance then decied the index
    of cell
    """
    all_mask_info = get_mask(phase)
    bbox = all_mask_info[0]
    mrcnn_pre = all_mask_info[1]
    
    # meanshift = MeanShift(bandwidth=90).fit(bbox)
    
    # #check the number of cluster, for debugging
    # # group_n = meanshift.labels_.max()
    
    # #add predicted results as a new column
    # bbox['group_n'] = meanshift.labels_
    
    
    #first remove cells that below dent_y or have a very high dent_y
    group_n = bbox['group_n'].max()
    #create an empty array to hold the mask
    all_masks = np.zeros((256,512))
    mask_candidate = pd.DataFrame()
    for col_n in range(0,group_n+1):
        #pick the lowest one as the mask of mother cell
        mask_candidate = mask_candidate.append(bbox.groupby(by='group_n').get_group(col_n).sort_values(by='y0').tail(1))

    #remove cells at top of the trap
    mask_candidate['dy0'] = mask_candidate['y0']-mask_candidate['y0'].mean()
    mask_candidate['dy1'] = mask_candidate['y1']-mask_candidate['y1'].mean()
    mask_candidate = mask_candidate[(mask_candidate['dy0']>-25) | (mask_candidate['dy1']>-20) ]

    
    #check whether the mask is below dent, if so remove it
    mask_candidate['dy0'] = mask_candidate['y0']-mask_candidate['y0'].mean()
    mask_candidate['dy1'] = mask_candidate['y1']-mask_candidate['y1'].mean()
    wrong_masks = mask_candidate[(mask_candidate['dy0']>10) & (mask_candidate['dy1']>20)]
    #check whether wrong_masks is empty, if not
    w_group_n = list(wrong_masks['group_n'])
    wrong_idx = list(wrong_masks.index)
    for w_i in range(0,len(w_group_n)):
        mask_candidate = mask_candidate.drop([wrong_idx[w_i]])
        mask_candidate = mask_candidate.append(bbox.groupby(by='group_n').get_group(w_group_n[w_i]).sort_values(by='y0').tail(2).head(1))

    
    #reorder the index by x_mean value
    mask_candidate = mask_candidate.sort_values(by='x_mean')
    mother_index = list(mask_candidate.index)
    #optional: update dy1
    mask_candidate['dy1'] = mask_candidate['y1']-mask_candidate['y1'].mean()
    #get the trap_n of the mother cell
    for cell_idx in range(0,len(mother_index)):
        all_masks += mrcnn_pre['masks'][:,:,mother_index[cell_idx]]

    
    #return bbox, 
    return all_masks, mask_candidate




# phase = fov_stack[0,0,:,:]
# plt.imshow(get_mother_mask(get_mask(phase))[0])

def get_dent(phase):
    """
    If this is the first frame, get the dent information
    """
    # print(phase.shape)
    # all_mask_info = get_mask(phase)
    mask_info = get_first_mask(phase)
    dent_y = mask_info[1]['y1'].min()
    
    return mask_info[0], mask_info[1], dent_y
    

def get_mother_mask(phase,dent_y):
    all_mask_info = get_mask(phase)
    bbox = pd.DataFrame
    bbox = all_mask_info[0]
    mrcnn_pre = all_mask_info[1]
    
    # print(bbox)  
    bbox['dent2y_mean'] = dent_y -bbox['y_mean']
    bbox['dent2y0'] = dent_y -bbox['y0']
    bbox['dent2y1'] = dent_y -bbox['y1']
    #dent2y_mean to remove cell below the dent, 
    bbox = bbox[((bbox['dent2y_mean'] > 5) | (bbox['dent2y0']>15)) & (bbox['dent2y1'] < 40) ]
    

    # bbox['y02dent'] = bbox['y0'] - dent_y
    # bbox['y12dent'] = bbox['y1'] - dent_y
    # single_mother = (bbox['dent2y0'] > 10) & (bbox['dent2y1']>-5)
    # mother_w_bud = (bbox['dent2y0'] > 10) & (bbox['dent2y1']>-5)
    # bbox = bbox[(bbox['dent2y0'] > 5) & (bbox['dent2y1']>-20)]
    # bbox = bbox[(bbox['dent2y1'] < 40) & (bbox['dent2y0'] < 80)]
    #Use Meanshift to decide cluster size incase of empty trap
    #Can retrain the model when get enough data
    # meanshift = MeanShift(bandwidth=90).fit(bbox)
    # #check the number of cluster, for debugging
    # # group_n = meanshift.labels_.max()
    
    # #add predicted results as a new column
    # bbox['group_n'] = meanshift.labels_
        
    # #first remove cells that below dent_y or have a very high dent_y
    # group_n = bbox['group_n'].max()
    
    #create an empty array to hold the mask
    all_masks = np.zeros((256,512))
    mask_candidate = pd.DataFrame() 
    
    k_number = bbox.group_n.unique()
    k_number.sort()
    
    
    for col_n in k_number:
    #pick the lowest one as the mask of mother cell
        mask_candidate = mask_candidate.append(bbox[(bbox['group_n'] == col_n)].sort_values(by='y1').tail(1))
        # print(col_n)
    # mask_candidate = mask_candidate[(mask_candidate['y02dent']<-10) & (mask_candidate['y12dent']>-20)]

    # bbox_filted = bbox[(bbox['y02dent']<-10) & (bbox['y12dent']>-20)]
    
    # Change groupby to index by unique group number and then iterate to get masks
    
    # for col_n in range(0,group_n+1):
    # #pick the lowest one as the mask of mother cell
    #     mask_candidate = mask_candidate.append(bbox.groupby(by='group_n').get_group(col_n).sort_values(by='y1').tail(1))
   
   
    mother_index = list(mask_candidate.index)
    
    # mother_index = list(bbox_filted.index)
    #optional: update dy1
    # mask_candidate['dy1'] = mask_candidate['y1']-mask_candidate['y1'].mean()
    #get the trap_n of the mother cell
    for cell_idx in mother_index:
        all_masks += mrcnn_pre['masks'][:,:,cell_idx]
    return all_masks, mask_candidate