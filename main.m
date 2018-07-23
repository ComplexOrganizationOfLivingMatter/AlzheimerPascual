addpath(genpath('src'));
tifFiles = dir('Data/NeuN*/**/*.tif');

folderRows={tifFiles(:).folder}';
[~, indicesFiles]=unique(folderRows);

warning('off')

densityInRedZone=cell(size(indicesFiles,1),1);
densityInNoRedZone=cell(size(indicesFiles,1),1);
densityInPeripheryOfRedZone=cell(size(indicesFiles,1),1);
densityOutRedZoneAndPeripheryAnomaly=cell(size(indicesFiles,1),1);
ratioPlaquesDamage=cell(size(indicesFiles,1),1);
nameFolder=cell(size(indicesFiles,1),1);
nSample=cell(size(indicesFiles,1),1);

count=1;

for numFile = indicesFiles(1:end)'
    actualFile = tifFiles(numFile);
    
    splittedNames=strsplit(actualFile.folder,'\');
    
    nameFolder(count)=splittedNames(end-1);
    nSample(count)=splittedNames(end);
    disp([nameFolder{count} ' - ' nSample{count}])
    
    [densityInRedZone{count}, densityInNoRedZone{count},densityInPeripheryOfRedZone{count},densityOutRedZoneAndPeripheryAnomaly{count},ratioPlaquesDamage{count}] = processingImg(strcat(actualFile.folder, '/', actualFile.name));

    count=count+1;
end

tableResults=cell2table([nameFolder,nSample,densityInRedZone,densityInNoRedZone,...
    densityInPeripheryOfRedZone,densityOutRedZoneAndPeripheryAnomaly,ratioPlaquesDamage],'VariableNames',{'folder','numberOfSample','neuronsDensityInDamage','neuronsDensityInNoDamage','neuronsDensityPeripheryOfDamage','neuronsDensityOutOfDamagenAndPeriphery','ratioPlaquesDamage'});
writetable(tableResults, strcat('results/densityNeuronsPerRegion_', date, '.xlsx'))
warning('on')