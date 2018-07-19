function [finalCentroidCircles, finalRadiusCircles] = intersectionNucleiNeuronsRecognition(nucleiWithNeuron,nucleiOriginalAdjusted,finalNeurons,ImgComposite,nucleiRadiusRangeInPixels,radiusOverlapping)

     originalImageOnlyRealNuclei = double(nucleiWithNeuron) .* double(nucleiOriginalAdjusted);
     originalImgNucleiAdjusted = imadjust(double(mat2gray(originalImageOnlyRealNuclei,[0,255])));
     figure('Visible', 'off'); imshow(ImgComposite)
     [centers, radii] = imfindcircles(originalImgNucleiAdjusted, nucleiRadiusRangeInPixels, 'Sensitivity', 0.95);
     %hold on; viscircles(centers, radii, 'EdgeColor', 'b');
     
     %Remove centroids not in the neurons images
     coordinatesNuclei = sub2ind(size(finalNeurons), round(centers(:, 2)), round(centers(:, 1)));
     
     goodNuclei = finalNeurons(coordinatesNuclei);
     
     hold on; viscircles(centers(goodNuclei, :), radii(goodNuclei), 'EdgeColor', 'b');
     
     %Remove overlapping centroids
     finalCentroidCircles = centers(goodNuclei, :);
     finalRadiusCircles = radii(goodNuclei);
     distanceBetweenRealNuclei = squareform(pdist(finalCentroidCircles));
     
     p2 = distanceBetweenRealNuclei <= (finalRadiusCircles*radiusOverlapping);
     [nuclei1, nuclei2] = find(p2);
     goodIndices = nuclei1 ~= nuclei2;
     goodYs = nuclei1(goodIndices);
     goodXs = nuclei2(goodIndices);
     
     overlappingCentroids = unique(sort([goodXs, goodYs], 2), 'rows');
     areaOfNuclei1 = zeros(size(finalNeurons));
     areaOfNuclei2 = zeros(size(finalNeurons));
     
     nucleiDuplicated = [];
     for numIndex = 1:size(overlappingCentroids, 1)
         centroidNuclei1 = round(finalCentroidCircles(overlappingCentroids(numIndex, 1), :));
         areaOfNuclei1(centroidNuclei1(1, 2), centroidNuclei1(1, 1)) = 1;
         radiusNuclei1 = bwdist(areaOfNuclei1) < (finalRadiusCircles(overlappingCentroids(numIndex, 1)));
         areaCoveringNuclei1 = sum(finalNeurons(radiusNuclei1));
         
         centroidNuclei2 = round(finalCentroidCircles(overlappingCentroids(numIndex, 2), :));
         areaOfNuclei2(centroidNuclei2(1, 2), centroidNuclei2(1, 1)) = 1;
         radiusNuclei2 = bwdist(areaOfNuclei2) < (finalRadiusCircles(overlappingCentroids(numIndex, 2)));
         
         areaCoveringNuclei2 = sum(finalNeurons(radiusNuclei2));
         
         if areaCoveringNuclei1 > areaCoveringNuclei2
             nucleiDuplicated(end+1) = overlappingCentroids(numIndex, 2);
         else
             nucleiDuplicated(end+1) = overlappingCentroids(numIndex, 1);
         end
     end
     
     finalCentroidCircles(nucleiDuplicated, :) = [];
     finalRadiusCircles(nucleiDuplicated) = [];
     
     hold on; viscircles(finalCentroidCircles, finalRadiusCircles, 'EdgeColor', 'r','LineWidth',0.3);
     print(strcat(outputDir, '/compositeWithNeurons.tif'), '-dtiff');
     
end

