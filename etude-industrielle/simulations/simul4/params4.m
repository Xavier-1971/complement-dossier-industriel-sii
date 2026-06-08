%% params4.m — Parametres communs aux deux simulations (entrainement et inference)
% A executer en debut de start4_train.m et start4_infer.m

%% Parametres temporels et frequentiels
fs      = 250;      % Hz  (Nyquist 125 Hz > DLPF 111 Hz)
T_win   = 10;       % s   duree fenetre d'analyse
N_win   = T_win * fs;          % 2500 echantillons
MODES   = {'Arret','Camion','Train','Avion'};

%% Profils DSP [f(Hz), S(g2/Hz)] — ASTM D4169-16 Table X1.1, Level II
noise_density = 120e-6;        % g/rtHz — datasheet ICM-20948
S_plancher    = noise_density^2;

dsp_arret  = [  1, S_plancher; 200, S_plancher];
dsp_camion = [  1, 0.00005;  4, 0.01; 16, 0.01; 40, 0.001; 300, 0.00001];
dsp_train  = [  1, 0.00001;  2, 0.001; 80, 0.001; 90, 0.0004; 200, 0.00001];
dsp_avion  = [  2, 0.0002; 12, 0.01; 100, 0.01; 200, 0.00001];
dsps       = {dsp_arret, dsp_camion, dsp_train, dsp_avion};

%% Modele capteur ICM-20948
fc_dlpf   = 111;   % Hz — DLPF (registre ACCEL_DLPFCFG = 010)
[b_dlpf, a_dlpf] = butter(2, fc_dlpf/(fs/2), 'low');
sigma_bruit = noise_density * sqrt(fs/2);   % bruit RMS sur [0, fs/2]
biais_acc   = 0.003;                        % g — offset DC typique
bruit_power = sigma_bruit^2 * (1/fs);      % pour bloc Band-Limited White Noise

fprintf('Parametres communs charges (fs=%d Hz, N_win=%d pts, DLPF=%d Hz)\n', ...
        fs, N_win, fc_dlpf);
