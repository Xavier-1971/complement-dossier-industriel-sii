function feat_norm = normalisation_fn(feat)
%NORMALISATION_FN  Normalise les features (z-score) avec les parametres du k-NN entraine
%  Entree : feat      vecteur 1x6 (issu de features_fn)
%  Sortie : feat_norm vecteur 1x6 normalise
%  mu_train et sigma_train lus depuis le workspace (mis en place par start4_infer_knn.m)
%#codegen
coder.extrinsic('evalin');

persistent mu sig
if isempty(mu)
    mu  = zeros(1, 6);
    sig = ones(1, 6);
    mu  = evalin('base', 'mu_train');
    sig = evalin('base', 'sigma_train');
end

feat_norm = (feat - mu) ./ sig;
end
