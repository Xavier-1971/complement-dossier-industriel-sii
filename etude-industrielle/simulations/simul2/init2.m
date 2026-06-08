%% Nettoyage au démarrage
clear all;   % efface toutes les variables du workspace
clc;         % efface la console
close all;   % ferme toutes les figures ouvertes

%% Profil DSP cible — ASTM D4728-17 (12 breakpoints, avant normalisation)
dsp_in = [  1,   4.25e-4;
            3,   1.062e-2;
            4,   1.062e-2;
            6,   4.25e-4;
           10,   4.25e-4;
           12,   2.12e-3;
           25,   2.12e-3;
           30,   4.25e-4;
           40,   2.12e-3;
           80,   2.12e-3;
          100,   2.12e-4;
          200,   1.062e-5];

%% Affichage du profil DSP cible
figure('Name', 'DSP cible — ASTM D4728-17', 'NumberTitle', 'off');
loglog(dsp_in(:,1), dsp_in(:,2), 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
grid on;
xlabel('Fréquence (Hz)');
ylabel('DSP (g²/Hz)');
title('Profil DSP cible — ASTM D4728-17');
xlim([1 200]);

%% Génération du signal temporel acc_reelle
fs = 5000;      % fréquence d'échantillonnage (Hz)
T  = 600;       % durée du signal (s)
N  = T * fs;    % nombre d'échantillons
df = 1 / T;     % résolution fréquentielle (Hz)
graine = 42;

k     = (1 : N/2-1);
f_pos = k * df;

log_S = interp1(log10(dsp_in(:,1)), log10(dsp_in(:,2)), log10(f_pos), 'linear', 'extrap');
S     = 10.^log_S;
A     = sqrt(S * df / 2);          % amplitude (spectre bilatéral)

rng(graine);
phi      = 2 * pi * rand(1, N/2-1);
ACC_pos  = A .* exp(1j * phi);
ACC_full = [0, ACC_pos, 0, conj(fliplr(ACC_pos))];
acc      = real(ifft(ACC_full)) * N;
t        = (0 : N-1)' / fs;

acc_reelle = timeseries(acc', t);   % format From Workspace

%% g_rms analytique (vérification)
f_dense2    = logspace(log10(4), log10(200), 100000);
log_S_dense = interp1(log10(dsp_in(:,1)), log10(dsp_in(:,2)), log10(f_dense2), 'linear', 'extrap');
grms_ref    = sqrt(trapz(f_dense2, 10.^log_S_dense));
fprintf('g_rms analytique (4-200 Hz) : %.3f g\n', grms_ref);

%% ── Paramètres capteur IEPE (Kistler 8792A100) ───────────────────────────

% Sensibilité nominale
K_s = 50e-3;            % 50 mV/g → en V/g  (Kistler 8792A100 : plage ±100 g)

% Erreur d'échelle (défaut réglable)
%   0    = capteur idéal
%  +0.01 = sensibilité +1 % (sur-estimation)
%  -0.01 = sensibilité -1 % (sous-estimation)
eps_capteur = 0;

% Filtre passe-haut IEPE (couplage capacitif piézoélectrique)
%   f_c = 0.5 Hz  →  tau = 1/(2*pi*f_c)
f_c_IEPE  = 0.5;                    % fréquence de coupure (Hz)
tau_IEPE  = 1 / (2 * pi * f_c_IEPE);  % constante de temps (s)  ≈ 0.318 s

% Bruit propre capteur
%   Bruit RMS typique : 0.5 mg sur [0-1000 Hz]
%   Après K_s = 100 mV/g :  0.5e-3 g × 100e-3 V/g = 0.05 mV = 50 µV
%   Pour Band-Limited White Noise Simulink : power = sigma² × Ts
sigma_bruit_V      = K_s * 0.5e-3;            % bruit en V (0.05 mV)
bruit_capteur_power = sigma_bruit_V^2 * (1/fs); % puissance pour bloc Simulink

fprintf('\n── Paramètres capteur ──────────────────────────────\n');
fprintf('Sensibilité     K_s          : %g mV/g\n',  K_s*1e3);
fprintf('Erreur d''échelle eps_capteur  : %+.1f %%\n', eps_capteur*100);
fprintf('Coupure HP IEPE f_c          : %.2f Hz  (tau = %.4f s)\n', f_c_IEPE, tau_IEPE);
fprintf('Bruit RMS capteur            : %.4f mV  (%.2f mg)\n', sigma_bruit_V*1e3, 0.5);
fprintf('────────────────────────────────────────────────────\n');

%% ── Paramètres filtre anti-repliement analogique (AAF) ───────────────────
%   Butterworth analogique 4 pôles, f_c = 500 Hz
%   Modélisé dans Simulink par le bloc "Analog Filter Design" (DSP System Toolbox)
%   → paramètres passés directement au bloc via ces variables

ordre_aaf    = 4;              % ordre du filtre (4 pôles)
f_aaf        = 500;            % fréquence de coupure (Hz)
omega_aaf    = 2*pi*f_aaf;     % pulsation de coupure (rad/s) — entrée du bloc Simulink

% Vérification analytique : atténuation à Nyquist (fs/2 = 2500 Hz)
%   Butterworth ordre n : |H(jω)|² = 1 / (1 + (ω/ω_c)^(2n))
omega_nyq    = 2*pi*(fs/2);
H_nyq_sq     = 1 / (1 + (omega_nyq/omega_aaf)^(2*ordre_aaf));
atten_nyq_dB = -10*log10(H_nyq_sq);

fprintf('\n── Paramètres AAF ───────────────────────────────────\n');
fprintf('Type             : Butterworth analogique %d pôles\n', ordre_aaf);
fprintf('Fréquence de coupure f_aaf : %g Hz  (omega = %.1f rad/s)\n', f_aaf, omega_aaf);
fprintf('Atténuation à Nyquist (%g Hz) : %.1f dB\n', fs/2, atten_nyq_dB);
fprintf('────────────────────────────────────────────────────\n');

%% ── Paramètres CAN 16 bits + PGA ─────────────────────────────────────────
%   Vref_adc : tension de référence fixe de l'ADC
%   PGA commute entre deux gains pour adapter la plage au signal
%     → mode vibration : G_pga_vib  = 10  (plage ±10 g)
%     → mode choc      : G_pga_choc =  1  (plage ±100 g)
%   Dans le modèle Simulink, double-cliquer sur PGA_SW pour commuter.

n_bits      = 16;           % résolution du CAN (bits)
Vref_adc    = 5;            % tension de référence ADC (V) — fixe

plage_g_vib  = 10;          % demi-plage mode vibration (g)
plage_g_choc = 100;         % demi-plage mode choc (g)

% Gains PGA : G_pga = Vref_adc / (plage_g × K_s)
G_pga_vib  = Vref_adc / (plage_g_vib  * K_s);   % = 10
G_pga_choc = Vref_adc / (plage_g_choc * K_s);   % = 1

% Mode actif par défaut : vibration
G_pga   = G_pga_vib;
plage_g = plage_g_vib;

% Pas de quantification (dans le domaine tension entrée ADC)
LSB_V = 2 * Vref_adc / 2^n_bits;           % pas en V (après PGA)
LSB_g = 2 * plage_g  / 2^n_bits;           % pas en g

% Bruit de quantification
sigma_quant_g = LSB_g / sqrt(12);
SNR_quant_dB  = 20*log10(0.40 / sigma_quant_g);

fprintf('\n── Paramètres CAN + PGA ─────────────────────────────\n');
fprintf('Résolution ADC   : %d bits\n', n_bits);
fprintf('Vref ADC         : ±%.1f V  (fixe)\n', Vref_adc);
fprintf('G_pga vibration  : ×%.0f  (plage ±%g g)\n', G_pga_vib,  plage_g_vib);
fprintf('G_pga choc       : ×%.0f   (plage ±%g g)\n', G_pga_choc, plage_g_choc);
fprintf('Mode actif       : vibration  (G_pga = ×%.0f)\n', G_pga);
fprintf('LSB              : %.2f µV  /  %.4f mg\n', LSB_V*1e6, LSB_g*1e3);
fprintf('Bruit quant. RMS : %.4f mg\n', sigma_quant_g*1e3);
fprintf('SNR quantif.     : %.1f dB  (signal 0.40 g_rms)\n', SNR_quant_dB);
fprintf('────────────────────────────────────────────────────\n');

%% ── Paramètres décimateur FIR (10:1) ────────────────────────────────────
%   Entrée  : signal numérique à fs = 5000 Hz
%   Sortie  : signal décimé à fs_dec = 500 Hz
%   Filtre  : Parks-McClellan équiripple, passband 0-200 Hz, stopband 250+ Hz
%             (stopband = Nyquist après décimation = fs_dec/2 = 250 Hz)

M_dec   = 10;                   % facteur de décimation
fs_dec  = fs / M_dec;           % fréquence d'échantillonnage après décimation (Hz)
N_fir   = 289;                  % ordre du filtre (290 coefficients)

% Fréquences normalisées (0 à 1, où 1 = Nyquist entrée = 2500 Hz)
fp_norm  = 200  / (fs/2);       % bord passant  : 200 Hz → 0.080
fs_norm  = 250  / (fs/2);       % bord coupant  : 250 Hz → 0.100

% Conception Parks-McClellan (équiripple optimal)
h_dec = firpm(N_fir, [0 fp_norm fs_norm 1], [1 1 0 0]);

% Vérification : atténuation réelle à 250 Hz
H_check  = freqz(h_dec, 1, [200 250], fs);
atten_250_dB = -20*log10(abs(H_check(2)));

fprintf('\n── Paramètres décimateur FIR ────────────────────────\n');
fprintf('Facteur de décimation M  : %d  (%g Hz → %g Hz)\n', M_dec, fs, fs_dec);
fprintf('Nombre de coefficients   : %d\n', N_fir+1);
fprintf('Bord passant             : %g Hz\n', fp_norm * (fs/2));
fprintf('Bord coupant (Nyquist)   : %g Hz\n', fs_norm * (fs/2));
fprintf('Atténuation à 250 Hz     : %.1f dB\n', atten_250_dB);
fprintf('────────────────────────────────────────────────────\n');
