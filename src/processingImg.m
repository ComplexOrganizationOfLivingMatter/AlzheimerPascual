function [finalRedZone] = processingImg(pathFile)
%%PROCESSINGIMG
% Channel 1: Nuclei (Blue)
% Channel 2: Neurons (Green)
% Channel 3: Damage (Red)
% Channel 4: Perfusion (White)

    micronsOfSurroundingZone = 10;
    minSizeCellInMicrons = 25;
    minObjectSizeDeleteCellsInMicrons=5;
    
    pixelWidthInMicrons = 0.3031224;
    minCellSizeInPixels = ceil(minSizeCellInMicrons/pixelWidthInMicrons)^2;
    pixelsOfSurroundingZone = ceil(micronsOfSurroundingZone/pixelWidthInMicrons);
    minObjectSizeInPixels2Delete= ceil(minObjectSizeDeleteCellsInMicrons/pixelWidthInMicrons)^2;
    
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
    
    for nChan=1:4
        imchan=imread(strrep(pathFile,'C=0',['C=' num2str(nChan)-1]));
        grayImages(:,:,nChan)=imchan(:,:,1)+imchan(:,:,2)+imchan(:,:,3);
        %to visualize image:
        %figure;imshow(double(mat2gray(grayImages(:,:,nChan),[0,255])))
    end
    
    %% Damage zone (Channel 3)
    redZone = imbinarize(grayImages(:,:,3));
    redZoneFilled = imfill(redZone, 'holes');
    onlyRedZone = bwareafilt(redZoneFilled, 1);
    finalRedZone = imdilate(onlyRedZone, strel('disk', 5));
    finalRedZone = imfill(finalRedZone, 'holes');
    finalRedZone = imerode(finalRedZone, strel('disk', 5));
    
    %We catch a half of the red zone and half from outside perimeter it.
    perimeterRedZone=bwperim(finalRedZone);
    borderRedZone = imdilate(perimeterRedZone, strel('disk', round(pixelsOfSurroundingZone/2)));
    
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
    neuronsAndMoreAreaOpen = bwareaopen(neuronsAndMore,minObjectSizeInPixels2Delete);
    neuronsAndMoreFilled = imfill(neuronsAndMoreAreaOpen, 'holes');
    neuronsAndMoreErode=imerode(neuronsAndMoreFilled,strel('disk',2));
    neuronsAndMoreDilate=imdilate(neuronsAndMoreErode,strel('disk',2));

    %figure; imshow(neuronsAndMoreFilled)


    nuclei = imbinarize(grayImages(:, :, 1));
    nucleiOpen = bwareaopen(nuclei,minObjectSizeInPixels2Delete);

    %figure; imshow(nuclei);
    nucleiFilled = imfill(nucleiOpen, 'holes');
    
%     nucleiFilled = imfill(nuclei, 'holes');
%     nuclei = nucleiFilled;
%     distMatrix = bwdist(~nuclei);
%     distMatrix = -distMatrix;
%     distMatrix(~nuclei) = Inf;
%     nucleiWatersheded = watershed(distMatrix);
%     nucleiWatersheded(~nuclei) = 0;
%     figure; imshow(double(nucleiWatersheded))
    
    neuronsAndMoreFilled = bwareafilt(neuronsAndMoreFilled, [minCellSizeInPixels Inf]);

    %With segmented images works better
    nucleiWithNeuron = imreconstruct(neuronsAndMoreFilled, nucleiFilled);
    %figure; imshow(nucleiWithNeuron);
    %Remove smaller non-cell elements
    nucleiWithNeuronOnlyRealCells = bwareafilt(nucleiWithNeuron, [minCellSizeInPixels Inf]);
    
    labelledNeurons = bwlabel(nucleiWithNeuronOnlyRealCells);
    
    %% Calculate density:
    % Cell per micra? or all the space occupied by cells per micra?
    
    %Red zone density
    %neuronsInRedZone = unique(labelledNeurons.*finalRedZone);
    neuronsInRedZone = labelledNeurons.*finalRedZone;
    neuronsInRedZone = neuronsInRedZone(neuronsInRedZone~=0);
    %figure; imshow(ismember(labelledNeurons, neuronsInRedZone).*labelledNeurons, colorcube(200))
    densityInRedZone = length(neuronsInRedZone)/redZoneAreaInMicrons;
    
    %Border of red zone
    %neuronsAtBorder = unique(labelledNeurons.*borderRedZone);
    neuronsAtBorder = labelledNeurons.*borderRedZone;
    neuronsAtBorder = neuronsAtBorder(neuronsAtBorder~=0);
    densityAtBorder = length(neuronsAtBorder)/borderRedZoneAreaInMicrons;
    
    %Outside of the red zone
    %neuronsNoRedZone = unique(labelledNeurons.*(finalRedZone == 0));
    neuronsNoRedZone = labelledNeurons.*(finalRedZone == 0);
    neuronsNoRedZone = neuronsNoRedZone(neuronsNoRedZone~=0);
    densityInNoRedZone = length(neuronsNoRedZone)/outsideRedZoneAreaInMicrons;
    
end