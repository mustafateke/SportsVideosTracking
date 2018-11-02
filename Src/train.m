% Disclaimer
% This code is written under GPL as is and without warranty
% Please cite this code if you use.
% Author: Mustafa Teke, www.mustafateke.com, mustafa.teke@gmail.com
% 11.06.2011
clear
sName='Training-Camera3_short.avi';
% fInfo=aviinfo(sName);
rObj=mmreader(sName);
im0=read(rObj,1);
% d=aviread(sName);
% cdata = d.cdata;
se = strel('disk',3);
h=mexCvBSLib(im0);%Initialize
mexCvBSLib(im0,h,[0.01 4*4 1 0.5]);%set parameters
figure(1)

TeamA = 1;
TeamB = 2;
Refree = 3;
Ball = 4;

global training;
global group;
for i=1:rObj.NumberOfFrames
    d=read(rObj,i);

    imMask=mexCvBSLib(d,h);
    
    imMask = imclose(imMask,se);
    imMask = imopen(imMask,se);
    
    bwIm = im2bw(imMask);
    cc = bwconncomp(bwIm);
    if (cc.NumObjects > 0 )
        labeled = labelmatrix(cc);
        [rows, cols] = size (bwIm);
        playerMaskA = zeros(size (bwIm) );
        playerMaskB = zeros(size (bwIm) );
        ballMask = zeros(size (bwIm) );
        stats = regionprops(labeled, 'Area', 'MajorAxisLength','MinorAxisLength','BoundingBox','PixelList' );
        for object = 1:size(stats, 1)
%             tim2 = zeros(size(d));
            if(stats(object).Area > 10 )% && (stats(object).MajorAxisLength/stats(object).MinorAxisLength) > 2 )
                x = stats(object).BoundingBox(1, 1);
                y = stats(object).BoundingBox(1, 2);
                width = stats(object).BoundingBox(1, 3);
                height = stats(object).BoundingBox(1, 4);
                pixelList = stats(object).PixelList;
                numPixels = size(pixelList, 1);
                pixels = zeros(numPixels, 3);
                for pixel=1:numPixels
                    row = pixelList(pixel, 2);
                    col = pixelList(pixel, 1);
                    pixels(pixel, :) = d(row, col, :);
                end
                histR = imhist(pixels(:, 1)/255.0);
                meanR = mean(pixels(:, 1));
                histG = imhist(pixels(:, 2)/255.0);
                meanG = mean(pixels(:, 2));
                histB = imhist(pixels(:, 3)/255.0);
                meanB = mean(pixels(:, 3));
                playerMaskA(y:y+height, x:x+width) = object;
                imwrite(d(y:y+height, x:x+width, :), [num2str(i) '_' num2str(object) '.jpg' ] );
                imshow(d(y:y+height, x:x+width, :));
                means =[ meanR meanG meanB];
                stdVal = std(means);
                feature = [means stdVal]
                numSamples = size(training, 1)
                
                a = 1;
            end
            
            if(stats(object).Area < 150) % && (stats(object).MajorAxisLength/stats(object).MinorAxisLength) < 2 )
                x = stats(object).BoundingBox(1, 1);
                y = stats(object).BoundingBox(1, 2);
                width = stats(object).BoundingBox(1, 3);
                height = stats(object).BoundingBox(1, 4);
                ballMask(y:y+height, x:x+width) = object;
            end
        end

        
    end

end
mexCvBSLib(h);%Release memory