function [BW_img] = segmentationRedZoneOfDamage(pathFile)

    rawImg=imread(pathFile);
    open(pathFile,1);
    load(pathFile);
    rgbImg=ind2rgb(cdata,colormap);

end