function [BW_img] = segmentationRedZoneOfDamage(pathFile)

    rawImg=imfinfo(pathFile);
    for k = 1:length(rawImg)
        rgbImage(:,:,k) = double(imread(pathFile,k));
        figure; imshow(rgbImage(:,:,k));
    end
    figure; imshow(rgbImage)

end