function [ classlist, list_titles, newclasslist_flag] = get_classlistTB( manualfilename, classfilename, pick_mode, class2use, classnum_default, total_roi );
%function [ classlist, list_titles] = get_classlist( manualfilename, classfilename, pick_mode, class2use, classnum_default, total_roi );
%For Imaging FlowCytobot roi picking; Use with manual_classify scripts;
%Loads existing or sets up new matrix for identification results;
%Heidi M. Sosik, Woods Hole Oceanographic Institution, 31 May 2009
%6 January 2010, modified to omit save line (no longer creates result file even if no roi categories are changed)
%11 November 2011, modified to fix bug with class2use_sub being replaced by value loaded from manual result file 
%containing (problem in cases with more than one subdivide); add class2use_sub_in to keep input value
%12 November 2011; further edit to "overlap" case to prevent manual assignment to another category 
%from being over-ruled by the subdivide category
%April 2015, revised to remove subdivide functionality

%INPUTS:
%manualfilename - mat filename (with path) for manual results
%classfilename - mat filename (with path) for SVM automated classifer results
%pick_mode - string label specifying type of identification:
%   'raw_roi' = pick classes from scartch
%   'correct_or_subdivide' = manual correction of classes and/or subdivision of a class
%class2use - cell array of main classes
%class2use_sub - cell array of classes for sub-categories
%classstr - category label for starting class for case of "subdivide"
%classnum_default - class number from class2usefor ROI default in case no class from auto classifier
%classnum_default_sub - class number from class2use_pick2 (sub) for ROI default
%total_roi - number of ROIs in file
%
%OUTPUTS:
%classlist - matrix of class identity results
%sub_col - column number for results in classlist matrix for "subdivide" case
%list_titles - cell array of text explaining columns of classlist
    %fix columns for classlist
manual_col = 2;
auto_col = 3;
class2use_in = class2use;
newclasslist_flag = 0; %default to false
if exist([manualfilename], 'file')  %~isempty(tempdir)
    load([manualfilename])
    if length(class2use_in) < length(class2use_manual),
        disp('Existing class2use_manual does not match class2use for ROI picking. You must remap the classes in result file first or change your picking categories.') 
        classlist = [];
        return
    elseif ~isequal(class2use_manual, class2use_in(1:length(class2use_manual)))
        disp('Existing class2use_manual does not match class2use for ROI picking. You must remap the classes in result file first or change your picking categories.') 
        classlist = [];
        return
    end;
    clear class2use_in
else 
    clear class2use_in
    list_titles = {'roi number' 'manual' 'auto'};
    newclasslist_flag = 1; %set to true
    switch pick_mode
        case 'raw_roi' %pick classes from scratch
            classlist = NaN(total_roi,auto_col); %start with auto_col width, grow to sub_col later if needed
            classlist(:,1) = 1:total_roi;
            classlist(:,manual_col) = classnum_default; %strmatch(classstr, class2use, 'exact');
            if ~isempty(classnum_default_sub),               
               classnum = strmatch(classstr, class2use, 'exact'); %default class number from original list
               sub_col = 4; %first one
               classlist(:,sub_col) = NaN;
               list_titles(sub_col) = {classstr};            
            end;    
        case 'correct_classifier'  %make subcategories starting with an automated class
            if exist(classfilename),
                load(classfilename) %load classifier results
                if ~exist('classlist', 'var'), 
                    classlist = NaN(total_roi,auto_col); %start with auto_col width, grow to sub_col later if needed
                    classlist(:,1) = 1:total_roi;
                    %make a temporary class2use that maps back to old names in MVCO classes
                    class2use_temp = class2use; 
                    if ~isempty([strfind(classfilename,'mvco') strfind(classfilename,'MVCO')])
                        class2use_temp{strmatch('Ciliate_mix', class2use)} = 'ciliate_mix';
                        class2use_temp{strmatch('Tintinnid', class2use)} = 'tintinnid';
                        class2use_temp{strmatch('Laboea_strobila', class2use)} = 'Laboea_strobila';
                        class2use_temp{strmatch('Mesodinium_sp', class2use)} = 'Myrionecta';
                        class2use_temp{strmatch('Guinardia_delicatula', class2use, 'exact')} = 'Guinardia';
                    end;
         %           classlist(:,auto_col)  = PreLabels(:,1);
                     %new case for TBclassification July 2012, Heidi
                     [~,ia] = ismember(TBclass_above_threshold, class2use_temp);
                     if ~isempty([strfind(classfilename,'vpr') strfind(classfilename,'VPR')])
                        classlist(:,auto_col)  = ia; 
                     else
                        classlist(roinum,auto_col)  = ia;
                     end;
                     classlist(classlist(:,auto_col) == 0,auto_col) = classnum_default;
                end;
            else
                classlist = NaN(total_roi,auto_col); %start with auto_col width, grow to sub_col later if needed
                classlist(:,1) = 1:total_roi;
            end;
            if ~isempty(classnum_default_sub) && exist('class2useTB', 'var'),
                %fudge for remap of MVCO ciliate labels
                class2useTBnew = class2useTB;
              %  class2useTBnew{strmatch('ciliate_mix', class2useTB)} = 'Ciliate_mix';
              %  class2useTBnew{strmatch('tintinnid', class2useTB)} = 'Tintinnid';
              %  class2useTBnew{strmatch('Laboea', class2useTB)} = 'Laboea_strobila';
              %  class2useTBnew{strmatch('Myrionecta', class2useTB)} = 'Mesodinium_sp';
                classnum = strmatch(classstr, class2use, 'exact'); %default class number from original list
                sub_col = 4; %first one
                classlist(:,sub_col) = NaN;
                list_titles(sub_col) = {classstr};        
                classlist(classlist(:,auto_col) == classnum, sub_col) = classnum_default_sub; %set to default new class
                [overlap, ind_sub, ind] = intersect(class2use_sub, class2useTBnew);
                for count1 = 1:length(overlap),
                    iii = strmatch(class2useTB(ind(count1)), TBclass_above_threshold);
                    if ~isempty(iii),
                        classlist(roinum(iii),sub_col) = ind_sub(count1);
                    end;
                    %classlist(classlist(:,auto_col) == ind(count1), sub_col) = ind_sub(count1); %set to new class number in subcol
                    %classlist(classlist(:,auto_col) == ind(count1), auto_col) = classnum; %set to parent class number in autocol
                end;
             end;                        
    end;
%    save(manualfilename, 'list_titles', 'class2use*', 'classlist'); %make sure initial file has proper list_titles    
end;
