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
    
    imwrite(finalRedZone, strcat(outputDir, '/redZoneSegmented.tif'));
    
    %We catch a half of the red zone and half from outside perimeter it.
    perimeterRedZone = bwperim(finalRedZone);
    borderRedZone = imdilate(perimeterRedZone, strel('disk', round(pixelsOfSurroundingZone)));
    finalRedZone = finalRedZone | borderRedZone;
    
    redZoneAreaInMicrons = sum(finalRedZone(:)) * pixelWidthInMicrons^2;
    outsideRedZoneAreaInMicrons = sum(finalRedZone(:) == 0) * pixelWidthInMicrons^2;
    
    
    
end

