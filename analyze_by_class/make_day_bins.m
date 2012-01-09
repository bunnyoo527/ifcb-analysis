function [matdate_bin, classcount_bin, ml_analyzed_mat_bin] = make_day_bins(matdate,classcount, ml_analyzed_mat)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

matdate_day = floor(matdate);
matdate_bin = unique(floor(matdate_day));
classcount_bin = NaN(length(matdate_bin),size(classcount,2));
ml_analyzed_mat_bin = classcount_bin;
for count = 1:length(matdate_bin),
    idx = find(matdate_day == matdate_bin(count));
    if ~isempty(idx),
        classcount_bin(count,:) = nansum(classcount(idx,:),1);
        ml_analyzed_mat_bin(count,:) = nansum(ml_analyzed_mat(idx,:),1);
    end;
end;

end
