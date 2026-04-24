%% Función impulso-respuesta
%{ 
Modelo de Long y Plosser (1983)
Considera el modelo no-lineal: variables en logaritmo
[1] Autor: Hamilton Galindo
[2] Fecha: Julio 2011, enero 2017, febrero 2017
Uso:
Ilustrar que se los gráficos de IRF obtenidos de Dynare pueden ser
mejorados mediante códigos de Matlab.
%}
clear all;
% Se corre el mod del modelo
dynare Long_Plosser_Dynare_nolineal_log;

% Se crea una matriz que contenga la función impulso-respuesta
IRF = [oo_.irfs.cc_e', oo_.irfs.ii_e', oo_.irfs.yy_e', oo_.irfs.kk_e', oo_.irfs.hh_e', oo_.irfs.rr_e', oo_.irfs.ww_e', oo_.irfs.aa_e',];

% Vector con nombres de las variables
names = {'Consumo', 'Inversión', 'Producto', 'Capital', 'Trabajo', 'Tasa de interés', 'Salario real', 'Productividad'};

% Gráfica de la función impulso-respuesta

for i=1:size(IRF,2)
    subplot(2,4,i)
    plot(IRF(:,i),'o','MarkerSize',4,'LineWidth', 1.5);
    title(names{i});
    grid;
end
orient landscape
saveas(gcf,'ifrs_nolineal_log_matlab1','pdf');