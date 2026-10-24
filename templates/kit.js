// éléments communs
window.STAR=(x,y,s,r)=>`<svg class="star" style="left:${x}px;top:${y}px;width:${s}px;height:${s}px;transform:rotate(${r||12}deg)" viewBox="0 0 100 100"><path d="M50 6 63 36 95 39 71 61 78 93 50 76 22 93 29 61 5 39 37 36Z" fill="#FFD950" stroke="#fff" stroke-width="7" stroke-linejoin="round"/><path d="M50 14 60 38 40 38Z" fill="#FFE98F" opacity=".7"/></svg>`;
window.SPARK=(x,y,s)=>`<svg style="position:absolute;left:${x}px;top:${y}px;width:${s}px;height:${s}px" viewBox="0 0 40 40"><path d="M20 0C22 14 26 18 40 20 26 22 22 26 20 40 18 26 14 22 0 20 14 18 18 14 20 0Z" fill="#fff"/></svg>`;
window.PAPER=`<svg class="paper" width="1080" height="1920"><filter id="n"><feTurbulence type="fractalNoise" baseFrequency=".012" numOctaves="3" seed="7"/><feColorMatrix values="0 0 0 0 .55  0 0 0 0 .45  0 0 0 0 .5  0 0 0 -1.6 1.05"/></filter><rect width="100%" height="100%" filter="url(#n)" opacity=".18"/></svg>`;
window.LOGO=`<div class="logo"><i>⚡</i>Zapp' Pronos</div>`;
