%-------------------------------------------------------------------------%
% Modelo de Long y Plosser (1983)
% Considera el modelo no-lineal: variables en logarítmo
%-------------------------------------------------------------------------%
/*
[1] Autor: Hamilton Galindo - Alexis Montecinos
[2] Fecha: Julio 2011, enero 2017
[3] Uso: 
- Este mod es utilizado en el capítulo 2 y 3. En el capítulo 2, este código 
se usa para  ejemplificar los comandos de Dynare. En el capítulo 3
se utiliza para obtener la solución del modelo y los IRF.
[4] Supuestos:
- El modelo de Long y Plosser (1983) supone: depreciación total y
función de utilidad logarítmica.
[5] Comentarios:
- La calibración corresponde a valores trimestrales y es tomado de
King y Rebelo (2000). "Resuscitating Real Business Cycles".
*/
%============================================
% Nota1: en el archivo mod se puede añadir comentarios colocando primero % o //. Tambien se puede
% escribir un parágrafo colocando /* al inicio y */ al final. 
%-------------------------------------------------------------------------%
% VARIABLES (8)                                                                        
%-------------------------------------------------------------------------%

var
% este comando (var) es para introducir las variables endógenas
cc   $ln c$ (long_name = 'Ln Consumo')                     % Ln consumo
ii    $ln i$ (long_name = 'Ln Inversión')                       %Ln inversión
yy   $ln y$ (long_name = 'Ln Producto')                      %Ln producto
kk   $ln k$ (long_name = 'Ln Capital')                         %Ln capital
hh   $ln h$ (long_name = 'Ln Trabajo')                        %Ln trabajo
rr   $ln r$ (long_name = 'Ln Tasa de interés real')      %Ln renta de alquiler de capital
ww   $ln w$ (long_name = 'Ln Salario real')                 %Ln salario real
aa   $ln a$ (long_name = 'Ln Productividad')              %Ln productividad
; % al final de este bloque (variables endógenas) se debe de colocar ";"

varexo e $e_t$ (long_name = 'Choque de productividad');
% el comando "varexo" es para introducir las variables exógenas
%-------------------------------------------------------------------------%
% PARAMETROS ()                                                                         
%-------------------------------------------------------------------------%
parameters
% el comando "parameters" introduce a los parámetros del modelo. Este bloque tambien termina
% con ";"
theta      $\theta$ (long_name = 'peso del ocio en la función de utilidad')
beta       $\beta$ (long_name = 'factor de descuento')
alpha     $\alpha$ (long_name = 'participación del trabajo en el ingreso nacional')
phi         $\phi$ (long_name = 'persistencia del choque')
sigma_ee $\sigma_e$ (long_name = 'des. est. del choque')
y_ss 
c_ss 
i_ss
w_ss
r_ss
k_ss
h_ss
a_ss
;
% Nota2: nunca nombra a la des. est. "sigma_e" debido a que es un nombre 
% propio de Dynare. Si se utiliza Dynare mostrará un error y no correrá el modelo.
%-------------------------------------------------------------------------%
% CALIBRACIÓN                                                                       
%-------------------------------------------------------------------------%
%1)Preferencias
%--------------
h_ss = 0.2;
beta = 0.984;
%2)Empresas
%--------------
alpha = 0.667;
%3)Choques
%--------------
phi = 0.979; 
sigma_ee = 0.0072;
%--------------
% Aquí recien se calcula theta (debido a que necesitaba que alpha y beta sean previamente definidos):
theta = alpha*(1 - h_ss)/(h_ss*(1 - beta*(1-alpha))); % =3.968
%-------------------------------------------------------------------------%
% ESTADO ESTACIONARIO                                                                    
%-------------------------------------------------------------------------%
r_ss = 1/beta;
a_ss = 1;
k_ss = h_ss*(1/(beta*(1-alpha)))^(-1/alpha);
i_ss = k_ss;
y_ss = k_ss*(1/(beta*(1-alpha)));
c_ss = k_ss*(1/(beta*(1-alpha)) - 1);
w_ss = alpha*y_ss/h_ss;
% Aqui recien acaba el bloque de "parameters"

model;
% El comando "model" hace referencia al modelo DSGE
%================================
% Familias 
%================================
1/exp(cc) = beta*(1/exp(cc(+1)))*(exp(rr(+1))); 
exp(kk) = exp(ii);
theta/(1-exp(hh)) = exp(ww)/exp(cc);
%================================
% Firmas
%================================
exp(yy) = exp(aa)*((exp(kk(-1)))^(1-alpha))*exp(hh)^(alpha);
exp(rr) = (1-alpha)*exp(yy)/exp(kk(-1));
exp(ww) = (alpha)*exp(yy)/exp(hh);
%================================
% Condición de mercado 
%================================
exp(yy) = exp(cc) + exp(ii);  
%================================
% Fuentes de incertidumbre 
%================================
aa = phi*aa(-1) + e;
end;
write_latex_dynamic_model; % escribe el modelo dinámica en formato LaTeX
%-------------------------------------------------------------------------%
% VALORES INICIALES
%-------------------------------------------------------------------------%
% el bloque "initval" hace referencia a los valores iniciales del modelo
initval;
hh = log(h_ss);
kk = log(k_ss);
ii = log(i_ss);
cc = log(c_ss);
ww = log(w_ss);
rr = log(r_ss);
yy = log(y_ss);
aa = log(a_ss);
end;
% Este bloque termina con "end"
resid(1);
%El comando "resid(1)" evalua las ecuaciones del modelo para los valores iniciales
steady;
%"steady" pide a dynare que considere los valores inciales como aproximaciones y que las
%simulaciones o IRFs empiecen desde el estado estacionario exacto.
%-------------------------------------------------------------------------%
% CHOQUES                                                                          
%-------------------------------------------------------------------------%
% el bloque "shocks" ...."end" define la varianza del choque
shocks;
var e = (sigma_ee)^2;
end;

check;
%"check" calcula y muestra los valores del sistema, los cuales son usados en el método de solución
%-------------------------------------------------------------------------%
%SIMULACIÓN: 
%-------------------------------------------------------------------------%
%stoch_simul(order = 1, hp_filter=1600); % usa filtro HP

% stoch_simul(order = 1, periods = 150); rplot yy;
stoch_simul(order = 1);
% Simulación 100 veces para 150 periodos
% - Quitar "/*....*/" para hacer la simulación
/*
stoch_simul(order = 1,irf=40, periods = 150, simul_replic=100); % usar para varias simulaciones
[sim_array]=get_simul_replications(M_,options_);
yy_sim=squeeze(sim_array(strmatch('yy',M_.endo_names,'exact'),:,:));
kk_sim=squeeze(sim_array(strmatch('kk',M_.endo_names,'exact'),:,:));
cc_sim=squeeze(sim_array(strmatch('cc',M_.endo_names,'exact'),:,:));
rr_sim=squeeze(sim_array(strmatch('rr',M_.endo_names,'exact'),:,:));
ii_sim=squeeze(sim_array(strmatch('ii',M_.endo_names,'exact'),:,:));
ww_sim=squeeze(sim_array(strmatch('ww',M_.endo_names,'exact'),:,:));
hh_sim=squeeze(sim_array(strmatch('hh',M_.endo_names,'exact'),:,:));
aa_sim=squeeze(sim_array(strmatch('aa',M_.endo_names,'exact'),:,:));

simulaciones = {yy_sim, cc_sim, ii_sim, kk_sim, rr_sim,ww_sim,hh_sim,aa_sim};
*/