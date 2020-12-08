%%03/13/2017
%A new method to show the dent,version 2 of cut_im
%Phase image were substract a baseline to find the outline
%input pos: positons for image; y_level: how much need to adjust
%output low: the y axis of the dent position. 
function low = cut_im_v4(pos)

ph_1 = ['Aligned/xy',pos,'/xy',pos,'c1A.tif'];
I_ph_1 =imread(ph_1);%load image
BW = imbinarize(I_ph_1);
row = sum(BW,2)';
[~,p_loca] = findpeaks(row,'MinPeakDistance',70,'SortStr','descend');
boundary = sort(p_loca(1:2));

low = boundary(2) - 4;
BW(low,:) = 1;

figure;imshow(BW);

adjust_mode = input('Need adjust? 1 for yes, 0 for no ;');

while adjust_mode 
    
%     line_c = input('Please type in the color of line...  1 for white, 0 for black: ');
    low
    adjust_v = input('Please type in the pixels the dent need to be moved: ');
    low = low - adjust_v;
    BW(low,:) = 1;
    figure;imshow(BW);
    adjust_mode = input('Continue to adjust? 1 for yes, 0 for no :');
end
close all

        