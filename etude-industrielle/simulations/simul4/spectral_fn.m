function [f_c, E_basse, E_milieu, E_haute] = spectral_fn(X_fft)
%SPECTRAL_FN  4 primitives spectrales a partir de la FFT brute d'une fenetre
%  Entree : X_fft   vecteur 2500x1 complexe — sortie directe du bloc FFT DSP
%  Sorties :
%    f_c      frequence centroide (Hz)
%    E_basse  energie relative bande [1-5 Hz]
%    E_milieu energie relative bande [5-50 Hz]
%    E_haute  energie relative bande [50-125 Hz]
%#codegen
fs_loc = 250;
N_loc  = 2500;

% DSP bilateral → spectre de puissance monolateral [1251 x 1]
X_pow  = abs(X_fft).^2 / (N_loc * fs_loc);
X_one  = X_pow(1:N_loc/2+1);
X_one(2:end-1) = 2 * X_one(2:end-1);    % doubler les termes internes

f_v    = (0:N_loc/2)' * fs_loc / N_loc; % vecteur frequences [0..125 Hz]
df_loc = fs_loc / N_loc;
E_tot  = sum(X_one) * df_loc + 1e-12;

f_c      = sum(f_v .* X_one) * df_loc / E_tot;
E_basse  = sum(X_one(f_v >= 1  & f_v <  5 )) * df_loc / E_tot;
E_milieu = sum(X_one(f_v >= 5  & f_v < 50 )) * df_loc / E_tot;
E_haute  = sum(X_one(f_v >= 50 & f_v < 125)) * df_loc / E_tot;
end
