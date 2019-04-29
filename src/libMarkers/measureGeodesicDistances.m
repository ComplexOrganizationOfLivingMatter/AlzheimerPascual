function [cellDistances1_1,cellDistances1_2,cellDistances2_1,cellDistances2_2,cellDistances1_2aux,cellDistances2_1aux] = measureGeodesicDistances(coordMark1,coordMark2,maskROIpoly,auxCoordMark,coordRand)
   
    cellDistances1_2 = zeros(size(coordMark1,1),size(coordMark2,1));
    cellDistances1_1 = cell(size(coordMark1,1),1);
    cellDistances2_1 = cell(size(coordMark2,1),1);
    cellDistances2_2 = cell(size(coordMark2,1),1);

    indMark1 = sub2ind(size(maskROIpoly),coordMark1(:,1),coordMark1(:,2));
    indMark2 = sub2ind(size(maskROIpoly),coordMark2(:,1),coordMark2(:,2));    

    cellDistances1_2aux = zeros(size(coordMark1,1),size(coordMark2,1));
    cellDistances2_1aux = cell(size(coordMark2,1),1);
    indMarkAux = [];
    if contains(coordRand,'2') && ~isempty(auxCoordMark)
        indMarkAux = sub2ind(size(maskROIpoly),auxCoordMark(:,1),auxCoordMark(:,2));    
    end
    
    numOfDistances = 5;

    %tic
    parfor nCoord = 1 : size(coordMark2,1)
        indCoordRef = sub2ind(size(maskROIpoly),coordMark2(nCoord,1),coordMark2(nCoord,2));
        D = bwdistgeodesic(maskROIpoly,indCoordRef); 

        %distances from all 1 to this 2
        distMarkers1 = D(indMark1);
        cellDistances1_2(:,nCoord) = distMarkers1;

        %distances from this 2 to all 1
        distMark1 = sort(D(indMark1));
        cellDistances2_1{nCoord} = distMark1(1:numOfDistances);

        %distances from this 2 to the rest of 2
        distMark2 = sort(D(indMark2(indMark2~=indMark2(nCoord))));
        cellDistances2_2{nCoord} = distMark2(1:numOfDistances);         

        if contains(coordRand,'2') && ~isempty(auxCoordMark)
            %distances from all 1 aux to this 2
            distMarkers1aux = D(indMarkAux);
            cellDistances1_2aux(:,nCoord) = distMarkers1aux;

            %distances from this 2 to all 1 aux
            distMark1aux = sort(D(indMarkAux));
            cellDistances2_1aux{nCoord} = distMark1aux(1:numOfDistances);     
        end
    end
    cellDistances1_2 = sort(cellDistances1_2,2);
    cellDistances1_2 = cellDistances1_2(:,1:numOfDistances);
    cellDistances1_2 = mat2cell(cellDistances1_2,ones(size(cellDistances1_2,1),1),size(cellDistances1_2,2));

    if contains(coordRand,'2') && ~isempty(auxCoordMark)
        cellDistances1_2aux = sort(cellDistances1_2aux,2);
        cellDistances1_2aux = cellDistances1_2aux(:,1:numOfDistances);
        cellDistances1_2aux = mat2cell(cellDistances1_2aux,ones(size(cellDistances1_2aux,1),1),size(cellDistances1_2aux,2));
    end
end

