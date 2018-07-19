function [finalNeurons,finalNuclei,nucleiWithNeuron] = segmentNeuronsAndNuclei(grayImages,minObjectSizeInPixels2Delete,outputDir)
    %Neurons
    originalNeurons = grayImages(:, :, 2);
    originalNeuronsAdjusted = adapthisteq(originalNeurons);
    neuronsAndMore = imbinarize(originalNeuronsAdjusted,'adaptive','Sensitivity',0.05);
    neuronsAndMoreAreaOpen = bwareaopen(neuronsAndMore, minObjectSizeInPixels2Delete);
    finalNeurons = imfill(neuronsAndMoreAreaOpen, 'holes');
    neuronsAndMoreErode=imerode(finalNeurons,strel('disk',2));
    finalNeurons=imdilate(neuronsAndMoreErode,strel('disk',2));
    finalNeurons = bwareaopen(finalNeurons, minObjectSizeInPixels2Delete, 4);
    
    %Nuclei
    nucleiOriginalAdjusted = adapthisteq(grayImages(:, :, 1));
    nucleiBinarized = imbinarize(nucleiOriginalAdjusted, 'adaptive');
    nucleiOpen = bwareaopen(nucleiBinarized, minObjectSizeInPixels2Delete);
    finalNuclei = imfill(nucleiOpen, 'holes');

    %Nuclei with Neurons
    nucleiWithNeuron = imreconstruct(finalNeurons, finalNuclei);
    nucleiWithNeuron = imfill(nucleiWithNeuron, 'holes');
    
    imwrite(finalNeurons, strcat(outputDir, '/neuronsSegmented.tif'));  
    imwrite(finalNuclei, strcat(outputDir, '/nucleiOfNeuronsSegmented.tif'));
     
end

