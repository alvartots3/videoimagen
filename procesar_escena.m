function procesar_escena(carpeta_entrada, carpeta_salida, nombre_escena, escena_num)
% PROCESAR_ESCENA - Detecta, clasifica y anota objetos en una secuencia de frames
%   carpeta_entrada : ruta a la carpeta con PNGs de entrada
%   carpeta_salida  : ruta donde guardar imágenes anotadas
%   nombre_escena   : nombre base para el video (ej. 'escena1_1')
%   escena_num      : número de escena (1-8) para elegir estrategia

if nargin < 4
    escena_num = 1;
end

% Crear carpeta de salida si no existe
if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
    fprintf('  Creada carpeta: %s\n', carpeta_salida);
end

% Leer todos los archivos PNG
archivos = dir(fullfile(carpeta_entrada, '*.png'));
if isempty(archivos)
    warning('No se encontraron PNGs en: %s', carpeta_entrada);
    return;
end

fprintf('  Procesando %d fotogramas de %s...\n', length(archivos), nombre_escena);

% Variables de tracking
objetos_memoria = [];
total_objetos_detectados = 0;

for f = 1:length(archivos)
    nombre_archivo = archivos(f).name;
    ruta_completa = fullfile(carpeta_entrada, nombre_archivo);

    imagenO = imread(ruta_completa);

    % === PREPROCESAMIENTO ADAPTATIVO POR ESCENA ===
    imagenD = preprocesar_imagen_adaptativo(imagenO, escena_num);

    stats = regionprops(imagenD, 'Area', 'Perimeter', 'Centroid', ...
        'BoundingBox', 'EulerNumber', 'Extent', 'Solidity');

    % Crear figura invisible
    f_fig = figure('Visible', 'off', 'Position', [0 0 1920 1080]);
    imshow(imagenO);
    hold on;
    title(sprintf('Escena %d - %s - Frame %d/%d', escena_num, nombre_escena, f, length(archivos)), ...
        'FontSize', 14, 'Color', 'white', 'FontWeight', 'bold');

    objetos_actuales = [];

    for i = 1:length(stats)
        area = stats(i).Area;

        if area > 300  % Umbral de área mínima
            centro    = stats(i).Centroid;
            caja      = stats(i).BoundingBox;
            perimetro = max(stats(i).Perimeter, 1);  % Evitar div/0
            euler     = stats(i).EulerNumber;
            extent    = stats(i).Extent;
            solidez   = stats(i).Solidity;
            circularidad = (4 * pi * area) / (perimetro^2);

            % === CLASIFICACIÓN: Frame 1 o tracking ===
            if f == 1 || isempty(objetos_memoria)
                % Clasificación basada en descriptores
                [forma, color_texto] = clasificar_objeto(euler, solidez, circularidad, extent);
            else
                % TRACKING ESPACIAL: heredar etiqueta del objeto más cercano
                distancias = arrayfun(@(o) norm(centro - o.centro), objetos_memoria);
                [dist_min, idx_min] = min(distancias);

                if dist_min < 200  % Umbral de distancia para tracking válido
                    forma = objetos_memoria(idx_min).etiqueta;
                    color_texto = objetos_memoria(idx_min).color;
                else
                    % Objeto nuevo detectado
                    [forma, color_texto] = clasificar_objeto(euler, solidez, circularidad, extent);
                end
            end

            % Guardar para tracking siguiente frame
            nuevo_obj.centro   = centro;
            nuevo_obj.etiqueta = forma;
            nuevo_obj.color    = color_texto;
            objetos_actuales   = [objetos_actuales; nuevo_obj]; %#ok<AGROW>

            % === DIBUJAR ANOTACIONES ===
            % Centroide
            plot(centro(1), centro(2), 'r+', 'MarkerSize', 14, 'LineWidth', 2.5);

            % Bounding box
            rectangle('Position', caja, 'EdgeColor', [0 1 0], 'LineWidth', 2);

            % Etiqueta con fondo
            text(centro(1) + 5, centro(2) - 15, forma, ...
                'Color', color_texto, 'FontSize', 10, 'FontWeight', 'bold', ...
                'BackgroundColor', 'black');

            % Métricas debajo
            text(centro(1) + 5, centro(2) + 15, ...
                sprintf('A:%.0f C:%.2f', area, circularidad), ...
                'Color', 'white', 'FontSize', 7);

            total_objetos_detectados = total_objetos_detectados + 1;
        end
    end

    objetos_memoria = objetos_actuales;
    hold off;

    % Guardar imagen anotada
    nombre_salida = strrep(nombre_archivo, '.png', '_salida.png');
    ruta_salida   = fullfile(carpeta_salida, nombre_salida);
    saveas(f_fig, ruta_salida);
    close(f_fig);
end

fprintf('  -> Frames guardados: %d | Objetos totales detectados: %d\n', ...
    length(archivos), total_objetos_detectados);

% === GENERAR VÍDEO MP4 ===
[ruta_padre, ~, ~] = fileparts(carpeta_salida);
nombre_video = fullfile(ruta_padre, [nombre_escena, '_resultado.mp4']);

try
    v = VideoWriter(nombre_video, 'MPEG-4');
    v.FrameRate = 1;
    open(v);

    archivos_salida = dir(fullfile(carpeta_salida, '*_salida.png'));
    for f = 1:length(archivos_salida)
        img = imread(fullfile(carpeta_salida, archivos_salida(f).name));
        writeVideo(v, img);
    end
    close(v);
    fprintf('  -> Video generado: %s\n', nombre_video);
catch ME
    fprintf('  [WARN] Error generando video: %s\n', ME.message);
end

end

% =====================================================================
% FUNCIÓN: Clasificador de formas con árbol de decisión
% =====================================================================
function [forma, color_texto] = clasificar_objeto(euler, solidez, circularidad, extent)
    if euler < 1
        forma = 'Toroide';       color_texto = 'magenta';
    elseif solidez >= 0.93 && circularidad >= 0.78
        forma = 'Esfera/Cilindro'; color_texto = 'cyan';
    elseif solidez >= 0.85 && circularidad >= 0.60
        forma = 'Cono';          color_texto = [0.3 0.7 1];
    elseif solidez >= 0.78 && extent >= 0.55
        forma = 'Cubo/Prisma';  color_texto = [0.2 1 0.2];
    elseif solidez >= 0.50
        forma = 'Monkey/Complejo'; color_texto = 'yellow';
    else
        forma = 'Desconocido';   color_texto = 'white';
    end
end

% =====================================================================
% FUNCIÓN: Preprocesamiento adaptativo según número de escena
% =====================================================================
function imagenD = preprocesar_imagen_adaptativo(imagenO, escena_num)
    I_gris = rgb2gray(imagenO);

    switch escena_num
        case {1, 2}
            % Escena 1 (objetos blancos) y 2 (luz movil): binarizacion clasica
            umbral = graythresh(I_gris) * 1.1;
            umbral = min(umbral, 0.95);
            I_bin = imbinarize(I_gris, 'adaptive', 'Sensitivity', umbral);
            I_bin = ~I_bin;

        case 3
            % Escena 3 (contraluz/cenital): umbral global más bajo + ajuste
            umbral = graythresh(I_gris);
            I_bin = imbinarize(I_gris, max(umbral - 0.05, 0.1));
            % Añadir bordes para capturar siluetas en contraluz
            bordes = edge(I_gris, 'canny');
            I_bin = I_bin | imdilate(bordes, strel('disk', 2));

        case {4, 5}
            % Escenas 4-5 (color/textura): usar umbral global Otsu sobre imagen
            % El fondo es negro, los objetos son coloreados -> umbral global funciona mejor
            if size(imagenO, 3) == 3
                % Intentar con canal de valor HSV primero
                I_hsv = rgb2hsv(imagenO);
                value = I_hsv(:,:,3);
                umbral_v = graythresh(value);
                I_bin_hsv = value > max(umbral_v * 0.7, 0.08);

                % Combinar con binarizacion global en gris
                umbral_g = graythresh(I_gris);
                I_bin_gris = I_gris > max(uint8(umbral_g * 255 * 0.5), uint8(20));

                I_bin = I_bin_hsv | I_bin_gris;

                % Si detecta demasiado (>40% imagen), refinar
                if sum(I_bin(:)) > 0.4 * numel(I_bin)
                    I_bin = I_bin_hsv & I_bin_gris;
                end

                % Fallback si detecta muy poco
                if sum(I_bin(:)) < 2000
                    I_bin = I_bin_hsv | I_bin_gris;
                end
            else
                umbral = graythresh(I_gris);
                I_bin = I_gris > uint8(umbral * 255 * 0.6);
            end

        otherwise
            % Escenas 6-8 y resto: método robusto combinado
            umbral = graythresh(I_gris);
            I_bin1 = imbinarize(I_gris, max(umbral * 0.9, 0.1));
            I_bin2 = ~imbinarize(I_gris, 'adaptive', 'Sensitivity', 0.6);
            I_bin = I_bin1 | I_bin2;
    end

    % Post-procesamiento morfológico común
    I_rellena  = imfill(I_bin, 'holes');
    I_mediana  = medfilt2(I_rellena, [5 5]);
    I_limpia   = bwareaopen(I_mediana, 300);
    ee         = strel('square', 3);
    imagenD    = imclose(I_limpia, ee);
end
