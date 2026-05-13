function [forma, color_txt] = clasificar_forma(euler, solidez, circularidad, extent)
% CLASIFICAR_FORMA - Clasifica las geometrías de la práctica de Visión
    if euler < 1
        forma = 'Toroide';          color_txt = 'magenta';
    elseif solidez >= 0.93 && circularidad >= 0.75
        forma = 'Esfera/Cilindro';  color_txt = 'cyan';
    elseif solidez >= 0.85 && circularidad >= 0.55
        forma = 'Cono';             color_txt = [0.3 0.7 1];
    elseif solidez >= 0.75 && extent >= 0.52
        forma = 'Cubo/Prisma';      color_txt = [0.2 1 0.2];
    elseif solidez >= 0.65 && solidez <= 0.74 && circularidad >= 0.35 && circularidad <= 0.60
        % Perfil específico de las sombras de los toroides (sin hueco)
        forma = 'Toroide';          color_txt = 'magenta';
    elseif solidez >= 0.40
        forma = 'Monkey/Complejo';  color_txt = 'yellow';
    else
        forma = 'Desconocido';      color_txt = 'white';
    end
end
