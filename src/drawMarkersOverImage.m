function drawMarkersOverImage(img,T,convertInch2Micr,resolution,pathFolders,nFolder)

    %select each marker    
    indMark1 = cellfun(@(x) contains(lower(x),'mark 1'),T.Var1);
    indMark2 = cellfun(@(x) contains(lower(x),'mark 2'),T.Var1);
    indMark3 = cellfun(@(x) contains(lower(x),'mark 3'),T.Var1);
    indPos = cellfun(@(x) contains(lower(x),'pos'),T.Var1);
    
    %pos centroids
    centroidXYPos = [vertcat(T.PosX),vertcat(T.PosY)];
    centroidXYPos = centroidXYPos(indPos,:);
    centroidXYPos = centroidXYPos( ~isnan(centroidXYPos(:,1))|~isnan(centroidXYPos(:,2)),:);

    %markers coordinates
    coordXYMarkers = [vertcat(T.X),vertcat(T.Y)];
    coordMark1 = coordXYMarkers(indMark1,:);
    coordMark1 = coordMark1( ~isnan(coordMark1(:,1))|~isnan(coordMark1(:,2)),:);
    
    coordMark2 = coordXYMarkers(indMark2,:);
    coordMark2 = coordMark2( ~isnan(coordMark2(:,1))|~isnan(coordMark2(:,2)),:);

    coordMark3 = coordXYMarkers(indMark3,:);
    coordMark3 = coordMark3( ~isnan(coordMark3(:,1))|~isnan(coordMark3(:,2)),:);   
    
    %% convert micrometers to pixels to match with the image
    %micrometers * inches/micrometers * pixels/inches 
    coordMark1Pixels = coordMark1.* ((1/convertInch2Micr) *(resolution));
    coordMark2Pixels = coordMark2.* ((1/convertInch2Micr) *(resolution));
    coordMark3Pixels = coordMark3.* ((1/convertInch2Micr) *(resolution));
    centroidXYPosPixels = centroidXYPos.* ((1/convertInch2Micr) *(resolution));
    
    if min([coordMark1Pixels(:,1);coordMark2Pixels(:,1);coordMark3Pixels(:,1);centroidXYPosPixels(:,1)]) < 0
       setupX = 1 + abs(min([coordMark1Pixels(:,1);coordMark2Pixels(:,1);coordMark3Pixels(:,1);centroidXYPosPixels(:,1)]));
    else
        if size(img,2)< max(coordMark1Pixels(:,1))
            setupX = -1 + size(img,2) - round(max(round([coordMark1Pixels(:,1);coordMark2Pixels(:,1);coordMark3Pixels(:,1);centroidXYPosPixels(:,1)])));
        else
            setupX = 0;
        end
    end
    if min([coordMark1Pixels(:,2);coordMark2Pixels(:,2);coordMark3Pixels(:,2);centroidXYPosPixels(:,2)]) < 0
       setupY = 1 + abs(min([coordMark1Pixels(:,2);coordMark2Pixels(:,2);coordMark3Pixels(:,2);centroidXYPosPixels(:,2)]));
    else
        if size(img,1)< max([coordMark1Pixels(:,2);coordMark2Pixels(:,2);coordMark3Pixels(:,2);centroidXYPosPixels(:,2)])
           setupY = -1 + size(img,1) - max(round([coordMark1Pixels(:,2);coordMark2Pixels(:,2);coordMark3Pixels(:,2);centroidXYPosPixels(:,2)]));
        else
           setupY = 0;
        end
    end
    
    
    
    %% Plot initial markers
    
    imgMarkers = zeros(size(img));
    indMark2 = sub2ind(size(img(:,:,1)),round(coordMark2Pixels(:,2)+setupY),round(coordMark2Pixels(:,1)+setupX));
    indMark1 = sub2ind(size(img(:,:,1)),round(coordMark1Pixels(:,2)+setupY),round(coordMark1Pixels(:,1)+setupX));
    indMark3 = sub2ind(size(img(:,:,1)),round(coordMark3Pixels(:,2)+setupY),round(coordMark3Pixels(:,1)+setupX));
    
    R = zeros(size(img(:,:,1))); 
    G = R;
    B = R;
    R(indMark1) = 255;
    G(indMark3) = 255;
    B(indMark2) = 255;

    imgMarkers(:,:,1) = R;
    imgMarkers(:,:,2) = G;
    imgMarkers(:,:,3) = B;
    imgMarkers(imgMarkers>0) = 255;
    imwrite(flipud(imgMarkers),[pathFolders(nFolder).folder '\markers.tiff'])   
    
    R_dil = imdilate(R,strel('disk',10));
    G(indMark3) = 255;
    G_dil = imdilate(G,strel('disk',10));
    B(indMark2) = 255;
    B_dil = imdilate(B,strel('disk',10));

    imgMarkers(:,:,1) = R_dil;
    imgMarkers(:,:,2) = G_dil;
    imgMarkers(:,:,3) = B_dil;
    imgMarkers(imgMarkers>0) = 255;
    
    imwrite(flipud(imgMarkers),[pathFolders(nFolder).folder '\bigMarkers.tiff']) 
    

end

