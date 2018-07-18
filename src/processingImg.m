function [densityInRedZone, densityAtBorder, densityInNoRedZone] = processingImg(pathFile)
%%PROCESSINGIMG
% Channel 1: Nuclei (Blue)
% Channel 2: Neurons (Green)
% Channel 3: Damage (Red)
% Channel 4: Perfusion (White)
    
    pixelWidthInMicrons = 0.3031224;
    minObjectSizeInPixels2Delete= round(pi*(7.5^2));
    
    pixelsOfSurroundingZone = 20;
    
    nucleiRadiusRangeInMicrons = [3, 10];
    nucleiRadiusRangeInPixels = round(nucleiRadiusRangeInMicrons ./ pixelWidthInMicrons);
    
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
    
    imwrite(finalRedZone, strcat(outputDir, '/redZoneSegmented.tif'));
    
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
    originalNeurons = grayImages(:, :, 2);
    originalNeuronsAdjusted = imadjust(originalNeurons, [0 0.5]);
    neuronsAndMore = imbinarize(originalNeuronsAdjusted,'global');
    neuronsAndMoreAreaOpen = bwareaopen(neuronsAndMore, minObjectSizeInPixels2Delete);
    finalNeurons = imfill(neuronsAndMoreAreaOpen, 'holes');
    neuronsAndMoreErode=imerode(finalNeurons,strel('disk',2));
    finalNeurons=imdilate(neuronsAndMoreErode,strel('disk',2));
    finalNeurons = bwareaopen(finalNeurons, minObjectSizeInPixels2Delete, 4);

   
    %figure; imshow(neuronsAndMoreFilled)

%     numberOfLevels = 10;
%     level = multithresh(grayImages(:, :, 1), numberOfLevels);
%     G = grayImages(:, :, 1);
%      G_he = histeq(G);

     % We modify G regarding intensity property. Get a treshold overlapping 3 diferent layers to obtein the most representative data.
%      J=adapthisteq(G);
%      meanJ=mean(mean(J));
%      h3=(meanJ/3); h15=(meanJ/1.5); h2=meanJ/2;
     
%      BWmin3 = imextendedmin(G,h3);
%      BWmin2 = imextendedmin(G,h2);
%      BWmin15 = imextendedmin(G,h15);
%      
     %BWmin = BWmin15 | BWmin3 | BWmin2;
     %figure;imshow(nucleiBinarized);
     %figure;imshow(double(mat2gray(B,[0,255])))
     
     nucleiOriginalAdjusted = imadjust(grayImages(:, :, 1), [0 0.5]);
     nucleiBinarized = imbinarize(nucleiOriginalAdjusted);
     nucleiOpen = bwareaopen(nucleiBinarized, minObjectSizeInPixels2Delete);
     %figure;imshow(nucleiOpen);
     nucleiWithNeuron = imreconstruct(finalNeurons, nucleiOpen);
     
     %figure; imshow(nuclei);
     nucleiFilled = imfill(nucleiWithNeuron, 'holes');
     
     finalNuclei = imfill(nucleiOpen, 'holes');
     
     imwrite(finalNeurons, strcat(outputDir, '/neuronsSegmented.tif'));  
     imwrite(finalNuclei, strcat(outputDir, '/nucleiOfNeuronsSegmented.tif'));
     
     originalImageOnlyRealNuclei = double(nucleiFilled) .* double(nucleiOriginalAdjusted);
     originalImgNucleiAdjusted = imadjust(double(mat2gray(originalImageOnlyRealNuclei,[0,255])));
     figure('Visible', 'off'); imshow(ImgComposite)
     [centers, radii] = imfindcircles(originalImgNucleiAdjusted, nucleiRadiusRangeInPixels, 'Sensitivity', 0.95);
     %hold on; viscircles(centers, radii, 'EdgeColor', 'b');
     
     %Remove centroids not in the neurons images
     coordinatesNuclei = sub2ind(size(finalNeurons), round(centers(:, 2)), round(centers(:, 1)));
     
     goodNuclei = finalNeurons(coordinatesNuclei);
     
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
     
     overlappingCentroids = unique(sort([goodXs, goodYs], 2), 'rows');
     areaOfNuclei1 = zeros(size(finalNeurons));
     areaOfNuclei2 = zeros(size(finalNeurons));
     
     nucleiDuplicated = [];
     for numIndex = 1:size(overlappingCentroids, 1)
         centroidNuclei1 = round(finalNeuronsCentroid(overlappingCentroids(numIndex, 1), :));
         areaOfNuclei1(centroidNuclei1(1, 2), centroidNuclei1(1, 1)) = 1;
         radiusNuclei1 = bwdist(areaOfNuclei1) < finalNucleiRadius(overlappingCentroids(numIndex, 1));
         areaCoveringNuclei1 = sum(finalNeurons(radiusNuclei1));
         
         centroidNuclei2 = round(finalNeuronsCentroid(overlappingCentroids(numIndex, 2), :));
         areaOfNuclei2(centroidNuclei2(1, 2), centroidNuclei2(1, 1)) = 1;
         radiusNuclei2 = bwdist(areaOfNuclei2) < finalNucleiRadius(overlappingCentroids(numIndex, 2));
         
         areaCoveringNuclei2 = sum(finalNeurons(radiusNuclei2));
         
         if areaCoveringNuclei1 > areaCoveringNuclei2
             nucleiDuplicated(end+1) = overlappingCentroids(numIndex, 2);
         else
             nucleiDuplicated(end+1) = overlappingCentroids(numIndex, 1);
         end
     end
     
     finalNeuronsCentroid(nucleiDuplicated, :) = [];
     finalNucleiRadius(nucleiDuplicated) = [];
     
     hold on; viscircles(finalNeuronsCentroid, finalNucleiRadius, 'EdgeColor', 'r','LineWidth',0.3);
     print(strcat(outputDir, '/compositeWithNeurons.tif'), '-dtiff');
     
     %% Exist some nuclei+neurons within a neuron unassigned with a circle
     % Remove overlapping areas very small
     overlappingNeuronsAndNuclei = finalNuclei & finalNeurons;
     overlappingLabelled = bwlabel(overlappingNeuronsAndNuclei);
     overlappingNeuronsAndNucleiEroded = imerode(overlappingNeuronsAndNuclei, strel('disk', round(nucleiRadiusRangeInPixels(1)/4)));
     biggerAreasOfOverlapping = unique(overlappingLabelled .* overlappingNeuronsAndNucleiEroded);
     
     overlappingLabelled  = ismember(overlappingLabelled, biggerAreasOfOverlapping) .* overlappingLabelled;
     
     indicesFinalNeuronsCentroid = sub2ind(size(overlappingLabelled), round(finalNeuronsCentroid(:, 2)), round(finalNeuronsCentroid(:, 1)));
     circleImg = zeros(size(overlappingLabelled));
     circleImg(indicesFinalNeuronsCentroid) = 1;
     circleImgDilated = imdilate(circleImg, strel('disk', round(mean(finalNucleiRadius)))); %%TODO: CHANGE THIS
     allNuclei = 1:max(overlappingLabelled(:));
     remainingNucleiIDs = ismember(allNuclei, unique(overlappingLabelled .* circleImgDilated)');
     remainingNucleiIDs = allNuclei(remainingNucleiIDs == 0);
     
     %figure; imshow(ismember(overlappingLabelled, remainingNucleiIDs))
     
     %Remaining nuclei unassigned
     remainingNucleiImg = ismember(overlappingLabelled, remainingNucleiIDs);
     indicesRemainingNuclei = remainingNucleiImg;
     %figure; imshow(finalNeurons)
     labelledNeurons = bwlabel(finalNeurons);
     
     %Check which neurons have any nuclei unassigned
     idsLabelledNeurons = unique(labelledNeurons(indicesFinalNeuronsCentroid));
     idsOfRemainingNeurons = unique(labelledNeurons(indicesRemainingNuclei));
     neuronsWithNucleiUnassigned = setdiff(idsOfRemainingNeurons, idsLabelledNeurons);
     imgRemainingNucleiLabelled = overlappingLabelled .* remainingNucleiImg;
     
     %Get centroid of nuclei
     centroidsOfNucleiUnassigned = regionprops(imgRemainingNucleiLabelled, 'Centroid');
     centroidsOfNucleiUnassigned = vertcat(centroidsOfNucleiUnassigned.Centroid);
     
     centroidsOfNucleiUnassigned(isnan(centroidsOfNucleiUnassigned(:, 1)), :) = [];
     indicesCentroidsNuclei = sub2ind(size(overlappingLabelled), round(centroidsOfNucleiUnassigned(:, 2)), round(centroidsOfNucleiUnassigned(:, 1)));
     
     nucleiBelongingToNeurons = labelledNeurons(indicesCentroidsNuclei);
     
     neuronsToLabel = unique(nucleiBelongingToNeurons);
     
     
     
     for numNeuron = 1:length(neuronsToLabel)
         actualNeuron = neuronsToLabel(numNeuron);
         
         actualNuclei = remainingNucleiIDs(actualNeuron == nucleiBelongingToNeurons);
         zoneOverlapped = ismember(overlappingLabelled, actualNuclei).*overlappingLabelled;
         %areaPerNuclei = regionprops(, 'Area');
         areaPerNuclei = areaPerNuclei(actualNuclei).Area;
     end
     
     overlapping = double(finalNuclei)*2 + double(finalNeurons);
     colours = parula(4);
     figure('Visible', 'off'); imshow(overlapping+1, colours);
     hold on;
    viscircles(finalNeuronsCentroid, finalNucleiRadius, 'EdgeColor', 'r','LineWidth',0.3);
    colorbar('Ticks',[2,3,4]+0.5,...
         'TickLabels',{ 'Neurons', 'Nuclei', 'Neurons+Nuclei'});
    
    print(strcat(outputDir, '/nucleiNeuronsOverlapping.tif'), '-dtiff');
     
    %% Calculate density:
    % Cell per micra?
    
    zonesOfImage = ones(size(finalRedZone));
    zonesOfImage(finalRedZone == 0) = 3;
    zonesOfImage(borderRedZone) = 2;
    h=figure ('Visible', 'off');imshow(zonesOfImage,colorcube(3))
    hold on
    imshow(ImgComposite)
    hold off
    alpha(.7)
    
    print(strcat(outputDir, '/compositePerZones.tif'), '-dtiff');
    
    %Red zone density
    
    neuronsIndices = sub2ind(size(finalNeurons), round(finalNeuronsCentroid(:, 2)), round(finalNeuronsCentroid(:, 1)));
    hold on; viscircles(finalNeuronsCentroid, finalNucleiRadius, 'EdgeColor', 'r');

    print(strcat(outputDir, '/compositePerZonesWithNeurons.tif'), '-dtiff');
    
    %figure; imshow(ismember(labelledNeurons, neuronsInRedZone).*labelledNeurons, colorcube(200))
    densityInRedZone = sum(zonesOfImage(neuronsIndices) == 1)/redZoneAreaInMicrons;
    
    %Border of red zone
    densityAtBorder = length(zonesOfImage(neuronsIndices) == 2)/borderRedZoneAreaInMicrons;
    
    %Outside of the red zone
    densityInNoRedZone = length(zonesOfImage(neuronsIndices) == 3)/outsideRedZoneAreaInMicrons;
    
    close all
    
end