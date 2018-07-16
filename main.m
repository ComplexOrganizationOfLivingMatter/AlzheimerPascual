addpath(genpath('src'));
tifFiles = dir('Data\NeuN*\**\*.tif');

folderRows={tifFiles(:).folder}';
namesRows={tifFiles(:).name}';
[~, indicesFiles]=unique(folderRows);
a=namesRows(indicesFiles);
for numFile = indicesFiles'
    actualFile = tifFiles(numFile);
    processingImg(strcat(actualFile.folder, '/', actualFile.name));
end