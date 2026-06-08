# Compléments Dossier Industriel — SII

Ressources associées au dossier industriel pour la préparation au concours de l'agrégation externe en **Sciences Industrielles de l'Ingénieur (SII)**.

Système étudié : **SAVER 3X90** (Lansmont) — testeur de transport par simulation vibratoire et choc.

---

## etude-industrielle/

### notebooks/
Notebooks Jupyter exécutables localement ou dans le navigateur via [Basthon](https://notebook.basthon.fr).

| Fichier | Description |
|---|---|
| `dilemme_choc_vibration.ipynb` | Système masse-ressort-amortisseur 1 DDL — transmissibilité, réponse au choc, optimisation f₀ et ζ |
| `fourier_transformees.ipynb` | Les quatre transformées de Fourier (TF, SF, TFTD, TFD) |
| `plancher_de_bruit.ipynb` | Plancher de bruit 0,02 g_rms / 500 Hz |
| `signaux_stochastiques.ipynb` | Signaux stochastiques |
| `synthese_spectrale.ipynb` | Synthèse spectrale à phases aléatoires |
| `welch_explication.ipynb` | Méthode de Welch — DSP pas à pas |

### simulations/
- `simscape-1ddl/` — Simulation Simscape Multibody du système masse-ressort-amortisseur 1 DDL (`simulglissieres.slx`, `init.m`, exports STEP, CAO SolidWorks)

### documentation/
- `saver/lansmont/` — Notices et spécifications SAVER 3X90 (Lansmont)
- `saver/kistler/` — Documentation capteurs Kistler
- `normes/` — Normes applicables (ASTM D4728…)
- `mesures/` — Données expérimentales brutes *(à compléter)*

### references-bib/
- `Méthode shinozuka.pdf` — Article sur la méthode de Shinozuka pour la génération de signaux stochastiques

---

## developpement-pedagogique/

Section en cours de construction.

---

## plateforme-stewart/

Ressources de conception de la plateforme de Stewart utilisée en TP (complément au dossier industriel).

- `cao/` — Fichiers SolidWorks version 2025 (pièces `.SLDPRT`, assemblages `.SLDASM`, fichier `.STL`)

---

Site de référence : [xl-si.fr](https://xl-si.fr)
