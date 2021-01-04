#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Dec 12 09:04:08 2020

@author: yang

need pip install pims-nd2
pims-nd2 version 1.1
"""

"""
def tracking(a_field):
    return image_intensity

def pick_mother(mask):
    return mother_mask, mask_bbox

def get_mask(phase_image):
    return mask
"""

from pims import ND2_Reader
# import matplotlib.pyplot as plt
"""
#Open nd2 file to extract the
exposure information, experiment setting up information
cell tracking per position

#run parraller to increase speed? 

def get_a_field('nd2',field_number):

    return a_field # a multidimensional array

"""
#{'x': 512, 'y': 256, 'c': 3, 't': 401, 'm': 112}

def load_stack(file_path='/mnt/d/Microscope_data/20191127_CR_metformin.nd2',fov_n = 0):
    with ND2_Reader(file_path) as images:
    # with ND2_Reader('./ROX1_NA_and_NAM.nd2') as images:
        images.bundle_axes = 'tcyx'
        images.iter_axes = 'm'
        # a = images[125]
        # print(len(images))
        fov_stack = images[fov_n]
        # print(images.metadata)
    return fov_stack


def get_metadata(file_path='/mnt/d/Microscope_data/20191127_CR_metformin.nd2'):
    #get the plane count,and image dimensions of the images
    with ND2_Reader(file_path) as images:
        image_dim = images.sizes
        image_planes = {}
        for c_n in range(0,image_dim['c']):
            plane_name = 'plane_' + str(c_n)
            image_planes[plane_name] = images.metadata[plane_name]['name']
    metadata={'planes':image_planes,'dimensions':image_dim}
    return metadata