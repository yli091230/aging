%% function cycle_fold normalize trajectory information based on either first few frames or first percentitle of lifespan
% put the code in the same fold with the mat file
function cycle_fold
fluN = input('how many fluorescence on this experiment :');
%%%%%%%load data%%%%%%%
all_data = input('Please type in the data set you want to plot,e.g. ''WT_20151112'': ');%assin the data name to variable all_data
name_str = all_data;%duplicate the name of the variable, make it easier to process later
eval(['load ' all_data]);%load data
eval(['all_data =' all_data ';']);%Rename the data to all_data

%%%%%%Specify normalization base%%%%%%%%
DT = input('please identify the death type that used for baseline :');%indentify the death type 
if ~isempty(DT)
    all_data_filtered = all_data([all_data.Death_type] == DT);%filter the data by DT
else
    all_data_filtered = all_data;
end

F_f = cell(1,fluN);
for i_Ff = 1:fluN
    F_f{i_Ff} = zeros(length(all_data_filtered),1);
end

% % F1_f = zeros(length(all_data_filtered),1);%Get the first cycle mean of all cells and stored in a array
% % 
% % NM = zeros(length(all_data_filtered),1);%Creat an empty array to hold all cells nuclear intensity of 1st cell cycle

for k_m = 1:length(all_data_filtered)
    all_data_filtered(k_m)
    start_1st = all_data_filtered(k_m).cycle(3)%get the start point of 1st cycle, THIS MIGHT NEED FINE TUNE
    end_1st = all_data_filtered(k_m).cycle(6);%get the end point of the 1st cycle
    for ik = 1:fluN
        F_f{ik}(k_m) = mean(all_data_filtered(k_m).traj(start_1st:end_1st,:,ik));
    end  
%     F1_f(k_m) = mean(all_data_filtered(k_m).traj(start_1st:end_1st,:,1));%get the average fluorescence of the 1st cell cycle
%     NM(k_m) = mean(all_data_filtered(k_m).traj(start_1st:end_1st,:,end));%get the nuclear marker intensity
end

Fm = zeros(1,fluN);
for ik = 1:fluN
% %     Fm(ik) = mean(F_f{ik});
    Fm(ik) = mean(F_f{ik}(~isnan(F_f{ik})));
% %     F1_m = mean(F1_f);%get the normalization factor for fluorescence 1
% %     NM_m = mean(NM);%get the normalization factor for nuclear marker
end
% Fm(1) = 554.8264; 
% % % F1_all = zeros(length(all_data),1);
% % % NM_all = zeros(length(all_data),1);
% % %  for k_mm = 1:length(all_data)
% % %     start_1st = all_data(k_mm).cycle(3);%get the start point of 1st cycle
% % %     end_1st = all_data(k_mm).cycle(6);%get the end point of the 1st cycle
% % %     F1_all(k_mm) = mean(all_data(k_mm).traj(start_1st:end_1st,:,1));%get the average fluorescence of the 1st cell cycle
% % %     NM_all(k_mm) = mean(all_data(k_mm).traj(start_1st:end_1st,:,end));
% % %     eval([name_str '(' num2str(k_mm) ').F1_all= F1_all(k_m);']);
% % %     eval([name_str '(' num2str(k_mm) ').NM_all= NM_all(k_m);']);
% % %  end   
% Fm
Fm(2)
Fm(1)
% normalize fluorescence of all cells with the cycle_m
for k_n = 1:length(all_data)
    curr_traj = [all_data(k_n).traj];%Get the traj info of current cell
    curr_traj_normalized = curr_traj;
    curr_traj_normalized_self = curr_traj;%added 2019/01/05
    %%all_data(k_n)%for debug
    for ik = 1:fluN
        curr_traj_normalized(:,:,ik) = curr_traj(:,:,ik)/Fm(ik);%normalized the fluorescence
        %added 01/03/2019 to get a self normalized trajectory
        curr_normal = curr_traj(1:end_1st,:,ik);
        curr_normal = mean(curr_normal(~isnan(curr_normal)));
        curr_traj_normalized_self(:,:,ik) = curr_traj(:,:,ik)/curr_normal;
    end
% %     curr_traj_normalized(:,:,end) = curr_traj(:,:,end)/NM_m;%normalized the nuclear marker
    eval([name_str '(' num2str(k_n) ').traj_normalized= curr_traj_normalized;']);%Assign a new filed traj_normalized to all_data
    eval([name_str '(' num2str(k_n) ').traj_normalized_self= curr_traj_normalized_self;']);
    %%%%%Get the mean fluorescence of eath cell cycle
    all_data(k_n)
    cycles = all_data(k_n).cycle(5:end)

    curr_cycle = zeros(1,length(cycles)-1);%create a empty array that hold fluorescence of each cell cycle   
    for c_m = 1:length(curr_cycle)
        %curr_traj_Dt(k_Dt) = curr_traj_normalized(k_Dt+1,1,1)-curr_traj_normalized(k_Dt,1,1);
        curr_cycle(c_m) = mean(curr_traj_normalized(cycles(c_m):cycles(c_m+1),1,1));
    end
    eval([name_str '(' num2str(k_n) ').cycle_m= curr_cycle;']);
    
    
    %%%%%Caculate the derivitive of each cell cycle
    cycle_dt = zeros(1,length(curr_cycle)-1);
    for k_dt = 1:length(cycle_dt)
        cycle_dt(k_dt) = curr_cycle(k_dt+1) - curr_cycle(k_dt);
    end
    eval([name_str '(' num2str(k_n) ').traj_Dt = cycle_dt;']);
% % %     
% % %     %create a empty array that hold derivitive of fluorescence cell cycle
% % %     %not normalized
% % %     cycle_in = zeros(1,length(cycles)-1);
% % %     %get the mean fluorescence of eath cell cycle
% % %     for c_in = 1:length(cycle_in)
% % %         %curr_traj_Dt(k_Dt) = curr_traj_normalized(k_Dt+1,1,1)-curr_traj_normalized(k_Dt,1,1);
% % %         cycle_in(c_in) = mean(all_data(k_n).traj(cycles(c_in):cycles(c_in+1),1,1));
% % %     end
% % %     
% % %     cycle_in_dt = zeros(1,length(cycle_in)-1);
% % %     for c_in = 1:length(cycle_in_dt)
% % %         cycle_in_dt(c_in) = cycle_in(c_in+1)-cycle_in(c_in);
% % %     end
% % %     eval([name_str '(' num2str(k_n) ').cycle_in= cycle_in_dt;']);
    

    %eval([new_name_str '(' num2str(k) ').normalization=' normal_method '{' average_type '}';']);
end
Fm
save([name_str,'.mat'],name_str)%save the normalized trajectories




