%% main hypoMarkers distance measurements

pathFolders = dir('**/*.xls');

for nFolder = 1 : size(pathFolders,1)
    
    T = readtable([pathFolders(nFolder).folder '\' pathFolders(nFolder).name],'Sheet','Quantities - Raw');
    pathRois = dir([pathFolders(nFolder).folder '\*.csv']);
    
    namesROIs = {pathRois(:).name};
    invalidROIs = namesROIs(cellfun(@(x) contains(lower(x),'invalid'),namesROIs));
    majorROI = namesROIs(cellfun(@(x) contains(lower(x),'major'),namesROIs));

    tableMajorROI = readtable([pathFolders(nFolder).folder '\' majorROI{1}]);

    tablesInvalidROI = cell(length(invalidROIs),1);
    for nInvROIs = 1:length(invalidROIs)
       tablesInvalidROI{nInvROIs} = readtable([pathFolders(nFolder).folder '\' majorROI{1}]);
    end
    
    imgInfo = imfinfo([pathFolders(nFolder).folder '\Image.tif']);
    img = imread([pathFolders(nFolder).folder '\Image.tif']);
    resolution = imgInfo.XResolution; % X inches -> 1 pixel
    % 1 inch -> 25400 micrometers
    convertInch2Micr = 25400/1;
    %pixels * inches/pixels * micrometers/inches
    sizeXmicrons = imgInfo.Width * (1/resolution) * convertInch2Micr;
    sizeYmicrons = imgInfo.Height * (1/resolution) * convertInch2Micr;

    %select each marker    
    indMark1 = cellfun(@(x) contains(lower(x),'mark 1'),T.Var1);
    indMark2 = cellfun(@(x) contains(lower(x),'mark 2'),T.Var1);
    indMark3 = cellfun(@(x) contains(lower(x),'mark 3'),T.Var1);
    indPos = cellfun(@(x) contains(lower(x),'pos'),T.Var1);
    
    %pos centroids
    centroidXYPos = [vertcat(T.PosX),vertcat(T.PosY)];
    centroidXYPos = centroidXYPos(indPos,:);
    centroidXYPos = centroidXYPos( ~isnan(centroidXYPos(:,1))|~isnan(centroidXYPos(:,2)),:);

    %markers coordinates
    coordXYMarkers = [vertcat(T.X),vertcat(T.Y)];
    coordMark1 = coordXYMarkers(indMark1,:);
    coordMark1 = coordMark1( ~isnan(coordMark1(:,1))|~isnan(coordMark1(:,2)),:);
    
    coordMark2 = coordXYMarkers(indMark2,:);
    coordMark2 = coordMark2( ~isnan(coordMark2(:,1))|~isnan(coordMark2(:,2)),:);

    coordMark3 = coordXYMarkers(indMark3,:);
    coordMark3 = coordMark3( ~isnan(coordMark3(:,1))|~isnan(coordMark3(:,2)),:);   
    
    %% convert micrometers to pixels to match with the image
    %micrometers * inches/micrometers * pixels/inches 
    coordMark1Pixels = coordMark1.* ((1/convertInch2Micr) *(resolution));
    coordMark2Pixels = coordMark2.* ((1/convertInch2Micr) *(resolution));
    coordMark3Pixels = coordMark3.* ((1/convertInch2Micr) *(resolution));
    centroidXYPosPixels = centroidXYPos.* ((1/convertInch2Micr) *(resolution));
    
    if min([coordMark1Pixels(:,1);coordMark2Pixels(:,1);coordMark3Pixels(:,1);centroidXYPosPixels(:,1)]) < 0
       setupX = abs(min([coordMark1Pixels(:,1);coordMark2Pixels(:,1);coordMark3Pixels(:,1);centroidXYPosPixels(:,1)]));
    else
       setupX = 0;
    end
    if min([coordMark1Pixels(:,2);coordMark2Pixels(:,2);coordMark3Pixels(:,2);centroidXYPosPixels(:,2)]) < 0
       setupY = abs(min([coordMark1Pixels(:,2);coordMark2Pixels(:,2);coordMark3Pixels(:,2);centroidXYPosPixels(:,2)]));
    else
       setupY = 0;
    end
   
    
    h = figure;imshow(flipud(rgb2gray(img)))
    
    hold on,plot(coordMark2Pixels(:,1)+setupX,coordMark2Pixels(:,2)+setupY,'.b','MarkerSize',3)
    hold on,plot(coordMark1Pixels(:,1)+setupX,coordMark1Pixels(:,2)+setupY,'.r','MarkerSize',3)
    hold on,plot(coordMark3Pixels(:,1)+setupX,coordMark3Pixels(:,2)+setupY,'*y')
%     hold on,plot(centroidXYPosPixels(:,1)+setupX,centroidXYPosPixels(:,2)+setupY,'ok')
    axis xy
    axis equal

    
    %command to calculate distances defining nan zones: bwdistgeodesic
    
    minDistFromMark1to2 = arrayfun(@(x,y) min(pdist2([x,y],coordMark2)),coordMark1(:,1),coordMark1(:,2));
    averageMinDFrom1to2 = mean(minDistFromMark1to2);
    stdMinDFrom1to2 = std(minDistFromMark1to2);   
    
    minDistFromMark2to1 = arrayfun(@(x,y) min(pdist2([x,y],coordMark1)),coordMark2(:,1),coordMark2(:,2));
    averageMinDFrom2to1 = mean(minDistFromMark2to1);
    stdMinDFrom2to1 = std(minDistFromMark2to1);
    
    %meter tambien distancias minimas entre marcadores del mismo tipo
    
    %%%
    
    numMark1 = size(coordMark1,1);
    numMark2 = size(coordMark2,1);
    
    %randomize markers 2 position fixing the marker 1
    
    %randomize markers 1 position fixing the marker 2

    
end