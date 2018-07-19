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
    
    numChannels = 4;
    radiusOverlapping = 1.3;
    
    pixelsOfSurroundingZone = 20;
    
    nucleiRadiusRangeInMicrons = [5, 12];
    nucleiRadiusRangeInPixels = round(nucleiRadiusRangeInMicrons ./ pixelWidthInMicrons);
    
    pathFileSplitted = strsplit(strrep(pathFile, '\', '/'), '/');
    outputDir = strcat('results/', strjoin(pathFileSplitted(end-3:end-1), '/'));
    mkdir(outputDir);

    %% Reading Raw images
        %% Getting the three necessary channels
    B=imread(pathFile);
    G=imread(strrep(pathFile,'C=0','C=1'));
    R=imread(strrep(pathFile,'C=0','C=2'));
    for nChan=1:numChannels
        imchan=imread(strrep(pathFile,'C=0',['C=' num2str(nChan)-1]));
        grayImages(:,:,nChan)=imchan(:,:,1)+imchan(:,:,2)+imchan(:,:,3);
        %to visualize image:
        %figure;imshow(double(mat2gray(grayImages(:,:,nChan),[0,255])))
    end
    ImgComposite=R+G+B;
    
    %% Segment red zone
    [finalRedZone,redZoneAreaInMicrons,outsideRedZoneAreaInMicrons] = segmentDamageRedZone(grayImages,minRedAreaPixels,pixelsOfSurroundingZone,pixelWidthInMicrons);
    
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