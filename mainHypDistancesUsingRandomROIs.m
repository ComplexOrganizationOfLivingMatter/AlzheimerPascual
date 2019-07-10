%% mainHypDistancesUsingRandomROIs
pathFolders = dir('**/*.xls');
addpath(genpath('src'))

circularROIs = cell(size(pathFolders,1),1);
for nFolder = 1:size(pathFolders,1)
    
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

    %pixels * inches/pixels * micrometers/inches
    pixels2microns = 1 * (1/resolution) * convertInch2Micr;
    

    %% Read matched Markers & images from Maribel
    fileName = pathFolders(nFolder).folder;
    imgMovMarkers = imread([pathFolders(nFolder).folder '\markersMovedFinal_Hyp' fileName(end-2:end) '.tif']);
    redMarkers = imgMovMarkers(:,:,1)>0;
    [row1,col1] = find(redMarkers);
    coordMark1 = [row1,col1];
    blueMarkers = imgMovMarkers(:,:,3)>0;
    [row2,col2] = find(blueMarkers);
    coordMark2 = [row2,col2];
   
    
    %% valid ROI
    maskROIpoly = imread([pathFolders(nFolder).folder '\validROI.tiff']);
    maskROIpoly = imbinarize(rgb2gray(maskROIpoly));
    areaPixels = sum(maskROIpoly(:)>0);
    area = regionprops(maskROIpoly,'Area');
    areaMicrons2 = areaPixels*pixels2microns*pixels2microns;
    
    %% delete markers out from the valid mask
    idCoord1 = sub2ind(size(maskROIpoly),coordMark1(:,1),coordMark1(:,2));
    coordMark1(maskROIpoly(idCoord1)==0,:) = [];
    idCoord2 = sub2ind(size(maskROIpoly),coordMark2(:,1),coordMark2(:,2));
    coordMark2(maskROIpoly(idCoord2)==0,:) = [];
    
    %% generate random circular ROIs
    clearvars -except pathFolders nFolder maskROIpoly coordMark1 coordMark2 pixels2microns circularROIs

%     if ~exist([pathFolders(nFolder).folder,'\randomCircularROIs.mat'],'file')
%         minMeanRawDist12_micro = 261.6;
%         minMeanRawDist12_pix = round(minMeanRawDist12_micro*(1/pixels2microns));
%         circularROIsProps = generateCircularROIs(maskROIpoly,minMeanRawDist12_pix,coordMark1,coordMark2);
%         save([pathFolders(nFolder).folder,'\randomCircularROIs.mat'],'circularROIsProps','-v7.3')      
%     else 
        load([pathFolders(nFolder).folder,'\randomCircularROIs.mat'],'circularROIsProps')
%     end
    
    circularROIs{nFolder} = circularROIsProps(1:4,:);
    
    
    %% associtate markers positions to circular ROIs
    
    
%     %% calculate euclidean distances in ROIs over the raw images
%     path2save1 = [pathFolders(nFolder).folder,'\markerDistancesRaw_randomROIs.mat'];
%     if  ~exist(path2save1,'file')
% %         [cellDistances1_1_raw,cellDistances1_2_raw,cellDistances2_1_raw,cellDistances2_2_raw] = measureGeodesicDistances(coordMark1,coordMark2,maskROIpoly,'shit');
%         save(path2save1,'cellDistances1_2_raw','cellDistances2_1_raw')
%     end
%     
%     
%     %% make randomization for the marker 1 (integrin), with the marker 2 fixed
%     posibleInd = find(maskROIpoly(:)>0);
%     totalRandom = 500;
%     cellDistances1rand_1rand = cell(totalRandom,1);
%     cellDistances1rand_2fixed = cell(totalRandom,1);
%     cellDistances2fixed_1rand = cell(totalRandom,1);
%     cellDistances2fixed_2fixed = cell(totalRandom,1);
% 
%     path2save2 = [pathFolders(nFolder).folder,'\markerDistancesRandom1Fixed2_randomROIs.mat'];
%     
%     if ~exist(path2save2,'file')
%         for nRand = 1:totalRandom
%             randPos = randperm(length(posibleInd));
%             selectedId = posibleInd(randPos(1:size(coordMark1,1)));
%             [randCoord1x, randCoord1y] = ind2sub(size(maskROIpoly),selectedId);
%             randCoordMark1 = [randCoord1x,randCoord1y];
%             
% %             [cellDistances1rand_1rand{nRand},cellDistances1rand_2fixed{nRand},cellDistances2fixed_1rand{nRand},cellDistances2fixed_2fixed{nRand},~,~] = measureGeodesicDistances(randCoordMark1,coordMark2,maskROIpoly,[],'no rand');
%             if rem(nRand,20)==0
%                 save(path2save2,'cellDistances1rand_2fixed','cellDistances2fixed_1rand','-v7.3')
%             end
%         end    
%     end
end

chooseTheBestROIs(circularROIs)