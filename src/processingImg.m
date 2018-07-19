function [densityInRedZone, densityInNoRedZone] = processingImg(pathFile)
%%PROCESSINGIMG
% Channel 1: Nuclei (Blue)
% Channel 2: Neurons (Green)
% Channel 3: Damage (Red)
% Channel 4: Perfusion (White)

    %% Initial variables
    minRedAreaPixels=8000;
    pixelWidthInMicrons = 0.3031224;
    minObjectSizeInPixels2Delete= round(pi*(7.5^2));
    
    pixelsOfSurroundingZone = 20;
    
    nucleiRadiusRangeInMicrons = [5, 10];
    nucleiRadiusRangeInPixels = round(nucleiRadiusRangeInMicrons ./ pixelWidthInMicrons);
    
    pathFileSplitted = strsplit(strrep(pathFile, '\', '/'), '/');
    outputDir = strcat('results/', strjoin(pathFileSplitted(end-3:end-1), '/'));
    
    mkdir(outputDir);

    %% Getting the three necessary channels
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
    
    %Remove the plaque from the red zone 
    
    
    %% Locate neurons (Channel 1 and 2)
    originalNeurons = grayImages(:, :, 2);
    originalNeuronsAdjusted = adapthisteq(originalNeurons);
    neuronsAndMore = imbinarize(originalNeuronsAdjusted,'adaptive','Sensitivity',0.05);
    neuronsAndMoreAreaOpen = bwareaopen(neuronsAndMore, minObjectSizeInPixels2Delete);
    finalNeurons = imfill(neuronsAndMoreAreaOpen, 'holes');
    neuronsAndMoreErode=imerode(finalNeurons,strel('disk',2));
    finalNeurons=imdilate(neuronsAndMoreErode,strel('disk',2));
    finalNeurons = bwareaopen(finalNeurons, minObjectSizeInPixels2Delete, 4);
    figure;imshow(finalNeurons);
    
     %% Nuclei
     nucleiOriginalAdjusted = adapthisteq(grayImages(:, :, 1)); %grayImages(:, :, 1);
     nucleiBinarized = imbinarize(nucleiOriginalAdjusted, 'adaptive');
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
     finalCentroidCircles = centers(goodNuclei, :);
     finalRadiusCircles = radii(goodNuclei);
     distanceBetweenRealNuclei = squareform(pdist(finalCentroidCircles));
     
     p2 = distanceBetweenRealNuclei <= (finalRadiusCircles);
     [nuclei1, nuclei2] = find(p2);
     goodIndices = nuclei1 ~= nuclei2;
     goodYs = nuclei1(goodIndices);
     goodXs = nuclei2(goodIndices);
     
     overlappingCentroids = unique(sort([goodXs, goodYs], 2), 'rows');
     areaOfNuclei1 = zeros(size(finalNeurons));
     areaOfNuclei2 = zeros(size(finalNeurons));
     
     nucleiDuplicated = [];
     for numIndex = 1:size(overlappingCentroids, 1)
         centroidNuclei1 = round(finalCentroidCircles(overlappingCentroids(numIndex, 1), :));
         areaOfNuclei1(centroidNuclei1(1, 2), centroidNuclei1(1, 1)) = 1;
         radiusNuclei1 = bwdist(areaOfNuclei1) < finalRadiusCircles(overlappingCentroids(numIndex, 1));
         areaCoveringNuclei1 = sum(finalNeurons(radiusNuclei1));
         
         centroidNuclei2 = round(finalCentroidCircles(overlappingCentroids(numIndex, 2), :));
         areaOfNuclei2(centroidNuclei2(1, 2), centroidNuclei2(1, 1)) = 1;
         radiusNuclei2 = bwdist(areaOfNuclei2) < finalRadiusCircles(overlappingCentroids(numIndex, 2));
         
         areaCoveringNuclei2 = sum(finalNeurons(radiusNuclei2));
         
         if areaCoveringNuclei1 > areaCoveringNuclei2
             nucleiDuplicated(end+1) = overlappingCentroids(numIndex, 2);
         else
             nucleiDuplicated(end+1) = overlappingCentroids(numIndex, 1);
         end
     end
     
     finalCentroidCircles(nucleiDuplicated, :) = [];
     finalRadiusCircles(nucleiDuplicated) = [];
     
     hold on; viscircles(finalCentroidCircles, finalRadiusCircles, 'EdgeColor', 'r','LineWidth',0.3);
     print(strcat(outputDir, '/compositeWithNeurons.tif'), '-dtiff');
     
     %% Exist some nuclei+neurons within a neuron unassigned with a circle
     % Remove overlapping areas very small
     overlappingNeuronsAndNuclei = finalNuclei & finalNeurons;
     overlappingLabelled = bwlabel(overlappingNeuronsAndNuclei);
     overlappingNeuronsAndNucleiEroded = imerode(overlappingNeuronsAndNuclei, strel('disk', round(nucleiRadiusRangeInPixels(1)/3)));
     biggerAreasOfOverlapping = unique(overlappingLabelled .* overlappingNeuronsAndNucleiEroded);
     overlappingLabelled  = ismember(overlappingLabelled, biggerAreasOfOverlapping) .* overlappingLabelled;
     
     % Obtaining centroids of circles
     indicesFinalNeuronsCentroid = sub2ind(size(overlappingLabelled), round(finalCentroidCircles(:, 2)), round(finalCentroidCircles(:, 1)));
     circleImg = zeros(size(overlappingLabelled));
     
     
     labelledNeurons = bwlabel(finalNeurons);
     imageNotMarkedNuclei = labelledNeurons;
    %Removing nucleis+neurons from red circles
    idNeurons2delete=[];
     for numFinalNuclei = 1:size(finalCentroidCircles, 1)
         circleImg(indicesFinalNeuronsCentroid(numFinalNuclei)) = 1;
         circleImgDilated = imdilate(circleImg, strel('disk', round(finalRadiusCircles(numFinalNuclei))));
         idNeurons=unique(labelledNeurons(logical(circleImgDilated)));
         idNeurons2delete=[idNeurons2delete;idNeurons];
         circleImg(indicesFinalNeuronsCentroid(numFinalNuclei)) = 0;
     end
     idNeurons2delete=unique(idNeurons2delete);
     idNeurons2delete=idNeurons2delete(idNeurons2delete~=0);
     imageNotMarkedNuclei(ismember(imageNotMarkedNuclei,idNeurons2delete))=0;
     overlappingNNIsolated=imageNotMarkedNuclei.*(overlappingLabelled>0);%NN = nuclei + neurons

     %When some nuclei belong to the same neuron, we will only count 1
     %neuron
     newNeurons = regionprops(overlappingNNIsolated, {'Centroid', 'MajorAxisLength'});
     newNeurons = newNeurons(unique(overlappingNNIsolated(overlappingNNIsolated~=0)));
     finalCentroidCircles = [finalCentroidCircles; vertcat(newNeurons.Centroid)];
     finalRadiusCircles = [finalRadiusCircles; vertcat(newNeurons.MajorAxisLength)/2];
     
     
     overlapping = double(finalNuclei)*2 + double(finalNeurons);
     colours = parula(4);
     figure('Visible', 'off'); imshow(overlapping+1, colours);
     hold on;
    viscircles(finalCentroidCircles, finalRadiusCircles, 'EdgeColor', 'r','LineWidth',0.3);
    colorbar('Ticks',[2,3,4]+0.5,...
         'TickLabels',{ 'Neurons', 'Nuclei', 'Neurons+Nuclei'});
    
    print(strcat(outputDir, '/nucleiNeuronsOverlapping.tif'), '-dtiff');
     
    %% Calculate density:
    % Cell per micra
    
    zonesOfImage = ones(size(finalRedZone));
    zonesOfImage(finalRedZone == 0) = 2;
%     zonesOfImage(borderRedZone) = 2;
    h=figure ('Visible', 'off');imshow(zonesOfImage,colorcube(2))
    hold on
    imshow(ImgComposite)
    hold off
    alpha(.7)
    
    print(strcat(outputDir, '/compositePerZones.tif'), '-dtiff');
    
    %Red zone density
    
    neuronsIndices = sub2ind(size(finalNeurons), round(finalCentroidCircles(:, 2)), round(finalCentroidCircles(:, 1)));
    hold on; viscircles(finalCentroidCircles, finalRadiusCircles, 'EdgeColor', 'r');

    print(strcat(outputDir, '/compositePerZonesWithNeurons.tif'), '-dtiff');
    
    if contains(lower(pathFile), 'wt') == 0
        %figure; imshow(ismember(labelledNeurons, neuronsInRedZone).*labelledNeurons, colorcube(200))
        densityInRedZone = sum(zonesOfImage(neuronsIndices) == 1)/redZoneAreaInMicrons;

        %Outside of the red zone
        densityInNoRedZone = length(zonesOfImage(neuronsIndices) == 3)/outsideRedZoneAreaInMicrons;
    else
        densityInRedZone = length(zonesOfImage(neuronsIndices) > 0) / (redZoneAreaInMicrons + outsideRedZoneAreaInMicrons);
        densityInNoRedZone = 0;
    end

    
    close all
    
end