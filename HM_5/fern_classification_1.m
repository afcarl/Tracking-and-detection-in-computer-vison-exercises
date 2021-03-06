
load('ferns_system_200_4000_class.mat');

normsys = normalize_fern_training_system(fern_training_system);

% Points that the classifier was trained on
Image_orig = rgb2gray(imread('img1.ppm'));
trained_corners = corner(Image_orig, 'Harris', 200);
first_image_class_amount = size(trained_corners, 1);

% New image.
Image = rgb2gray(imread('img2.ppm'));
corners_to_classify = corner(Image, 'Harris', 300);
amount_of_classes = size(corners_to_classify, 1);

Image_tmp = padarray(Image,[30 30],'symmetric');


%% Display selected points.


figure, imshow(Image);
hold on;

for i = 1:amount_of_classes
    plot(corners_to_classify(i, 1), corners_to_classify(i, 2), 'o');
end


%% Retrieve patches around possible points

patch_size = [30 30];
patch_of_original_big_images = zeros(patch_size(1), patch_size(2), amount_of_classes);

for current_point_number = 1:amount_of_classes
    
    col = corners_to_classify(current_point_number, 1) + 30;
    row = corners_to_classify(current_point_number, 2) + 30;

    image_patch = Image_tmp( (row-patch_size/2):(row+patch_size/2)-1, (col-patch_size/2):(col+patch_size/2)-1);
    patch_of_original_big_images(:, :, current_point_number) = image_patch;
end

% demo
%imshow(uint8(patch_of_original_big_images(:, :, 3)))

%% Classify points based on extracted patches

class_correspondence = zeros(first_image_class_amount, 2, 'double');

for current_point_number = 1:amount_of_classes
    
    current_point_patch = patch_of_original_big_images(:, :, current_point_number);
    posteriors = classify_using_fern_system(normsys, current_point_patch(:)');
    maximum = find(posteriors==max(posteriors));
    most_probable_class = maximum(1);
    
    if class_correspondence(most_probable_class, 2) < posteriors(most_probable_class)
        class_correspondence(most_probable_class, 1) = current_point_number;
        class_correspondence(most_probable_class, 2) = posteriors(most_probable_class);
    end
    
end

%% Create matching array. First row point of first image, second row corresponding point from second image.

matched_amount = sum(class_correspondence(:, 1) > 0);
matches = zeros(2, matched_amount);
matched_pair_count = 1;

for i = 1:first_image_class_amount
    
    if class_correspondence(i, 1) > 0
        matches(1, matched_pair_count) = i;
        matches(2, matched_pair_count) = class_correspondence(i, 1);
        matched_pair_count = matched_pair_count + 1;
    end
end

%% 

trained_corners = trained_corners';
corners_to_classify = corners_to_classify';

S =[];

S(1, :) = trained_corners(1, matches(1, :));
S(2, :) = trained_corners(2, matches(1, :));
S(3, :) = corners_to_classify(1,matches(2, :));
S(4, :) = corners_to_classify(2,matches(2, :));

%[H Si] = RANSAC_DLT(S, 5, 1, 70, 50);
[H Si] = RANSAC_adaptive(S, 5, 10, 0.99);

im1 = Image_orig;
im2 = Image;


T = maketform('projective', H');

[im2t, xdataim2t, ydataim2t] = imtransform(im1, T);
xdataout=[min(1,xdataim2t(1)) max(size(im2, 2),xdataim2t(2))];
ydataout=[min(1,ydataim2t(1)) max(size(im2, 1),ydataim2t(2))];

im2t=imtransform(im1,T,'XData',xdataout,'YData',ydataout);
im1t=imtransform(im2,maketform('affine',eye(3)),'XData',xdataout,'YData',ydataout);

ims=im1t/2+im2t/2;
figure, imshow(ims)


