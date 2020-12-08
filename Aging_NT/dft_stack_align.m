%Code for align images
%code read image stacks and do alignment use dft method, then store the
%aligned images into image stacks
%Input position number, image number, channel number and nuclear channel
%Yang Li 08/23/2017



function dft_stack_align(pos,imN,channel,N_C)
    mkdir(['Aligned/xy',pos]);
    %define the size of images;should be 256 by 512
    mImage = 512;
    nImage = 256;
    
    %Define the name of current stack, then acquire the stack info
    curr_stack_names = cell(1,channel);
    curr_stack_info = cell(1,channel);
    new_stack_names = cell(1,channel);
    
%%%%%%%%%%%%Variables that needs for saveastiff methods%%%%%%%%%%%%%%%%%
% % % %     options.append = true;
% % % %     options.message   = false;

    %Create names and image infos for loading and saving
    for cc = 1:channel
        curr_stack_names{cc} = ['data/xy',pos,'c',num2str(cc),'.tif'];
        curr_stack_info{cc} = imfinfo(curr_stack_names{cc});
        new_stack_names{cc} = ['Aligned/xy',pos,'/xy',pos,'c',num2str(cc),'A.tif'];
    end
    
    PN_overlay_name = ['Aligned/xy',pos,'/xy',pos,'_PN_overlay.tif'];

    %start registration 
    for imid = 1:imN
        
        fprintf('Aligning xy%s, frame %d.\n', pos, imid); %debug

        curr_frame = zeros(nImage,mImage,channel,'uint16');
        for cfcc = 1:channel
            curr_frame(:,:,cfcc) = imread(curr_stack_names{cfcc},'Index',imid,'Info',curr_stack_info{cfcc});
        end
        
        if imid == 1
            Iph_ref = curr_frame(:,:,1);
        end
        
        Iph = curr_frame(:,:,1);
        
        part_Iph = Iph(:,1:90);%newly_added 06/08/2018
        part_Iph_ref = Iph_ref(:,1:90);%newly_added 06/08/2018
        shifts = dftregistration(fft2(part_Iph),fft2(part_Iph_ref),100);%revised 06/08/2018
        
%         Iph_ref = Iph;%newly_added 06/12/2018
        
       %shifts = dftregistration(fft2(Iph),fft2(Iph_ref),100);
        
        if imid == 1
            new_curr_frame = curr_frame;
        else
            d_col = round(shifts(4));
            d_row = round(shifts(3));
            new_curr_frame = zeros(nImage,mImage,channel,'uint16');
            
            if d_col >0
                new_col= 1:mImage - d_col;
                curr_col= d_col+1:mImage;
            else
                new_col= -d_col+1:mImage;
                curr_col= 1:mImage + d_col;    
            end

            if d_row >0
                 new_row= 1:nImage - d_row;
                 curr_row = d_row+1:nImage;
            else
                new_row = -d_row+1:nImage; 
                curr_row =1:nImage + d_row;
            end
            
            for z = 1:channel
                new_curr_frame(new_row,new_col,z) = curr_frame(curr_row,curr_col,z);
            end
        end
        
        %Write the registrated images into stacks
        Phase_nuclear_overlay = imfuse(new_curr_frame(:,:,1),new_curr_frame(:,:,N_C),'falsecolor','ColorChannels','red-cyan');

        if imid == 1
            for z = 1:channel
                imwrite(new_curr_frame(:,:,z), new_stack_names{z}, 'writemode', 'overwrite');
            end

            imwrite(Phase_nuclear_overlay, PN_overlay_name, 'writemode', 'overwrite');
        else
            for z = 1:channel
                imwrite(new_curr_frame(:,:,z), new_stack_names{z}, 'writemode', 'append');
            end
        
            imwrite(Phase_nuclear_overlay, PN_overlay_name, 'writemode', 'append');
        end
        
%%%%%%%%%An alternative way to write images (seems slower than imwrite)
% % % % %         for z = 1:channel
% % % % %             saveastiff(new_curr_frame(:,:,z), new_stack_names{z}, options);
% % % % %         end
% % % % %         
% % % % %         imwrite(Phase_nuclear_overlay, PN_overlay_name, 'writemode', 'append');
            
            
    end
        
   






