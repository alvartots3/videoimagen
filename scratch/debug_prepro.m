clear; clc;
ruta_base = 'C:\Users\crist\VideoImagen\proyectoVideo\escena2_1';
img1 = imread(fullfile(ruta_base, 'frame_0005.png'));

imagenFondo = imread(fullfile(ruta_base, 'frame_0001.png'));

imagenD = preprocesar_imagen(img1, imagenFondo);

stats = regionprops(imagenD, 'Area', 'EulerNumber', 'Centroid', 'Solidity', 'Extent', 'Perimeter');
for i=1:length(stats)
    circ = (4 * pi * stats(i).Area) / max(stats(i).Perimeter^2, 1);
    fprintf('Obj %d: Area=%.0f, Euler=%d, Solidez=%.2f, Circ=%.2f\n', i, stats(i).Area, stats(i).EulerNumber, stats(i).Solidity, circ);
end
