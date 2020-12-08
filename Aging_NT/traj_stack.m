% Generate mask
% Output both phase_mask overlaby and the phase_nuc overlay. 20160120 by Yang Li
% Output all pixels from the experiment
% Add N to the end of output data name

function traj_stack(pos,imN,colN,channel,ybound,N_C)
    


    % Initialize empty 3D matrix to store trajectories (frame #, trap #, flu channel #)
%     traj = zeros(imN, colN, channel-1);
    traj_all = cell(imN,colN,channel-1); %added on 08/17/2017
    % Output trajectory data for all traps on this xy position
    output_data =['Aligned/xy',pos,'/xy',pos,'_traj_N.mat']; %include position and date in the filename
    
    %define the size of images;should be 256 by 512
    mImage = 512;
    nImage = 256;
    
    %Define the name of current stack, then acquire the stack info
    curr_stack_names = cell(1,channel);
    curr_stack_info = cell(1,channel);
%     new_stack_names = cell(1,channel);
    
    %Create names and image infos for loading and saving
    for cc = 1:channel
        curr_stack_names{cc} = ['Aligned/xy',pos,'/xy',pos,'c',num2str(cc),'A.tif'];
        curr_stack_info{cc} = imfinfo(curr_stack_names{cc});
%         new_stack_names{cc} = ['Aligned/xy',pos,'/xy',pos,'c',num2str(cc),'A.tif'];
    end
    
    PM_overlay_name = ['Aligned/xy',pos,'/xy',pos,'_PM_overlay_N.tif'];
    

    % Define column slice width as the image width divided by colN
    block = round(mImage/colN);
    
    mother_x = zeros(1,colN);

    % Store the centroids and column masks of each mother cell
    for w = 1:colN
        mother_x(w) = block/2; %initialize with x-centroid right in the middle of block
    end
    mother_y = zeros(1,colN);
    mother_area_rec = zeros(1,colN);
    mother_BW = cell(1,colN); %initalize with completely blank columns
    for p = 1:colN
        mother_BW{p} = zeros(nImage,block);
    end


    % For each frame...
    for imid = 1:imN
        
        fprintf('Generating masks and trajectories for xy%s, frame %d.\n', pos, imid); %debug
        
        %load images
        curr_frame = zeros(nImage,mImage,channel,'uint16');
        for cfcc = 1:channel
            curr_frame(:,:,cfcc) = imread(curr_stack_names{cfcc},'Index',imid,'Info',curr_stack_info{cfcc});
        end
        
        %substruct image background with rolling ball method
        

        
        I_ph = curr_frame(:,:,1);
        I_nuc = curr_frame(:,:,N_C);

        I_nuc_bkgd = mean(mean(I_nuc));
        
        cuty_up = ybound; 
        I_nuc(cuty_up:min(cuty_up+150,nImage), 1:mImage) = I_nuc_bkgd;

        % Input directory and image paths for every fluorescent channel
        for z = 2:channel
            temp = curr_frame(:,:,z);
            I_fluz_bkgd = 0.95*mean(mean(temp)); % can be changed to a blank area
            temp(cuty_up:min(cuty_up+150,nImage), 1:mImage) =I_fluz_bkgd;
            curr_frame(:,:,z) = temp;
        end

        % Output directory and mask image name
        % out_name = ['xy',pos,'/mask/xy',pos,'_mask_t',sprintf('%04g',imid),'.tif'];
%         out_name_mother = ['xy',pos,'/mother_phase_mask/xy',pos,'_mask_overlay_t',sprintf('%04g',imid),'.tif'];
%         out_name_nuc =
%         ['xy',pos,'/mother_phase_nuc/xy',pos,'_nuc_overlay_t',sprintf('%04g',imid),'.tif'];%has
%         been done in frame alignment

        % Initialize mask image for this frame
%         if rem(width,colN) == 0 % if image width is divisible by 7, init blank mask array
%             I_mother_mask = [];
%         else
%             I_mother_mask = zeros(height,2); %
%         end
%         
        I_mother_mask = zeros(nImage,mImage);

        

        % For each column in the current frame...
        for i = 1:colN
            use_sum_tag=0;
            Icf = I_nuc(:,1+(i-1)*block:i*block); %current column of nuclear marker image
            %figure; imagesc(I_nuc(:,1+(i-1)*block:i*block)) %debug


            % Otsu's threshold nuclear marker image to obtain binary column mask
            %[level EM] = graythresh(Icf);
            level = 0.06;
            BW = im2bw(Icf,level);
            BW2 = imfill(BW,'holes');
            %BW3 = imdilate(BW2, strel('disk',1)); %dilate mask with disk
            %figure; imshow(BW3) %debug


            mask_prop = regionprops(BW2,Icf,'Area','Centroid'); %areas and centroids of the cell masks for the current column

            % Get centroids of all cells and their x,y coordinates
            all_centroids = [mask_prop(:).Centroid];
            x_centroids = all_centroids(1:2:end-1);
            y_centroids = all_centroids(2:2:end);

            % Structure for holding the cell fluorescence and other property data for all cells
            % mask_prop_2 has dimensions of 3 rows (cell properties) x n cols (# of cells in the trap)
            mask_prop_2 = [mask_prop(:).Area; x_centroids; y_centroids];
            %fprintf('Column #%d has %d cells.\n', i, length(mask_prop_2(:))/4); %debug

            % The centroid with the highest y-coordinate value is the cell that is lowest in the trap, aka the mother cell; its index, idx, specifies the column in mask_prop_2 that stores its properties
            [~,idx] = max(y_centroids);

            % Properties of the mother cell, from the column #idx
            mother_prop = mask_prop_2(:,idx); %mother_prop(1) is the area of the mother cell
            areas = mask_prop_2(1,:);

            % If there are no cells detected via nuclear mask in this column, reduce threshold up to 3 times to try to detect them
            num_tries = 0;
            while isempty(mother_prop) && num_tries < 3
                num_tries = num_tries + 1;
                level = level-0.005;
                BW = im2bw(Icf,level); %repeat Otsu's method with new paramaters
                BW2 = imfill(BW,'holes');
                %BW3 = imdilate(BW2, strel('disk',1));
                mask_prop = regionprops(BW2,Icf,'Area','Centroid');

                all_centroids = [mask_prop(:).Centroid];
                x_centroids = all_centroids(1:2:end-1);
                y_centroids = all_centroids(2:2:end);
                mask_prop_2 = [mask_prop(:).Area; x_centroids; y_centroids];
                [~,idx] = max(y_centroids);
                mother_prop = mask_prop_2(:,idx);
                areas = mask_prop_2(1,:);
            end

            %num_tries = 0;
            % Check the following conditions to determine whether or not to further reduce the thresold level, thereby increasing the mask radius
            while ~isempty(mother_prop) && (mother_prop(1) < 45 || min(areas) < 20) && max(areas) < 75 && num_tries < 7
                % Check that there is a mother cell identified
                % Check if the mother cell is too small, OR if any other cell is also too small (this or statement deals with the scenario wherein the lowermost cell of the initial threshold may be sufficiently large to skip the while loop, but it is not the actual mother cell, which may not be detected that that thrsh level)
                % Stop if the largest cell exceeds too large a size, as this could imply oversaturation during threshold
                % Limit the number of retries to < 3
                level = level-0.005; %reduce level for Otsu's method
                num_tries = num_tries + 1;
                BW = im2bw(Icf,level); %repeat Otsu's method with new paramaters
                BW2 = imfill(BW,'holes');
                %BW3 = imdilate(BW2, strel('disk',1));
                mask_prop = regionprops(BW2,Icf,'Area','Centroid');

                all_centroids = [mask_prop(:).Centroid];
                x_centroids = all_centroids(1:2:end-1);
                y_centroids = all_centroids(2:2:end);
                mask_prop_2 = [mask_prop(:).Area; x_centroids; y_centroids];
                [~,idx] = max(y_centroids);
                mother_prop = mask_prop_2(:,idx);
                areas = mask_prop_2(1,:);

                %[mother_prop(1),min(areas),max(areas),num_tries] %debug
            end


            % Get the mask of the mother cell only for this column
            % bwlabel does column-wise search by default; so to do row-wise searching for the lowest object, we transpose the BW3 binary image input and then transpose back the output of bwlabel
            BW4 = BW2.';
            BW4 = bwareaopen(BW4,10); % Remove tiny objects/artifacts, BUT be careful not to accidentally remove mother masks that are very small!

            [L,num] = bwlabel(BW4,4); %

            if num == 0 %if there are no cells in the column, use a pure black, empty column (all zeros)
                temp_mother = zeros(nImage,block);
            else
                temp_mother0 = (L==num); %image is only the mask of the mother cell
                temp_mother = imdilate(temp_mother0, strel('disk',1));
                temp_mother = temp_mother.'; %transpose to orient axes correctly
                
            end

            % % Declump non-circular mother cell masks, based on circularity
            % p_a = regionprops(temp_mother,'Area','Perimeter');
            % if ~isempty(p_a)
            %     A = p_a(1).Area;
            %     P = p_a(1).Perimeter;
            %     pa_rat = (P^2)/(4*A*pi); %circularity; perfectly circular = 1

            %     % Binary watershed
            %     if (pa_rat < 0.6 | pa_rat > 2)
            %         D = bwdist(~temp_mother); % calculate distance matrix
            %         D = -D;
            %         %figure, imshow(D,[])
            %         D(~temp_mother) = -Inf;

            %         L = watershed(D);
            %         L2 = zeros(size(temp_mother));
            %         dim = size(L);
            %         for r = 1:dim(1)
            %             for s = 1:dim(2)
            %                 if (L(r,s) == 1 | L(r,s) == 0)
            %                     L2(r,s) = 0;
            %                 else
            %                     L2(r,s) = 1;
            %                 end
            %             end
            %         end
            %         temp_mother = L2;

            %         % Once again, relabel to find the mother cell among the declumped cells
            %         temp_mother = temp_mother';
            %         [L,num] = bwlabel(temp_mother); %
            %         temp_mother = (L==num);
            %         temp_mother = temp_mother.';
            %     end
            % end

            % Increase the size of the mother if it is too small
            mother_area = regionprops(temp_mother,'Area');
            if ~isempty(mother_area)
                mother_area_2 = [mother_area(1).Area];
                while mother_area_2 < 50
                    temp_mother = imdilate(temp_mother, strel('disk',1));
                    mother_area = regionprops(temp_mother,'Area');
                    mother_area_2 = [mother_area(1).Area];
                end
            end

            % Find centroid of current col mother cell, update mother_x, mother_y, and mother_BW arrays IF the current mother cell meets the following criteria:
            mother_prop = regionprops(temp_mother,'centroid'); % find centroid of the current column mother cell
            if ~isempty(mother_prop) %if there is a mother cell in this particular column
%                 mother_prop2 = [mother_prop(1).Centroid(1),mother_prop(1).Centroid(2)];
                % figure; imshow(temp_mother); hold on;
                % for x = 1: numel(mother_prop)
                %     plot(mother_prop(x).Centroid(1),mother_prop(x).Centroid(2),'ro');
                % end
                curr_mother_x = mother_prop(1).Centroid(1); %current mother mask's centroids
                curr_mother_y = mother_prop(1).Centroid(2);

               % (1) the previous y-centroid is 0, meaning there is no mother cell yet detected; and (2) the current y-centroid moves up within an acceptable range up and down from the previous y-centroid; and (3) the current x-centroid moves left/right within range
                y_up_allow = 10; %allowable vertical distance upwards from previous y-centroid
                y_down_allow = 50;
                x_allow = 10; %allow centroids to move horizontally up to 12px
                if (mother_y(i) == 0 || curr_mother_y < mother_y(i) + y_down_allow && curr_mother_y + y_up_allow >= mother_y(i) && abs(curr_mother_x-mother_x(i)) <= x_allow )
                    mother_x(i) = curr_mother_x; %update centroids
                    mother_y(i) = curr_mother_y;
                    mother_area_rec(i) = mother_area_2;
                    mother_BW{i} = mother_BW{i} + double(temp_mother); %update mother_BW for current col
                % if the current mother cell doesn't meet these criteria or there is no mother cell in the column, do not update the arrays and load the previous frame's mother_BW as the current temp_mother column mother mask
                else
                    use_sum_tag=1;               
                end
                
                if (mother_area_2/mother_area_rec(i) > 1.5 ) &&(mother_area_rec(i)~=0)
                    use_sum_tag=1;
                end
                    
            else %if there are no mother cells/centroids, use previous mother mask
                use_sum_tag=1;
            end
            
            if use_sum_tag==1

                sum_max = max(max(mother_BW{i})); 
                if sum_max>0
                    sum_thrsh = graythresh(mother_BW{i});
%                     figure; imagesc(mother_BW{i})
                    [temp_mask0,num2] = bwlabel((mother_BW{i}> sum_max*sum_thrsh*1.25));

                    if num2>1
                        temp_mask = (temp_mask0==num2);
                    else
                        temp_mask = temp_mask0;
                    end
                    
                    temp_mother = imdilate(temp_mask,strel('disk',1)); %restore previous frame's mother cell col mask without updating the centroids
                    mother_BW{i} = mother_BW{i} + double(temp_mask);

                    temp_props = regionprops(temp_mask, 'Centroid','Area');
                                                      
                        
                    mother_y(i) = temp_props.Centroid(2);
                    mother_area_rec(i)=temp_props.Area;
                end
            end

            % % Add current column mask to the overall mask image for output
            % I_nuc_mask = horzcat(I_nuc_mask,BW3);
            % Add current mother cell mask to the overall mother mask image
            I_mother_mask(:,1+(i-1)*block:i*block) = temp_mother;


            % For each of the fluorescent channels...
            for y = 2:channel
                curr_I_flu = curr_frame(:,:,y); % current fluorescent image
                I_flu_col = curr_I_flu(:,1+(i-1)*block:i*block); % current column in flu image

                % Determine the properties of the segmented cells using regionprops(BW_image,Intensity_Image,Properties)
                % Since we already have a column mask of just the single mother cell, we can simply track its PixelValues and there is no need to recalculate centroids
                temp_mother2 = imdilate(temp_mother, strel('disk',2));
                col_prop = regionprops(temp_mother2,I_flu_col,'PixelValues');

                % Structure for holding the cell fluorescence and other property data for all cells
                col_prop_2 = [col_prop(:).PixelValues];%the values of all the pixels in the mother cell mask

                % Top 40 fluorescence method #1: Take the top half of the values in the array
%                 col_prop_3 = sort(col_prop_2); %sort PixelValues in ascending order
%                 num_px = numel(col_prop_3); %number of pixels (area) of mother cell
%                 top_40 = floor(0.6*num_px+1):num_px; % top 50% range%%change to top 40% for NAM device
%                 col_prop_4 = mean(col_prop_3(top_40)); %
% 
%                 % % Top 50 fluorescence method #2: Find midpoint of min/max, and take the values above this threshold
%                 % mi_px = min(col_prop_2); ma_px = max(col_prop_2);
%                 % avg_px = (ma_px - mi_px)*0.5 + mi_px;
%                 % col_prop_3 = col_prop_2(col_prop_2 > avg_px);
%                 % col_prop_4 = mean(col_prop_3);
% 
%                 % Store mother cell fluorescence in trajectories matrix
%                 traj(imid,i,y-1) = col_prop_4;
                traj_all{imid,i,y-1} = col_prop_2;
            end
        end

        %  Output overlay image of phase and nuclear
        %has been done in frame alignment
% %         I_overlay_1 = imfuse(I_ph,I_nuc_FS,'falsecolor','ColorChannels','red-cyan');
% %         imwrite(I_overlay_1, out_name_nuc)

        % Output mother mask+phase overlay
        I_overlay_2 = imfuse(I_ph,I_mother_mask,'falsecolor','ColorChannels','red-cyan');
        %figure; imshow(I_overlay_2);
        %to make sure the mask stack is start from 1
        if imid == 1
            imwrite(I_overlay_2, PM_overlay_name,'writemode', 'overwrite');
        else
            imwrite(I_overlay_2, PM_overlay_name,'writemode', 'append');
        end

    end
    
    fileID = fopen('analyzed_position_N.txt','a');
    fprintf(fileID,'Finished position xy%s\n',pos);
    fclose(fileID);
    % Write trajectory data to output_data
    save(output_data,'traj_all');
end
