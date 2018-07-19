function [finalRedZone,redZoneAreaInMicrons,outsideRedZoneAreaInMicrons] = segmentDamageRedZone(grayImages,minRedAreaPixels,pixelsOfSurroundingZone,pixelWidthInMicrons)

    %% Damage zone (Channel 3)
    redZone = imbinarize(adapthisteq(grayImages(:,:,3)));
    redZoneFilled = imfill(redZone, 'holes');
    areaRedZone=regionprops(redZoneFilled,'Area');
    redZoneFilledLabelled= bwlabel(redZoneFilled);
    onlyRedZone=ismember(redZoneFilledLabelled,find(cat(1,areaRedZone.Area)>minRedAreaPixels));
    finalRedZone = imdilate(onlyRedZone, strel('disk', 5));
    finalRedZone = imfill(finalRedZone, 'holes');
    finalRedZone = imerode(finalRedZone, strel('disk', 5));
    
    
    
    %We catch a half of the red zone and half from outside perimeter it.
    perimeterRedZone = bwperim(finalRedZone);
    borderRedZone = imdilate(perimeterRedZone, strel('disk', round(pixelsOfSurroundingZone)));
    finalRedZone = finalRedZone | borderRedZone;
    
    redZoneAreaInMicrons = sum(finalRedZone(:)) * pixelWidthInMicrons^2;
    outsideRedZoneAreaInMicrons = sum(finalRedZone(:) == 0) * pixelWidthInMicrons^2;
    
    % Detecting plaque and removing it from red zone
    perfusionChannel = imbinarize(adapthisteq(grayImages(:,:,4)));
    plaqueDetection = perfusionChannel & imbinarize(adapthisteq(grayImages(:,:,1)), 'adaptive') & finalRedZone;
    plaqueBigger = imbinarize(grayImages(:, :, 4), 'adaptive');
    plaqueBiggerFilled = imfill(plaqueBigger, 'holes');
    plaquesLabelled = bwlabel(plaqueBiggerFilled);
    idsOfPlaque = unique(plaquesLabelled(plaqueDetection));
    finalPlaques = ismember(plaquesLabelled, idsOfPlaque);
    
    finalPlaques = imdilate(finalPlaques, strel('disk', 5));
    finalPlaques = imfill(finalPlaques, 'holes');
    finalPlaques = imerode(finalPlaques, strel('disk', 5));
    
    finalRedZone(finalPlaques) = 0;
    imwrite(finalRedZone, strcat(outputDir, '/redZoneSegmented.tif'));
    
end

