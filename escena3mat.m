% Script principal: main.m calibrado para tu ruta
% 1. Definir la ruta base absoluta o relativa al proyecto
ruta_base = fullfile(pwd, 'proyectoVideo');

% 2. Definir la carpeta de entrada (dentro de la ruta base)
nombre_escena = 'escena3_1'; 
carpeta_entrada = fullfile(ruta_base, nombre_escena);
carpeta_salida = fullfile(ruta_base, [nombre_escena, '_salida']);

% Crear la carpeta de salida si no existe
if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

% 3. Leer todos los archivos PNG de la carpeta de entrada
archivos = dir(fullfile(carpeta_entrada, '*.png'));

if isempty(archivos)
    error('No se han encontrado fotos en: %s. Revisa que el nombre de la carpeta coincide.', carpeta_entrada);
end

% (Todo lo de arriba se queda igual: definir rutas, leer archivos...)

% (Todo lo de arriba se queda igual: definir rutas, leer archivos...)

fprintf('Procesando %d fotogramas...\n', length(archivos));

% Variable para guardar la memoria del fotograma anterior (TRACKING)
objetos_memoria = []; 

for f = 1:length(archivos)
    nombre_archivo = archivos(f).name;
    ruta_completa = fullfile(carpeta_entrada, nombre_archivo);
    
    imagenO = imread(ruta_completa);
    imagenD = preprocesar_imagen(imagenO); % USA TU VERSIÓN HÍBRIDA QUE FUNCIONABA BIEN
    
    stats = regionprops(imagenD, 'Area', 'Perimeter', 'Centroid', 'BoundingBox', 'EulerNumber', 'Extent', 'Solidity');
    
    f_fig = figure('Visible', 'off'); 
    imshow(imagenO);
    hold on;
    
    % Array temporal para guardar los objetos de este frame
    objetos_actuales = []; 
    
    for i = 1:length(stats)
        area = stats(i).Area;
        
        if area > 150
            centro = stats(i).Centroid;
            caja = stats(i).BoundingBox;
            perimetro = stats(i).Perimeter;
            euler = stats(i).EulerNumber;
            extent = stats(i).Extent;
            solidez = stats(i).Solidity;
            circularidad = (4 * pi * area) / (perimetro^2);
            
            % =========================================================
            % LÓGICA DE CLASIFICACIÓN Y TRACKING
            % =========================================================
            
            if f == 1
                % FOTOGRAMA 1: La luz es buena, usamos tu árbol de decisión puro
                if euler < 1
                    forma = 'Toroide'; color_texto = 'magenta';
                elseif solidez >= 0.94 && circularidad >= 0.80
                    forma = 'Esfera/Cilindro'; color_texto = 'cyan';
                elseif solidez >= 0.88 && circularidad >= 0.65
                    forma = 'Cono'; color_texto = 'blue';
                elseif solidez >= 0.80 && extent >= 0.58
                    forma = 'Cubo/Prisma'; color_texto = 'green';
                else
                    forma = 'Mona/Compleja'; color_texto = 'yellow';
                end
            else
                % FOTOGRAMA > 1: La luz deforma todo. Usamos TRACKING espacial.
                % Buscamos cuál era el objeto más cercano en el frame anterior.
                distancia_minima = inf;
                indice_mejor = -1;
                
                for j = 1:length(objetos_memoria)
                    % Distancia Euclídea entre centroides
                    d = norm(centro - objetos_memoria(j).centro);
                    if d < distancia_minima
                        distancia_minima = d;
                        indice_mejor = j;
                    end
                end
                
                % Heredamos la identidad del objeto del frame anterior
                forma = objetos_memoria(indice_mejor).etiqueta;
                color_texto = objetos_memoria(indice_mejor).color;
            end
            
            % Guardamos los datos actuales para el SIGUIENTE fotograma
            nuevo_obj.centro = centro;
            nuevo_obj.etiqueta = forma;
            nuevo_obj.color = color_texto;
            objetos_actuales = [objetos_actuales; nuevo_obj];
            
            % =========================================================
            
            % Dibujamos
            plot(centro(1), centro(2), 'r+', 'MarkerSize', 10, 'LineWidth', 2);
            rectangle('Position', caja, 'EdgeColor', 'g', 'LineWidth', 2);
            text(centro(1) + 5, centro(2) + 5, forma, 'Color', color_texto, 'FontSize', 10, 'FontWeight', 'bold');
        end
    end
    
    % Actualizamos la memoria para el próximo ciclo
    objetos_memoria = objetos_actuales;
    
    hold off;
    
    % (Guardar la imagen y cerrar figure se queda igual...)
    nombre_salida = strrep(nombre_archivo, '.png', '_salida.png');
    ruta_salida = fullfile(carpeta_salida, nombre_salida);
    saveas(f_fig, ruta_salida);
    close(f_fig); 
    
    fprintf('Fotograma %d/%d guardado.\n', f, length(archivos));
end

% =========================================================
% GENERACIÓN DE VÍDEO
% =========================================================
nombre_video = fullfile(ruta_base, [nombre_escena, '_resultado.mp4']);
v = VideoWriter(nombre_video, 'MPEG-4');
v.FrameRate = 1; % 1 fps
open(v);

for f = 1:length(archivos)
    nombre_salida = strrep(archivos(f).name, '.png', '_salida.png');
    ruta_img = fullfile(carpeta_salida, nombre_salida);
    if exist(ruta_img, 'file')
        img = imread(ruta_img);
        writeVideo(v, img);
    end
end
close(v);
disp(['Vídeo guardado en: ', nombre_video]);

disp('¡Proceso completado con éxito!');
