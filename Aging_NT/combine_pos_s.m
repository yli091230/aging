function combine_pos_s(pos_str,strain,Date,Details,name)
    %% combine good trajectories from each position into one structure, 
    % which contains the strains information, cell trajectories and other 
    % informations of each trajectories.
    %%
    % Array for storing all trajectory data across all cells
    all_traj = cell(1,numel(pos_str));
    % Array for storing manually curated lifespan data
    all_lifespan = cell(1,numel(pos_str));
    %creat a empty struct for storing all of the good trajectory
    %all_data.(strains) = struct('traj',{},'cycle',{},'id',{},'Date', {},'Details',{},'Death_type',{});  
    all_data = struct('strain',{},'traj',{},'cycle',{},'id',{},'Date', {},'Details',{},'Death_type',{},'name',{},'age',{});

    % For every position...
    for i = 1:numel(pos_str)
        pos = pos_str{i};
        % Horizontally concatenate traj matrices for every position, forming a super array with dimensions:
        % # of frames x # of cells/traps (from all positions) x # of fluorescent channel
        %For single traj file in subfolders.
%         traj_file = ['xy',pos,'/xy',pos,'_traj.mat'];
        traj_file = ['xy',pos,'_traj.mat'];
        load(traj_file);
        all_traj{i} = traj;

        % Import manually curated lifespan data for each cell in each position
        % Add lifespan data to all_lifespan cell array (1 x num pos), where each position's lifespan data is an array with dim:
        % # of cells rows x 3 cols (cell #, lifespan start frame, lifespan end frame)
%         lifespan_file = csvread(['xy',pos,'/xy',pos,'_lifespan.txt']);
        lifespan_file = csvread(['xy',pos,'_lifespan.txt']);

        all_lifespan{i} = lifespan_file;


        [ls_i,~] = size(all_lifespan{i}); % get the dimension of useful lifespan in current position
        %For each cell trap in current position...

        %creat a empty struct for storing all of the good trajectory
        %all_data.(strains) = struct('traj',{},'cycle',{},'id',{},'Date', {},'Details',{},'Death_type',{});

        %Death_type = {'Die with bud','Die without bud','Escape dying','later daughter'};
        %check is there any useful trap in current position
        if ls_i >= 1
            for i_ls = 1:ls_i 
                %Get the cell trap id
                cell_id = all_lifespan{i}(i_ls,1); 
                %Get the death type information
                death_id = all_lifespan{i}(i_ls,2);
                %Get the lifespan data (or cell cycle) of current cell trap
                cell_cycle = all_lifespan{i}(i_ls,:);
                %Remove the zeros in cell_cycle array, which will overcount
                %the lifespan
                cell_cycle = cell_cycle(cell_cycle>0);
                %Get the cell life span
                cell_age = length(cell_cycle(5:end));
                %Get the trajactory data of current cell trap
                cell_traj = all_traj{i}(:,cell_id,:);
                %add current trap infor into strains
                all_data = [all_data, struct('strain',strain,'traj',cell_traj,'cycle',cell_cycle,'id',['xy',pos,'_',num2str(cell_id)],'Date',Date,'Death_type',death_id,'Details',Details,'name',name,'age',cell_age)];
            end
        else
        end
    end
    %Remove death 1 and death 2 cell that live short than 10 generation
    all_data = all_data(~([all_data.age]<10 & [all_data.Death_type]~=3));

    FileName = [strain '_' num2str(Date)];
    % change the name of all_data to FileName 
    eval([FileName '=all_data;']);
    save([FileName '.mat'],FileName);
    
        
