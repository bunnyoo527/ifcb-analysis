function [ target ] = blob( target )
% find a "blob" in the image and produce its mask.
persistent se2 se3;

if isempty(se2)
    se2 = strel('disk',2);
end;

if isempty(se3)
    se3 = strel('disk',3);
end;

config = target.config;
img = target.img;
pc3 = config.pc3;
[M m , ~, ~, ~, ~, ~] = phasecong3(img, pc3.nscale, pc3.norient, pc3.minWaveLength, pc3.mult, pc3.sigmaOnf, pc3.k, pc3.cutOff, pc3.g, pc3.noiseMethod);
img_blob = hysthresh(M+m, config.hysthresh.high, config.hysthresh.low);
%img_edge = img_blob; %keep this to plot?
% omit spurious edges along margins
img_blob(1,img_blob(2,:)==0)=0;
img_blob(end,img_blob(end-1,:)==0)=0;
img_blob(img_blob(:,2)==0,1)=0;
img_blob(img_blob(:,end-1)==0,end)=0;
img_edge = img_blob; %keep this to plot?
% now use kmean clustering approach to make sure dark areas are included
img_dark = kmean_segment(img);
img_blob(img_dark==1)=1;
% now apply some structuring morphs to fill in various gaps
img_blob = imclose(img_blob, se3);
img_blob = imdilate(img_blob, se2);
img_blob = bwmorph(img_blob, 'thin', 3); %20 oct 2011, Heidi thinks 3 times here might be better than previous 1
img_blob = imfill(img_blob, 'holes');
%get rid of blobs < blob_min
blob_min = config.blob_min;
img_cc = bwconncomp(img_blob);
t = regionprops(img_cc, 'Area');
target = add_field(target, 'blob_props');
target.blob_props.Area = t;
disp([t.Area])
idx = find([t.Area] > blob_min);
img_blob = ismember(labelmatrix(img_cc), idx); %is this most efficient method?

if config.plot,
    img_proc_plot(img, M+m, img_edge, img_dark, img_blob)
    pause
end;

target.img_blob = img_blob;
target.img_edge = img_edge;

end