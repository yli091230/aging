%Version 2
function combine_pos_quick(pos_str,strain,Date,Details,name,threshold)
    
    %count the number of good cells
%     cell_per_position = zeros(1,length(pos_str));
%     for i = 1:numel(pos_str)
%         lifespan_file = csvread(['xy',pos_str{i},'_lifespan.txt']);
%         [ls_i,~] = size(lifespan_file); 
%         cell_per_position(i) = ls_i;
%     end
%     all_goodcell = sum(cell_per_position);
    
    
    %creat a empty struct for storing all of the good trajectory
    %all_data.(strains) = struct('traj',{},'cycle',{},'id',{},'Date', {},'Details',{},'Death_type',{});  
    all_data = struct('strain',{},'traj',{},'traj_all',{},'cycle',{},'index',{},'Details',{},'Death_type',{},'id',{},'Date', {},'name',{},'age',{});

    % For every position...
    for i = 1:length(pos_str)
        pos = pos_str{i}
        % Horizontally concatenate traj matrices for every position, forming a super array with dimensions:
        % # of frames x # of cells/traps (from all positions) x # of fluorescent channel
        %For single traj file in subfolders.
        traj_file = ['Aligned/xy',pos,'/xy',pos,'_traj_N.mat'];
        %traj_file = ['xy',pos,'_traj.mat'];
        load(traj_file);
        lifespan_file = csvread(['xy',pos,'_lifespan.txt']);
        [ls_i,~] = size(lifespan_file); % get the dimension of useful lifespan in current position
        %For each cell trap in current position...

        %creat a empty struct for storing all of the good trajectory
        %all_data.(strains) = struct('traj',{},'cycle',{},'id',{},'Date', {},'Details',{},'Death_type',{});

        %Death_type = {'Die with bud','Die without bud','Escape dying','later daughter'};
        %check is there any useful trap in current position
        if ls_i >= 1
            for i_ls = 1:ls_i 
                %Get the cell trap id
                cell_id = lifespan_file(i_ls,1); 
                %Get the death type information
                death_id = lifespan_file(i_ls,2);
                %Get the lifespan data (or cell cycle) of current cell trap
                cell_cycle = lifespan_file(i_ls,:);
                %Remove the zeros in cell_cycle array, which will overcount
                %the lifespan
                cell_cycle = cell_cycle(cell_cycle>0);
                %Get the cell life span
                cell_age = length(cell_cycle(5:end));
                %Get the trajactory data of current cell trap
                cell_traj = traj_all(:,cell_id,:);
                [frame,~,flu] = size(cell_traj);
                cell_traj_all = zeros(frame,1,flu);
                for flu_i = 1:flu
                    curr_flu = traj_all(:,cell_id,flu_i);
                    for frame_i = 1:frame
                        curr_frame = curr_flu{frame_i,:};
                        %remove NaN value
                        curr_frame = curr_frame(~isnan(curr_frame));
                        curr_frame = sort(curr_frame);
                        pixel_n = length(curr_frame);
                        if pixel_n >0
                            top_x = curr_frame(fix(threshold*pixel_n):pixel_n);
                            cell_traj_all(frame_i,1,flu_i) = mean(top_x);%//changed to sum 11/1/2017
                        else
                             cell_traj_all(frame_i,1,flu_i) = 0;
                        end
%                         cell_traj_all(frame_i,1,flu_i) = mean(top_x);
                    end
                end
                id = ['xy',pos,'_',num2str(cell_id)];
                index = [num2str(Date),'_',id];
                %add current trap infor into strains
                all_data = [all_data, struct('strain',strain,'traj',cell_traj_all,'traj_all',{cell_traj},'cycle',cell_cycle,'index',index,'Death_type',death_id,'id',id,'Date',Date,'Details',Details,'name',name,'age',cell_age)];
            end
        else
        end
    end
    %Remove cells that are not later mother or later daughter and live short than 5 generations
% % %     all_data = all_data(~([all_data.age]<10 & [all_data.Death_type]~=3));
    FileName = [strain '_' num2str(Date)];
    % change the name of all_data to FileName 
    eval([FileName '=all_data']);
    save([FileName '.mat'],FileName);
    
        
