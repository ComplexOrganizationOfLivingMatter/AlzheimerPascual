function propertiesCaptByRadius = generateCircularROIs(maskROIpoly,radiusROI,coord1,coord2)

    %try from average the min distance from plaques to integrin, using
    %integers multipliers until reach the 10x. Then choose the case
    %that capture more markers and leave few region without ROI mapping.
    possibleRadius = (1:10).*radiusROI;
    
    % generate 200 circular random ROIs, and get the randomization with 
    % more markers. In draw case select the randomization with more
    % area filled.
    
    
    numRandomizations = 100;
    propertiesCaptByRadius = cell(length(possibleRadius),4);
    
    for nRadius = 1:length(possibleRadius)
        propCaptMarkers = zeros(length(numRandomizations),1);
        propROIsAnyNanMarker = zeros(length(numRandomizations),1);
        propFilledArea = zeros(length(numRandomizations),1);
        circlesCenters = cell(length(numRandomizations),1);
        parfor nRand = 1:numRandomizations
            [propCaptMarkers(nRand),propROIsAnyNanMarker(nRand),propFilledArea(nRand),circlesCenters{nRand}] = checkRadiusROIByMaxOfMarkersCaptured(maskROIpoly,possibleRadius(nRadius),coord1,coord2);
        end
        propertiesCaptByRadius(nRadius,1:4) = {propCaptMarkers,propROIsAnyNanMarker,propFilledArea,circlesCenters};
    end
end

