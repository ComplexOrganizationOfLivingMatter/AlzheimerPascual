function [finalCentroidCircles,finalRadiusCircles] = reassigningNotRecognizedNucleiNeurons(finalNuclei,finalNeurons,nucleiRadiusRangeInPixels,finalCentroidCircles,finalRadiusCircles,outputDir)
    %% Exist some nuclei+neurons within a neuron unassigned with a circle
     % Remove overlapping areas very small
     overlappingNeuronsAndNuclei = finalNuclei & finalNeurons;
     overlappingLabelled = bwlabel(overlappingNeuronsAndNuclei);
     overlappingNeuronsAndNucleiEroded = imerode(overlappingNeuronsAndNuclei, strel('disk', round(nucleiRadiusRangeInPixels(1)/3)));
     biggerAreasOfOverlapping = unique(overlappingLabelled .* overlappingNeuronsAndNucleiEroded);
     overlappingLabelled  = ismember(overlappingLabelled, biggerAreasOfOverlapping) .* overlappingLabelled;
     
     % Obtaining centroids of circles
     indicesFinalNeuronsCentroid = sub2ind(size(overlappingLabelled), round(finalCentroidCircles(:, 2)), round(finalCentroidCircles(:, 1)));
     circleImg = zeros(size(overlappingLabelled));
     
     labelledNeurons = bwlabel(finalNeurons);
     imageNotMarkedNuclei = labelledNeurons;
    %Removing nucleis+neurons from red circles
    idNeurons2delete=[];
     for numFinalNuclei = 1:size(finalCentroidCircles, 1)
         circleImg(indicesFinalNeuronsCentroid(numFinalNuclei)) = 1;
         circleImgDilated = imdilate(circleImg, strel('disk', round(finalRadiusCircles(numFinalNuclei))));
         idNeurons=unique(labelledNeurons(logical(circleImgDilated)));
         idNeurons2delete=[idNeurons2delete;idNeurons];
         circleImg(indicesFinalNeuronsCentroid(numFinalNuclei)) = 0;
     end
     idNeurons2delete=unique(idNeurons2delete);
     idNeurons2delete=idNeurons2delete(idNeurons2delete~=0);
     imageNotMarkedNuclei(ismember(imageNotMarkedNuclei,idNeurons2delete))=0;
     overlappingNNIsolated=imageNotMarkedNuclei.*(overlappingLabelled>0);%NN = nuclei + neurons

     %When some nuclei belong to the same neuron, we will only count 1
     %neuron
     newNeurons = regionprops(overlappingNNIsolated, {'Centroid', 'MajorAxisLength'});
     newNeurons = newNeurons(unique(overlappingNNIsolated(overlappingNNIsolated~=0)));
     finalCentroidCircles = [finalCentroidCircles; vertcat(newNeurons.Centroid)];
     finalRadiusCircles = [finalRadiusCircles; vertcat(newNeurons.MajorAxisLength)/2];
     
     
     overlapping = double(finalNuclei)*2 + double(finalNeurons);
     colours = parula(4);
     figure('Visible', 'off'); imshow(overlapping+1, colours);
     hold on;
    viscircles(finalCentroidCircles, finalRadiusCircles, 'EdgeColor', 'r','LineWidth',0.3);
    colorbar('Ticks',[2,3,4]+0.5,...
         'TickLabels',{ 'Neurons', 'Nuclei', 'Neurons+Nuclei'});
    
    print(strcat(outputDir, '/nucleiNeuronsOverlapping.tif'), '-dtiff');
     
end

