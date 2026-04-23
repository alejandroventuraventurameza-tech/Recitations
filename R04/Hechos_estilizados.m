%% Hechos estilizados: economía EEUU
%{ 
Autor: Hamilton Galindo
Fecha(update): marzo 2017
%}
%% Descripción
%{ 
Las secciones de  este m-file son:
 [1] XXXX
%}
%% [1] Levantando los datos
plot(Fecha,ln_gdp)
grid;

%% [2] Calculando el capital 
ko = 2754.555; % el stock del capital de 1948 
% dato sacado de "mfp_tables_historical.xlsx", hoja "XG" (celda D9)
delta = 0.03; %parámetro de depreciación del capital

inv0 = inversion_privada_real(9:end,1)'; %desde 1949.T1
inv1 = inv0(272:-1:1); %estoy invirtiendo el orden del vector
d = [];
for j=0:size(inv,2)-1
d(j+1) = (1-delta)^j;
end;
D = d';

for t=1:size(inv,2)
    S(t) = inv1(end-t+1:end)*D(1:t);
    k(t) = ((1-delta)^t)*ko + S(t);
end;
ln_k = log(k);
%% [3] Gráficos
ln_capital = log(capital); %desde 1947 hasta 2014.4
ln_TFP = log(TFP); %desde 1947 hasta 2014.4

ln_TFP1 = log(TFP1); %desde 1949.1 hasta 2014.4 (2 forma de calcular TFP: 
% GDP.xls, hoja Data_TFP")

matriz_var = [ln_gdp_percapita,...
                    ln_consumo_percapita,...
                    ln_inversion_percapita_bd,...
                    ln_horas_percapita,...
                    ln_empleo_percapita,...
                    ln_salario_real_porhora,...
                    ln_precio,...
                    ln_productividad,...
                    ln_horas_promedio...
                    ln_capital...
                    ln_TFP];
% Gráficas
nombres = {'Ln(PBI)', 'Ln(Consumo)', 'Ln(Inversión)', 'Ln(Total de Horas)', 'Ln(Empleo)', 'Ln(Salario Real)', 'Ln(Precio)', 'Ln(Productividad Laboral)'};

subplot(2,2,1)
plot(Fecha(5:end),matriz_var(5:end,1),'--',Fecha(5:end),matriz_var(5:end,2),':',Fecha(5:end),matriz_var(5:end,3),'LineWidth',1.5);
xlim([1949 2017]);
leg1=legend('Ln(PBI)', 'Ln(Consumo)', 'Ln(Inversión)');
set(leg1, 'location', 'North');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');
grid;
                
subplot(2,2,2)
plot(Fecha(5:end),matriz_var(5:end,4),'LineWidth',1.5);
title('Ln(Total de Horas)')
xlim([1949 2017]);
grid;

subplot(2,2,3)
plot(Fecha(5:end),matriz_var(5:end,5),'LineWidth',1.5);
title('Ln(Empleo)');
xlim([1949 2017]);
grid;

subplot(2,2,4)
plot(Fecha(5:end),matriz_var(5:end,6),'LineWidth',1.5);
title('Ln(Salario Real)');
xlim([1949 2017]);
grid;

orient landscape
saveas(gcf,'series_macro0','pdf');

%% [] Filtro HP
trend = [];
cycle = [];
for j=1:size(matriz_var,2)
[trend(:,j),cycle(:,j)] = hpfilter(matriz_var(5:end,j),1600);
end;
[trend_tfp,cycle_tfp] = hpfilter(ln_TFP,1600);

%Gráfica de TFP: ciclo y tendencia

plot(Fecha(5:end-8),cycle(1:end-8,1),Fecha(5:end-8),cycle_tfp(5:end,1),'r','LineWidth',1.5);
xlim([1949 2015]);
leg1=legend('Ln(PBI)','Ln(TFP)');
set(leg1, 'location', 'South');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');

%Gráfica del PBI: tendencia y nivel
plot(Fecha(5:end),matriz_var(5:end,1),Fecha(5:end),trend(:,1),'--','LineWidth',1.5);
xlim([1949 2017]);
leg1=legend('Ln(PBI)', 'Tendencia de Ln(PBI)');
set(leg1, 'location', 'South');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');
orient landscape
saveas(gcf,'series_macro1','pdf');

%Gráfica del componente cíclico
subplot(3,2,1)
plot(Fecha(5:end),cycle(:,1),'r','LineWidth',1.5);
xlim([1949 2017]);
ylim([-0.1 0.05]);
leg1=legend('Ln(PBI)');
set(leg1, 'location', 'South');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');

for j =2:6
subplot(3,2,j)
plot(Fecha(5:end),cycle(:,1),'--',Fecha(5:end),cycle(:,j),'LineWidth',1.5);
xlim([1949 2017]);
if j ~= 3
    ylim([-0.1 0.05]);
    else
    ylim([-0.3 0.25]);
end
leg1=legend('Ln(PBI)', nombres{j});
set(leg1, 'location', 'South');
set(leg1, 'Orientation', 'Horizontal');
legend('boxoff');
end;

orient landscape
saveas(gcf,'series_macro2','pdf');

%% [] Estadísticos
%nombres = {'Ln(PBI)', 'Ln(Consumo)', 'Ln(Inversión)', 'Ln(Total de Horas)'
%, 'Ln(Empleo)', 'Ln(Salario Real)', 'Ln(Precio)', 'Ln(Productividad Laboral)', 'Ln(horas promedio)'};
media = mean(cycle);
desviacion_std = std(cycle);
correlacion = corrcoef(cycle);

corrcoef(cycle(1:end-8,1),cycle_tfp(5:end,1))
desviacion_std_tfp = std(cycle_tfp(5:end,1));

autocorrelacion.pbi = autocorr(cycle(:,1),1);
autocorrelacion.consumo = autocorr(cycle(:,2),1);
autocorrelacion.inversion = autocorr(cycle(:,3),1);
autocorrelacion.horas = autocorr(cycle(:,4),1);
autocorrelacion.empleo = autocorr(cycle(:,5),1);
autocorrelacion.salario_real = autocorr(cycle(:,6),1);

