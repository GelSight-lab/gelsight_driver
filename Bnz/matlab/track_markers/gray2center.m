function center=gray2center(grayim, thresh)
% y,x

grayim(grayim<thresh)=0;
L = bwlabel(grayim,4);
s = regionprops(L,grayim, 'WeightedCentroid','Area');

areathresh=100;
ind=find([s(:).Area]>areathresh);
center_=[s(ind).WeightedCentroid];
n=length(ind);
center(:,1)=center_(2:2:end);
center(:,2)=center_(1:2:end);
center(:,3)=[s(ind).Area];