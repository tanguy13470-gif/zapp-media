# Kit DA Star AC' Pronos — journal intime + digital

- `da.css` + `kit.js` : fond pastel papier, logo, étoile sticker, scotch, polaroïd, bulles de message, barre de recherche, post-it, cases à cocher.
- Rendu : `node shot.js <fichier>.html s1 s2 ...` → `out/` (créer le dossier, et `clara2.png` si le gabarit utilise la photo).
- `journal.html` : gabarit du Journal de Zapp' (5 slides 1080x1350). Remplacer les textes d'exemple par les vrais chiffres et retirer les `<div class="mod">`.

Règles de DA (validées par Clara) :
- Pastels uniquement (rose #FFD7E5, bleu #D4E5FF, jaune #FFF1B4, menthe #D9F4E7, lilas #EFE6FF), magenta #B32D72 pour les étiquettes, brun #3B2314 pour le texte.
- Mélange journal intime (papier ligné ou quadrillé, scotch, post-it, écriture manuscrite, stickers) et codes du numérique (bulles de message, barre de recherche, notifications, widgets).
- Photos : dans un polaroïd, une bulle ronde ou avec un contour net. JAMAIS d'effet flou ou de bords fondus.
- Jamais le style « journal papier éditorial / presse ».
- Ne plus utiliser la photo du micro (Gemini « Micro star ac »).

Photos détourées (covers plus visuelles) :
- `candidats/<prénom sans accent>.png` : les 17 élèves, détourés avec contour blanc, récupérés depuis le site de l'appli (`https://star-academy-clarou.netlify.app/candidates/<prénom>.jpg`). Dans `covers-photos.html`, `P('noemie',x,y,largeur,rotation)`.
- `moi_selfie.png`, `moi_top.png`, `cut_defi.png` : photos de moi détourées. `ME('moi_top.png',x,y,largeur,rotation)`.
- Règle : dès qu'un post parle d'un·e élève, sa photo détourée va sur la cover ; sinon une photo de moi. Plus des emojis pertinents en sticker (`EM`).
- `covers-photos.html#nom5` est un modèle : remplacer le tableau `N` par le vrai top 3 (prénom du fichier, prénom affiché, %).
