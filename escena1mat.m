% =====================================================================
% ESCENA1MAT.m  –  Procesamiento robusto de la Escena 1 (objetos blancos)
%
% Técnica: Sustracción de fondo + Tracking espacial
% Entrada : proyectoVideo/Escena 1/escena1_1/  (3 secuencias)
% Salida  : proyectoVideo/Escena 1/escena1_1_salida/  + video MP4
% =====================================================================
clear; clc; close all;

ruta_base  = 'C:\Users\crist\VideoImagen\proyectoVideo\Escena 1';
secuencias = {'escena1_1', 'escena1_2', 'escena1_3'};

for s = 1:length(secuencias)
    nombre_escena   = secuencias{s};
    carpeta_entrada = fullfile(ruta_base, nombre_escena);
    carpeta_salida  = fullfile(ruta_base, [nombre_escena, '_salida']);

    fprintf('\n=== Procesando %s ===\n', nombre_escena);

    if ~exist(carpeta_salida, 'dir'), mkdir(carpeta_salida); end

    archivos = dir(fullfile(carpeta_entrada, '*.png'));
    if isempty(archivos)
        warning('Sin imágenes en: %s', carpeta_entrada);
        continue;
    end

    fprintf('Encontrados %d fotogramas.\n', length(archivos));

    % -------------------------------------------------------
    % Cargar frame de referencia (fondo limpio = frame 1)
    % -------------------------------------------------------
    imagenFondo = imread(fullfile(carpeta_entrada, archivos(1).name));

    objetos_memoria = [];

    for f = 1:length(archivos)
        nombre_archivo = archivos(f).name;
        imagenO        = imread(fullfile(carpeta_entrada, nombre_archivo));

        % Preprocesamiento con sustracción de fondo desde frame 2 en adelante
        if f == 1
            imagenD = preprocesar_imagen(imagenO);          % frame 1: sin fondo
        else
            imagenD = preprocesar_imagen(imagenO, imagenFondo); % resto: con fondo
        end

        stats = regionprops(imagenD, 'Area', 'Perimeter', 'Centroid', ...
                            'BoundingBox', 'EulerNumber', 'Extent', 'Solidity');

        fig = figure('Visible', 'off');
        imshow(imagenO); hold on;
        title(sprintf('%s  –  Frame %d/%d', nombre_escena, f, length(archivos)), ...
              'FontSize', 11, 'FontWeight', 'bold');

        objetos_actuales = [];

        for i = 1:length(stats)
            area = stats(i).Area;
            if area < 300, continue; end

            centro       = stats(i).Centroid;
            caja         = stats(i).BoundingBox;
            perimetro    = max(stats(i).Perimeter, 1);
            euler        = stats(i).EulerNumber;
            extent       = stats(i).Extent;
            solidez      = stats(i).Solidity;
            circularidad = (4 * pi * area) / (perimetro^2);

            % --- Clasificación o Tracking ---
            if f == 1 || isempty(objetos_memoria)
                [forma, color_txt] = clasificar_forma(euler, solidez, circularidad, extent);
            else
                dists = arrayfun(@(o) norm(centro - o.centro), objetos_memoria);
                [dmin, idx] = min(dists);
                if dmin < 150
                    forma     = objetos_memoria(idx).etiqueta;
                    color_txt = objetos_memoria(idx).color;
                else
                    [forma, color_txt] = clasificar_forma(euler, solidez, circularidad, extent);
                end
            end

            nuevo.centro   = centro;
            nuevo.etiqueta = forma;
            nuevo.color    = color_txt;
            objetos_actuales = [objetos_actuales; nuevo]; %#ok<AGROW>

            % Dibujar
            plot(centro(1), centro(2), 'r+', 'MarkerSize', 12, 'LineWidth', 2);
            rectangle('Position', caja, 'EdgeColor', 'g', 'LineWidth', 2);
            text(centro(1)+4, centro(2)-12, forma, ...
                 'Color', color_txt, 'FontSize', 9, 'FontWeight', 'bold', ...
                 'BackgroundColor', 'k');
            text(centro(1)+4, centro(2)+14, sprintf('A:%.0f C:%.2f', area, circularidad), ...
                 'Color', 'white', 'FontSize', 7);
        end

        objetos_memoria = objetos_actuales;
        hold off;

        nombre_salida = strrep(nombre_archivo, '.png', '_salida.png');
        saveas(fig, fullfile(carpeta_salida, nombre_salida));
        close(fig);

        fprintf('  Frame %02d: %d objetos detectados.\n', f, length(objetos_actuales));
    end

    % --- Generar vídeo ---
    ruta_video = fullfile(ruta_base, [nombre_escena, '_resultado.mp4']);
    generar_video(carpeta_salida, ruta_video);
end

disp('=== ESCENA 1 COMPLETA ===');




function generar_video(carpeta_salida, ruta_video)
    archivos_sal = dir(fullfile(carpeta_salida, '*_salida.png'));
    if isempty(archivos_sal)
        warning('Sin imágenes de salida para el video.');
        return;
    end
    try
        v = VideoWriter(ruta_video, 'MPEG-4');
        v.FrameRate = 1;
        open(v);
        for k = 1:length(archivos_sal)
            img = imread(fullfile(carpeta_salida, archivos_sal(k).name));
            writeVideo(v, img);
        end
        close(v);
        fprintf('  Video: %s\n', ruta_video);
    catch ME
        warning('Error generando video: %s', ME.message);
    end
end
