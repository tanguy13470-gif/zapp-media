const {chromium}=require('playwright');const [,,file,...ids]=process.argv;(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1080,height:1920}});
await p.goto('file://'+__dirname+'/'+file);await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(300);
for(const id of ids){await (await p.$('#'+id)).screenshot({path:__dirname+'/out/'+file.replace('.html','')+'-'+id+'.jpg',type:'jpeg',quality:92})}
await b.close()})();
