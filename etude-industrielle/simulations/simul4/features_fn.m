function feat = features_fn(frame)
%FEATURES_FN  Extraction de 6 primitives spectrales sur une fenetre de 2500 pts
%  Entree : frame  vecteur 2500x1 (issu du bloc Buffer DSP, cadence T_hop = 5 s)
%  Sortie : feat   vecteur 1x6 [RMS, crete, f_centroid, E_basse, E_milieu, E_haute]
%
%  Le bloc Buffer DSP ne sort qu'une fenetre complete par appel :
%  le calcul est donc systematique (pas de garde sur les zeros).
%#codegen
fs_loc = 250;
N_loc  = 2500;

x = frame;

rms_val  = sqrt(mean(x.^2));
crete    = max(abs(x)) / (rms_val + 1e-12);

X_fft    = abs(fft(x)).^2 / (N_loc * fs_loc);
X_one    = X_fft(1:N_loc/2+1);
X_one(2:end-1) = 2 * X_one(2:end-1);
f_v      = (0:N_loc/2)' * fs_loc / N_loc;
df_loc   = fs_loc / N_loc;
E_tot    = sum(X_one) * df_loc + 1e-12;

f_c      = sum(f_v .* X_one) * df_loc / E_tot;
E_basse  = sum(X_one(f_v >= 1  & f_v <  5 )) * df_loc / E_tot;
E_milieu = sum(X_one(f_v >= 5  & f_v < 50 )) * df_loc / E_tot;
E_haute  = sum(X_one(f_v >= 50 & f_v < 125)) * df_loc / E_tot;

feat = [rms_val, crete, f_c, E_basse, E_milieu, E_haute];
end
