function [rms_val, crete] = stats_fn(frame)
%STATS_FN  RMS et facteur de crete d'une fenetre temporelle
%  Entree : frame    vecteur 2500x1 (issu du bloc Buffer DSP)
%  Sorties :
%    rms_val  valeur efficace  sqrt(mean(x^2))
%    crete    facteur de crete max(|x|) / (rms + eps)
%#codegen
rms_val = sqrt(mean(frame.^2));
crete   = max(abs(frame)) / (rms_val + 1e-12);
end
