function [finalRedZone,redZoneAreaInMicrons,outsideRedZoneAreaInMicrons,plaqueDetection,peripheryOfAnomaly] = segmentDamageRedZone(grayImages,minRedAreaPixels,pixelWidthInMicrons,radiusInPixelsPeripheryAnomaly, outputDir)
%%SEGEMENTDAMAGEREDZONE
% Damage zone (Channel 3)

    %Pre-Processing: apply a median filter and enhancing contrast
    medianFilteredImage = medfilt2(adapthisteq(grayImages(:,:,3)), [20 20]);
    %Segment
    redZone = imbinarize(medianFilteredImage);
    %Post-processing
    redZoneFilled = imfill(redZone, 'holes');
    areaRedZone=regionprops(redZoneFilled,'Area');
    redZoneFilledLabelled= bwlabel(redZoneFilled);
    finalRedZone=ismember(redZoneFilledLabelled,find(cat(1,areaRedZone.Area)>minRedAreaPixels));
    finalRedZone=imdilate(finalRedZone,strel('disk',30));
    finalRedZone = imfill(finalRedZone, 'holes');
    finalRedZone=imerode(finalRedZone,strel('disk',30));

    finalRedZoneLabel=bwlabel(finalRedZone);
    
    
    
    %Get a red zone more or less convex (similar to convex hull), to avoid
    %strange holes
    for nRegion = 1 : max(max(finalRedZoneLabel))
        [X,Y]=find(finalRedZoneLabel==nRegion);
        [Xzeros,Yzeros]=find(finalRedZoneLabel==0);
        k = boundary(X,Y,0.2);
        [in,on] = inpolygon(Xzeros,Yzeros,X(k),Y(k));
        subCoord=sub2ind(size(finalRedZone),[Xzeros(in);Xzeros(on)],[Yzeros(in);Yzeros(on)]);
        finalRedZone(subCoord)=1;
    end

    %Area in microns
    redZoneAreaInMicrons = sum(finalRedZone(:)) * pixelWidthInMicrons^2;
    outsideRedZoneAreaInMicrons = sum(finalRedZone(:) == 0) * pixelWidthInMicrons^2;
    
    %% Segmentation of plaques
    [plaqueDetection] = plaquesSegmentation(grayImages,finalRedZone);
    finalRedZone(plaqueDetection) = 0;
    imwrite(finalRedZone, strcat(outputDir, '/redZoneSegmented.tif'));
    
    %% Periphery of the anomaly
    peripheryOfAnomaly=imdilate(finalRedZone,strel('disk',round(radiusInPixelsPeripheryAnomaly)));
    peripheryOfAnomaly=peripheryOfAnomaly-finalRedZone-plaqueDetection;
    imwrite(peripheryOfAnomaly, strcat(outputDir, '/peripheryOfAnomaly.tif'));
end

