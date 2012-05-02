%manual_classify_2_0.m
%Main script for manual IFCB roi classification
%User selects paths for data and results and sets "pick_mode" for type of
%classification (e.g., starting from scratch with a new list of categories,
%or correcting an automated classifier, etc.)
%
%Requires several scripts / functions:
%   makescreen.m
%   select_category.m
%   get_classlist.m
%   get_roi_indices.m
%   fillscreen.m
%   selectrois.m
%   stitchrois.m    
%
%Heidi M. Sosik, Woods Hole Oceanographic Institution, 8 June 2009
%
%(Version 2.0 heavily modified from manual_classify_stream2b)
%
%Version 2_2 - Heidi 9/29/09. Fixed bug with mark_col when using both class2view1 and
%class2view2 (now shows marks on back one screen within class); also includes previous bug fix for raw_roi mode to avoid
%stopping on no existing class file or result file. 
%Version 3 - Heidi 11/5/09. Modified to display overlapping rois as one
%stiched image. Added call to stitchrois.m
%Version 3_1 - Heidi 1/6/10. Modified to handle cases with no stitched rois. 
%Also modified to skip saving a result file if no roi categories are changed (includes modifications to get_classlist and selectrois to omit save steps). 
%1/12/10 modified fillscreen to skip zero-sized rois
%1/13/10 modified in if change_flag loop so that subdivide ID overrides a previous main manual column ID
%Version 3_2 - Heidi 11/10/11. Modified to address bug with missing class2use_sub? for cases
%with multiple subdivides; added back -append option on save (previously removed in 1/6/10 version)
%includes modifications to get_classlist.m

close all; clear all;

screens = 1; %% MB edit - adjust figure size according to number of computer monitors

filenum2start = 1;  %USER select file number to begin (within the chose day), MB edit: if set to 0 review last 3 files
% pick_mode = 'correct_or_subdivide'; %USER choose one from case list below
pick_mode = 'raw_roi';
big_only = 0; %case for picking Laboea and tintinnids only
xbig = 150; ybig = 75;
redwater = 0; %case for default pmt A/B > 1 to Alexandrium singlet or doublet cells

resultpath = '\\queenrose\g_work_ifcb1\Demo_28Apr2012\ManualClassify\'; %USER set
% resultpath = '/mellon/projects/2012/ifcb_saltpond/manualclassify/'; %USER set
classpath = '/mellon/projects/2012/ifcb_saltpond/data/manualclassify/'; %USER set
basedir = '\\queenrose\g_work_ifcb1\Demo_28Apr2012\D2012\';
stitchpath = '/mellon/data/ifcb/saltpond/stitches';  %%USER set, roi stitch info files
class_filestr = '_class_revMar2012'; %USER set, string appended on roi name for class files

%filespec = 'D20120417*'; %USER set; include at least year and day; time optional
filespec = 'D20120428*'; %USER set; include at least year and day; time optional
year = filespec(2:5);

streampath = [basedir filespec(1:9) '\']; % needed for batch case
% classpath(end-21:end-18) = year;  %set the correct year, needed for batch case
% stitchpath(end-4:end-1) = year;
filelist = dir([streampath '*.roi']);

if (filenum2start == 0), filenum2start = length(filelist) - 3; end
    
if ~exist(resultpath, 'dir'),
    dos(['mkdir ' resultpath]);
end;
if isempty(filelist),
    disp('No files found. Check streampath or file specification in m-file.')
    return
end;

switch pick_mode
    case 'raw_roi' %pick classes from scratch
%         class2use = {'Alexandrium tamarense'; 'Alexandrium doublet'; 'Alexandrium infected'; 'Alexandrium planozygote'; ...
%             'Amylax triacantha'; 'Ceratium'; 'Chaetoceros'; 'Dinophysis accuminata'; 'Geminogera'; 'Gonyaulax'; ...
%             'Guinardia delicatula'; 'Guinardia flaccida'; 'Guinardia striata'; 'Laboea'; 'Myrionecta rubra'; 'Pleurosigma'; ...
%             'Prorocentrum gracile'; 'Protoperidinium'; 'Pseudo-nitzchia'; 'Rhizosolenia'; 'Skeletonema'; 'Thalassionema'; ...
%             'Thalassiosira'; 'Tintinnid'; 'beads'; 'detritus'; 'other'; 'pennate'; 'sm dinoflagellate'; 'Eucampia'; ...
%             'Asterionellopsis'; 'Strombidium'; 'centric'; 'centric chain'; 'Ditylum'; 'Cochlodinium'; 'lg dinoflagellate'; ...
%             'lorica'; 'flagellate'; 'sm round cell'; 'Leptocylindrus'; 'Odontella'; 'Melosira'; 'Alexandrium quadruplet'; ...
%             'Alexandrium fusion'; 'Alexandrium triplet'; 'Dinobryon'}; %USER type or load list
         load class2use_MVCOmanual3 %load class2use
         class2use = [class2use 'Alexandrium' 'other_small', 'other_large', 'Guinardia_delicatula'];
         class2use = setdiff(class2use, {'crypto', 'dino10', 'mix_elongated', 'bad', 'kiteflagellate', 'flagellate', 'DactFragCerataul', 'roundCell',...
            'mix', 'other', 'Guinardia', 'Thalassiosira_dirty', 'Eucampia_groenlandica', 'Tropidoneis', 'kiteflagellates'});
         class2use = sort(class2use);
%% If adding categories to class2use, add them to the end:
%% eg class2use = [class2use 'newclass1' 'newclass2'];
        classnum_default = strmatch('other_large', class2use); %USER class for default
        classstr = [];
        class2use_pick1 = class2use; %to set button labels
        class2use_manual = class2use;
        class2use_sub = []; %not needed for this case
        class2use_auto = [];
        class2use_pick2 = [];
        class2view1 = 1:length(class2use);
        class2view2 = [];
        class2view2 = 1:length(class2use_sub);
    case 'correct_or_subdivide'  %make subcategories starting with an automated class
        %load first file to get class2use, presumes all files have same
        classfile = [classpath filelist(filenum2start).name(1:end-4) class_filestr '.mat'];
        if exist(classfile),
            load([classpath filelist(filenum2start).name(1:end-4) class_filestr]);
            class2use_auto = class2use;
        else
            class2use_auto = [];
        end;
        class2use = class2use_auto; 
        %if adding new categories
        %class2use = {'class1'; 'class2'; 'other'}; %USER type or load list
        load class2use_MVCOmanual3 %load class2use
        [junk, fulldiff] = setdiff(class2use, class2use_auto);
        class2use = [class2use_auto class2use(sort(fulldiff))];  %append new classes on end of auto classes
        class2use_pick1 = class2use;
        class2use_manual = class2use;
        classstr = 'ciliate'; %USER class to start from
        %class2use_sub = [];  %use this if no subdividing 
        %new subclasses, first one for rois NOT in the class
        class2use_sub = {'not_ciliate' 'ciliate_mix' 'tintinnid' 'Myrionecta' 'Laboea'}; %USER type or load list
        classnum_default = strmatch('ciliate_mix', class2use_sub); %USER class for default
        class2use_pick2 = class2use_sub; %to set button labels
        class2view1 = 1:length(class2use); %use this to view all classes
        %[junk, class2view1] = setdiff(class2use_pick1, {'bad', 'mix'});  %use this to exclude some classes
        class2view1 = sort(class2view1);
        class2view1 = [];  %use this to skip all original auto categories-Emily Brownlee can use this to look at just ciliates. Recomment with % to see everything.
        class2view2 = 1:length(class2use_sub);
    otherwise
        disp('Invalid pick_mode. Check setting in m-file.')
        return
end;

%IFCB largest possible image settings
camx = 1381;  %changed from 1380, heidi 8/18/06
camy = 1035;  %camera image size, changed from 1034 heidi 6/8/09
border = 3; %to separate images

%make the collage window
[figure_handle, button_handles1, button_handles2, instructions_handle] = makescreen(class2use_pick1, class2use_pick2);

for filecount = filenum2start:length(filelist),
    streamfile = filelist(filecount).name(1:end-4);
    disp(['File number: ' num2str(filecount)])
    if ~strcmp(pick_mode, 'raw_roi') & ~exist([resultpath streamfile '.mat']) & ~exist([classpath filelist(filecount).name(1:end-4) class_filestr '.mat']),
    %if ~exist([resultpath streamfile '.mat']) & ~exist([classpath filelist(filecount).name(1:end-4) class_filestr '.mat']),
        disp('No class file and no existing result file. You must choose pick_mode "raw_roi" or locate a valid class file.')
        return
    end;
    adcdata = load([streampath streamfile '.adc']);
%     x_all = adcdata(:,12);  y_all = adcdata(:,13); startbyte_all = adcdata(:,14);
    x_all = adcdata(:,16);  y_all = adcdata(:,17); startbyte_all = adcdata(:,18);
    hdr = IFCBxxx_readhdr([streampath streamfile '.hdr']); 
    runtime = adcdata(end,13)-adcdata(1,13); %triggers 2-last
    temp = runtime./(adcdata(end,1)-1);
    runtime = runtime+temp; %add average for 1 extra trigger (first)
    missed_ratio = hdr.inhibittime./hdr.runtime;
    looktime = runtime-runtime*missed_ratio;
    flowrate = 0.25; %milliliters per minute for syringe pump
    ml_analyzed = flowrate*looktime/60;
    disp(['ml analyzed: ' num2str(ml_analyzed,3)])
    stitch_info = [];
    if exist([stitchpath streamfile '_roistitch.mat']), 
        load([stitchpath streamfile '_roistitch.mat']);
    end;
    
    fid=fopen([streampath streamfile '.roi']);
    disp([streampath streamfile]), disp([num2str(size(adcdata,1)) ' total ROI events'])
    
    %% Added by MB: change default in redwater case:
    if ~exist([resultpath streamfile '.mat']),
        firstmanfile=1;
    else
        firstmanfile=0;
    end
        
    [ classlist, sub_col, list_titles ] = get_classlist( [resultpath streamfile '.mat'],[classpath streamfile class_filestr '.mat'], pick_mode, class2use_manual, class2use_sub, classstr, classnum_default, length(x_all) );
    if isempty(classlist), %indicates bad class2use match
        return
    end;
    %small_ind = find(x_all.*y_all < xbig*ybig);
    small_ind = find(x_all <= xbig & y_all <= ybig);
    classlist(small_ind,2) = strmatch('other_small', class2use, 'exact');
    
    if firstmanfile,
        if redwater,
            keyboard
%             AlexSind = intersect(intersect(intersect(find(adcdata(:,3) > 1),find(adcdata(:,4) > 1)),find((adcdata(:,16)./adcdata(:,17)) < 1.5)),find((adcdata(:,17).*adcdata(:,16)) > 15000));
            AlexSind = intersect(intersect(find(adcdata(:,3) > 1),find(adcdata(:,4) > 1)),find((adcdata(:,16)./adcdata(:,17)) < 1.5));
            classlist(AlexSind,2)=1;
%             AlexDind = intersect(intersect(intersect(find(adcdata(:,3) > 1),find(adcdata(:,4) > 1)),find((adcdata(:,16)./adcdata(:,17)) > 1.5)),find((adcdata(:,17).*adcdata(:,16)) > 30000));
            AlexDind = intersect(intersect(find(adcdata(:,3) > 1),find(adcdata(:,4) > 1)),find((adcdata(:,16)./adcdata(:,17)) > 1.5));
            classlist(AlexDind,2)=2;
        end
    end
    
    if ~isempty(stitch_info), 
        classlist(stitch_info(:,1)+1,2:3) = NaN; %force NaN class for second roi in pair to be stitched
    end;
    mark_col = 2; %added back 11 jan 2010
    if ~isempty(sub_col), 
         eval(['class2use_sub' num2str(sub_col) '= class2use_sub;'])
         mark_col = sub_col; %reset col for ID in classlist
    end;
    %save([resultpath streamfile], 'list_titles', 'class2use_auto', 'class2use_manual', 'class2use_sub*', 'classlist', '-append'); %make sure initial file has proper list_titles    
    for view_num = 1:2,
        if view_num == 1,
            class2view = class2view1;
            class2use_now = class2use;  
    %        mark_col = 2; %added 9/29/09 Heidi
        else
            class2view = class2view2;
            class2use_now = class2use_sub;
    %        mark_col = sub_col; %added 9/29/09 Heidi
        end;
        class_with_rois = [];
        classcount = 1;
        while classcount <= length(class2view),
            classnum = class2view(classcount);

            roi_ind = get_roi_indices(classlist, classnum, pick_mode, sub_col, view_num);            
            startbyte_temp = startbyte_all(classlist(roi_ind,1)); x = x_all(classlist(roi_ind,1)); y = y_all(classlist(roi_ind,1));
            startbyte = startbyte_all(roi_ind); x = x_all(roi_ind); y = y_all(roi_ind); %heidi 11/5/09
            if (startbyte_temp - startbyte), disp('CHECK for error!'), keyboard, end;
            %read roi images
            imagedat = {};
            for imgcount = 1:length(startbyte),
                fseek(fid, startbyte(imgcount), -1);
                data = fread(fid, x(imgcount).*y(imgcount), 'ubit8');
                imagedat{imgcount} = reshape(data, x(imgcount), y(imgcount));
            end;
            indA = [];
            if ~isempty(stitch_info), 
                [roinum , indA, indB] = intersect(roi_ind, stitch_info(:,1));
            end;
            for stitchcount = 1:length(indA), %loop over any rois that need to be stitched
                startbytet = startbyte_all(roinum(stitchcount)+1); xt = x_all(roinum(stitchcount)+1); yt = y_all(roinum(stitchcount)+1); %heidi 11/5/09
                fseek(fid, startbytet,-1); %go to the next aroi in the pair
                data = fread(fid, xt.*yt, 'ubit8');
                imgB = reshape(data,xt,yt);
                xpos = stitch_info(indB(stitchcount),[2,4])'; ypos = stitch_info(indB(stitchcount),[3,5])';
                [ imagedat{indA(stitchcount)}, xpos_merge, ypos_merge ] = stitchrois({imagedat{indA(stitchcount)} imgB},xpos,ypos);
                clear xt yt startbytet
                figure(1)
            end;
            
            next_ind = 1; %start with the first roi
            next_ind_list = next_ind; %keep track of screen start indices within a class
            if ~isempty(imagedat),
                class_with_rois = [class_with_rois classcount]; %keep track of which classes to jump back (i.e., which have ROIs)
                while next_ind <= length(x),
                    change_col = 2; if view_num > 1, change_col = sub_col;, end; %1/15/10 to replace mark_col in call to fillscreen
                    [next_ind_increment, imagemap] = fillscreen(imagedat(next_ind:end),roi_ind(next_ind:end), camx, camy, border, [class2use_now(classnum) filelist(filecount).name], classlist, change_col, classnum);
                    next_ind = next_ind + next_ind_increment - 1;
                    figure(figure_handle)
                    [ classlist, change_flag, go_back_flag ] = selectrois(instructions_handle, imagemap, classlist, class2use_pick1, class2use_pick2, mark_col);
                    %keyboard
                    if change_flag,
                        if ~isempty(sub_col),  %strncmp(pick_mode, 'subdiv',6)
                            %reassign manual column (#2) with relevant sub_col entries
                           % keyboard
                            %next line presumes that a manual column ID should NOT be overridden by a subsequent sub_col ID (e.g., put in main ciliate categoryfirst, then move to subdivided catetory
                            %classlist(~isnan(classlist(:,sub_col)) & ~isnan(classlist(:,2)) & classlist(:,2) ~= strmatch(classstr, class2use_manual), sub_col) = NaN;
                            %1/15/10, recast above so the subdivide ID overrides instead (i.e., just skip above line)
                            classlist(classlist(:,sub_col) >= 2,2) = strmatch(classstr, class2use_manual);  %reassign manual column (#2) with relevant sub_col entries
                            classlist(classlist(:,2) == strmatch(classstr, class2use_manual) & isnan(classlist(:,sub_col)), sub_col) = classnum_default;  % = 2; changed 1/15/10 ??correct??
                            eval(['class2use_sub' num2str(sub_col) '= class2use_sub;'])
                            mark_col = sub_col; %reset col for ID in classlist %comment out 9/29/09 Heidi
                        end;
                        %save([resultpath streamfile], 'classlist', 'class2use_auto', 'class2use_manual', 'class2use_sub*', 'list_titles', '-append'); %omit append option, 6 Jan 2010
                        save([resultpath streamfile], 'classlist', 'class2use_auto', 'class2use_manual', 'class2use_sub*', 'list_titles', 'ml_analyzed'); %omit append option, 6 Jan 2010
                    end;
                    clear change_flag
                    if go_back_flag,
                        if length(next_ind_list) == 1,%case for back one whole class
                            next_ind = length(x) + 1;
                            if length(class_with_rois) == 1,  %just go back to start of file
                                if class_with_rois == 1,
                                    set(instructions_handle, 'string', ['NOT POSSIBLE TO BACKUP PAST THE START OF A FILE! Restart on previous file if necessary.'], 'foregroundcolor', 'r')
                                end;
                                classcount = 0;
                                class_with_rois = [];
                            else %back up to next class with rois in it
                                classcount = class_with_rois(end-1) - 1;
                                class_with_rois(end-1:end) = [];
                            end;
                        else %go back one screen in same class
                            next_ind = next_ind_list(end-1);
                            next_ind_list(end-1:end) = [];
                        end;
                    end;
                    next_ind_list = [next_ind_list next_ind]; %keep track of screen starts within a class to go back
                end;  %
            end; %if ~isempty(imagedat),
            classcount = classcount + 1;
        end; %while classcount
    end; % for view_num
    fclose(fid);
end;