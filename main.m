addpath(genpath('src'));
tifFiles = dir('Data/NeuN*/**/*.tif');

folderRows={tifFiles(:).folder}';
[~, indicesFiles]=unique(folderRows);

for numFile = indicesFiles(2:end)'
    actualFile = tifFiles(numFile);
    processingImg(strcat(actualFile.folder, '/', actualFile.name));
end