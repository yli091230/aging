%% Pipeline wrapper for aging chip code
%This is for nuclear tracking stack Version 2.0 2019/01/04

%% Initialization
clear;
% Add scripts folder to {search path
addpath('/Users/Yang/Desktop/Yang_code/Aging_NT_V3/stack_method_v3');
% Input the position numbers to be analyzed
pos_input = input('xy positions to analyze {01, 02, ..., 99}: ');

% Convert input positions from ints to strs
pos = cell(1,numel(pos_input));
for k = 1:length(pos_input) % for each position input
    pos{k} = int2str(pos_input{k}); % add its xy pos name to pos {}
    if length(pos{k}) == 1 % for single digit positions, append 0 in front to make it two digits, ie 1 -> 01
        pos{k} = ['0',pos{k}];
    end
end
posn = length(pos);

% Automatically scan the the xy01c1.tif to get the frame numbers
% sample_name = ['data/xy',pos{1},'c1.tif'];
% sample_stack = imfinfo(sample_name);
% imN = length(sample_stack);
% clear sample_stack sample_name
% fprintf('Processing %d frames.\n', imN);


%% Align all of the frames
%Yang Li 03/04/2016
tic
fluN = input('Input # of channels: ');
NC = input('Type in the nuclear channel No., e.g. 1: ');
% parfor_progress(posn);
for iaf = 1:posn
    current_pos = pos{iaf};
    dft_stack_align(current_pos,imN,fluN, NC);%can use phase_align_v3 or dft_align
%     parfor_progress;

end
toc
% parfor_progress(0);
%% Get the lowest y limit
% Yang Li 11/15/2015
cutoff_Y = zeros(1,posn);
%N_im = cell(1,posn);% for debugging
%y_l = input('Distance of dent to the top feature, should be same for same device...e.g. 30 : ');
for i = 1:posn
    
    current_pos = pos{i};
    cutoff_Y(i) = cut_im_v4(current_pos);%the smaller the number the lower the y
    %figure,imshow(N_im{i}); % debug
end
fprintf('Got the lowest y limit.\n');
%new_Y = max(cutoff_Y);% pick the lowest Y of all positions as new_Y

% %other ways to get the new_Y
%new_Y = round(mean(cutoff_Y)); use the mean of lowest y position from all
%image as a new_Y
%new_Y = cutoff_Y; each position will use it own y limit
%% Generate masks and cell trajectories
% Can add a wait bar in the future
close all
tic 

% % Input the number of traps per image
colN = input('Input # of traps: ');
% colN = 6;
NC = input('Type in the nuclear channel No., e.g. 1: ');
% Input the number of fluorescent channels to analyze
channel = input('Input # of channels: ');

%cutoff_Y = input('Input cutoff Y array for to-be-analyzed xy positions [y1, y2, ...yn]: ')
% an array of Y positions for the bottom of "mother cell region" for those
% to-be-analyzed positions 
% parfor_progress(posn);
fileID = fopen('analyzed_position.txt','w');
fclose(fileID);
for i = 1:posn
    type analyzed_position.txt;
    curr_pos = pos{i};
    curr_Y = cutoff_Y(i);
   % fprintf('Generating mask and trajectories for position xy%d.\n', str2num(curr_pos));
    traj_stack(curr_pos,imN,colN,channel,curr_Y,NC)
%     parfor_progress;
end
%     parfor_progress(0);

toc
%
%% Combine data from each single position
%Yang Li 11/20/2015 
%combine all of the good trajectories from each position into a struct,
%strains_Date

%strains_Date.(strains) contain information to speifiy the strains type.
%Strainscan be TEL for telomere, RDN for RDNA reporter, ura3-1 for ura3
%locus

%strains_Date.strains.() contain other field of the trajectory information:
%traj: array [image_number,cell_trap_id,flu_id]
%cycle: array [cell division, cell_trap_id]
%Date: date of the experiment YYYYMMDD
%Details: description of the experiment
tic
strains = input('Please identity reporter for this experiment: e.g. ''TEL'',''RDN'',''HML''...' );
Date = input('Please type in the date of the experiment: e.g. ''YYYYMMDD''...');
Details = input('Please type in the details of the experiment: e.g. ''check the unsilencing of TEL''...');
name = input('Please type in your name: ');
threshold = input('Please type in the threhsold for picking pixel (0.01-0.99); e.g. "0.6 for top 40%" ');

%%%%combine all datas with cell cycle
combine_pos_quick(pos,strains,Date,Details,name,threshold);

%%%%combine all datas without cell cycle
% combine_no_cycle(pos,strains,Date,Details,name,threshold);

toc