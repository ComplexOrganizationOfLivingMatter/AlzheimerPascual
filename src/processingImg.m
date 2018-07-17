function [densityInRedZone, densityAtBorder, densityInNoRedZone] = processingImg(pathFile)
%%PROCESSINGIMG
% Channel 1: Nuclei (Blue)
% Channel 2: Neurons (Green)
% Channel 3: Damage (Red)
% Channel 4: Perfusion (White)

    micronsOfSurroundingZone = 5;
    minSizeCellInMicrons = 25;
    minObjectSizeDeleteCellsInMicrons=5;
    
    pixelWidthInMicrons = 0.3031224;
    minCellSizeInPixels = ceil(minSizeCellInMicrons/pixelWidthInMicrons)^2;
    pixelsOfSurroundingZone = ceil(micronsOfSurroundingZone/pixelWidthInMicrons);
    minObjectSizeInPixels2Delete= ceil(minObjectSizeDeleteCellsInMicrons/pixelWidthInMicrons)^2;
    
    cellRadiusRangeInMicrons = [3, 8];
    cellRadiusRangeInPixels = round(cellRadiusRangeInMicrons ./ pixelWidthInMicrons);
    
    pathFileSplitted = strsplit(strrep(pathFile, '\', '/'), '/');
    outputDir = strcat('results/', strjoin(pathFileSplitted(end-3:end-1), '/'));
    
    mkdir(outputDir);
    %% Getting all the initial information
%     rawImg=imfinfo(pathFile);
%     maxValue = 4095;
%     for numChannel = 1:length(rawImg)
%          actualImgChannel = imread(pathFile,numChannel);
%          rawImages(:, :, numChannel) = actualImgChannel;
%          
%          %Transform them to gray
%          actualImgChannelGray = ind2rgb(actualImgChannel, gray(maxValue));
%          actualImgChannelGray = actualImgChannelGray(:, :, 1);
%          
%          grayImages(:,:,numChannel) = actualImgChannelGray;
%     end
    B=imread(pathFile);
    G=imread(strrep(pathFile,'C=0','C=1'));
    R=imread(strrep(pathFile,'C=0','C=2'));
    for nChan=1:4
        imchan=imread(strrep(pathFile,'C=0',['C=' num2str(nChan)-1]));
        grayImages(:,:,nChan)=imchan(:,:,1)+imchan(:,:,2)+imchan(:,:,3);
        %to visualize image:
        %figure;imshow(double(mat2gray(grayImages(:,:,nChan),[0,255])))
    end
    ImgComposite=R+G+B;
    
    %% Damage zone (Channel 3)
    redZone = imbinarize(grayImages(:,:,3));
    redZoneFilled = imfill(redZone, 'holes');
    onlyRedZone = bwareafilt(redZoneFilled, 1);
    finalRedZone = imdilate(onlyRedZone, strel('disk', 5));
    finalRedZone = imfill(finalRedZone, 'holes');
    finalRedZone = imerode(finalRedZone, strel('disk', 5));
    
    %We catch a half of the red zone and half from outside perimeter it.
    perimeterRedZone = bwperim(finalRedZone);
    borderRedZone = imdilate(perimeterRedZone, strel('disk', round(pixelsOfSurroundingZone)));
    
    redZoneAreaInMicrons = sum(finalRedZone(:)) * pixelWidthInMicrons^2;
    %CARE: surrounding to red zone and outside red zone overlap between
    %each other
    borderRedZoneAreaInMicrons = sum(borderRedZone(:)) * pixelWidthInMicrons^2;
    outsideRedZoneAreaInMicrons = sum(finalRedZone(:) == 0) * pixelWidthInMicrons^2;
    
%     figure; imshow(finalRedZone)
%     figure; imshow(surroundingToRedZone)
    
    %
    %% Locate neurons (Channel 1 and 2)
%     figure; imshow(grayImages(:,:,1))
%     figure; imshow(grayImages(:,:,2))
    neuronsAndMore = imbinarize(grayImages(:, :, 2),'global');
    neuronsAndMoreAreaOpen = bwareaopen(neuronsAndMore, minObjectSizeInPixels2Delete);
    neuronsAndMoreFilled = imfill(neuronsAndMoreAreaOpen, 'holes');
    neuronsAndMoreErode=imerode(neuronsAndMoreFilled,strel('disk',2));
    neuronsAndMoreDilate=imdilate(neuronsAndMoreErode,strel('disk',2));

    %figure; imshow(neuronsAndMoreFilled)

%     numberOfLevels = 10;
%     level = multithresh(grayImages(:, :, 1), numberOfLevels);
    G = grayImages(:, :, 1);
     G_he = histeq(G);

     % We modify G regarding intensity property. Get a treshold overlapping 3 diferent layers to obtein the most representative data.
     J=adapthisteq(G);
     meanJ=mean(mean(J));
     h3=(meanJ/3); h15=(meanJ/1.5); h2=meanJ/2;
     
     BWmin3 = imextendedmin(G,h3);
     BWmin2 = imextendedmin(G,h2);
     BWmin15 = imextendedmin(G,h15);
     
     BWmin = BWmin15 | BWmin3 | BWmin2;
     
     nucleiBinarized = 1 - BWmin;
     nucleiOpen = bwareaopen(nucleiBinarized, minObjectSizeInPixels2Delete);

     %neuronsAndMoreFilled = bwareafilt(neuronsAndMoreFilled, [minCellSizeInPixels Inf]);
     
     nucleiWithNeuron = imreconstruct(neuronsAndMoreFilled, nucleiOpen);
     
     %figure; imshow(nuclei);
     nucleiFilled = imfill(nucleiWithNeuron, 'holes');
     
     originalImageOnlyRealNuclei = double(nucleiFilled) .* double(grayImages(:, : ,1));
     originalImgNucleiAdjusted = imadjust(double(mat2gray(originalImageOnlyRealNuclei,[0,255])));
     figure; imshow(ImgComposite)
     [centers, radii, metric] = imfindcircles(originalImgNucleiAdjusted, cellRadiusRangeInPixels, 'Sensitivity', 0.93);
     %hold on; viscircles(centers, radii, 'EdgeColor', 'b');
     
     %Remove centroids not in the neurons images
     coordinatesNuclei = sub2ind(size(neuronsAndMoreFilled), round(centers(:, 2)), round(centers(:, 1)));
     
     goodNuclei = neuronsAndMoreFilled(coordinatesNuclei);
     
     %hold on; viscircles(centers(goodNuclei, :), radii(goodNuclei), 'EdgeColor', 'r');
     
     %Remove overlapping centroids
     finalNeuronsCentroid = centers(goodNuclei, :);
     finalNucleiRadius = radii(goodNuclei);
     distanceBetweenRealNuclei = squareform(pdist(finalNeuronsCentroid));
     
     p2 = distanceBetweenRealNuclei <= (finalNucleiRadius);
     [nuclei1, nuclei2] = find(p2);
     goodIndices = nuclei1 ~= nuclei2;
     goodYs = nuclei1(goodIndices);
     goodXs = nuclei2(goodIndices);
     
     overlappingCentroids = unique(sort([goodXs,goodYs], 2), 'rows');
     areaOfNuclei1 = zeros(size(neuronsAndMoreFilled));
     areaOfNuclei2 = zeros(size(neuronsAndMoreFilled));
     
     nucleiDuplicated = [];
     for numIndex = 1:size(overlappingCentroids, 1)
         centroidNuclei1 = round(finalNeuronsCentroid(overlappingCentroids(numIndex, 1), :));
         areaOfNuclei1(centroidNuclei1(1, 2), centroidNuclei1(1, 1)) = 1;
         radiusNuclei1 = bwdist(areaOfNuclei1) < finalNucleiRadius(overlappingCentroids(numIndex, 1));
         areaCoveringNuclei1 = sum(neuronsAndMoreFilled(radiusNuclei1));
         
         centroidNuclei2 = round(finalNeuronsCentroid(overlappingCentroids(numIndex, 2), :));
         areaOfNuclei2(centroidNuclei2(1, 2), centroidNuclei2(1, 1)) = 1;
         radiusNuclei2 = bwdist(areaOfNuclei2) < finalNucleiRadius(overlappingCentroids(numIndex, 2));
         
         areaCoveringNuclei2 = sum(neuronsAndMoreFilled(radiusNuclei2));
         
         if areaCoveringNuclei1 > areaCoveringNuclei2
             nucleiDuplicated(end+1) = overlappingCentroids(numIndex, 2);
         else
             nucleiDuplicated(end+1) = overlappingCentroids(numIndex, 1);
         end
     end
     
     finalNeuronsCentroid(nucleiDuplicated, :) = [];
     finalNucleiRadius(nucleiDuplicated) = [];
     
     hold on; viscircles(finalNeuronsCentroid, finalNucleiRadius, 'EdgeColor', 'r','LineWidth',0.3);
     print(strcat(outputDir, '/compisiteWithNeurons.tif'), '-dtiff');
%     level = graythresh(grayImages(:, :, 1));
%     nuclei = imbinarize(grayImages(:, :, 1), level);
%     nucleiOpen = bwareaopen(nuclei,minObjectSizeInPixels2Delete);
% 
%     %figure; imshow(nuclei);
%     nucleiFilled = imfill(nucleiOpen, 'holes');
    
%     figure; imshow(nucleiFilled)
    
%     nucleiFilled = imfill(nuclei, 'holes');
%     nuclei = nucleiFilled;
%     distMatrix = bwdist(~nuclei);
%     distMatrix = -distMatrix;
%     distMatrix(~nuclei) = Inf;
%     nucleiWatersheded = watershed(distMatrix);
%     nucleiWatersheded(~nuclei) = 0;
%     figure; imshow(double(nucleiWatersheded))
    
%     neuronsAndMoreFilled = bwareafilt(neuronsAndMoreFilled, [minCellSizeInPixels Inf]);
% 
%     %With segmented images works better
%     nucleiWithNeuron = imreconstruct(neuronsAndMoreFilled, nucleiFilled);
%     %figure; imshow(nucleiWithNeuron);
%     %Remove smaller non-cell elements
%     nucleiWithNeuronOnlyRealCells = bwareafilt(nucleiWithNeuron, [minCellSizeInPixels Inf]);
%     
%     labelledNeurons = bwlabel(nucleiWithNeuronOnlyRealCells);
    
    %% Calculate density:
    % Cell per micra?
    
    zonesOfImage = ones(size(finalRedZone));
    zonesOfImage(finalRedZone == 0) = 3;
    zonesOfImage(borderRedZone) = 2;
    h=figure;imshow(zonesOfImage,colorcube(3))
    hold on
    imshow(ImgComposite)
    hold off
    alpha(.7)
    
    print(strcat(outputDir, '/compisitePerZones.tif'), '-dtiff');
    
    %Red zone density
    
    neuronsIndices = sub2ind(size(neuronsAndMoreFilled), round(finalNeuronsCentroid(:, 2)), round(finalNeuronsCentroid(:, 1)));
    hold on; viscircles(finalNeuronsCentroid, finalNucleiRadius, 'EdgeColor', 'r');

    print(strcat(outputDir, '/compisitePerZonesWithNeurons.tif'), '-dtiff');
    
    %figure; imshow(ismember(labelledNeurons, neuronsInRedZone).*labelledNeurons, colorcube(200))
    densityInRedZone = sum(zonesOfImage(neuronsIndices) == 1)/redZoneAreaInMicrons;
    
    %Border of red zone
    densityAtBorder = length(zonesOfImage(neuronsIndices) == 2)/borderRedZoneAreaInMicrons;
    
    %Outside of the red zone
    densityInNoRedZone = length(zonesOfImage(neuronsIndices) == 3)/outsideRedZoneAreaInMicrons;
    
end