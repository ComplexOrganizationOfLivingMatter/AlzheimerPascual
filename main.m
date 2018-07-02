
addpath(genpath('src'));
tifFiles = dir('Data/*.tif');

for numFile = 1:length(tifFiles)
    actualFile = tifFiles(numFile);
    segmentationRedZoneOfDamage(strcat(actualFile.folder, '/', actualFile.name));
end