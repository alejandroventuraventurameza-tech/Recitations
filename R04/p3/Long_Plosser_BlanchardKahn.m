%% Modelo de Long y Plosser (1983, 1989)
% Real Business Cycles (1983), JPE
% Understanding Real Business Cycles (1989), JEP
%{
Autor: Hamilton Galindo
Fecha(update): Enero 2017, Febrero 2017
Modelo: depreciación total y utilidad logarítmica
"Long_Plosser_Dynare_nolineal_log.mod"
Uso: aplicación del método de solución (Blanchard y Kahn, 1980)
al archivo mod antes mencionado.
%}
%% Descripción
%{ 
Las secciones de  este m-file son:
[1] Número de variables 
[2] Parámetros 
[3] Matrices del modelo estructural 
[4] Matrices del modelo reducido 
[5] Descomponiendo F (descomposición de Jordan) 
[6] Verificando la condiciones de BK 
[7] Ordenando 
[8] Matriz H inversa 
[9] Matriz de eigenvalores 
[10] Matrices 
[11] Función de política 
[12] Función de estado
%}
%% [1] Número de variables 
m = 1; % Número de variables forward looking (o de control). En este caso es el consumo
n = 2; % Número de variable pre-determinadas (o de estado). En este caso son: capital y la productividad

%% [2] Parámetros 
phi = 0.979;
beta =  0.984;
alpha = 0.667;
h_ss = 0.2;
n_y = 1/(1 - alpha*(1-h_ss)); 
k_ss = h_ss*(1/(beta*(1-alpha)))^(-1/alpha);
i_ss = k_ss;
y_ss = k_ss*(1/(beta*(1-alpha)));
c_ss = k_ss*(1/(beta*(1-alpha)) - 1);
n_c = (c_ss/y_ss)*(1 - alpha*(1-h_ss)) + alpha*(1-h_ss); 
n_k = (1 - alpha*(1-h_ss))*i_ss/y_ss; 

%% [3] Matrices del modelo estructural 
% -(1 + alpha*(1-h_ss)*n_y/h_ss)
A = [-(1-(1-alpha)*n_y), n_y, -(1 + alpha*(1-h_ss)*n_y)
       n_k, 0, 0
       0, 1, 0];
B = [0, 0, -1;
       (1-alpha), 1, -n_c;
       0, phi, 0];
C = [0;0;1];

%% [4] Matrices del modelo reducido 
A_inv = inv(A);
F = A_inv*B;
G = A_inv*C;

%% [5] Descomponiendo F (descomposición de Jordan)
[eigenvectores,eigenvalores]=eig(F);
% extrayendo la diagonal de la matriz de eigenvalores
eig1=diag(eigenvalores);% ordenando los eigenvalores: de menor a mayor 
% ordenando los eigenvalores: de menor a mayor 
[eig2,ord]=sort(abs(eig1)); % vector "ord" contiene el número de orden que cada eigenvalor tenia antes de ordenarlo

%% [6] Verificando la condiciones de BK 
% Este bucle construye un vector de 0 y 1, donde 1 indica que el eigenvalor
% es mayor a 1.
for i=1:size(eig2,1)
if eig2(i) >1
   xx(i,1) = 1; 
end
end;
% h = N de eigenvalores fuera del circulo unitario
h = sum(xx);
% Verificando las condiciones de BK
if h == m
    display('La solución es única');
elseif h > m
    display('No hay solución del sistema')
elseif h < m
    display('Existe infinitas soluciones')
end;

%% [7] Ordenando 
% Ordenando la matriz de eigenvectores para que esté asociado a su
% eigenvalor correspondiente (después de ordenarlos)
eigenvectores_ord = eigenvectores(:,ord);
% En la notación del modelo:
H = eigenvectores_ord;
J = diag(eig2); % crea una matriz cuya diagonal es el vector "eig2"
% Verificando (descomposición de Jordan):
FF = F - H*J*inv(H); % Esta diferencia debería ser cero.

%% [8] Matriz H inversa
% inversa de la matriz de eigenvectores
H_inv = inv(H); % H^-1 es llamada "H_hat"
H_hat_11 = H_inv([1:2],[1:2]); % en este caso "hat" se refiere a "~"
H_hat_12 = H_inv([1:2],3);
H_hat_21 = H_inv(3,[1:2]);
H_hat_22 = H_inv(3,3);

%% [9] Matriz de eigenvalores 
J1 = J([1:2],[1:2]); % eigenvalores con módulo menor a uno (estable)
J2 = J(3,3); % eigenvalores con módulo mayor a uno (inestable)

%% [10] Matrices
%Matriz F
F_11 = F([1:2],[1:2]);
F_12 = F([1:2],3);
F_21 = F(3,[1:2]);
F_22 = F(3,3);
%Matriz G
G_1 = G([1:2],1);
G_2 = G(3,1);
%Matriz G inversa
G_hat = H_inv*G;
G_hat_1 = G_hat(2,1);
G_hat_1 = G_hat(3,1);

%% [11] Función de política 
% c_t = n_yx*[k_t a_t]';
n_yx = -H_hat_22^(-1)*H_hat_21;

%% [12] Función de estado
% [k_{t+1} a_{t+1}]' =  n_xx*[k_t a_t]' + n_xv*V_{t+1}
n_xx = F_11 - F_12*H_hat_22^(-1)*H_hat_21;
n_xv = G_1;