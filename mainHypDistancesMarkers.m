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
    fileName = pathFolders(nFolder).folder;
    imgMovMarkers = imread([pathFolders(nFolder).folder '\markersMovedFinal_Hyp' fileName(end-2:end) '.tif']);
    redMarkers = imgMovMarkers(:,:,1)>0;
    [row1,col1] = find(redMarkers);
    coordMark1 = [row1,col1];
    blueMarkers = imgMovMarkers(:,:,3)>0;
    [row2,col2] = find(blueMarkers);
    coordMark2 = [row2,col2];
    
    
    
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
        maskROIpoly = imread([pathFolders(nFolder).folder '\validROI.tiff']);
        maskROIpoly = imbinarize(rgb2gray(maskROIpoly));
    end
    
    

    
    %delete markers out from the valid mask
    idCoord1 = sub2ind(size(maskROIpoly),coordMark1(:,1),coordMark1(:,2));
    coordMark1(maskROIpoly(idCoord1)==0,:) = [];
    idCoord2 = sub2ind(size(maskROIpoly),coordMark2(:,1),coordMark2(:,2));
    coordMark2(maskROIpoly(idCoord2)==0,:) = [];
%     figure;imshow(maskROIpoly);hold on
%     plot(coordMark1(:,2),coordMark1(:,1),'.r')
%     plot(coordMark2(:,2),coordMark2(:,1),'.b')
    

    %% calculate geodesic distances in raw images
    path2save1 = [pathFolders(nFolder).folder,'\markerDistancesRaw.mat'];
    if exist(path2save1,'file')
        load(path2save1)
    else
        [cellDistances1_1_raw,cellDistances1_2_raw,cellDistances2_1_raw,cellDistances2_2_raw] = measureGeodesicDistances(coordMark1,coordMark2,maskROIpoly,'shit');
        save(path2save1,'cellDistances1_1_raw','cellDistances1_2_raw','cellDistances2_1_raw','cellDistances2_2_raw')
    end
    
    %% make randomization for the marker 1 (integrin), with the marker 2 fixed
    posibleInd = find(maskROIpoly(:)>0);
    totalRandom = 100;
    cellDistances1_1_rand = cell(1, totalRandom);
    cellDistances1_2_rand = cell(1, totalRandom);
    cellDistances2_1_rand = cell(1, totalRandom);
    cellDistances2_2_rand = cell(1, totalRandom);

    path2save2 = [pathFolders(nFolder).folder,'\markerDistancesRandom1Fixed2.mat'];
    
    if ~exist(path2save2,'file')
        for nRand = 1:totalRandom
            randPos = randperm(length(posibleInd));
            selectedId = posibleInd(randPos(1:size(coordMark1,1)));
            [randCoord1x, randCoord1y] = ind2sub(size(maskROIpoly),selectedId);
            randCoordMark1 = [randCoord1x,randCoord1y];
            [cellDistances1_1_rand{nRand},cellDistances1_2_rand{nRand},cellDistances2_1_rand{nRand},cellDistances2_2_rand{nRand}] = measureGeodesicDistances(randCoordMark1,coordMark2,maskROIpoly,'shit');

            if rem(nRand,20)==0
                save(path2save2,'cellDistances1_1_rand','cellDistances1_2_rand','cellDistances2_1_rand','cellDistances2_2_rand','-v7.3')
            end
        end    
    end
    
    %% make randomization for the marker 2 (plaques), with the marker 1 fixed
    path2save3 = [pathFolders(nFolder).folder,'\markerDistancesRandom2Fixed1.mat'];
    cellDistances1_1_rand = cell(1, totalRandom);
    cellDistances1_2_rand = cell(1, totalRandom);
    cellDistances2_1_rand = cell(1, totalRandom);
    cellDistances2_2_rand = cell(1, totalRandom);   
    
    if ~exist(path2save3,'file')
        for nRand = 1:totalRandom
            randPos = randperm(length(posibleInd));
            selectedId = posibleInd(randPos(1:size(coordMark2,1)));
            [randCoord2x, randCoord2y] = ind2sub(size(maskROIpoly),selectedId);
            randCoordMark2 = [randCoord2x,randCoord2y];
            [cellDistances1_1_rand{nRand},cellDistances1_2_rand{nRand},cellDistances2_1_rand{nRand},cellDistances2_2_rand{nRand}] = measureGeodesicDistances(coordMark1,randCoordMark2,maskROIpoly,'shit');

            if rem(nRand,20)==0
                save(path2save3,'cellDistances1_1_rand','cellDistances1_2_rand','cellDistances2_1_rand','cellDistances2_2_rand','-v7.3')
            end
        end  
    end
    
    clearvars -except pathFolders nFolder
end