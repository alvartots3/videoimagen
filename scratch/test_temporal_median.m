clear; clc;
ruta_base = 'C:\Users\crist\VideoImagen\proyectoVideo\escena2_1';
archivos = dir(fullfile(ruta_base, '*.png'));

img_stack = zeros(540, 960, length(archivos)); % asumiendo 540x960, ajustamos leyendo la primera
img1 = imread(fullfile(ruta_base, archivos(1).name));
img_stack = zeros(size(img1,1), size(img1,2), length(archivos));

for f=1:length(archivos)
    img = rgb2gray(imread(fullfile(ruta_base, archivos(f).name)));
    img_stack(:,:,f) = double(img);
end

% Calcular mediana temporal
img_median = median(img_stack, 3);
img_median = uint8(img_median);

% Probar a umbralizar esta imagen "limpia" de sombras móviles
bg = double(median(img_median(:)));
dark_mask  = img_median < uint8(bg * 0.82);
light_mask = img_median > uint8(min(bg * 1.07, 255));
I_bin = dark_mask | light_mask;

inv       = ~I_bin;
inv_clean = bwareaopen(inv, 150);
I_rellena = ~inv_clean;
I_cerrada = imclose(I_rellena, strel('disk', 4));
imagenD = bwareaopen(I_cerrada, 300);

stats = regionprops(imagenD, 'Area', 'BoundingBox', 'Centroid', 'Solidity', 'EulerNumber');

fprintf('Objetos detectados en Mediana Temporal:\n');
for i=1:length(stats)
    fprintf('Obj %d: Area=%.0f, Euler=%d, Solidez=%.2f, Centro=(%.0f, %.0f)\n', i, stats(i).Area, stats(i).EulerNumber, stats(i).Solidity, stats(i).Centroid(1), stats(i).Centroid(2));
end
