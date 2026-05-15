% test_escena2.m
clear; clc; close all;

ruta_base     = 'C:\Users\crist\VideoImagen\proyectoVideo';
nombre_escena = 'escena2_1';
carpeta_entrada =  fullfile(ruta_base, nombre_escena);

archivos = dir(fullfile(carpeta_entrada, '*.png'));

% Frame 1
img1 = imread(fullfile(carpeta_entrada, archivos(1).name));
% Frame 5
img5 = imread(fullfile(carpeta_entrada, archivos(5).name));
% Frame 10
img10 = imread(fullfile(carpeta_entrada, archivos(10).name));

figure;
subplot(1,3,1); imshow(img1); title('Frame 1');
subplot(1,3,2); imshow(img5); title('Frame 5');
subplot(1,3,3); imshow(img10); title('Frame 10');
