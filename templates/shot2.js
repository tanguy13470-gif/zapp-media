const {chromium}=require('playwright');(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1080,height:3400}});
await p.goto('file://'+__dirname+'/patch.html');await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(300);
for(const id of ['h3','dl']){await (await p.$('#'+id)).screenshot({path:__dirname+'/out/'+id+'.jpg',type:'jpeg',quality:92})}
await b.close()})();
