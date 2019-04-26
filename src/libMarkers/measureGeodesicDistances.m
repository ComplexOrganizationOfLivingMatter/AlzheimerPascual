function [cellDistances1_1_raw,cellDistances1_2_raw,cellDistances2_1_raw,cellDistances2_2_raw] = measureGeodesicDistances(coordMark1,coordMark2,maskROIpoly,typeImg)
    cellDistances1_2_raw = cell(size(coordMark1,1),1);
    cellDistances1_1_raw = cell(size(coordMark1,1),1);
    cellDistances2_1_raw = cell(size(coordMark2,1),1);
    cellDistances2_2_raw = cell(size(coordMark2,1),1);

    indMark1 = sub2ind(size(maskROIpoly),coordMark1(:,1),coordMark1(:,2));
    indMark2 = sub2ind(size(maskROIpoly),coordMark2(:,1),coordMark2(:,2));    
    
        
    %if we want the distances between the markers 1 use the raw option.
    if contains(lower(typeImg),'distmarkers1')
%         tic
%         parfor nCoord = 1 : size(coordMark1,1)
%             indCoordRef = sub2ind(size(maskROIpoly),coordMark1(nCoord,1),coordMark1(nCoord,2));
%             D = bwdistgeodesic(maskROIpoly,indCoordRef); 
%             cellDistances1_2_raw{nCoord} = sort(D(indMark2));
%             cellDistances1_1_raw{nCoord} = sort(D(indMark1(indMark1~=indMark1(nCoord))));
%         end
% 
%         parfor nCoord = 1 : size(coordMark2,1)
%             indCoordRef = sub2ind(size(maskROIpoly),coordMark2(nCoord,1),coordMark2(nCoord,2));
%             D = bwdistgeodesic(maskROIpoly,indCoordRef); 
%             cellDistances2_1_raw{nCoord} = sort(D(indMark1));
%             cellDistances2_2_raw{nCoord} = sort(D(indMark2(indMark2~=indMark2(nCoord))));         
%         end
%         toc
    %if we DO NOT need the distances between the markers 1....
    else
        
        cellDistances1_2_raw = zeros(size(coordMark1,1),size(coordMark2,1));
        %tic
        parfor nCoord = 1 : size(coordMark2,1)
            indCoordRef = sub2ind(size(maskROIpoly),coordMark2(nCoord,1),coordMark2(nCoord,2));
            D = bwdistgeodesic(maskROIpoly,indCoordRef); 
            distMarkers1 = D(indMark1);
            cellDistances1_2_raw(:,nCoord) = distMarkers1;
            cellDistances2_1_raw{nCoord} = sort(D(indMark1));
            cellDistances2_2_raw{nCoord} = sort(D(indMark2(indMark2~=indMark2(nCoord))));         
        end
        cellDistances1_2_raw = sort(cellDistances1_2_raw,2);
        cellDistances1_2_raw = mat2cell(cellDistances1_2_raw,ones(size(cellDistances1_2_raw,1),1),size(cellDistances1_2_raw,2));
        %toc
    end
end

