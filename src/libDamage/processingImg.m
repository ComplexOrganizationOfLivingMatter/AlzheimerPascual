function [densityInRedZone, densityInNoRedZone, densityInPeripheryOfRedZone,densityOuterPeripheryAnomaly,ratioPlaquesDamage] = processingImg(pathFile)
%%PROCESSINGIMG 
% Channel 1: Nuclei (Blue)
% Channel 2: Neurons (Green)
% Channel 3: Damage (Red)
% Channel 4: Perfusion (White)

    %% Initial variables
    minRedAreaPixels=6000;
    %1024 pixels -> 310.40 microns. 1 pixel -> ~0.3 microns
    pixelWidthInMicrons = 0.3031224;
    %Minimum size of the objects to delete in pixels
    minObjectSizeInPixels2Delete= round(pi*(7.5^2));
    
    %Number of channels
    numChannels = 5;
    %To remove overlapping circular neurons
    radiusOverlapping = 1.3;
    
    %Periphery variables
    radiusInMicronsPeripheryAnomaly=50;
    radiusInPixelsPeripheryAnomaly=radiusInMicronsPeripheryAnomaly/pixelWidthInMicrons;
     
    %The radius for the function imfindcircles
    nucleiRadiusRangeInMicrons = [5, 12];
    nucleiRadiusRangeInPixels = round(nucleiRadiusRangeInMicrons ./ pixelWidthInMicrons);
    
    pathFileSplitted = strsplit(strrep(pathFile, '\', '/'), '/');
    outputDir = strcat('results/', strjoin(pathFileSplitted(end-3:end-1), '/'));
    mkdir(outputDir);

    %% Reading Raw images
    % Getting the three necessary channels
    B=imread(pathFile);
    G=imread(strrep(pathFile,'C=0','C=1'));
    R=imread(strrep(pathFile,'C=0','C=2'));
    for nChan=1:numChannels
        try
            imchan=imread(strrep(pathFile,'C=0',['C=' num2str(nChan)-1]));
            grayImages(:,:,nChan)=imchan(:,:,1)+imchan(:,:,2)+imchan(:,:,3);
            %to visualize image:
            %figure;imshow(double(mat2gray(grayImages(:,:,nChan),[0,255])))
        catch
        end
    end
    ImgComposite=R+G+B;
    
    %% Getting invalid region
    if size(grayImages,3) == 5
        invalidRegion = grayImages(:, :, 5);
        invalidRegion = invalidRegion>0;
        invalidRegionAreaInMicrons = sum(invalidRegion(:)) * pixelWidthInMicrons^2;
        for numChannel = 1:numChannels-1
            actualChannel = grayImages(:, :, numChannel);
            actualChannel(invalidRegion) = 0;
            grayImages(:, :, numChannel) = actualChannel;
        end
    else
        invalidRegion = zeros(size(grayImages(:, :, 1)));
        invalidRegionAreaInMicrons = 0;
    end
    
    %% Segment red zone
    [finalRedZone,redZoneAreaInMicrons,outsideRedZoneAreaInMicrons,plaqueDetection,peripheryOfAnomaly] = segmentDamageRedZone(grayImages,minRedAreaPixels,pixelWidthInMicrons,radiusInPixelsPeripheryAnomaly,outputDir);
    
    %% Segment neurons and nuclei
    [finalNeurons,finalNuclei,nucleiWithNeuron] = segmentNeuronsAndNuclei(grayImages,minObjectSizeInPixels2Delete,outputDir);
    
    %% Get intersection of neurons with nuclei
    [finalCentroidCircles, finalRadiusCircles] = intersectionNucleiNeuronsRecognition(outputDir, grayImages, nucleiWithNeuron,finalNeurons,ImgComposite,nucleiRadiusRangeInPixels,radiusOverlapping);
    
    %% Get neuron+nucleus that were not assigned in the circular shape recognition
    [finalCentroidCircles,finalRadiusCircles] = reassigningNotRecognizedNucleiNeurons(finalNuclei,finalNeurons,nucleiRadiusRangeInPixels,finalCentroidCircles,finalRadiusCircles,outputDir);
    
    %% Final Representation
    zonesOfImage = ones(size(finalRedZone));
    if contains(lower(pathFile), 'wt') == 0
        zonesOfImage(finalRedZone == 0) = 5;
        zonesOfImage(plaqueDetection>0) = 8;
        zonesOfImage(peripheryOfAnomaly>0) = 4;
    end
    zonesOfImage(logical(invalidRegion)) = 10;
    c=jet(10);
    c(5,:)=[230,255,242]/255;
    figure('Visible', 'off');
    imshow(zonesOfImage, c)
    hold on;
    mask2Show=ImgComposite(:,:,3);
    mask2Show(plaqueDetection>0)=0;
    imshow(cat(3,ImgComposite(:,:,1:2),mask2Show));
    hold off
    alpha(.7)
    print(strcat(outputDir, '/compositePerZones.tif'), '-dtiff');
    
    neuronsIndices = sub2ind(size(finalNeurons), round(finalCentroidCircles(:, 2)), round(finalCentroidCircles(:, 1)));
    hold on; viscircles(finalCentroidCircles, finalRadiusCircles, 'EdgeColor', 'r');

    print(strcat(outputDir, '/compositePerZonesWithNeurons.tif'), '-dtiff');
    
    %% Get density neurons per zone
    plaquesAreaInMicrons = sum(plaqueDetection(:)) * pixelWidthInMicrons^2;
    peripheryOfRedZoneInMicrons = sum(peripheryOfAnomaly(:)) * pixelWidthInMicrons^2;
    outsideRedZoneAreaInMicrons = outsideRedZoneAreaInMicrons - invalidRegionAreaInMicrons - plaquesAreaInMicrons;
    % If the image belongs to WT, it does not have red damage
    if contains(lower(pathFile), 'wt') == 0
        densityInRedZone = sum(zonesOfImage(neuronsIndices) == 1)/redZoneAreaInMicrons;

        %Outside of the red zone
        densityInPeripheryOfRedZone = sum(zonesOfImage(neuronsIndices) == 4)/(peripheryOfRedZoneInMicrons);
        densityInNoRedZone = (sum(zonesOfImage(neuronsIndices) == 5) + sum(zonesOfImage(neuronsIndices) == 4)) /(outsideRedZoneAreaInMicrons);
        densityOuterPeripheryAnomaly=sum(zonesOfImage(neuronsIndices) == 5)/(outsideRedZoneAreaInMicrons-peripheryOfRedZoneInMicrons);
        
        %ratio area of plaques and damage
        ratioPlaquesDamage=sum(plaqueDetection(:))/sum(finalRedZone(:));
    else
        %The image neurons density
        densityInNoRedZone = sum(zonesOfImage(neuronsIndices) > 0) / (redZoneAreaInMicrons + outsideRedZoneAreaInMicrons);
        densityInRedZone = 0;
        densityInPeripheryOfRedZone=0;
        densityOuterPeripheryAnomaly=0;
        ratioPlaquesDamage=0;
    end

    close all
end