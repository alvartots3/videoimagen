clear; clc;
img = imread('C:\Users\crist\VideoImagen\proyectoVideo\escena2_1\frame_0001.png');
I_gris = rgb2gray(img);
I_med = medfilt2(I_gris, [5 5]);

% Metodo 1: Canny + Relleno (bueno para formas completas si hay contraste)
bw_canny = edge(I_med, 'canny', [0.02 0.08]);
bw_canny_closed = imclose(bw_canny, strel('disk', 3));
bw_filled = imfill(bw_canny_closed, 'holes');

% Metodo 2: Umbral de Otsu con 3 clases (fondo, oscuro, claro)
thresh = multithresh(I_med, 2);
q = imquantize(I_med, thresh);
bw_otsu = (q == 1) | (q == 3); % oscuro y claro

% Metodo 3: Adaptativo
bw_adapt = imbinarize(I_med, 'adaptive', 'Sensitivity', 0.5);

figure('Visible','off');
subplot(2,2,1); imshow(img); title('Original');
subplot(2,2,2); imshow(bw_filled); title('Canny+Fill');
subplot(2,2,3); imshow(bw_otsu); title('Otsu 3 clases');
subplot(2,2,4); imshow(~bw_adapt); title('Adaptive (inv)');
saveas(gcf, 'scratch/test_segment.png');
