
addpath(genpath('src'));
tifFiles = dir('Data/*.tif');


for numFile = 1:length(tifFiles)
    
    actualFile = tifFiles(numFile);
    processingImg(strcat(actualFile.folder, '/', actualFile.name));
end