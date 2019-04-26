function [plaqueDetection] = plaquesSegmentation(grayImages,finalRedZone)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    % Detecting plaque and removing it from red zone
    perfusionChannel = imbinarize(adapthisteq(grayImages(:,:,4)));%, 'adaptive', 'Sensitivity', 0.2);
    plaqueDetection = perfusionChannel & finalRedZone; %imbinarize(adapthisteq(grayImages(:,:,1)), 'adaptive')
    plaqueDetection = bwareaopen(plaqueDetection, 20);
    plaqueDetection = imdilate(plaqueDetection, strel('disk', 5));
    plaqueDetection = imfill(plaqueDetection, 'holes');
    plaqueDetection = imerode(plaqueDetection, strel('disk', 5));
    %plaqueDetection = bwareaopen(plaqueDetection, 20);
    plaqueDetection = bwareaopen(plaqueDetection, 500);
    
    plaquesRegion = regionprops(plaqueDetection, 'all');
    plaquesElongated = [vertcat(plaquesRegion.MinorAxisLength) ./ vertcat(plaquesRegion.MajorAxisLength) > 0.30];
    plaqueDetection = ismember(bwlabel(plaqueDetection), find(plaquesElongated));
    
    % Using the nuclei channel to detect the plaque
    plaqueDetectionRec = imreconstruct(plaqueDetection,imbinarize(adapthisteq(grayImages(:,:,4)), 'adaptive','Sensitivity',0.2));
    
    plaqueDetection = plaqueDetection | plaqueDetectionRec;
    plaqueDetection = imfill(plaqueDetection, 'holes');
    
%     plaqueDetection = plaqueDetection & finalNuclei;
%     figure;imshow(plaqueDetection)
%     close
    
    plaqueDetection = bwareaopen(plaqueDetection, 400);
    plaqueDetection = imerode(plaqueDetection, strel('disk', 8));
    plaqueDetection = imfill(plaqueDetection, 'holes');
    plaqueDetection = imdilate(plaqueDetection, strel('disk', 8));
    
    plaquesRegion = regionprops(plaqueDetection, 'all');
    plaquesElongated = vertcat(plaquesRegion.MinorAxisLength)>35 & [vertcat(plaquesRegion.MinorAxisLength)  ./ vertcat(plaquesRegion.MajorAxisLength) > 0.30];
    plaqueDetection = ismember(bwlabel(plaqueDetection), find(plaquesElongated));
    
    plaqueDetection = imdilate(plaqueDetection, strel('disk', 10));
    plaqueDetection = imfill(plaqueDetection, 'holes');
    plaqueDetection = imerode(plaqueDetection, strel('disk', 10));
    
end

