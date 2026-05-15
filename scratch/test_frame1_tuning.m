clear; clc;
img1 = imread('C:\Users\crist\VideoImagen\proyectoVideo\escena2_1\frame_0001.png');
I_gris = rgb2gray(img1);
I_med = medfilt2(I_gris, [5 5]);

bg = double(median(I_med(:)));

% Ajustamos umbrales para no romper los toroides
dark_mask  = I_med < uint8(bg * 0.85); % un poco más relajado
light_mask = I_med > uint8(min(bg * 1.02, 255)); % muy cerca del fondo para capturar toda el área blanca
I_bin = dark_mask | light_mask;

inv       = ~I_bin;
inv_clean = bwareaopen(inv, 150);
I_rellena = ~inv_clean;

I_cerrada = imclose(I_rellena, strel('disk', 8)); % Cierre más fuerte para unir

imagenD = bwareaopen(I_cerrada, 1000); % Objetos pequeños son ruido

stats = regionprops(imagenD, 'Area', 'EulerNumber', 'Centroid', 'BoundingBox');

fprintf('Objetos en Frame 1:\n');
for i=1:length(stats)
    fprintf('Obj %d: Area=%.0f, Euler=%d, Centro=(%.0f, %.0f)\n', i, stats(i).Area, stats(i).EulerNumber, stats(i).Centroid(1), stats(i).Centroid(2));
end
