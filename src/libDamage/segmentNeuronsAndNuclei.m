function [finalNeurons,finalNuclei,nucleiWithNeuron] = segmentNeuronsAndNuclei(grayImages,minObjectSizeInPixels2Delete,outputDir)
%%SEGMENTNEURONSANDNUCLEI Segmentation of neurons and nuclei channels   
% 

    %% Neurons
    %Pre-processing
    originalNeurons = grayImages(:, :, 2);
    originalNeuronsAdjusted = adapthisteq(originalNeurons);
    %Segmentation
    neuronsAndMore = imbinarize(originalNeuronsAdjusted, 'adaptive', 'Sensitivity',0.05);
    %Post-processing
    neuronsAndMoreAreaOpen = bwareaopen(neuronsAndMore, minObjectSizeInPixels2Delete);
    finalNeurons = imfill(neuronsAndMoreAreaOpen, 'holes');
    neuronsAndMoreErode=imerode(finalNeurons,strel('disk',2));
    finalNeurons=imdilate(neuronsAndMoreErode,strel('disk',2));
    finalNeurons = bwareaopen(finalNeurons, minObjectSizeInPixels2Delete, 4);
    
    %% Nuclei
    %Pre-processing
    nucleiOriginalAdjusted = adapthisteq(grayImages(:, :, 1));
    %Segment
    nucleiBinarized = imbinarize(nucleiOriginalAdjusted, 'adaptive');
    %Post-processing
    nucleiOpen = bwareaopen(nucleiBinarized, minObjectSizeInPixels2Delete);
    finalNuclei = imfill(nucleiOpen, 'holes');

    %% Coupling nuclei with neurons
    nucleiWithNeuron = imreconstruct(finalNeurons, finalNuclei);
    nucleiWithNeuron = imfill(nucleiWithNeuron, 'holes');
    
    imwrite(finalNeurons, strcat(outputDir, '/neuronsSegmented.tif'));  
    imwrite(finalNuclei, strcat(outputDir, '/nucleiOfNeuronsSegmented.tif'));
     
end

