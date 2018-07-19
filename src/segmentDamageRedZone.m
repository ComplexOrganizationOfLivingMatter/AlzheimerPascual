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
    perfusionChannel = imbinarize(adapthisteq(grayImages(:,:,4)));
    plaqueDetection = perfusionChannel & imbinarize(adapthisteq(grayImages(:,:,1)), 'adaptive') & finalRedZone;

    plaqueDetection = imdilate(plaqueDetection, strel('disk', 5));
    plaqueDetection = imfill(plaqueDetection, 'holes');
    plaqueDetection = imerode(plaqueDetection, strel('disk', 5));
    plaqueDetection = bwareaopen(plaqueDetection, 300);
    
    finalRedZone(plaqueDetection) = 0;
    imwrite(finalRedZone, strcat(outputDir, '/redZoneSegmented.tif'));
    
end

