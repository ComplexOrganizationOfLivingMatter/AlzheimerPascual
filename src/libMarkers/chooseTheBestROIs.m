function chooseTheBestROIs(circularROIs)

    BestROIsBySample = cell(length(circularROIs),1);
    for nSample = 1:length(circularROIs)
        
        sampleCircROIs = circularROIs{nSample};
        
        bestROIbySize = zeros(4,4);
        for nSizeROI = 1:4
            propNoCaptMarkers = sampleCircROIs{nSizeROI,1};
            propROIsempty = sampleCircROIs{nSizeROI,2};
            propFilledArea = sampleCircROIs{nSizeROI,3};
            
            [~, id] = min(propNoCaptMarkers);
            
            bestROIbySize(nSizeROI,:) = [propNoCaptMarkers(id),propROIsempty(id),propFilledArea(id),id];
        end
        BestROIsBySample{nSample} = bestROIbySize;
    end
    
    meanBestProps = mean(cat(3,BestROIsBySample{:}),3);
    stdBestProps = std(cat(3,BestROIsBySample{:}),[],3);

end