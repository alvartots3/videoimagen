clear; clc;
ruta_base = 'C:\Users\crist\VideoImagen\proyectoVideo\escena2_1';
img10 = imread(fullfile(ruta_base, 'frame_0010.png'));
imgFondo = imread(fullfile(ruta_base, 'frame_0001.png'));

imagenD = preprocesar_imagen(img10, imgFondo);
stats = regionprops(imagenD, 'Area', 'BoundingBox', 'Centroid');

fprintf('Objetos en Frame 10:\n');
for i=1:length(stats)
    fprintf('Obj %d: Area=%.0f, Centro=(%.0f, %.0f)\n', i, stats(i).Area, stats(i).Centroid(1), stats(i).Centroid(2));
end
