function all_data_filted = Remove_bad_cell(all_data)

data_name = input('please put the name of data to be loaded, eg ''NTS1'': ');
eval(['load ',data_name]);
% bad_cell_id = [7,10,29,30,35,41,54,60,69,67,73,88,93,99];
%bad_DT2_cell = [3,4,7,20,26,40,65,69,73,79,81,86,103,116,123,125,127,137,138,142,173,179,168];
bad_cell_id = input('Please put the index of bad cells, eg [1 2 4]: ');
[~,lenth] = size(all_data);
all_index = 1:lenth;
find_bad = ismember(all_index,bad_cell_id);
all_bad_data = all_data(find_bad);
bad_cell_index = eval(['ismember({',data_name,'.index},{all_bad_data.index})']);
% bad_cell_date = eval(['ismember([',data_name,'.Date],[all_bad_data.Date])']);

eval(['all_data_filted =',data_name,'(~bad_cell_index);']);
end