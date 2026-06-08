function frame = buffer_fn(x)
%BUFFER_FN  Fenetre glissante 2500 pts, overlap 50%
%  Entree : x      scalaire (1 echantillon a 250 Hz)
%  Sortie : frame  vecteur 2500x1 (nouveau toutes les 1250 entrees, zeros sinon)
%#codegen
N  = int32(2500);
NO = int32(1250);

persistent buf cnt
if isempty(buf)
    buf = zeros(N, 1);
    cnt = int32(0);
end

buf = [buf(2:end); x];
cnt = cnt + int32(1);

% Declaration explicite AVANT le if : Simulink connait la taille de sortie
frame = zeros(N, 1);
if cnt >= NO
    frame = buf;
    cnt   = int32(0);
end
end
