clear; clc;
img = imread('C:\Users\crist\VideoImagen\proyectoVideo\escena2_1\frame_0001.png');
I_gris = rgb2gray(img);

umbral = graythresh(I_gris) * 1.1;
umbral = min(umbral, 0.95);
I_bin = imbinarize(I_gris, 'adaptive', 'Sensitivity', umbral);
I_bin = ~I_bin;

inv = ~I_bin;
inv_clean = bwareaopen(inv, 500); % Mantenemos los huecos grandes (fondo)
I_rellena = ~inv_clean;

% Unir pedazos que se hayan separado por sombras fuertes
I_cerrada = imclose(I_rellena, strel('disk', 8));

imagenD = bwareaopen(I_cerrada, 1000); % Objetos < 1000 px son ruido en escena 2

stats = regionprops(imagenD, 'Area', 'BoundingBox', 'Centroid', 'EulerNumber');
for i=1:length(stats)
    fprintf('Obj %d: Area=%.0f, Euler=%d, Centro=(%.0f, %.0f)\n', i, stats(i).Area, stats(i).EulerNumber, stats(i).Centroid(1), stats(i).Centroid(2));
end
