clear; clc;
img1 = imread('C:\Users\crist\VideoImagen\proyectoVideo\escena2_1\frame_0001.png');
I_gris = rgb2gray(img1);
I_med = medfilt2(I_gris, [5 5]);

bg = double(median(I_med(:)));

dark_mask  = I_med < uint8(bg * 0.82);
light_mask = I_med > uint8(min(bg * 1.07, 255));
I_bin = dark_mask | light_mask;

inv       = ~I_bin;
inv_clean = bwareaopen(inv, 150);
I_rellena = ~inv_clean;

% En lugar de disk 4, usamos disk 12 para fusionar fragmentos del mismo objeto
I_cerrada = imclose(I_rellena, strel('disk', 15));

imagenD = bwareaopen(I_cerrada, 1000);

stats = regionprops(imagenD, 'Area', 'BoundingBox', 'Centroid', 'Solidity', 'EulerNumber');

fprintf('Objetos en Frame 1 (Disk 15):\n');
for i=1:length(stats)
    fprintf('Obj %d: Area=%.0f, Euler=%d, Solidez=%.2f, Centro=(%.0f, %.0f)\n', i, stats(i).Area, stats(i).EulerNumber, stats(i).Solidity, stats(i).Centroid(1), stats(i).Centroid(2));
end
