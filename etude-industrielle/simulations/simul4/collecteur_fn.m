function [valid_out, feat_out, label_out] = collecteur_fn(feat, label)
%COLLECTEUR_FN  Associe chaque nouvelle fenetre a son label de mode
%  Entree : feat      vecteur 1x6 (issu de features_fn)
%           label     scalaire  (classe courante : 1=Arret…4=Avion)
%  Sortie : valid_out 1 si nouvelle fenetre disponible, 0 sinon
%           feat_out  vecteur 1x6 (copie de feat — pour To Workspace)
%           label_out scalaire (label associe — pour To Workspace)
%  Seules les lignes ou valid_out=1 seront utilisees par stop4_train.m
%#codegen

persistent last_feat
if isempty(last_feat)
    last_feat = zeros(1, 6);
end

% Declaration avant le if — taille connue de Simulink
valid_out  = double(0);
feat_out   = feat;
label_out  = label;

if any(feat ~= last_feat)
    valid_out = double(1);
    last_feat = feat;
end
end
