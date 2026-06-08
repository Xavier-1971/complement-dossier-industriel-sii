%% Nettoyage au démarrage
clear all;   % efface toutes les variables du workspace
clc;         % efface la console
close all;   % ferme toutes les figures ouvertes

%% Affichage du dsp d'origine
% Récupération de la valeur du bloc Constant Simulink
dsp_in = eval(get_param('simul1/dsp_in', 'Value'));

% Affichage log-log
figure('Name', 'DSP cible — ASTM D4728-17', 'NumberTitle', 'off');
loglog(dsp_in(:,1), dsp_in(:,2), 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
grid on;
xlabel('Fréquence (Hz)');
ylabel('DSP (g²/Hz)');
title('Profil DSP cible — ASTM D4728-17');
xlim([1 200]);

%% Génération du signal temporel x(t)
% Paramètres
fs=5000;        % fréquence d'échantillonnage (Hz)
T=600;         % durée du signal (s)
N=T*fs;      % nombre d'échantillons
df=1/T;       % résolution fréquentielle (Hz)
graine=42;

% Fréquences positives 
k     = (1 : N/2-1); % (hors DC et dernière)
f_pos = k * df;

% Interpolation log-log du profil dsp_in
log_S = interp1(log10(dsp_in(:,1)), log10(dsp_in(:,2)),log10(f_pos), 'linear', 'extrap');
S = 10.^log_S;

% Amplitude de chaque raie
A = sqrt(S*df/2);

% Phases aléatoires
rng(graine); % aléatoire mais graine fixe
phi = 2 * pi * rand(1, N/2-1);

% Spectre complexe
ACC_pos  = A .* exp(1j * phi);

% Construction du spectre bilatéral (fréquences négatives = miroir conjugué)
ACC_full = [0, ACC_pos, 0, conj(fliplr(ACC_pos))];  % longueur N

% Signal temporel
acc = real(ifft(ACC_full)) * N;
t = (0 : N-1)' / fs;

% Format pour le bloc From Workspace
acc_reelle = timeseries(acc', t);

%% calcul du g_rms du dsp_in entre 4 et 200 Hz
f_dense = logspace(log10(4), log10(200), 100000);
log_S_dense = interp1(log10(dsp_in(:,1)), log10(dsp_in(:,2)), ...
                      log10(f_dense), 'linear', 'extrap');
S_dense = 10.^log_S_dense;
grms_ref = sqrt(trapz(f_dense, S_dense));
fprintf('g_rms analytique (4-200 Hz) : %.3f g\n', grms_ref);