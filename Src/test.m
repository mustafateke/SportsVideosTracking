% Disclaimer
% This code is written under GPL as is and without warranty
% Please cite this code if you use.
% Author: Mustafa Teke, www.mustafateke.com, mustafa.teke@gmail.com
% 11.06.2011
clear
sName='Testing-Camera3_short.avi';
% fInfo=aviinfo(sName);
rObj=mmreader(sName);
im0=read(rObj,1);
% d=aviread(sName);
% cdata = d.cdata;
se = strel('disk',3);
h=mexCvBSLib(im0);%Initialize
mexCvBSLib(im0,h,[0.01 4*4 1 0.5]);%set parameters
figure(1)
global training;
global group;
classColors(1,:) = [1 1 1];
classColors(2,:) = [1 0 0];
classColors(3,:) = [0 0 0];
classColors(4,:) = [0 1 1];

for i=1:rObj.NumberOfFrames
    d=read(rObj,i);
    %     d=aviread(sName,i);
    imMask=mexCvBSLib(d,h);
    
    imMask = imclose(imMask,se);
    imMask = imopen(imMask,se);
    
    bwIm = im2bw(imMask);
    cc = bwconncomp(bwIm);
    samples = zeros(0, 4);
    if (cc.NumObjects > 0 )
        labeled = labelmatrix(cc);
        [rows, cols] = size (bwIm);
        playerMaskA = zeros(size (bwIm) );
        playerMaskB = zeros(size (bwIm) );
        ballMask = zeros(size (bwIm) );
        stats = regionprops(labeled, 'Area', 'MajorAxisLength','MinorAxisLength','BoundingBox','PixelList' );
        
        boundingBoxes = zeros(0, 4);
        areas = zeros(0, 4);
        for object = 1:size(stats, 1)
            %             tim2 = zeros(size(d));
            if(stats(object).Area > 100 && (stats(object).MajorAxisLength/stats(object).MinorAxisLength) > 1.5 )
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
                %                 imwrite(d(y:y+height, x:x+width, :), [num2str(i) '_' num2str(object) '.jpg' ] );
                means =[ meanR meanG meanB];
                stdVal = std(means);
                feature = [means stdVal];
                
                numSamples = size(samples, 1);
                samples(numSamples +1,:) = feature;
                areas(numSamples +1,:) = feature;
                boundingBoxes(numSamples +1,:) = stats(object).BoundingBox;
                
                if(stats(object).Area > 25 && stats(object).Area < 100 && (stats(object).MajorAxisLength/stats(object).MinorAxisLength) < 1.5 )
                    x = stats(object).BoundingBox(1, 1);
                    y = stats(object).BoundingBox(1, 2);
                    width = stats(object).BoundingBox(1, 3);
                    height = stats(object).BoundingBox(1, 4);
                    ballMask(y:y+height, x:x+width) = object;
                    
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
                    
                    means =[ meanR meanG meanB];
                    stdVal = std(means);
                    feature = [means stdVal];
                    
                    numSamples = size(samples, 1);
                    samples(numSamples +1,:) = feature;
                    areas(numSamples +1,:) = feature;
                    boundingBoxes(numSamples +1,:) = stats(object).BoundingBox;
                end
            end
            
            
            
            %         d(:,:, 3) = d(:,:, 3) + uint8(255*playerMask);
            RGB_label_player = label2rgb(playerMaskA, @copper, 'k', 'shuffle');
            RGB_label_ball = label2rgb(ballMask, @copper, 'k', 'shuffle');
            %RGB_label = label2rgb(labeled, @copper, 'c', 'shuffle');
            % figure, imshow(RGB_label,'InitialMagnification','fit')
            d(:,:, 3) = d(:,:, 3) + rgb2gray(RGB_label_player);
            rgb_ball_lbl = rgb2gray(RGB_label_ball);
            d(:,:, 1) = d(:,:, 1) + rgb_ball_lbl(1:rows, 1:cols)  ;
            imshow(d);
            
            %% Draw Results
            c = knnclassify(samples, training, group, 3, 'correlation');
            numClasses = size(c, 1);
            for rectNum=1:numClasses
                
                if(areas(rectNum) > 100 && c(rectNum, 1) == 4 )
                    c(rectNum, 1) = 1;
                elseif (areas(rectNum) < 100 && c(rectNum, 1) == 1 )
                    c(rectNum, 1) = 4;
                end
                
                rectangle('Position',boundingBoxes(rectNum, :),'Curvature',[1,1],...
                    'EdgeColor',classColors(c(rectNum, 1), :));
                
            end
            
            
            imshow(d);
        end
    end
end
mexCvBSLib(h);%Release memory