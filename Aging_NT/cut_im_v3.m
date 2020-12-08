%%03/13/2017
%A new method to show the dent,version 2 of cut_im
%Phase image were substract a baseline to find the outline
%input pos: positons for image; y_level: how much need to adjust
%output low: the y axis of the dent position. 
function low = cut_im_v3(pos,y_level)

ph_1 = ['Aligned/xy',pos,'/xy',pos,'c1A.tif'];
I_ph_1 =imread(ph_1);%load image
row = sum(I_ph_1,2)';%add each pixel from each row together to detect boundary of device
% col = sum(I_ph_1);
[~,p_loca] = findpeaks(row,'MinPeakDistance',70,'SortStr','descend');%use distance to find the two peak

% [~,p_loca] = findpeaks(row,'MinPeakProminence',mean(row),'SortStr','descend');
boundary = sort(p_loca(1:2));%get the phase boundary of the image
m_phase_pixel = mean(mean(I_ph_1(boundary(1):boundary(2),:)));
I_ph_2 = I_ph_1 - m_phase_pixel;%subtract the phase background to get feature;
level = graythresh(I_ph_2);
BW = im2bw(I_ph_2,level);% convert the phase to binary image
low = boundary(2) - y_level;
BW(low,:) = 1;

figure;imshow(BW);

        