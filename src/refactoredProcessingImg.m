function [densityInRedZone, densityInNoRedZone] = refactoredProcessingImg(pathFile)

    %%PROCESSINGIMG
    % Channel 1: Nuclei (Blue)
    % Channel 2: Neurons (Green)
    % Channel 3: Damage (Red)
    % Channel 4: Perfusion (White)

    %% Initial variables
    minRedAreaPixels=8000;
    pixelWidthInMicrons = 0.3031224;
    minObjectSizeInPixels2Delete= round(pi*(7.5^2));
    
    radiusOverlapping = 1.3;
    
    pixelsOfSurroundingZone = 20;
    
    nucleiRadiusRangeInMicrons = [5, 12];
    nucleiRadiusRangeInPixels = round(nucleiRadiusRangeInMicrons ./ pixelWidthInMicrons);
    
    pathFileSplitted = strsplit(strrep(pathFile, '\', '/'), '/');
    outputDir = strcat('results/', strjoin(pathFileSplitted(end-3:end-1), '/'));
    mkdir(outputDir);

    %% Reading Raw images
    [R,G,B,grayImages,ImgComposite] = readImagesPerChannels(pathFile);
    
    
    %% Segment red zone
    [finalRedZone,redZoneAreaInMicrons,outsideRedZoneAreaInMicrons] = segmentDamageRedZone(grayImages,minRedAreaPixels,pixelsOfSurroundingZone,pixelWidthInMicrons);
    
    %% Remove plaques
    
    %% Segment neurons and nuclei
    [finalNeurons,finalNuclei,nucleiWithNeuron] = segmentNeuronsAndNuclei(grayImages,minObjectSizeInPixels2Delete,outputDir);

    %% Get intersection of neurons with nuclei
    [finalCentroidCircles, finalRadiusCircles] = intersectionNucleiNeuronsRecognition(nucleiWithNeuron,nucleiOriginalAdjusted,finalNeurons,ImgComposite,nucleiRadiusRangeInPixels,radiusOverlapping);
    
    %% Get neuron+nucleus that were not assigned in the circular shape recognition
    [finalCentroidCircles,finalRadiusCircles] = reassigningNotRecognizedNucleiNeurons(finalNuclei,finalNeurons,nucleiRadiusRangeInPixels,finalCentroidCircles,finalRadiusCircles,outputDir);

    %Final Representation
    zonesOfImage = ones(size(finalRedZone));
    zonesOfImage(finalRedZone == 0) = 2;
    figure('Visible', 'off');
    imshow(zonesOfImage,colorcube(2))
    hold on;imshow(ImgComposite);hold off
    alpha(.7)
    print(strcat(outputDir, '/compositePerZones.tif'), '-dtiff');
    
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