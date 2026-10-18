// Deterministic artwork: real product captures, vector type, reference palette.
const fs=require('fs'),path=require('path'),sharp=require('sharp');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..'),out=path.join(root,'white-direction');
const locales=['zh-Hant','en-US'];
const font=fs.readFileSync(path.join(root,'fonts/NotoSansCJKtc-VF.woff2')).toString('base64');
const image=p=>'data:image/png;base64,'+fs.readFileSync(path.join(root,p)).toString('base64');
const colours=['#91f9e3','#96f3fa','#87c3fa','#805dff','#bd60f7','#dc5cf7'];
const copy={
 'zh-Hant':[
 ['用電腦鍵盤，\n輸入到手機。','熟悉的輸入法，每個想法都打得順手。','同一 Wi-Fi · 瀏覽器連接'],
 ['輸入配對碼，\n開始連接。','打開瀏覽器，輸入六位數配對碼。','毋須安裝電腦軟件'],
 ['文字之外，\n加點表情。','用電腦輸入法寫好，再一按傳送。','Emoji 分類與搜尋'],
 ['亦可直接\n用手機打字。','切換本機英文 QWERTY 鍵盤。','淺色與深色 · 英文拼字建議'],
 ['幾個步驟，\n準備就緒。','加入鍵盤，允許完整取用及本地網絡。','iPhone + iPad · iOS 17 或以上']],
 'en-US':[
 ['Type from the computer\nyou’re working on.','Your familiar keyboard. Your favourite input method.','Same Wi-Fi · Connect in a browser'],
 ['One code.\nYou’re connected.','Open a browser. Enter the six-digit pairing code.','No desktop installation'],
 ['More words.\nMore expression.','Compose in your language. Add an emoji.','Browse and search emoji'],
 ['Or type directly\non your device.','Switch to the local English QWERTY keyboard.','Light & dark · English spelling suggestions'],
 ['A few steps.\nReady to type.','Add AirType. Allow Full Access & Local Network.','iPhone + iPad · iOS 17 or later']]
};
const band=()=>`<div class="band">${colours.map(c=>`<i style="background:${c}"></i>`).join('')}</div>`;
const brand=()=>`<div class="brand critical"><img src="${image('icons/airtype-brand-1024.png')}"><span>AirType</span></div>`;
function device(loc,type,state,x,y,w){return `<div class="device ${type} critical" style="left:${x}px;top:${y}px;width:${w}px"><img src="${image(`sources/${loc}/${type}-${state}.png`)}"></div>`;}
function browser(loc,state,x,y,w,type='iphone'){return `<div class="browser critical" style="left:${x}px;top:${y}px;width:${w}px"><header><i></i><i></i><i></i><span>AirType · Web Access</span></header><img src="${image(`sources/${loc}/${type}-browser-${state}.png`)}"></div>`;}
function shell(loc,w,h,body,css=''){return `<!doctype html><html lang="${loc}"><meta charset="utf-8"><style>
@font-face{font-family:Noto;src:url(data:font/woff2;base64,${font})}*{box-sizing:border-box}body{margin:0;width:${w}px;height:${h}px;background:#fff;font-family:Noto,sans-serif;color:#14afc0;overflow:hidden}.art{position:relative;width:100%;height:100%;overflow:hidden;background:#fff}.brand{position:absolute;display:flex;align-items:center;gap:9px;font-size:19px;font-weight:450;color:#45818b}.brand img{width:30px;height:30px;border-radius:8px}.band{position:absolute;bottom:0;left:0;width:100%;height:12%;display:flex}.band i{flex:1}h1{margin:0;font-weight:450;line-height:1.27;letter-spacing:-.8px;white-space:pre-line;color:#11b3c5}p{margin:0;font-weight:400;line-height:1.6;color:#718487}.device{position:absolute;border:2px solid #b7a5f7;border-radius:22px;padding:7px;background:#fff;overflow:hidden}.device img{width:100%;display:block;border-radius:13px}.device.ipad{border-radius:17px;padding:8px}.device.ipad img{border-radius:8px}.browser{position:absolute;overflow:hidden;border:1px solid #dce6e8;background:#fff;border-radius:7px;box-shadow:0 8px 20px #354b5511}.browser header{height:22px;background:#f2f4f5;display:flex;align-items:center;gap:4px;padding:0 8px}.browser header i{width:5px;height:5px;border-radius:50%;background:#d9dde0}.browser header i:first-child{background:#fb8fa5}.browser header i:nth-child(2){background:#f6d889}.browser header span{font-size:8px;color:#8b999d;margin:auto}.browser>img{width:100%;display:block}.tag{position:absolute;text-align:center;color:#789396;font-size:12px}.detail{position:absolute;overflow:hidden;border:2px solid #c7f5f5;border-radius:10px;background:#fff}.detail img{position:absolute;width:100%;bottom:0;left:0}.signal{position:absolute;width:60px;height:60px;fill:none;stroke:#09c6c9;stroke-linecap:round;stroke-width:5}${css}
</style><div class="art">${body}${band()}</div></html>`;}
function portrait(loc,type,i){const pad=type==='ipad',w=pad?688:440,h=pad?2752/3:2622/(1206/440);let [title,desc,tag]=copy[loc][i];if(pad&&loc==='zh-Hant')title=title.replace('手機','iPad');
 let art='';
 if(i===0)art=device(loc,type,'connected',pad?64:38,pad?338:342,pad?310:196)+browser(loc,'connected',pad?310:150,pad?474:510,pad?330:266,type);
 if(i===1)art=browser(loc,'pair',pad?54:28,pad?350:365,pad?580:384,type);
 if(i===2)art=browser(loc,'emoji',pad?76:24,pad?330:390,pad?536:392,type);
 if(i>=3)art=device(loc,type,i===3?'qwerty-dark':'setup',pad?184:110,pad?326:324,pad?320:220);
 return shell(loc,w,h,`${brand()}<h1 class="critical">${title}</h1><p class="desc critical">${desc}</p>${art}<p class="tag critical">${tag}</p>`,`.brand{top:32px;left:50%;transform:translateX(-50%)}h1{position:absolute;top:${pad?103:112}px;left:20px;right:20px;text-align:center;font-size:${pad?44:loc==='en-US'?(i===0?29:34):37}px}p.desc{position:absolute;top:${pad?240:240}px;left:24px;right:24px;text-align:center;font-size:${pad?17:12.5}px}.tag{bottom:15%;left:16px;right:16px;font-size:${pad?14:11}px}.band{height:11%}`);
}
function hero(loc,w,h,kind){const zh=loc==='zh-Hant',header=kind==='header',search=kind==='search-results',land=kind==='social-landscape',story=kind==='social-story';
 const title=zh?'用電腦鍵盤，\n輸入到手機。':'Type from the computer\nyou’re working on.';
 let body='',css='';
 if(header){body=brand()+`<h1 class="critical">${zh?'電腦打字。\n手機收到。':'Your keyboard.\nYour device.'}</h1><p class="desc critical">${zh?'同一 Wi-Fi · 瀏覽器連接':'Same Wi-Fi · Browser connection'}</p>`+device(loc,'iphone','connected',783,177,83)+browser(loc,'connected',658,239,175);css='.brand{left:380px;top:177px;font-size:18px}.brand img{width:26px;height:26px}h1{position:absolute;left:380px;top:219px;font-size:30px}.desc{position:absolute;left:380px;top:317px;font-size:11px}.browser header{height:10px}.browser header span{font-size:5px}.browser header i{width:3px;height:3px}.band{height:12%}';}
 else if(search){body=brand()+`<h1 class="critical">${title}</h1><p class="desc critical">${zh?'同一 Wi-Fi，透過瀏覽器連接 iPhone 與 iPad。':'Same Wi-Fi. Connect to iPhone and iPad in a browser.'}</p>`+device(loc,'iphone','connected',268,342,166)+browser(loc,'connected',535,394,450);css=`.brand{left:50%;top:52px;transform:translateX(-50%);font-size:24px}.brand img{width:38px;height:38px}h1{position:absolute;top:125px;left:80px;right:80px;text-align:center;font-size:${zh?55:49}px}.desc{position:absolute;top:278px;left:60px;right:60px;text-align:center;font-size:19px}.band{height:10%}`;}
 else if(land){body=brand()+`<h1 class="critical">${zh?'電腦打字。\n手機收到。':'Your keyboard.\nYour device.'}</h1><p class="desc critical">${zh?'同一 Wi-Fi · 瀏覽器連接':'Same Wi-Fi · Connect in a browser'}</p>`+device(loc,'iphone','connected',660,60,176)+browser(loc,'connected',820,196,330);css='.brand{top:52px;left:64px;font-size:24px}.brand img{width:38px;height:38px}h1{position:absolute;top:156px;left:64px;font-size:62px}.desc{position:absolute;top:355px;left:66px;font-size:20px}.band{height:12%}';}
 else{body=brand()+`<h1 class="critical">${title}</h1><p class="desc critical">${zh?'同一 Wi-Fi · 瀏覽器連接':'Same Wi-Fi · Connect in a browser'}</p>`+device(loc,'iphone','connected',story?240:142,story?680:475,story?320:200)+browser(loc,'connected',story?420:390,story?930:500,story?570:560);css=`.brand{top:${story?92:54}px;left:50%;transform:translateX(-50%);font-size:29px}.brand img{width:46px;height:46px}h1{position:absolute;left:60px;right:60px;top:${story?252:160}px;text-align:center;font-size:${zh?72:62}px}.desc{position:absolute;left:40px;right:40px;top:${story?485:360}px;text-align:center;font-size:25px}.band{height:12%}`;}
 return shell(loc,w,h,body,css);
}
async function main(){fs.mkdirSync(out,{recursive:true});const browserEngine=await chromium.launch({headless:true});const manifest=[];
 async function render(file,loc,w,h,lw,lh,markup,placement,safe){const target=path.join(out,file);fs.mkdirSync(path.dirname(target),{recursive:true});const source='sources/'+file.replace(/\.png$/,'.html');fs.mkdirSync(path.dirname(path.join(out,source)),{recursive:true});fs.writeFileSync(path.join(out,source),markup);
 const p=await browserEngine.newPage({viewport:{width:w,height:h},deviceScaleFactor:1});await p.setContent(markup);await p.evaluate(scale=>{document.body.style.transform=`scale(${scale})`;document.body.style.transformOrigin='top left'},w/lw);await p.evaluate(()=>document.fonts.ready);await p.locator('img').evaluateAll(imgs=>Promise.all(imgs.map(im=>im.decode())));
 const bounds=await p.locator('.critical').evaluateAll(els=>els.map(el=>{const r=el.getBoundingClientRect();return {element:el.className,x:r.x,y:r.y,width:r.width,height:r.height,right:r.right,bottom:r.bottom}}));
 const box=safe||{x:0,y:0,w,h};for(const r of bounds)if(r.x<box.x-1||r.y<box.y-1||r.right>box.x+box.w+1||r.bottom>box.y+box.h+1)throw Error(JSON.stringify({file,r,box}));
 const bandTop=await p.locator('.band').evaluate(el=>el.getBoundingClientRect().top);for(const r of bounds)if(r.bottom>bandTop+1)throw Error('Content overlaps colour band: '+file);
 await p.screenshot({path:target});await p.close();await sharp(target).removeAlpha().withIccProfile('srgb').png().toFile(target+'.tmp');fs.renameSync(target+'.tmp',target);const m=await sharp(target).metadata();if(m.width!==w||m.height!==h||m.hasAlpha||m.space!=='srgb')throw Error(file);
 manifest.push({file,locale:loc,placement,width:w,height:h,colourSpace:m.space,hasAlpha:m.hasAlpha,bounds,safeArea:safe||null,passed:true,source});console.log(file);
 }
 for(const loc of locales){for(const type of ['iphone','ipad'])for(let i=0;i<5;i++){const pad=type==='ipad',w=pad?2064:1206,h=pad?2752:2622,lw=pad?688:440;await render(`screenshots/${loc}/${type}/0${i+1}-${['computer-typing','pairing','emoji','local-keyboard','setup'][i]}.png`,loc,w,h,lw,h/(w/lw),portrait(loc,type,i),type);}
 for(const [kind,w,h]of [['social-square',1080,1080],['social-story',1080,1920],['social-landscape',1200,630],['header',3840,1646],['search-results',3840,2560]]){const creative=['header','search-results'].includes(kind),lw=creative?1280:w,lh=h/(w/lw);await render(`${creative?'creative':'promo'}/airtype-${kind}-${loc}-${w}x${h}.png`,loc,w,h,lw,lh,hero(loc,lw,lh,kind),kind,kind==='header'?{x:1097,y:493,w:1646,h:661}:null);}}
 fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 // Review-only contact sheets; formal uploads keep their full resolutions.
 fs.mkdirSync(path.join(out,'previews'),{recursive:true});
 for(const loc of locales)for(const type of ['iphone','ipad']){const entries=manifest.filter(m=>m.locale===loc&&m.placement===type);const thumbs=await Promise.all(entries.map(m=>sharp(path.join(out,m.file)).resize({width:240}).png().toBuffer()));const height=type==='iphone'?522:320;await sharp({create:{width:1260,height:height+40,channels:3,background:'#edf3f4'}}).composite(thumbs.map((input,i)=>({input,left:10+i*250,top:20}))).png().toFile(path.join(out,`previews/${loc}-${type}.png`));}
 for(const m of manifest.filter(x=>!['iphone','ipad'].includes(x.placement)))await sharp(path.join(out,m.file)).resize({width:1000}).png().toFile(path.join(out,'previews',path.basename(m.file)));
 for(const m of manifest.filter(x=>x.placement==='header')){await sharp(path.join(out,m.file)).extract({left:1097,top:493,width:1646,height:661}).resize({width:1000}).png().toFile(path.join(out,'previews',`header-safe-crop-${m.locale}.png`));}
 const cards=manifest.map(m=>`<article><a href="${m.file}"><img loading="lazy" src="${m.file}"></a><p>${m.locale} · ${m.placement}</p><small>${m.width} × ${m.height}</small></article>`).join('');fs.writeFileSync(path.join(out,'index.html'),`<!doctype html><meta charset="utf-8"><title>AirType · White direction</title><style>body{font-family:system-ui;margin:40px;background:#edf4f4;color:#28747c}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:24px}article{padding:12px;background:white;border-radius:12px}img{width:100%;display:block}p{line-height:1.5}</style><h1>AirType · 白底與六色色帶</h1><p>30 張全尺寸宣傳圖片 · zh-Hant + en-US · 2026-10-18</p><div class="grid">${cards}</div>`);
 await browserEngine.close();console.log('Validated '+manifest.length+' opaque sRGB exports.');}
main().catch(e=>{console.error(e);process.exit(1)});
