function [finalRedZone,redZoneAreaInMicrons,outsideRedZoneAreaInMicrons] = segmentDamageRedZone(grayImages,minRedAreaPixels,pixelsOfSurroundingZone,pixelWidthInMicrons, outputDir)

    %% Damage zone (Channel 3)
    redZone = imbinarize(adapthisteq(grayImages(:,:,3)));
    redZoneFilled = imfill(redZone, 'holes');
    areaRedZone=regionprops(redZoneFilled,'Area');
    redZoneFilledLabelled= bwlabel(redZoneFilled);
    onlyRedZone=ismember(redZoneFilledLabelled,find(cat(1,areaRedZone.Area)>minRedAreaPixels));
    finalRedZone = imdilate(onlyRedZone, strel('disk', 5));
    finalRedZone = imfill(finalRedZone, 'holes');
%     finalRedZone = imerode(finalRedZone, strel('disk', 5));
    
    %We catch a half of the red zone and half from outside perimeter it.
%     perimeterRedZone = bwperim(finalRedZone);
%     borderRedZone = imdilate(perimeterRedZone, strel('disk', round(pixelsOfSurroundingZone)));
%     finalRedZone = finalRedZone | borderRedZone;
    
    

    redZoneAreaInMicrons = sum(finalRedZone(:)) * pixelWidthInMicrons^2;
    outsideRedZoneAreaInMicrons = sum(finalRedZone(:) == 0) * pixelWidthInMicrons^2;
    
    % Detecting plaque and removing it from red zone
    perfusionChannel = imbinarize(adapthisteq(grayImages(:,:,4)), 'adaptive', 'Sensitivity', 0.2);
    plaqueDetection = perfusionChannel & finalRedZone; %imbinarize(adapthisteq(grayImages(:,:,1)), 'adaptive')
    plaqueDetection = bwareaopen(plaqueDetection, 20);
    plaqueDetection = imdilate(plaqueDetection, strel('disk', 5));
    plaqueDetection = imfill(plaqueDetection, 'holes');
    plaqueDetection = imerode(plaqueDetection, strel('disk', 5));
    plaqueDetection = bwareaopen(plaqueDetection, 500);
    
    plaquesRegion = regionprops(plaqueDetection, 'all');
    plaquesElongated = [vertcat(plaquesRegion.MinorAxisLength) ./ vertcat(plaquesRegion.MajorAxisLength) > 0.3];
    plaqueDetection = ismember(bwlabel(plaqueDetection), find(plaquesElongated));
    
    % Using the nuclei channel to detect the plaque
    plaqueDetection = plaqueDetection & imbinarize(adapthisteq(grayImages(:,:,1)), 'adaptive');
    plaqueDetection = imfill(plaqueDetection, 'holes');
    plaqueDetection = bwareaopen(plaqueDetection, 500);
    
    finalRedZone(plaqueDetection) = 0;
    imwrite(finalRedZone, strcat(outputDir, '/redZoneSegmented.tif'));
    
end

