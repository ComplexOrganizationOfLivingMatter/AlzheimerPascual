function [finalRedZone,redZoneAreaInMicrons,outsideRedZoneAreaInMicrons,plaqueDetection,peripheryOfAnomaly] = segmentDamageRedZone(grayImages,minRedAreaPixels,pixelWidthInMicrons,radiusInPixelsPeripheryAnomaly, outputDir)

    %% Damage zone (Channel 3)
    medianFilteredImage = medfilt2(adapthisteq(grayImages(:,:,3)), [20 20]);
    redZone = imbinarize(medianFilteredImage);
    redZoneFilled = imfill(redZone, 'holes');
    areaRedZone=regionprops(redZoneFilled,'Area');
    redZoneFilledLabelled= bwlabel(redZoneFilled);
    finalRedZone=ismember(redZoneFilledLabelled,find(cat(1,areaRedZone.Area)>minRedAreaPixels));
    finalRedZoneLabel=bwlabel(finalRedZone);
    
    for nRegion = 1 : max(max(finalRedZoneLabel))
        [X,Y]=find(finalRedZoneLabel==nRegion);
        [Xzeros,Yzeros]=find(finalRedZoneLabel==0);
        k = boundary(X,Y,0.2);
        [in,on] = inpolygon(Xzeros,Yzeros,X(k),Y(k));
        subCoord=sub2ind(size(finalRedZone),[Xzeros(in);Xzeros(on)],[Yzeros(in);Yzeros(on)]);
        finalRedZone(subCoord)=1;
    end

    %We catch a half of the red zone and half from outside perimeter it.
%     perimeterRedZone = bwperim(finalRedZone);
%     borderRedZone = imdilate(perimeterRedZone, strel('disk', round(pixelsOfSurroundingZone)));
%     finalRedZone = finalRedZone | borderRedZone;

    redZoneAreaInMicrons = sum(finalRedZone(:)) * pixelWidthInMicrons^2;
    outsideRedZoneAreaInMicrons = sum(finalRedZone(:) == 0) * pixelWidthInMicrons^2;
    
    %% Segmentation of plaques
    [plaqueDetection] = plaquesSegmentation(grayImages,finalRedZone);
%     figure;imshow(plaqueDetection)
%     close
    finalRedZone(plaqueDetection) = 0;
    imwrite(finalRedZone, strcat(outputDir, '/redZoneSegmented.tif'));
    
    peripheryOfAnomaly=imdilate(finalRedZone,strel('disk',round(radiusInPixelsPeripheryAnomaly)));
    peripheryOfAnomaly=peripheryOfAnomaly-finalRedZone-plaqueDetection;
    imwrite(peripheryOfAnomaly, strcat(outputDir, '/peripheryOfAnomaly.tif'));
end

