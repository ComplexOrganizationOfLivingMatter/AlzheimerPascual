function [finalRedZone,redZoneAreaInMicrons,outsideRedZoneAreaInMicrons,plaqueDetection,peripheryOfAnomaly] = segmentDamageRedZone(grayImages,minRedAreaPixels,pixelWidthInMicrons,radiusInPixelsPeripheryAnomaly, finalNuclei, outputDir)

    %% Damage zone (Channel 3)
    redZone = imbinarize(grayImages(:,:,3));
    redZoneFilled = imfill(redZone, 'holes');
    areaRedZone=regionprops(redZoneFilled,'Area');
    redZoneFilledLabelled= bwlabel(redZoneFilled);
    onlyRedZone=ismember(redZoneFilledLabelled,find(cat(1,areaRedZone.Area)>minRedAreaPixels));
    finalRedZone = imdilate(onlyRedZone, strel('disk', 5));
    finalRedZone = imfill(finalRedZone, 'holes');
    finalRedZone = imerode(finalRedZone, strel('disk', 20));
    finalRedZone = imdilate(finalRedZone, strel('disk', 20));
    
    areaRedZone=regionprops(finalRedZone,'Area');
    redZoneFilledLabelled= bwlabel(finalRedZone);
    finalRedZone=ismember(redZoneFilledLabelled,find(cat(1,areaRedZone.Area)>minRedAreaPixels));
    
    %We catch a half of the red zone and half from outside perimeter it.
%     perimeterRedZone = bwperim(finalRedZone);
%     borderRedZone = imdilate(perimeterRedZone, strel('disk', round(pixelsOfSurroundingZone)));
%     finalRedZone = finalRedZone | borderRedZone;

    redZoneAreaInMicrons = sum(finalRedZone(:)) * pixelWidthInMicrons^2;
    outsideRedZoneAreaInMicrons = sum(finalRedZone(:) == 0) * pixelWidthInMicrons^2;
    
    % Detecting plaque and removing it from red zone
    perfusionChannel = imbinarize(adapthisteq(grayImages(:,:,4)));%, 'adaptive', 'Sensitivity', 0.2);
    plaqueDetection = perfusionChannel & finalRedZone; %imbinarize(adapthisteq(grayImages(:,:,1)), 'adaptive')
    plaqueDetection = bwareaopen(plaqueDetection, 20);
    plaqueDetection = imdilate(plaqueDetection, strel('disk', 5));
    plaqueDetection = imfill(plaqueDetection, 'holes');
    plaqueDetection = imerode(plaqueDetection, strel('disk', 5));
    %plaqueDetection = bwareaopen(plaqueDetection, 20);
    plaqueDetection = bwareaopen(plaqueDetection, 500);
    
    plaquesRegion = regionprops(plaqueDetection, 'all');
    plaquesElongated = [vertcat(plaquesRegion.MinorAxisLength) ./ vertcat(plaquesRegion.MajorAxisLength) > 0.30];
    plaqueDetection = ismember(bwlabel(plaqueDetection), find(plaquesElongated));
    
    % Using the nuclei channel to detect the plaque
    plaqueDetectionRec = imreconstruct(plaqueDetection,imbinarize(adapthisteq(grayImages(:,:,4)), 'adaptive','Sensitivity',0.2));
    
    plaqueDetection = plaqueDetection | plaqueDetectionRec;
    plaqueDetection = imfill(plaqueDetection, 'holes');
    
%     plaqueDetection = plaqueDetection & finalNuclei;
%     figure;imshow(plaqueDetection)
%     close
    
    plaqueDetection = bwareaopen(plaqueDetection, 400);
    plaqueDetection = imerode(plaqueDetection, strel('disk', 5));
    plaqueDetection = imfill(plaqueDetection, 'holes');
    plaqueDetection = imdilate(plaqueDetection, strel('disk', 5));
    
    plaquesRegion = regionprops(plaqueDetection, 'all');
    plaquesElongated = vertcat(plaquesRegion.MinorAxisLength)>35 & [vertcat(plaquesRegion.MinorAxisLength)  ./ vertcat(plaquesRegion.MajorAxisLength) > 0.30];
    plaqueDetection = ismember(bwlabel(plaqueDetection), find(plaquesElongated));
    
    plaqueDetection = imdilate(plaqueDetection, strel('disk', 10));
    plaqueDetection = imfill(plaqueDetection, 'holes');
    plaqueDetection = imerode(plaqueDetection, strel('disk', 10));
    
%     figure;imshow(plaqueDetection)
%     close
    finalRedZone(plaqueDetection) = 0;
    imwrite(finalRedZone, strcat(outputDir, '/redZoneSegmented.tif'));
    
    peripheryOfAnomaly=imdilate(finalRedZone,strel('disk',round(radiusInPixelsPeripheryAnomaly)));
    peripheryOfAnomaly=peripheryOfAnomaly-finalRedZone-plaqueDetection;
    imwrite(peripheryOfAnomaly, strcat(outputDir, '/peripheryOfAnomaly.tif'));
end

