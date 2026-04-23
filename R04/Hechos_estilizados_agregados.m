%% Hechos estilizados: economía EEUU
%{ 
Autor: Hamilton Galindo
Fecha(update): marzo 2017
%}
%% Descripción
%{ 
Este m-file grafica las variables macroeconómicas en niveles y halla
el componente cíclico por medio del filtro HP. Además, calcula los 
estadísticos del componente cíclico.
%}

%% Levantando los datos
load data_matlab_agregada.mat;

%% Base de datos
% Renombrando las variables
ln_y = ln_gdp;
ln_c = ln_consumo_real;
ln_inv = ln_inv_privada_real_bd;
ln_k = ln_stock_capital;
ln_h = ln_horas_total_nonfarm;
ln_e = ln_empleo_total_nonfarm;
ln_w = ln_salario_real_porhora;
ln_prod = ln_productividad;

% Borrando las variables previas
clear ln_gdp...
ln_consumo_real...
ln_inv_privada_real_bd...
ln_stock_capital...
ln_horas_total_nonfarm...
ln_empleo_total_nonfarm...
ln_salario_real_porhora...
ln_productividad;

%% Gráficas

% Gráfica del Y, C, I (1954.1 - 2015.4)
plot(Fecha(30:277),ln_y(30:277),'--',Fecha(30:277),ln_c(30:277),'k',Fecha(30:277),ln_inv(30:277),'r-','LineWidth',2.25);
xlim([1954 2017]);
leg1=legend('Ln(PBI)', 'Ln(Consumo)', 'Ln(Inversión)');
set(leg1, 'location', 'South');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');
grid;

orient landscape
saveas(gcf,'series_y_c_inv','pdf');

% Gráfica del stock de capital
plot(Fecha(30:277),ln_k(30:277),'LineWidth',2.25);
xlim([1954 2017]);
leg1=legend('Ln(Stock de Capital)');
set(leg1, 'location', 'South');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');
grid;

orient landscape
saveas(gcf,'series_k','pdf');

% Gráfica 

M = [ln_h ln_e ln_w ln_prod];
nombres = {'ln(Horas)', 'ln(Empleo)', 'ln(Salario Real)', 'ln(Productividad)'};
for j=1:4
subplot(2,2,j)
plot(Fecha(30:277),M(30:277,j),'LineWidth',2.25);
title(nombres{j})
xlim([1954 2017]);
grid;
end;

orient landscape
saveas(gcf,'series_resto','pdf');

%% Filtro HP
M1 = [ln_y ln_c ln_inv ln_k ln_h ln_e ln_w ln_prod];
nombres1 = {'ln(PBI)','ln(Consumo)','ln(Inversión)','ln(Stock de capital)','ln(Horas)', 'ln(Empleo)', 'ln(Salario Real)', 'ln(Productividad)'};

trend = [];
cycle = [];
for j=1:size(M1,2)
[trend(:,j),cycle(:,j)] = hpfilter(M1(30:277,j),1600); 
end;

%Gráfica del PBI: tendencia y nivel
plot(Fecha(30:277),ln_y(30:277),Fecha(30:277),trend(:,1),'--','LineWidth',1.5);
xlim([1953 2017]);
leg1=legend('Ln(PBI)', 'Tendencia de Ln(PBI)');
set(leg1, 'location', 'South');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');
orient landscape
saveas(gcf,'ln_y','pdf');

%Gráfica del componente cíclico
subplot(2,2,1)
plot(Fecha(30:277),cycle(:,1),'b','LineWidth',1.5);
xlim([1953 2017]);
leg1=legend('Ln(PBI)');
set(leg1, 'location', 'NorthEast');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');

for j =2:4
subplot(2,2,j)
plot(Fecha(30:277),cycle(:,1),'--',Fecha(30:277),cycle(:,j),'LineWidth',1.5);
xlim([1953 2017]);
leg1=legend('Ln(PBI)', nombres1{j});
set(leg1, 'location', 'NorthEast');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');
end;
orient landscape
saveas(gcf,'ln_ycinvk','pdf');

for j =5:8
subplot(2,2,j-4)
plot(Fecha(30:277),cycle(:,1),'--',Fecha(30:277),cycle(:,j),'LineWidth',1.5);
xlim([1953 2017]);
leg1=legend('Ln(PBI)', nombres1{j});
set(leg1, 'location', 'NorthEast');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');
end;
orient landscape
saveas(gcf,'ln_resto','pdf');

%% Estadísticos del componente cíclico
media = mean(cycle);
desviacion_std = std(cycle);
correlacion = corrcoef(cycle);

% Correlación entre el componente cíclico del PBI y el correspondiente a la productividad (ventanas móviles)
% 164 corresponde a 1994.4
x1=[];
for j=0:21
x = corrcoef(cycle(1:164+j*4,1),cycle(1:164+j*4,8));
x1 = [x1;x];
end;
% 108 corresponde a 1980.4
x2=[];
for j=0:35
xx = corrcoef(cycle(1:108+j*4,1),cycle(1:108+j*4,8));
x2 = [x2;xx];
end;

% Correlación entre el componente cíclico del PBI y el correspondiente a las horas trabajadas y el empleo (ventanas móviles)
% 108 corresponde a 1980.4
% Horas
x3=[];
for j=0:35
xxx = corrcoef(cycle(1:108+j*4,1),cycle(1:108+j*4,5));
x3 = [x3;xxx];
end;

% Empleo
x4=[];
for j=0:35
xxxx = corrcoef(cycle(1:108+j*4,1),cycle(1:108+j*4,6));
x4 = [x4;xxxx];
end;

% Autocorrelaciones
autocorrelacion.pbi = autocorr(cycle(:,1),1);
autocorrelacion.consumo = autocorr(cycle(:,2),1);
autocorrelacion.inversion = autocorr(cycle(:,3),1);
autocorrelacion.capital = autocorr(cycle(:,4),1);
autocorrelacion.horas = autocorr(cycle(:,5),1);
autocorrelacion.empleo = autocorr(cycle(:,6),1);
autocorrelacion.salario_real = autocorr(cycle(:,7),1);
autocorrelacion.productividad = autocorr(cycle(:,8),1);

%% PTF-PBI (anual)
load PBI_TFP_anual;
%{ 
Nota:
- La primera columna de PBI_TFP_anual es el PBI real (en billones de US$ del 2009)
- La segunda columna es TFP (mfp_tables_historical.xlsx, fila 786)
%}
% Data en logarítmo natural
PBI_TFP_anual1 = [PBI_TFP_anual(:,1)*10^9, PBI_TFP_anual(:,2)];
ln_PBI_TFP_anual = log(PBI_TFP_anual1);
% Filtro HP
[trend1, ciclo1] = hpfilter(ln_PBI_TFP_anual,1600);
time = 1948:2015;
plot(time, ciclo1(:,1),'r',time, ciclo1(:,2),'--b','LineWidth',1.5);
xlim([1947 2016]);
leg1=legend('Ln(PBI)', 'Ln(PTF)');
set(leg1, 'location', 'North');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');
grid;
orient landscape
saveas(gcf,'TFP','pdf');

% Estadísticos
desviacion_std = std(ciclo1);
correlacion = corrcoef(ciclo1);
autocorrelacion = autocorr(ciclo1,1);
