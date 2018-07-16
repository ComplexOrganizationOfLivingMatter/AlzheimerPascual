function [finalRedZone] = processingImg(pathFile)
%%PROCESSINGIMG
% Channel 1: Nuclei (Blue)
% Channel 2: Neurons (Green)
% Channel 3: Damage (Red)
% Channel 4: Perfusion (White)
    for nChan=1:4
        imchan=imread(strrep(pathFile,'C=0',['C=' num2str(nChan)-1]));
        grayImages(:,:,nChan)=imchan;
    end
    
    micronsOfSurroundingZone = 10;
    minSizeCellInMicrons = 3;
    
    pixelWidthInMicrons = 0.3031224;
    minCellSizeInPixels = ceil(minSizeCellInMicrons/pixelWidthInMicrons)^2;
    pixelsOfSurroundingZone = ceil(micronsOfSurroundingZone/pixelWidthInMicrons);

    %% Getting all the initial information
    rawImg=imfinfo(pathFile);
    maxValue = 4095;
    for numChannel = 1:length(rawImg)
         actualImgChannel = imread(pathFile,numChannel);
         rawImages(:, :, numChannel) = actualImgChannel;
         
         %Transform them to gray
         actualImgChannelGray = ind2rgb(actualImgChannel, gray(maxValue));
         actualImgChannelGray = actualImgChannelGray(:, :, 1);
         
         grayImages(:,:,numChannel) = actualImgChannelGray;
    end
    
    %% Damage zone (Channel 3)
    redZone = imbinarize(grayImages(:,:,3));
    redZoneFilled = imfill(redZone, 'holes');
    onlyRedZone = bwareafilt(redZoneFilled, 1);
    finalRedZone = imdilate(onlyRedZone, strel('disk', 2));
    finalRedZone = imfill(finalRedZone, 'holes');
    
    redZoneDilated = imdilate(finalRedZone, strel('disk', round(pixelsOfSurroundingZone/2)));
    redZoneEroded = imerode(finalRedZone, strel('disk', round(pixelsOfSurroundingZone/2)));
    %We catch a half of the red zone and half from outside it.
    borderRedZone = ~redZoneEroded & redZoneDilated;
    
    redZoneAreaInMicrons = sum(finalRedZone(:)) * pixelWidthInMicrons;
    %CARE: surrounding to red zone and outside red zone overlap between
    %each other
    borderRedZoneAreaInMicrons = sum(borderRedZone(:)) * pixelWidthInMicrons;
    outsideRedZoneAreaInMicrons = sum(finalRedZone(:) == 0) * pixelWidthInMicrons;
    
%     figure; imshow(finalRedZone)
%     figure; imshow(surroundingToRedZone)
    
    %
    %% Locate neurons (Channel 1 and 2)
%     figure; imshow(grayImages(:,:,1))
%     figure; imshow(grayImages(:,:,2))
    neuronsAndMore = imbinarize(grayImages(:, :, 2),'global');
    %figure; imshow(neuronsAndMore)
    neuronsAndMoreFilled = imfill(neuronsAndMore, 'holes');
    
    nuclei = imbinarize(grayImages(:, :, 1),'adaptive','Sensitivity',0.05);
    %figure; imshow(nuclei);
    nucleiFilled = imfill(nuclei, 'holes');
    
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