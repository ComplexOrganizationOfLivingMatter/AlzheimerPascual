function [propNoCaptMarkers,propROIsAnyNanMarker,propFilledArea,circlesCenters] = checkRadiusROIByMaxOfMarkersCaptured(imgROIraw,radiusROI,coord1,coord2)

    indCoord1 = sub2ind(size(imgROIraw),coord1(:,1),coord1(:,2));
    indCoord2 = sub2ind(size(imgROIraw),coord2(:,1),coord2(:,2));

    flag = 0;
    maskROIs = imerode(imgROIraw,strel('disk',radiusROI));
    
    numCoord1 = [];
    numCoord2 = [];
    centerX = [];
    centerY = [];
    counter = 1;
    
    [columnsInImage, rowsInImage] = meshgrid(1:size(imgROIraw,2), 1:size(imgROIraw,1));
    maskFullCircles = zeros(size(imgROIraw));
%     figure;imshow(imgROIraw)
    
    while flag == 0 && sum(maskROIs(:))>0
        
        ids = find(maskROIs);
        indRand = randperm(length(ids));
        
        % Next create the circle in the image.
        [centerY(counter),centerX(counter)] = ind2sub(size(imgROIraw),ids(indRand(1)));
        circlePixels = (rowsInImage - centerY(counter)).^2 ...
            + (columnsInImage - centerX(counter)).^2 <= radiusROI.^2;
%         figure;imshow(circlePixels)
        
        circlePixels2x = (rowsInImage - centerY(counter)).^2 ...
            + (columnsInImage - centerX(counter)).^2 <= (2*radiusROI).^2;
%         figure;imshow(circlePixels2x)
        
        numCoord1(counter) = sum(circlePixels(indCoord1));
        numCoord2(counter) = sum(circlePixels(indCoord2));

        maskROIs(circlePixels2x)=0;
%         imgROIrawPerim(circlePixels2x)=1;
        maskFullCircles(circlePixels) = 1;
%         imshow(maskFullCircles);
%         hold on
%         figure;imshow(maskROIs)
%         close all
        counter = counter + 1;
        if sum(maskROIs)==0
          flag = 1; 
        end
        
    end

    propFilledArea = sum(maskFullCircles(:))/sum(imgROIraw(:));
    propROIsAnyNanMarker = sum(sum([numCoord1',numCoord2']>0,2) < 2)/(counter-1);
    propNoCaptMarkers = sum(maskFullCircles([indCoord1;indCoord2])==0)/length([indCoord1;indCoord2]);
    circlesCenters = [centerY',centerX'];
end

