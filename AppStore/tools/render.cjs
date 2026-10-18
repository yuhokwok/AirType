const fs=require('fs'),path=require('path');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..');
const iphoneOnly=process.argv.includes('--iphone-only');
const iphoneSize={width:1206,height:2622};
const image=p=>'data:image/png;base64,'+fs.readFileSync(path.join(root,p)).toString('base64');
const font=fs.readFileSync(path.join(root,'fonts/NotoSansCJKtc-VF.woff2')).toString('base64');
const copy={
 'zh-Hant':[
 ['電腦打字。\n手機收到。','用熟悉的鍵盤，寫下每個想法。','同一 Wi-Fi · 瀏覽器連接'],
 ['輸入配對碼，\n開始連接。','六位數配對，電腦毋須安裝軟件。','保持 Web Access 鍵盤顯示'],
 ['中文、英文，\n加點表情。','用電腦輸入法寫好，再一按傳送。','Emoji 分類與搜尋'],
 ['離開電腦，\n繼續打字。','隨時切換本機英文 QWERTY 鍵盤。','淺色與深色 · 英文拼字建議'],
 ['幾個步驟，\n準備就緒。','加入鍵盤、允許完整取用及本地網絡。','iPhone + iPad · iOS 17 或以上']
 ],
 'en-US':[
 ['Your keyboard.\nYour device.','Type on your computer. Send to your device.','Same Wi-Fi · Connect in a browser'],
 ['One code.\nYou’re connected.','Six digits. No desktop installation.','Keep the Web Access keyboard visible'],
 ['More words.\nMore expression.','Compose in your language. Add an emoji.','Browse and search emoji'],
 ['Keep typing.\nAnywhere.','Switch to the local English QWERTY keyboard.','Light & dark · English spelling suggestions'],
 ['A few steps.\nReady to type.','Add AirType. Allow Full Access & Local Network.','iPhone + iPad · iOS 17 or later']
 ]};
function html(loc,device,i){
 const pad=device==='ipad',w=pad?688:440,h=pad?917.333333:iphoneSize.height/(iphoneSize.width/440);
 const [title,desc,tag]=copy[loc][i];
 const source=i===1?'connected':i===3?'qwerty-dark':i===4?'setup':'connected';
 const browser=i<3?image(`sources/${loc}/${device}-browser-${['connected','pair','emoji'][i]}.png`):'';
 return `<!doctype html><html lang="${loc}"><meta charset="utf-8"><style>
 @font-face{font-family:Noto;src:url(data:font/woff2;base64,${font})}*{box-sizing:border-box}body{margin:0;width:${w}px;height:${h}px;font-family:Noto,sans-serif;background:#241347;color:white;overflow:hidden}.art{position:relative;width:100%;height:100%;background:radial-gradient(ellipse at 95% 63%,#6942a9 0,transparent 60%),linear-gradient(155deg,#211337,#332055 70%,#503077)}.brand{position:absolute;left:30px;top:28px;display:flex;align-items:center;gap:10px;font-size:20px;font-weight:550;letter-spacing:.2px}.brand img{width:34px;height:34px;border-radius:9px}.number{position:absolute;right:30px;top:36px;color:#c6b5e1;font-size:12px;letter-spacing:2px}h1{position:absolute;left:${pad?42:30}px;top:${pad?79:92}px;margin:0;font-size:${pad?62:loc==='en-US'?40:48}px;line-height:1.2;letter-spacing:-1.8px;font-weight:750;white-space:pre-line}p{position:absolute;left:${pad?44:32}px;right:28px;top:${pad?239:230}px;margin:0;color:#d8caee;font-size:${pad?20:16}px;line-height:1.6}.device{position:absolute;top:${pad?318:300}px;left:50%;transform:translateX(-50%);width:${pad?390:250}px;border:7px solid #16131e;border-radius:${pad?22:34}px;overflow:hidden;box-shadow:0 28px 55px #10031d70;background:#fff}.device>img{display:block;width:100%}.browser{position:absolute;left:${pad?32:24}px;top:${pad?318:310}px;width:${pad?470:392}px;border:1px solid #e3dbea;border-radius:12px;overflow:hidden;box-shadow:0 24px 50px #16082560;background:#fff}.browser header{height:28px;background:#f1eef6;display:flex;gap:5px;align-items:center;padding:0 10px}.dot{width:6px;height:6px;border-radius:50%;background:#b3a6c4}.url{font:10px Noto;color:#776c85;margin:auto}.browser-shot{overflow:hidden}.browser img{width:100%;display:block}.browser.emoji{width:${pad?470:355}px;left:${pad?32:24}px;top:${pad?310:300}px}.tag{position:absolute;bottom:24px;left:0;right:0;text-align:center;font-size:${pad?17:12}px;letter-spacing:.3px;color:#e0d2f1}.bar{position:absolute;bottom:0;height:5px;width:100%;background:linear-gradient(90deg,#8af5d9,#83d9ff,#8d7aff,#d774ef)}${i===4?`.device{top:${pad?320:308}px;width:${pad?390:255}px}`:''}${i===3?`.device{top:${pad?324:315}px;width:${pad?390:255}px}`:''}
 </style><div class="art"><div class="brand"><img src="${image('icons/airtype-brand-1024.png')}">AirType</div><div class="number">0${i+1} / 05</div><h1>${title}</h1><p>${desc}</p><div class="device"><img src="${image(`sources/${loc}/${device}-${source}.png`)}"></div>${browser?`<div class="browser ${i===2?"emoji":""}"><header><span class="dot"></span><span class="dot"></span><span class="dot"></span><span class="url">AirType · Web Access</span></header><div class="browser-shot"><img src="${browser}"></div></div>`:''}<div class="tag">${tag}</div><div class="bar"></div></div></html>`;
}
(async()=>{const browser=await chromium.launch({headless:true});const manifest=iphoneOnly?JSON.parse(fs.readFileSync(path.join(root,'manifest.json'))).filter(x=>x.device!=='iphone'):[];const layoutChecks=iphoneOnly?JSON.parse(fs.readFileSync(path.join(root,'layout-validation.json'))).filter(x=>x.device!=='iphone'):[];
for(const loc of Object.keys(copy))for(const device of iphoneOnly?['iphone']:['iphone','ipad'])for(let i=0;i<5;i++){
 const pad=device==='ipad',w=pad?2064:iphoneSize.width,h=pad?2752:iphoneSize.height;
 const page=await browser.newPage({viewport:{width:w,height:h},deviceScaleFactor:1});
 const markup=html(loc,device,i);const source=`sources/layout-${loc}-${device}-${i+1}.html`;fs.writeFileSync(path.join(root,source),markup);
 await page.setContent(markup);await page.evaluate(scale=>{document.body.style.transform=`scale(${scale})`;document.body.style.transformOrigin='top left'},w/(pad?688:440));await page.evaluate(()=>document.fonts.ready);
 const check=await page.evaluate(()=>{const nodes=[...document.querySelectorAll('.brand,h1,p,.device,.browser,.tag')];return nodes.map(el=>{const r=el.getBoundingClientRect();return {element:el.className||el.tagName,x:r.x,y:r.y,right:r.right,bottom:r.bottom}})});
 for(const rect of check)if(rect.x < -1||rect.y < -1||rect.right>w+1||rect.bottom>h+1)throw Error(JSON.stringify({loc,device,i,rect}));
 layoutChecks.push({locale:loc,device,slide:i+1,allElementsInsideCanvas:true});
 const output=`screenshots/${loc}/${device}/0${i+1}-${['computer-typing','pairing','emoji','local-keyboard','setup'][i]}.png`;
 await page.screenshot({path:path.join(root,output)});manifest.push({file:output,width:w,height:h,locale:loc,device,title:copy[loc][i][0],sourceScreenshot:`sources/${loc}/${device}-${i===1?'connected':i===3?'qwerty-dark':i===4?'setup':'connected'}.png`});await page.close();
}
fs.writeFileSync(path.join(root,'layout-validation.json'),JSON.stringify(layoutChecks,null,2));
fs.writeFileSync(path.join(root,'manifest.json'),JSON.stringify(manifest,null,2));await browser.close();console.log(iphoneOnly?'Re-exported 10 iPhone screenshots at 1206 × 2622':`Exported ${manifest.length} screenshots`);
})().catch(e=>{console.error(e);process.exit(1)});
