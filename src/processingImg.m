function [finalRedZone] = processingImg(pathFile)
%%PROCESSINGIMG
% Channel 1: Nuclei (Blue)
% Channel 2: Neurons (Green)
% Channel 3: Damage (Red)
% Channel 4: Perfusion (White)

    pixelWidthInMicrons = 0.3031224;
    minCellSizeInPixels = 3/pixelWidthInMicrons;

    %Getting all the initial information
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
    
    %Damage zone (Channel 3)
    redZone = imbinarize(grayImages(:,:,3));
    redZoneFilled = imfill(redZone, 'holes');
    onlyRedZone = bwareafilt(redZoneFilled, 1);
    finalRedZone = imdilate(onlyRedZone, strel('disk', 2));
    
    %Locate neurons (Channel 1 and 2)
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
    
    %With segmented images works better
    nucleiWithNeuron = imreconstruct(neuronsAndMoreFilled, nucleiFilled);
    figure; imshow(nucleiWithNeuron);
    %Remove smaller non-cell elements
    bwareafilt(nucleiWithNeuron, [minCellSizeInPixels Inf]);
    
    %works worse
    %figure; imshow(imreconstruct(grayImages(:, :, 2), grayImages(:, :,
    %1)))
    
    %Calculate density
    
    
end