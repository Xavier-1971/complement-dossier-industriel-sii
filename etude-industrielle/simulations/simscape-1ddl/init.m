g=9.81;
% définition du choc
T=11E-3;
A=10*g;

% Récupère la valeur actuelle du Rotary Switch
config = str2double(get_param([gcs, '/Rotary Switch'], 'Value'));

% caractéristiques de l'emballage de la palette (modèle simple)
%   souple   médium     rigide
K = [157914,  986960,  3947842]; % N/m
C = [ 2513,    6283,    12566]; % N/s.m
config
k = K(config)
c = C(config)

% Met à jour le workspace
assignin('base', 'config', config);
assignin('base', 'k', k);
assignin('base', 'c', c);



% équilibre statique
deltaSt=m*g/k;

m=1000;


