addpath(genpath('src'));
tifFiles = dir('Data/NeuN*/**/*.tif');

folderRows={tifFiles(:).folder}';
[~, indicesFiles]=unique(folderRows);

warning('off')

densityInRedZone=cell(size(indicesFiles,1),1);
densityInNoRedZone=cell(size(indicesFiles,1),1);
nameFolder=cell(size(indicesFiles,1),1);
nSample=cell(size(indicesFiles,1),1);

count=1;

for numFile = indicesFiles(1:end)'
    actualFile = tifFiles(numFile);
    
    splittedNames=strsplit(actualFile.folder,'\');
    
    nameFolder(count)=splittedNames(end-1);
    nSample(count)=splittedNames(end);
    disp([nameFolder{count} ' - ' nSample{count}])
    
    [densityInRedZone{count}, densityInNoRedZone{count}] = processingImg(strcat(actualFile.folder, '/', actualFile.name));

    count=count+1;
end

tableResults=cell2table([nameFolder,nSample,densityInRedZone,densityInNoRedZone],'VariableNames',{'folder','numberOfSample','neuronsDensityInDamage','neuronsDensityInNoDamage'});
writetable(tableResults, strcat('results/densityNeuronsPerRegion_', date, '.xlsx'))
warning('on')