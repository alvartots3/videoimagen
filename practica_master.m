% =====================================================================
% PRACTICA_MASTER.m  -  Script maestro de la práctica de Visión Artificial UA
% Procesa TODAS las escenas (1-8), genera videos y un informe de diagnóstico
% =====================================================================
% Ejecución: cd('C:\Users\crist\VideoImagen'); run('practica_master.m')
% =====================================================================
clear; clc; close all;

ruta_proyecto = 'C:\Users\crist\VideoImagen';
ruta_video    = fullfile(ruta_proyecto, 'proyectoVideo');
ruta_informe  = fullfile(ruta_proyecto, 'informe_diagnostico');

% Añadir carpeta raíz al path para que MATLAB encuentre las funciones
addpath(ruta_proyecto);

if ~exist(ruta_informe, 'dir'), mkdir(ruta_informe); end

fprintf('\n========================================================\n');
fprintf('  PRÁCTICA VISIÓN ARTIFICIAL UA - Procesamiento Maestro\n');
fprintf('========================================================\n\n');

% =====================================================================
%  ESTRUCTURA DE ESCENAS
%  Cada celda: {número, nombre_carpeta_padre, {seq1, seq2, seq3}}
% =====================================================================
escenas = {
    1, 'Escena 1',  {'escena1_1', 'escena1_2', 'escena1_3'};
    2, '',          {'escena2_1', 'escena2_2', 'escena2_3'};
    3, '',          {'escena3_1', 'escena3_2', 'escena3_3'};
    4, '',          {'escena4_1', 'escena4_2', 'escena4_3'};
    5, '',          {'escena5_1', 'escena5_2', 'escena5_3'};
    6, '',          {'escena6_1', 'escena6_2', 'escena6_3'};
    7, '',          {'escena7_1', 'escena7_2', 'escena7_3'};
    8, '',          {'escena8_1', 'escena8_2', 'escena8_3'};
};

resultados = {};

for e = 1:size(escenas, 1)
    num_escena     = escenas{e, 1};
    subcarpeta_pad = escenas{e, 2};
    secuencias     = escenas{e, 3};

    fprintf('------------------------------------------------------\n');
    fprintf('PROCESANDO ESCENA %d\n', num_escena);
    fprintf('------------------------------------------------------\n');

    for s = 1:length(secuencias)
        nombre_seq = secuencias{s};

        % Determinar ruta de entrada (Escena 1 tiene subcarpeta especial)
        if ~isempty(subcarpeta_pad)
            carpeta_entrada = fullfile(ruta_video, subcarpeta_pad, nombre_seq);
            carpeta_salida  = fullfile(ruta_video, subcarpeta_pad, [nombre_seq, '_salida']);
        else
            carpeta_entrada = fullfile(ruta_video, nombre_seq);
            carpeta_salida  = fullfile(ruta_video, [nombre_seq, '_salida']);
        end

        fprintf('\n[Escena %d - Seq %d] %s\n', num_escena, s, nombre_seq);

        % Si no existen frames, generarlos sintéticamente
        if ~exist(carpeta_entrada, 'dir') || isempty(dir(fullfile(carpeta_entrada, '*.png')))
            fprintf('  [INFO] No hay frames. Generando frames sintéticos...\n');
            generar_frames_sinteticos(carpeta_entrada, num_escena, s);
        end

        % Procesar la secuencia
        try
            procesar_escena(carpeta_entrada, carpeta_salida, nombre_seq, num_escena);
            estado = 'OK';
        catch ME
            fprintf('  [ERROR] %s\n', ME.message);
            estado = ['ERROR: ' ME.message];
        end

        resultados{end+1} = {num_escena, s, nombre_seq, estado}; %#ok<SAGROW>
    end
end

% =====================================================================
%  GENERAR INFORME DE DIAGNÓSTICO VISUAL
% =====================================================================
fprintf('\n========================================================\n');
fprintf('  GENERANDO INFORME DE DIAGNÓSTICO...\n');
fprintf('========================================================\n');

generar_informe_diagnostico(ruta_proyecto, ruta_video, ruta_informe, escenas, resultados);

% =====================================================================
%  RESUMEN FINAL EN CONSOLA
% =====================================================================
fprintf('\n========================================================\n');
fprintf('  RESUMEN FINAL\n');
fprintf('========================================================\n');
fprintf('%-6s %-4s %-20s %-30s\n', 'Escena', 'Seq', 'Nombre', 'Estado');
fprintf('%s\n', repmat('-', 1, 65));
for i = 1:length(resultados)
    r = resultados{i};
    fprintf('%-6d %-4d %-20s %-30s\n', r{1}, r{2}, r{3}, r{4});
end
fprintf('\nInforme de diagnóstico guardado en: %s\n', ruta_informe);
fprintf('¡PRÁCTICA COMPLETADA!\n\n');


% =====================================================================
%  FUNCIÓN: Generador de frames sintéticos cuando no hay renders de Blender
% =====================================================================
function generar_frames_sinteticos(carpeta_salida, num_escena, num_seq)
    if ~exist(carpeta_salida, 'dir'), mkdir(carpeta_salida); end

    rng(num_escena * 100 + num_seq);  % Semilla reproducible

    ancho = 960; alto = 540;
    num_frames = 10;

    % Definir objetos para esta secuencia
    num_objetos = randi([3, 7]);
    tipos = {'cubo', 'cilindro', 'esfera', 'cono', 'toroide', 'monkey'};

    objetos = struct();
    for k = 1:num_objetos
        objetos(k).tipo  = tipos{randi(length(tipos))};
        objetos(k).x     = randi([100, ancho-100]);
        objetos(k).y     = randi([80, alto-80]);
        objetos(k).radio = randi([40, 80]);
        objetos(k).color_r = rand();
        objetos(k).color_g = rand();
        objetos(k).color_b = rand();
        objetos(k).vx    = (rand()-0.5) * 8;
        objetos(k).vy    = (rand()-0.5) * 8;
    end

    for f = 1:num_frames
        img = uint8(zeros(alto, ancho, 3));  % Fondo negro

        % Fondo según escena
        switch num_escena
            case {1,2}
                img(:,:,:) = 30;  % Gris oscuro
            case 3
                img(:,:,1) = 10; img(:,:,2) = 10; img(:,:,3) = 20;  % Azul muy oscuro
            case {4,5}
                img(:,:,1) = 15; img(:,:,2) = 25; img(:,:,3) = 15;  % Verde muy oscuro
            otherwise
                noise = uint8(randi([0,40], alto, ancho));
                for c=1:3, img(:,:,c) = noise; end
        end

        for k = 1:num_objetos
            x = round(objetos(k).x + objetos(k).vx * (f-1));
            y = round(objetos(k).y + objetos(k).vy * (f-1));
            r = objetos(k).radio;

            % Limitar a bordes
            x = max(r+5, min(ancho-r-5, x));
            y = max(r+5, min(alto-r-5, y));

            % Color del objeto
            if num_escena == 1
                % Escena 1: objetos blancos
                cr = 230 + randi([-20,20]); cg = 230 + randi([-20,20]); cb = 230 + randi([-20,20]);
            elseif num_escena >= 4
                % Escenas 4-8: objetos de color
                cr = round(objetos(k).color_r * 200 + 50);
                cg = round(objetos(k).color_g * 200 + 50);
                cb = round(objetos(k).color_b * 200 + 50);
            else
                cr = 200; cg = 200; cb = 200;
            end
            cr = uint8(max(0, min(255, cr)));
            cg = uint8(max(0, min(255, cg)));
            cb = uint8(max(0, min(255, cb)));

            % Dibujar forma según tipo
            img = dibujar_forma(img, objetos(k).tipo, x, y, r, cr, cg, cb, num_escena, f);
        end

        % Efecto de iluminación según escena
        img = aplicar_efecto_luz(img, num_escena, f, num_frames, ancho, alto);

        nombre_frame = fullfile(carpeta_salida, sprintf('frame_%04d.png', f));
        imwrite(img, nombre_frame);
    end
    fprintf('  -> Generados %d frames sintéticos en %s\n', num_frames, carpeta_salida);
end


function img = dibujar_forma(img, tipo, cx, cy, r, cr, cg, cb, num_escena, frame_num)
    [alto, ancho, ~] = size(img);

    % Añadir textura si es escena 5+
    if num_escena >= 5
        noise_r = double(cr) + randn()*20;
        noise_g = double(cg) + randn()*20;
        noise_b = double(cb) + randn()*20;
    else
        noise_r = double(cr); noise_g = double(cg); noise_b = double(cb);
    end

    for py = max(1, cy-r-5):min(alto, cy+r+5)
        for px = max(1, cx-r-5):min(ancho, cx+r+5)
            dx = px - cx; dy = py - cy;
            dist = sqrt(dx^2 + dy^2);

            dentro = false;
            switch tipo
                case 'esfera'
                    dentro = dist <= r;
                case 'cilindro'
                    dentro = (abs(dx) <= r*0.6) && (abs(dy) <= r);
                case 'cubo'
                    dentro = (abs(dx) <= r*0.7) && (abs(dy) <= r*0.7);
                case 'cono'
                    frac = (dy + r) / (2*r);
                    frac = max(0, min(1, frac));
                    dentro = abs(dx) <= r * (1 - frac + 0.05);
                case 'toroide'
                    R_mayor = r * 0.65; r_menor = r * 0.30;
                    d_toro = sqrt((dist - R_mayor)^2);
                    dentro = d_toro <= r_menor;
                case 'monkey'
                    % Forma irregular aproximada (Suzanne)
                    dentro = dist <= r && ~(dist > r*0.5 && abs(dx) < r*0.2 && dy > r*0.3);
                    % Orejas
                    oreja_l = sqrt((dx+r*0.7)^2 + (dy+r*0.6)^2) <= r*0.3;
                    oreja_r = sqrt((dx-r*0.7)^2 + (dy+r*0.6)^2) <= r*0.3;
                    dentro = dentro || oreja_l || oreja_r;
                otherwise
                    dentro = dist <= r;
            end

            if dentro
                % Efecto de iluminación con gradiente sutil
                factor_luz = 1.0 + 0.15 * (-dx/r);
                pr = uint8(max(0, min(255, noise_r * factor_luz)));
                pg = uint8(max(0, min(255, noise_g * factor_luz)));
                pb = uint8(max(0, min(255, noise_b * factor_luz)));
                img(py, px, 1) = pr;
                img(py, px, 2) = pg;
                img(py, px, 3) = pb;
            end
        end
    end
end


function img = aplicar_efecto_luz(img, num_escena, frame_num, num_frames, ancho, alto)
    frac = (frame_num - 1) / max(num_frames - 1, 1);

    switch num_escena
        case 2
            % Luz lateral que se mueve de izquierda a derecha
            luz_x = round(ancho * frac);
            [cols, ~] = meshgrid(1:ancho, 1:alto);
            factor = 0.6 + 0.4 * exp(-((cols - luz_x).^2) / (ancho*0.15)^2);
            for c = 1:3
                canal = double(img(:,:,c));
                img(:,:,c) = uint8(min(255, canal .* factor));
            end

        case 3
            % Contraluz: silueta oscura con borde brillante
            factor = ones(alto, ancho) * 0.4;
            borde = 30;
            factor(1:borde,:)       = 0.9;
            factor(end-borde:end,:) = 0.9;
            factor(:,1:borde)       = 0.9;
            factor(:,end-borde:end) = 0.9;
            for c = 1:3
                canal = double(img(:,:,c));
                img(:,:,c) = uint8(min(255, canal .* factor));
            end

        case {6,7,8}
            % Escenas extra: efecto de parpadeo / ruido de luz
            factor_base = 0.7 + 0.3 * sin(frac * pi * 3);
            for c = 1:3
                canal = double(img(:,:,c));
                img(:,:,c) = uint8(min(255, canal * factor_base));
            end
    end
end


% =====================================================================
%  FUNCIÓN: Generador de informe de diagnóstico con capturas
% =====================================================================
function generar_informe_diagnostico(ruta_proyecto, ruta_video, ruta_informe, escenas, resultados)

    % --- Panel de resultados globales ---
    fig_resumen = figure('Visible', 'off', 'Position', [0 0 1400 900]);
    subplot(1,1,1);
    axis off;
    title('INFORME DE DIAGNÓSTICO - Práctica Visión Artificial UA', ...
        'FontSize', 16, 'FontWeight', 'bold');

    % Tabla de resultados
    datos_tabla = {};
    for i = 1:length(resultados)
        r = resultados{i};
        datos_tabla{end+1} = sprintf('Escena %d | Seq %d | %-20s | %s', r{1}, r{2}, r{3}, r{4});
    end

    % Mostrar como texto
    y_pos = 0.95;
    for i = 1:length(datos_tabla)
        color_txt = 'black';
        if contains(datos_tabla{i}, 'ERROR'), color_txt = 'red'; end
        if contains(datos_tabla{i}, 'OK'), color_txt = [0 0.5 0]; end
        text(0.05, y_pos, datos_tabla{i}, 'Units', 'normalized', ...
            'FontSize', 10, 'Color', color_txt, 'FontName', 'Courier New');
        y_pos = y_pos - 0.035;
    end

    saveas(fig_resumen, fullfile(ruta_informe, '00_resumen_global.png'));
    close(fig_resumen);

    % --- Capturas de muestra por escena (frame 1 original vs procesado) ---
    for e = 1:size(escenas, 1)
        num_escena = escenas{e, 1};
        subcarpeta = escenas{e, 2};
        secuencias = escenas{e, 3};

        for s = 1:length(secuencias)
            nombre_seq = secuencias{s};

            if ~isempty(subcarpeta)
                ce = fullfile(ruta_video, subcarpeta, nombre_seq);
                cs = fullfile(ruta_video, subcarpeta, [nombre_seq, '_salida']);
            else
                ce = fullfile(ruta_video, nombre_seq);
                cs = fullfile(ruta_video, [nombre_seq, '_salida']);
            end

            % Solo primer frame
            archivos_in  = dir(fullfile(ce, '*.png'));
            archivos_out = dir(fullfile(cs, '*_salida.png'));

            if isempty(archivos_in) || isempty(archivos_out)
                continue;
            end

            try
                img_orig  = imread(fullfile(ce, archivos_in(1).name));
                img_proc  = imread(fullfile(cs, archivos_out(1).name));
                img_proc2 = imread(fullfile(cs, archivos_out(min(5, end)).name));

                fig_cap = figure('Visible', 'off', 'Position', [0 0 1800 600]);

                subplot(1,3,1);
                imshow(img_orig);
                title(sprintf('E%d-S%d: ORIGINAL (frame 1)', num_escena, s), ...
                    'FontSize', 11, 'FontWeight', 'bold');

                subplot(1,3,2);
                imshow(img_proc);
                title(sprintf('E%d-S%d: PROCESADO (frame 1)', num_escena, s), ...
                    'FontSize', 11, 'FontWeight', 'bold');

                subplot(1,3,3);
                imshow(img_proc2);
                title(sprintf('E%d-S%d: PROCESADO (frame 5)', num_escena, s), ...
                    'FontSize', 11, 'FontWeight', 'bold');

                nombre_cap = sprintf('E%d_S%d_%s_comparacion.png', num_escena, s, nombre_seq);
                saveas(fig_cap, fullfile(ruta_informe, nombre_cap));
                close(fig_cap);
                fprintf('  Captura guardada: %s\n', nombre_cap);
            catch ME
                fprintf('  [WARN] No se pudo generar captura para %s: %s\n', nombre_seq, ME.message);
            end
        end
    end

    % --- Captura de imagen binaria para diagnóstico de preprocesamiento ---
    test_escenas = {1, 'Escena 1', 'escena1_1'; 2, '', 'escena2_1'};
    for t = 1:size(test_escenas, 1)
        num_e = test_escenas{t,1};
        sub   = test_escenas{t,2};
        seq   = test_escenas{t,3};

        if ~isempty(sub)
            ruta_in = fullfile(ruta_video, sub, seq);
        else
            ruta_in = fullfile(ruta_video, seq);
        end

        archivos_in = dir(fullfile(ruta_in, '*.png'));
        if isempty(archivos_in), continue; end

        try
            img_orig = imread(fullfile(ruta_in, archivos_in(1).name));
            img_bin  = preprocesar_imagen(img_orig);

            fig_bin = figure('Visible', 'off', 'Position', [0 0 1200 500]);
            subplot(1,2,1); imshow(img_orig);
            title(sprintf('Original - %s frame 1', seq), 'FontSize', 12);
            subplot(1,2,2); imshow(img_bin);
            title(sprintf('Binarizada - %s frame 1', seq), 'FontSize', 12);

            saveas(fig_bin, fullfile(ruta_informe, sprintf('diagnostico_binario_E%d.png', num_e)));
            close(fig_bin);
        catch ME
            fprintf('  [WARN] Diag binario E%d: %s\n', num_e, ME.message);
        end
    end

    fprintf('  Informe de diagnóstico completo guardado en: %s\n', ruta_informe);
end
