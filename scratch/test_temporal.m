clear; clc;
ruta_base = 'C:\Users\crist\VideoImagen\proyectoVideo\escena2_1';
archivos = dir(fullfile(ruta_base, '*.png'));

img1 = imread(fullfile(ruta_base, archivos(1).name));
img_stack = zeros(size(img1,1), size(img1,2), length(archivos));
for f=1:length(archivos)
    img_stack(:,:,f) = double(rgb2gray(imread(fullfile(ruta_base, archivos(f).name))));
end
img_median = uint8(median(img_stack, 3));
I_med = medfilt2(img_median, [5 5]);
bg = double(median(I_med(:)));

% Toroides son blancos
light_mask = I_med > uint8(min(bg * 1.07, 255));
light_clean = bwareaopen(light_mask, 500);
light_fill = ~bwareaopen(~light_clean, 150); % rellenar huecos pequeños, preservar el del toroide

% Cubos/Monkeys son oscuros
dark_mask = I_med < uint8(bg * 0.85);
dark_clean = bwareaopen(dark_mask, 500);
dark_fill = imfill(dark_clean, 'holes');

% Combinar
I_bin = light_fill | dark_fill;
I_cerrada = imclose(I_bin, strel('disk', 6));
imagenD = bwareaopen(I_cerrada, 1000);

stats = regionprops(imagenD, 'Area', 'BoundingBox', 'Centroid', 'Solidity', 'EulerNumber');
fprintf('Objetos en Mediana Temporal:\n');
for i=1:length(stats)
    fprintf('Obj %d: Area=%.0f, Euler=%d, Solidez=%.2f, Centro=(%.0f, %.0f)\n', i, stats(i).Area, stats(i).EulerNumber, stats(i).Solidity, stats(i).Centroid(1), stats(i).Centroid(2));
end
