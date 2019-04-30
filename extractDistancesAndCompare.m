pathFolders = dir('**/*.xls');
addpath(genpath('src'))

tableDistances = zeros(size(pathFolders,1),16);
for nFolder = size(pathFolders,1):-1:1

    path2load1 = [pathFolders(nFolder).folder,'\markerDistancesRaw.mat'];
    path2load2 = [pathFolders(nFolder).folder,'\markerDistancesFixed1Random2.mat'];
    path2load3 = [pathFolders(nFolder).folder,'\markerDistancesRandom1Fixed2.mat'];
    path2load4 = [pathFolders(nFolder).folder,'\markerDistancesRandom1Random2.mat'];
    imgInfo = imfinfo([pathFolders(nFolder).folder '\Image.tif']);

    resolution = imgInfo.XResolution; % X inches -> 1 pixel
    
    % 1 inch -> 25400 micrometers
    convertInch2Micr = 25400/1;
    %pixels * inches/pixels * micrometers/inches
    sizeXmicrons = imgInfo.Width * (1/resolution) * convertInch2Micr;
    sizeYmicrons = imgInfo.Height * (1/resolution) * convertInch2Micr;
    
    load(path2load1,'cellDistances1_1_raw','cellDistances1_2_raw','cellDistances2_1_raw','cellDistances2_2_raw')
    
    min1_2=cellfun(@(x) x(1),cellDistances1_2_raw);
    min2_1=cellfun(@(x) x(1),cellDistances2_1_raw);
    min2_2=cellfun(@(x) x(1),cellDistances2_2_raw);
    
    
    meanMinDistance1_2raw = mean(min1_2);
    stdMinDistance1_2raw = std(min1_2);
    meanMinDistance2_1raw = mean(min2_1);
    stdMinDistance2_1raw = std(min2_1);
    meanMinDistance2_2raw = mean(min2_2);
    stdMinDistance2_2raw = std(min2_2);
    
    %% Fixed 1 vs Random 2
    load(path2load2,'cellDistances2rand_1fixed','cellDistances1fixed_1fixed','cellDistances1fixed_2rand','cellDistances2rand_2rand')
    numRand = 200;size(cellDistances2rand_1fixed,1);
    min2rand_1fix = zeros(numRand,1);
    min1fix_2rand = zeros(numRand,1);
    min2rand_2rand = zeros(numRand,1);
    for nRand = 1 : numRand
        min2rand_1fix(nRand) = mean(cellfun(@(x) x(1),cellDistances2rand_1fixed{nRand}));
        min1fix_2rand(nRand) = mean(cellfun(@(x) x(1),cellDistances1fixed_2rand{nRand}));
        min2rand_2rand(nRand) = mean(cellfun(@(x) x(1),cellDistances2rand_2rand{nRand}));
    end
    
    meanMinDistance2rand_1fix = mean(min2rand_1fix);
    stdMinDistance2rand_1fix = std(min2rand_1fix);
    meanMinDistance1fix_2rand = mean(min1fix_2rand);
    stdMinDistance1fix_2rand = std(min1fix_2rand);
    meanMinDistance2rand_2rand = mean(min2rand_2rand);
    stdMinDistance2rand_2rand = std(min2rand_2rand);
    
    %% Random 1 vs Fixed 2
    load(path2load3,'cellDistances1rand_2fixed','cellDistances2fixed_1rand')
    min1rand_2fix = zeros(numRand,1);
    min2fix_1rand = zeros(numRand,1);
    for nRand = 1 : numRand
        min1rand_2fix(nRand) = mean(cellfun(@(x) x(1),cellDistances1rand_2fixed{nRand}));
        min2fix_1rand(nRand) = mean(cellfun(@(x) x(1),cellDistances2fixed_1rand{nRand}));
    end
    
    meanMinDistance1rand_2fix = mean(min1rand_2fix);
    stdMinDistance1rand_2fix = std(min1rand_2fix);
    meanMinDistance2fix_1rand = mean(min2fix_1rand);
    stdMinDistance2fix_1rand = std(min2fix_1rand);
    
    %% Random 1 vs Random 2
    load(path2load4,'cellDistances1rand_2rand','cellDistances2rand_1rand')

    min1rand_2rand = zeros(numRand,1);
    min2rand_1rand = zeros(numRand,1);
    for nRand = 1 : numRand
        min1rand_2rand(nRand) = mean(cellfun(@(x) x(1),cellDistances1rand_2rand{nRand}));
        min2rand_1rand(nRand) = mean(cellfun(@(x) x(1),cellDistances2rand_1rand{nRand}));
    end
    
    meanMinDistance1rand_2rand = mean(min1rand_2rand);
    stdMinDistance1rand_2rand = std(min1rand_2rand);
    meanMinDistance2rand_1rand = mean(min2rand_1rand);
    stdMinDistance2rand_1rand = std(min2rand_1rand);
    
    tableDistances(nFolder,:) = double([meanMinDistance1_2raw,stdMinDistance1_2raw,meanMinDistance2_1raw,stdMinDistance2_1raw,...
        meanMinDistance1fix_2rand,stdMinDistance1fix_2rand,meanMinDistance2rand_1fix,stdMinDistance2rand_1fix,...
        meanMinDistance1rand_2fix,stdMinDistance1rand_2fix,meanMinDistance2fix_1rand,stdMinDistance2fix_1rand,...
        meanMinDistance1rand_2rand,stdMinDistance1rand_2rand,meanMinDistance2rand_1rand,stdMinDistance2rand_1rand]);
end

T_distances = array2table(tableDistances,'VariableNames',{'mean1_2raw','std1_2raw','mean2_1raw','std2_1raw','mean1fix_2rand','std1fix_2rand',...
    'mean2rand_1fix','std2rand_1fix','mean1rand_2fix','std1rand_2fix','mean2fix_1rand','std2fix_1rand',...
    'mean1rand_2rand','std1rand_2rand','mean2rand_1rand','std2rand_1rand'});
writetable(T_distances,'results/tableMarkersDistances.xlsx')