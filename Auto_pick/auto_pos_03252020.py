#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Create Nikon macro for loading positions on Wed Mar 25 16:04:46 2020

input parameters of 2 positions to get all the rest positions @author: Yang
"""

import numpy as np
import math as mt
import xml.etree.ElementTree as ET
import os


tree = ET.parse('multipoints_export.xml')
root = tree.getroot()
#get the child name:
child = root.find('no_name')
#caculate the device number
input_no = int((len(child.getchildren())-2))
dev_n = int(input_no*2)

#get the initial position information
def get_input(dev_n):
    #creat an array to hold the initial tow pos of all devices
    init_pos = np.zeros((4,input_no))
    #collect the position information of the device
    for xy_n in child[2:]:
        curr_id = int(xy_n.tag[-2:])
        for pos in xy_n:
            # print(pos)
            # print(pos.tag,pos.attrib)
            if pos.tag == 'dXPosition':
                init_pos[0,curr_id] = float(pos.attrib['value'])
            elif pos.tag == 'dYPosition':
                init_pos[1,curr_id] = float(pos.attrib['value'])
            elif pos.tag == 'dZPosition':
                init_pos[2,curr_id] = float(pos.attrib['value'])
            elif pos.tag == 'dPFSOffset':
                init_pos[3,curr_id] = float(pos.attrib['value'])
    #return the position and different between positions
    return init_pos


def get_position(two_pos):
    xx = np.zeros((17,4))
    yy = np.zeros((17,4))
    zz = np.zeros((17,4))
    L = np.zeros((4,1))
    xx[0][0] = two_pos[0][0] #position 1
    xx[16][0] = two_pos[0][1] #position 1
    yy[0][0] = two_pos[1][0] #position 17
    yy[16][0] = two_pos[1][1] #postion 17
    zz[0][0] = two_pos[2][0]
    zz[16][0] = two_pos[2][1]
    alpha = mt.atan((yy[16][0]-yy[0][0])/(xx[16][0]-xx[0][0]))
    L[0] = 0  #distance between device_1 and 1
    L[1] = 250 #distance between device_1 and 2
    L[2] = 3221+250 #distance between device_1 and 3
    L[3] = 500+3221 #distance between device_1 and 4
    for j in range(0,4):
        for i in range(17):
            xx[i][j] = xx[0][0] + (xx[16][0]-xx[0][0])/16*i - L[j]*mt.sin(alpha)
            yy[i][j] = yy[0][0] + (yy[16][0]-yy[0][0])/16*i + L[j]*mt.cos(alpha)
            zz[i][j] = zz[0][0] + (zz[16][0]-zz[0][0])/16*i
            
        pfs = np.ones((17,4)) * two_pos[3,0]
        # print(pfs.shape)
    return xx,yy,zz,pfs



def get_all(init_pos):
    all_pos = np.zeros((dev_n,17,4))
    for i in range(int(input_no/2)):
        two_pos_i = init_pos[:,2*i:(2*i)+2]
        xx,yy,zz,pfs = get_position(two_pos_i)
        # print(xx.shape)
        all_pos[i*4:(i+1)*4,:,0] = xx.T
        all_pos[i*4:(i+1)*4,:,1] = yy.T
        all_pos[i*4:(i+1)*4,:,2] = zz.T
        all_pos[i*4:(i+1)*4,:,3] = pfs.T
    return all_pos
   


def write_docu(position_info,dev_n):
    #print(all_pos)
    f = open('auto_xy.txt','w')
    pos_name = 1;
    for d_i in range(dev_n):
        for d_t in range(17):
            a = position_info[d_i,d_t,:]
            # f.write("ND_AppendMultipointPointPFS("+'%.5f'%a[0]+","+'%.5f'%a[1]
            # +","+'%.5f'%a[2]+","+str(a[3])+","+"\""+str(pos_name)+"\""+");"+"\n")
            f.write('ND_AppendMultipointPointPFS({0:.5f},{1:.5f},{2:.5f},{3:.1f},{pos});\n'.format(a[0],a[1],a[2],a[3],pos = "\""+"#"+str(pos_name)+"\""))
            pos_name = pos_name + 1
    
    f.close()
    


a = get_input(dev_n)
all_pos = get_all(a)

write_docu(all_pos,dev_n)
os.rename('auto_xy.txt','auto_xy.mac')


