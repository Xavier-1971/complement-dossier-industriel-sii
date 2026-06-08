%% init3.m — Jumeau numérique simul3 : chaîne avec défauts
%
%  Trois défauts introduits par rapport à la chaîne idéale (simul2) :
%    1. Erreur d'échelle capteur : eps_capteur = +0.03  (+3 %)
%    2. Bruit capteur dégradé   : 2 mg_rms  (au lieu de 0,5 mg)
%    3. Plage CAN réduite       : ±5 g      (au lieu de ±10 g)
%       → LSB doublé, SNR réduit de 6 dB

%% Nettoyage au démarrage
clear all;
clc;
close all;

%% Profil DSP cible — ASTM D4728-17
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

%% Génération du signal temporel acc_reelle (identique à simul2)
fs = 5000;
T  = 600;
N  = T * fs;
df = 1 / T;
graine = 42;

k     = (1 : N/2-1);
f_pos = k * df;

log_S = interp1(log10(dsp_in(:,1)), log10(dsp_in(:,2)), log10(f_pos), 'linear', 'extrap');
S     = 10.^log_S;
A     = sqrt(S * df / 2);

rng(graine);
phi      = 2 * pi * rand(1, N/2-1);
ACC_pos  = A .* exp(1j * phi);
ACC_full = [0, ACC_pos, 0, conj(fliplr(ACC_pos))];
acc      = real(ifft(ACC_full)) * N;
t        = (0 : N-1)' / fs;

acc_reelle = timeseries(acc', t);

%% g_rms analytique (vérification)
f_dense2    = logspace(log10(4), log10(200), 100000);
log_S_dense = interp1(log10(dsp_in(:,1)), log10(dsp_in(:,2)), log10(f_dense2), 'linear', 'extrap');
grms_ref    = sqrt(trapz(f_dense2, 10.^log_S_dense));
fprintf('g_rms analytique (4-200 Hz) : %.3f g\n', grms_ref);

%% ── Paramètres capteur IEPE (avec défauts) ───────────────────────────────
K_s = 50e-3;            % 50 mV/g  (Kistler 8792A100 : plage ±100 g)

% DÉFAUT 1 : erreur d'échelle +3 %  (simul2 : eps_capteur = 0)
eps_capteur = +0.03;

% Filtre passe-haut IEPE
f_c_IEPE  = 0.5;
tau_IEPE  = 1 / (2 * pi * f_c_IEPE);

% DÉFAUT 2 : bruit capteur dégradé — 2 mg_rms  (simul2 : 0,5 mg)
sigma_bruit_g       = 2e-3;                        % 2 mg
sigma_bruit_V       = K_s * sigma_bruit_g;         % en V
bruit_capteur_power = sigma_bruit_V^2 * (1/fs);

fprintf('\n── Paramètres capteur (avec défauts) ───────────────\n');
fprintf('Sensibilité K_s          : %g mV/g\n',  K_s*1e3);
fprintf('Erreur d''échelle         : %+.1f %%  (DÉFAUT 1)\n', eps_capteur*100);
fprintf('Coupure HP IEPE          : %.2f Hz  (tau = %.4f s)\n', f_c_IEPE, tau_IEPE);
fprintf('Bruit capteur RMS        : %.1f mg  (DÉFAUT 2, simul2 : 0,5 mg)\n', sigma_bruit_g*1e3);
fprintf('────────────────────────────────────────────────────\n');

%% ── Paramètres AAF (identique à simul2) ──────────────────────────────────
ordre_aaf = 4;
f_aaf     = 500;
omega_aaf = 2*pi*f_aaf;

%% ── Paramètres PGA AD8253 (identique à simul2) ───────────────────────────
Vref_adc     = 5;            % tension de référence ADC (V) — fixe

plage_g_vib  = 10;           % demi-plage mode vibration (g)
plage_g_choc = 100;          % demi-plage mode choc (g)

G_pga_vib  = Vref_adc / (plage_g_vib  * K_s);   % = 10
G_pga_choc = Vref_adc / (plage_g_choc * K_s);   % = 1

G_pga   = G_pga_vib;
plage_g = plage_g_vib;

fprintf('\n── Paramètres PGA ───────────────────────────────────\n');
fprintf('G_pga vibration  : ×%.0f  (plage ±%g g)\n', G_pga_vib,  plage_g_vib);
fprintf('G_pga choc       : ×%.0f   (plage ±%g g)\n', G_pga_choc, plage_g_choc);
fprintf('Mode actif       : vibration  (G_pga = ×%.0f)\n', G_pga);
fprintf('────────────────────────────────────────────────────\n');

%% ── Paramètres CAN AD7606-4 16 bits ──────────────────────────────────────
n_bits  = 16;

LSB_V = 2 * Vref_adc / 2^n_bits;   % pas en V (après PGA)
LSB_g = 2 * plage_g  / 2^n_bits;   % pas en g

sigma_quant_g = LSB_g / sqrt(12);
SNR_quant_dB  = 20*log10(0.40 / sigma_quant_g);

fprintf('\n── Paramètres CAN ───────────────────────────────────\n');
fprintf('Résolution     : %d bits\n', n_bits);
fprintf('Vref ADC       : ±%.1f V  (fixe)\n', Vref_adc);
fprintf('Plage          : ±%g g  (mode vibration)\n', plage_g);
fprintf('LSB            : %.2f µV  /  %.4f mg\n', LSB_V*1e6, LSB_g*1e3);
fprintf('Bruit quant.   : %.4f mg\n', sigma_quant_g*1e3);
fprintf('SNR quantif.   : %.1f dB\n', SNR_quant_dB);
fprintf('────────────────────────────────────────────────────\n');

%% ── Paramètres décimateur FIR (identique à simul2) ──────────────────────
M_dec   = 10;
fs_dec  = fs / M_dec;
N_fir   = 289;

fp_norm = 200  / (fs/2);
fs_norm = 250  / (fs/2);
h_dec   = firpm(N_fir, [0 fp_norm fs_norm 1], [1 1 0 0]);

fprintf('\n── Paramètres FIR décimateur ────────────────────────\n');
fprintf('Facteur de décimation : %d  (%g Hz → %g Hz)\n', M_dec, fs, fs_dec);
fprintf('Nombre de coefficients : %d\n', N_fir+1);
fprintf('────────────────────────────────────────────────────\n');
