function [BW_img] = segmentationRedZoneOfDamage(pathFile)
    % Channel 1: Neurons
    % Channel 2: Nuclei
    % Channel 3: Damage
    % Channel 4: Perfusion 

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
    
end