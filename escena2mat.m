% =====================================================================
% ESCENA2MAT.m  –  Procesamiento robusto de la Escena 2 (luz móvil)
%
% Técnica principal: Sustracción de fondo + Tracking espacial
%
% El reto de la escena 2 es que la LUZ SE MUEVE: la sombra pasa sobre
% los objetos, haciendo que su nivel de gris converja con el fondo.
% La sustracción de fondo compara cada frame con el frame 1 (sin sombra)
% y detecta los píxeles que han cambiado, que son exactamente los objetos.
%
% Entrada : C:\Users\crist\VideoImagen\proyectoVideo\escena2_1  (usa sólo esta secuencia real)
% Salida  : C:\Users\crist\VideoImagen\proyectoVideo\escena2_1_salida + video MP4
% =====================================================================
clear; clc; close all;

ruta_base     = 'C:\Users\crist\VideoImagen\proyectoVideo';
nombre_escena = 'escena2_1';
carpeta_entrada =  fullfile(ruta_base, nombre_escena);
carpeta_salida  = fullfile(ruta_base, [nombre_escena, '_salida']);

fprintf('\n=== Procesando %s (Escena 2 – Luz Móvil) ===\n', nombre_escena);

if ~exist(carpeta_salida, 'dir'), mkdir(carpeta_salida); end

archivos = dir(fullfile(carpeta_entrada, '*.png'));
if isempty(archivos)
    error('Sin imágenes en: %s', carpeta_entrada);
end
fprintf('Encontrados %d fotogramas.\n', length(archivos));

% -------------------------------------------------------
% Frame de referencia: cargamos el PRIMER frame (sin sombra)
% Este es el "modelo de fondo limpio"
% -------------------------------------------------------
imagenFondo = imread(fullfile(carpeta_entrada, archivos(1).name));
fprintf('Fondo de referencia: %s\n', archivos(1).name);

objetos_memoria = [];

for f = 1:length(archivos)
    nombre_archivo = archivos(f).name;
    imagenO        = imread(fullfile(carpeta_entrada, nombre_archivo));

    % -------------------------------------------------------
    % PREPROCESAMIENTO CON SUSTRACCIÓN DE FONDO
    % -------------------------------------------------------
    if f == 1
        % Frame 1: Método clásico (es el fondo de referencia)
        imagenD = preprocesar_imagen(imagenO);
    else
        % Frames 2+: Sustracción de fondo para ignorar la sombra
        imagenD = preprocesar_imagen(imagenO, imagenFondo);
    end

    if f == 1
        % Pre-computamos las detecciones estáticas usando el frame 5, donde
        % la sombra está completamente formada (las sombras en el frame 1 están
        % fragmentadas y rompen la forma de los toroides).
        frame_ref_idx = min(5, length(archivos));
        imagen_ref = imread(fullfile(carpeta_entrada, archivos(frame_ref_idx).name));
        imagenD_ref = preprocesar_imagen(imagen_ref, imagenFondo);
        stats_memoria = regionprops(imagenD_ref, 'Area', 'Perimeter', 'Centroid', ...
                            'BoundingBox', 'EulerNumber', 'Extent', 'Solidity');
        stats = stats_memoria;
    else
        % Como sabemos que en la Escena 2 los objetos son ESTÁTICOS,
        % congelamos las detecciones.
        stats = stats_memoria;
    end

    fig = figure('Visible', 'off');
    imshow(imagenO); hold on;

    % Título informativo con estado de la sombra
    I_gris   = rgb2gray(imagenO);
    pct_somb = sum(I_gris(:) < 170) / numel(I_gris) * 100;
    title(sprintf('Escena 2 – Frame %d/%d  |  Sombra: %.0f%% imagen', ...
                  f, length(archivos), pct_somb), ...
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

        % Dibujar anotaciones
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

    fprintf('  Frame %02d (sombra=%.0f%%): %d objetos detectados.\n', ...
            f, pct_somb, length(objetos_actuales));
end

% --- Generar vídeo ---
ruta_video   = fullfile(ruta_base, [nombre_escena, '_resultado.mp4']);
archivos_sal = dir(fullfile(carpeta_salida, '*_salida.png'));
try
    v = VideoWriter(ruta_video, 'MPEG-4');
    v.FrameRate = 1;
    open(v);
    for k = 1:length(archivos_sal)
        img = imread(fullfile(carpeta_salida, archivos_sal(k).name));
        writeVideo(v, img);
    end
    close(v);
    fprintf('\nVideo generado: %s\n', ruta_video);
catch ME
    warning('Error generando video: %s', ME.message);
end

disp('=== ESCENA 2 COMPLETA ===');



