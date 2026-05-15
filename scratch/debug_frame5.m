clear; clc;
ruta_base = 'C:\Users\crist\VideoImagen\proyectoVideo\escena2_1';
img5 = imread(fullfile(ruta_base, 'frame_0005.png'));
imgFondo = imread(fullfile(ruta_base, 'frame_0001.png'));

imagenD = preprocesar_imagen(img5, imgFondo);

stats = regionprops(imagenD, 'Area', 'BoundingBox', 'Centroid', 'Solidity');

fprintf('Objetos en Frame 5:\n');
for i=1:length(stats)
    if stats(i).Area >= 300
        fprintf('Obj %d: Area=%.0f, Solidez=%.2f, Centro=(%.0f, %.0f)\n', i, stats(i).Area, stats(i).Solidity, stats(i).Centroid(1), stats(i).Centroid(2));
    end
end

% Guardar imagen para depuración visual si fuera necesario (aunque la consola basta)
imwrite(imagenD, 'scratch/debug_frame5_bin.png');
