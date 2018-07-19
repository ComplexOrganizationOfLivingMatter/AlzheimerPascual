function finalNuclei = segmentNuclei(grayImages,minObjectSizeInPixels2Delete)
 
    nucleiOriginalAdjusted = adapthisteq(grayImages(:, :, 1));
    nucleiBinarized = imbinarize(nucleiOriginalAdjusted, 'adaptive');
    nucleiOpen = bwareaopen(nucleiBinarized, minObjectSizeInPixels2Delete);
    finalNuclei = imfill(nucleiOpen, 'holes');
    %figure;imshow(nucleiOpen);
        
end

