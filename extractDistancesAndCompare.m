pathFolders = dir('**/*.xls');
addpath(genpath('src'))

tableDistancesMeans = zeros(size(pathFolders,1),16);

tableDistancesStds = zeros(size(pathFolders,1),16);


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
    pixels2microns = 1 * (1/resolution) * convertInch2Micr;
    
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
    numRand = size(cellDistances2rand_1fixed,1);
    meanMin2rand_1fix = zeros(numRand,1);
    meanMin1fix_2rand = zeros(numRand,1);
    meanMin2rand_2rand = zeros(numRand,1);
    stdMin2rand_1fix = zeros(numRand,1);
    stdMin1fix_2rand = zeros(numRand,1);
    stdMin2rand_2rand = zeros(numRand,1);
    for nRand = 1 : numRand
        meanMin2rand_1fix(nRand) = mean(cellfun(@(x) x(1),cellDistances2rand_1fixed{nRand}));
        stdMin2rand_1fix(nRand) = std(cellfun(@(x) x(1),cellDistances2rand_1fixed{nRand}));
        meanMin1fix_2rand(nRand) = mean(cellfun(@(x) x(1),cellDistances1fixed_2rand{nRand}));
        stdMin1fix_2rand(nRand) = std(cellfun(@(x) x(1),cellDistances1fixed_2rand{nRand}));
        meanMin2rand_2rand(nRand) = mean(cellfun(@(x) x(1),cellDistances2rand_2rand{nRand}));
        stdMin2rand_2rand(nRand) = std(cellfun(@(x) x(1),cellDistances2rand_2rand{nRand}));

    end
    
    meanMeansMinDistance2rand_1fix = mean(meanMin2rand_1fix);
    stdMeansMinDistance2rand_1fix = std(meanMin2rand_1fix);
    meanMeansMinDistance1fix_2rand = mean(meanMin1fix_2rand);
    stdMeansMinDistance1fix_2rand = std(meanMin1fix_2rand);
    
    meanStdsMinDistance2rand_1fix = mean(stdMin2rand_1fix);
    stdStdsMinDistance2rand_1fix = std(stdMin2rand_1fix);
    meanStdsMinDistance1fix_2rand = mean(stdMin1fix_2rand);
    stdStdsMinDistance1fix_2rand = std(stdMin1fix_2rand);
    
    %% Random 1 vs Fixed 2
    load(path2load3,'cellDistances1rand_2fixed','cellDistances2fixed_1rand')
    meanMin1rand_2fix = zeros(numRand,1);
    meanMin2fix_1rand = zeros(numRand,1);
    stdMin1rand_2fix = zeros(numRand,1);
    stdMin2fix_1rand = zeros(numRand,1);
    for nRand = 1 : numRand
        meanMin1rand_2fix(nRand) = mean(cellfun(@(x) x(1),cellDistances1rand_2fixed{nRand}));
        stdMin1rand_2fix(nRand) = std(cellfun(@(x) x(1),cellDistances1rand_2fixed{nRand}));
        meanMin2fix_1rand(nRand) = mean(cellfun(@(x) x(1),cellDistances2fixed_1rand{nRand}));
        stdMin2fix_1rand(nRand) = std(cellfun(@(x) x(1),cellDistances2fixed_1rand{nRand}));
    end
    
%     h = figure('units','normalized','outerposition',[0 0 1 1],'Visible','on');
%     histogram(meanMin1rand_2fix.*pixels2microns,'Normalization','probability','FaceAlpha',1)%,'BinWidth',5,'BinLimits',[200 2000]
%     hold on 
%     plot(meanMinDistance1_2raw.*pixels2microns,0.005,'.r','MarkerSize',20)
%     legend({'random integrin fixed plaques','raw'},'Location','best')
%     xlabel('mean distance (micrometers)')
%     ylabel('probability')
%     spName = strsplit(pathFolders(nFolder).folder,'\');
%     title([lower(spName{end}) ' - distances from integrins to plaques'])
%     set(gca,'FontSize', 24,'FontName','Helvetica','YGrid','on','TickDir','out','Box','off');
%     print(h,[pathFolders(nFolder).folder '\histogramDistances_' lower(spName{end}) '_' date],'-dtiff','-r300')
%     close all
    
    meanMeansMinDistance1rand_2fix = mean(meanMin1rand_2fix);
    stdMeansMinDistance1rand_2fix = std(meanMin1rand_2fix);
    meanMeansMinDistance2fix_1rand = mean(meanMin2fix_1rand);
    stdMeansMinDistance2fix_1rand = std(meanMin2fix_1rand);
    
    meanStdsMinDistance1rand_2fix = mean(stdMin1rand_2fix);
    stdStdsMinDistance1rand_2fix = std(stdMin1rand_2fix);
    meanStdsMinDistance2fix_1rand = mean(stdMin2fix_1rand);
    stdStdsMinDistance2fix_1rand = std(stdMin2fix_1rand);
    
    
    %% Random 1 vs Random 2
    load(path2load4,'cellDistances1rand_2rand','cellDistances2rand_1rand')

    meanMin1rand_2rand = zeros(numRand,1);
    meanMin2rand_1rand = zeros(numRand,1);
    stdMin1rand_2rand = zeros(numRand,1);
    stdMin2rand_1rand = zeros(numRand,1);
    for nRand = 1 : numRand
        meanMin1rand_2rand(nRand) = mean(cellfun(@(x) x(1),cellDistances1rand_2rand{nRand}));
        stdMin1rand_2rand(nRand) = std(cellfun(@(x) x(1),cellDistances1rand_2rand{nRand}));
        meanMin2rand_1rand(nRand) = mean(cellfun(@(x) x(1),cellDistances2rand_1rand{nRand}));
        stdMin2rand_1rand(nRand) = std(cellfun(@(x) x(1),cellDistances2rand_1rand{nRand}));
    end
    
    meanMeansMinDistance1rand_2rand = mean(meanMin1rand_2rand);
    stdMeansMinDistance1rand_2rand = std(meanMin1rand_2rand);
    meanMeansMinDistance2rand_1rand = mean(meanMin2rand_1rand);
    stdMeansMinDistance2rand_1rand = std(meanMin2rand_1rand);
    
    meanStdsMinDistance1rand_2rand = mean(stdMin1rand_2rand);
    stdStdsMinDistance1rand_2rand = std(stdMin1rand_2rand);
    meanStdsMinDistance2rand_1rand = mean(stdMin2rand_1rand);
    stdStdsMinDistance2rand_1rand = std(stdMin2rand_1rand);
    
    tableDistancesMeans(nFolder,:) = double([meanMinDistance1_2raw,stdMinDistance1_2raw,meanMinDistance2_1raw,stdMinDistance2_1raw,...
        meanMeansMinDistance1fix_2rand,stdMeansMinDistance1fix_2rand,meanMeansMinDistance2rand_1fix,stdMeansMinDistance2rand_1fix,...
        meanMeansMinDistance1rand_2fix,stdMeansMinDistance1rand_2fix,meanMeansMinDistance2fix_1rand,stdMeansMinDistance2fix_1rand,...
        meanMeansMinDistance1rand_2rand,stdMeansMinDistance1rand_2rand,meanMeansMinDistance2rand_1rand,stdMeansMinDistance2rand_1rand]);
    
    tableDistancesStds(nFolder,:) = double([meanMinDistance1_2raw,stdMinDistance1_2raw,meanMinDistance2_1raw,stdMinDistance2_1raw,...
        meanStdsMinDistance1fix_2rand,stdStdsMinDistance1fix_2rand,meanStdsMinDistance2rand_1fix,stdStdsMinDistance2rand_1fix,...
        meanStdsMinDistance1rand_2fix,stdStdsMinDistance1rand_2fix,meanStdsMinDistance2fix_1rand,stdStdsMinDistance2fix_1rand,...
        meanStdsMinDistance1rand_2rand,stdStdsMinDistance1rand_2rand,meanStdsMinDistance2rand_1rand,stdStdsMinDistance2rand_1rand]);
    
end

T_MeanDistances = array2table(tableDistancesMeans.*pixels2microns,'VariableNames',{'mean1_2raw','std1_2raw','mean2_1raw','std2_1raw','meanMeans1fix_2rand','stdMeans1fix_2rand',...
    'meanMeans2rand_1fix','stdMeans2rand_1fix','meanMeans1rand_2fix','stdMeans1rand_2fix','meanMeans2fix_1rand','stdMeans2fix_1rand',...
    'meanMeans1rand_2rand','stdMeans1rand_2rand','meanMeans2rand_1rand','stdMeans2rand_1rand'});

T_StdDistances = array2table(tableDistancesStds(:,5:end).*pixels2microns,'VariableNames',{'meanStds1fix_2rand','stdStds1fix_2rand',...
    'meanStds2rand_1fix','stdStds2rand_1fix','meanStds1rand_2fix','stdStds1rand_2fix','meanStds2fix_1rand','stdStds2fix_1rand',...
    'meanStds1rand_2rand','stdStds1rand_2rand','meanStds2rand_1rand','stdStds2rand_1rand'});

% writetable([T_MeanDistances,T_StdDistances],'results/tableMarkersDistances.xlsx')