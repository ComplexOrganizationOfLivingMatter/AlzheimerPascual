%% main hypoMarkers distance measurements

pathFolders = dir('**/*.xls');
addpath(genpath('src'))

for nFolder = 1 : size(pathFolders,1)
    
    T = readtable([pathFolders(nFolder).folder '\' pathFolders(nFolder).name],'Sheet','Quantities - Raw');
    pathRois = dir([pathFolders(nFolder).folder '\*.csv']);
    
    namesROIs = {pathRois(:).name};
    majorROI = namesROIs(cellfun(@(x) contains(lower(x),'major'),namesROIs));
    tableMajorROI = readtable([pathFolders(nFolder).folder '\' majorROI{1}]);
    
    imgInfo = imfinfo([pathFolders(nFolder).folder '\Image.tif']);
    img = imread([pathFolders(nFolder).folder '\Image.tif']);
    resolution = imgInfo.XResolution; % X inches -> 1 pixel
    % 1 inch -> 25400 micrometers
    convertInch2Micr = 25400/1;
    %pixels * inches/pixels * micrometers/inches
    sizeXmicrons = imgInfo.Width * (1/resolution) * convertInch2Micr;
    sizeYmicrons = imgInfo.Height * (1/resolution) * convertInch2Micr;

    
    %% Draw image for Maribel's matching
    if ~exist([pathFolders(nFolder).folder '\markers.tiff'],'file')
        drawMarkersOverImage(img,T,convertInch2Micr,resolution,pathFolders,nFolder)
    end
    
    %% Read matched Markers & images from Maribel
    
    
    
    
    
    %% Define ROI (and invalid ROI)
    if ~exist([pathFolders(nFolder).folder '\validROI.tiff'],'file')
        invalidROIs = namesROIs(cellfun(@(x) contains(lower(x),'invalid'),namesROIs));

        tablesInvalidROI = cell(length(invalidROIs),1);
        for nInvROIs = 1:length(invalidROIs)
           tablesInvalidROI{nInvROIs} = readtable([pathFolders(nFolder).folder '\' invalidROIs{nInvROIs}]);
        end

        ROIpolyCoord = [tableMajorROI.X,tableMajorROI.Y];
        ROIpolyCoordPixels = [[ROIpolyCoord(:,1);ROIpolyCoord(1,1)]*resolution,[ROIpolyCoord(:,2);ROIpolyCoord(1,2)]*resolution];

        maskROIpoly = false(size(rgb2gray(img)));
        [allX,allY]=find(maskROIpoly==0);
        inRoi = inpolygon(allY,allX,ROIpolyCoordPixels(:,1),ROIpolyCoordPixels(:,2));
        maskROIpoly(inRoi)=1;
        for nNoValidRois = 1 : length(tablesInvalidROI)
            tableAux = tablesInvalidROI{nNoValidRois};
            ROIpolyCoordAux = [tableAux.X,tableAux.Y];
            ROIpolyCoordPixelsAux = [[ROIpolyCoordAux(:,1);ROIpolyCoordAux(1,1)]*resolution,[ROIpolyCoordAux(:,2);ROIpolyCoordAux(1,2)]*resolution];
            inRoi = inpolygon(allY,allX,ROIpolyCoordPixelsAux(:,1),ROIpolyCoordPixelsAux(:,2));
            maskROIpoly(inRoi) = 0;
        end
        imwrite(maskROIpoly,[pathFolders(nFolder).folder '\validROI.tiff']) 
    else
%         maskROIpoly = imread([pathFolders(nFolder).folder '\markers.tiff']);
    end
    
    

    
%     %command to calculate distances defining nan zones: bwdistegeodsic
%     
%     for nCoord = 1 : length(coord)
%     
%         indCoord = sub2ind(maskROIpoly,coord(:,1),coord(:,2));
%         
%         D = bwdistgeodesic(maskROIpoly,indCoord); 
%     
%     end

%     minDistFromMark1to2 = arrayfun(@(x,y) min(pdist2([x,y],coordMark2)),coordMark1(:,1),coordMark1(:,2));
%     averageMinDFrom1to2 = mean(minDistFromMark1to2);
%     stdMinDFrom1to2 = std(minDistFromMark1to2);   
%     
%     minDistFromMark2to1 = arrayfun(@(x,y) min(pdist2([x,y],coordMark1)),coordMark2(:,1),coordMark2(:,2));
%     averageMinDFrom2to1 = mean(minDistFromMark2to1);
%     stdMinDFrom2to1 = std(minDistFromMark2to1);
%     
%     %meter tambien distancias minimas entre marcadores del mismo tipo
%     
%     %%%
%     
%     numMark1 = size(coordMark1,1);
%     numMark2 = size(coordMark2,1);
%     
%     %randomize markers 2 position fixing the marker 1
%     
%     %randomize markers 1 position fixing the marker 2

    clearvars -except pathFolders nFolder
end