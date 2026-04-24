%% Modelo de Long y Plosser (1983, 1989)
% Real Business Cycles (1983), JPE
% Understanding Real Business Cycles (1989), JEP
%{ 
Autor: Hamilton Galindo
Fecha(update): enero 2017, febrero 2017
Modelo: depreciación total y utilidad logarítmica
"Long_Plosser_Dynare_nolineal_log.mod"
Uso: utiliza el archivo mod mencionado y realiza tareas
como simulación, filtro HP y calculo de momentos.
%}
%% Descripción
%{ 
Las secciones de  este m-file son:
 [1] Calibración
 [2] Cálculo del estado estacionario (SS)
 [3] Cálculo de los coeficientes de la solución
 [4] Aplicación del filtro HP
 [5] Cálculo de los momentos del componente cíclico
 [6] Simulación de las variables 
%}
%% [1] Calibración 
% Calibración para un modelo trimestral. Los valores se toman de King y Rebelo (2000) 
beta = 0.984;
alpha = 0.667;
%% [2] Cálculo de estado estacionario 
r_ss = 1/beta;
h_ss = 0.2;
a_ss = 1;
k_ss = h_ss*(1/(beta*(1-alpha)))^(-1/alpha);
i_ss = k_ss;
y_ss = k_ss*(1/(beta*(1-alpha)));
c_ss = k_ss*((1/(beta*(1-alpha))) - 1);
w_ss = alpha*y_ss/h_ss;
%% [3] Cálculo de los coeficientes de la solución
% Del "Long_Plosser_BlanchardKahn.m" se obtiene la solución del modelo
% La solución también se puede obtener de "Long_Plosser_Dynare_nolineal_log.mod"
n_kk = 0.333;
n_rk = -0.667;
% Función de estado: k1_hat = n_kk*k_hat  + a_hat;
% Función de política: c_hat = n_kk*k_hat  + a_hat;
% Gráfica del consumo en función del capital
a_hat = [0,0.5,1]; % valores de a_hat, que desplaza paralelamente la función de política
k_hat = [0:0.1:1]';
c_hat = [];
r_hat = [];
for j=1:size(a_hat,2);
c_hat(:,j) = n_kk*k_hat  + a_hat(j);
r_hat(:,j) = n_rk*k_hat  + a_hat(j);
end;
% Gráfica
subplot(1,2,1)
plot(k_hat,c_hat, 'LineWidth',1.5);
title('Consumo: c\_hat = 0.333*k\_hat  + a\_hat');
leg0 = legend('c\_hat = 0.333*k\_hat','c\_hat = 0.333*k\_hat + 0.5', 'c\_hat = 0.333*k\_hat + 1');
set(leg0, 'location', 'southeast');
set(leg0, 'FontSize', 11); 
legend('boxoff');
grid;
subplot(1,2,2)
plot(k_hat,r_hat, 'LineWidth',1.5);
title('Tasa de interés: r\_hat = -0.667*k\_hat  + a\_hat');
leg = legend('r\_hat = -0.667*k\_hat','r\_hat = -0.667*k\_hat + 0.5', 'r\_hat = -0.667*k\_hat + 1');
set(leg, 'location', 'southwest');
set(leg, 'FontSize', 11); 
legend('boxoff');
grid;
orient landscape
saveas(gcf,'policy_function1','pdf');
%% [4] Aplicación del filtro HP
%{ 
- En "Long_Plosser_Dynare_nolineal_log.mod", 
se encuentra la simulación realizada (primero 
correr este mod).
- Para obtener la simulación se aplicó la función 
"get_simul_replications.m" (ver cap 2.)
- Simulación: 150 periodos para 100 veces
- Orden del vector de celda: 
simulaciones = {yy_sim, cc_sim, ii_sim, kk_sim, rr_sim,ww_sim};
%}
% Aplicando Filtro HP:
trend = {};
cycle = {};
for j=1:size(simulaciones,2)
[trend{j},cycle{j}] = hpfilter(simulaciones{j},1600);
end;
% Gráfica del componente tendencial (de la simulación N°10)
periodos = 1:150;
nombres_sim1 = {'LnProducto', 'LnConsumo', 'LnInversion', 'LnCapital', 'LnTasaInt', 'LnSalario', 'LnTrabajo', 'LnProductividad'};
for j=1:size(simulaciones,2)
subplot(2,4,j)
plot(periodos,simulaciones{j}(:,10),periodos,trend{j}(:,10),'--','LineWidth',1.5);
title(nombres_sim1{j});
end;
legend('Variable','Tendencia');
orient landscape
saveas(gcf,'tendencia_lp1','pdf');

% Gráfica del componente cíclico (de la simulación N°10)
for j=1:size(simulaciones,2)
subplot(2,4,j)
plot(periodos,cycle{j}(:,10),'--','LineWidth',1.5);
title(nombres_sim1{j});
end;
orient landscape
saveas(gcf,'ciclo_lp1','pdf');

%% [5] Cálculo de los momentos del componente cíclico
nombres = {'LnProducto', 'LnConsumo', 'LnInversion', 'LnCapital', 'LnTasaInt', 'LnSalario'};
for j=1:size(nombres,2)
estadisticos.medias.(nombres{j}) = mean(cycle{j});
estadisticos.std.(nombres{j}) = std(cycle{j});
end;
% Graficando la distribución de la des. est.
for j=1:size(nombres,2)
subplot(2,3,j)
hist(estadisticos.std.(nombres{j}));
title(nombres{j})
end;
orient landscape
saveas(gcf,'distribuciones_lp_std','pdf');
%% [6] Simulación de las variables
%{
- La simulación (una sol vez) se puede hacer en Dynare
por medio de: stoch_simul(order = 1, periods = 150); rplot yy;
donde "periods = 150", define el N° de periodos de simulación
y "rplot yy" grafica la variable simulada "yy".
- La simulación de estas variables es guardada por Dynare en 
oo_.endo_simul (cada fila es una variable y el orden es el que
aparece en el preambulo del mod las variables: cc, ii, yy, kk, hh, rr, ww, aa).
%}
nombres_sim = {'LnConsumo', 'LnInversion','LnProducto', 'LnCapital','LnTrabajo', 'LnTasaInt', 'LnSalario', 'LnProductividad'};
for j=1:size(nombres_sim,2)
subplot(2,4,j)
plot(oo_.endo_simul(j,:),'LineWidth',1.5);
title(nombres_sim{j})
end;
orient landscape
saveas(gcf,'simulacion_lp','pdf');
% Segunda forma de simular: usando la función de 
% simulaciones = {yy_sim, cc_sim, ii_sim, kk_sim, rr_sim,ww_sim,hh_sim,aa_sim};
% graficando la décima y veinteava simulación
for j=1:size(simulaciones,2)
subplot(2,4,j)
plot(periodos,simulaciones{j}(:,10),'--',periodos,simulaciones{j}(:,20),'LineWidth',1.5);
title(nombres_sim1{j});
end;
legend('Simulación N°10','Simulación N°20');
orient landscape
saveas(gcf,'simulacion_lp10_20','pdf');