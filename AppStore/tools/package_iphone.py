from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib,json
root=Path(__file__).resolve().parents[1]
manifest=[x for x in json.loads((root/'manifest.json').read_text()) if x['device']=='iphone']
checks=[x for x in json.loads((root/'image-validation.json').read_text()) if '/iphone/' in x['file']]
assert len(manifest)==len(checks)==10
assert all(x['width']==1206 and x['height']==2622 and not x['hasAlpha'] and x['passed'] for x in checks)
assert all(x['width']==1206 and x['height']==2622 for x in manifest)
readme='''AirType — iPhone screenshots (medium display)

10 static PNG screenshots: 5 Traditional Chinese + 5 English.
Resolution: 1206 × 2622 pixels. RGB, opaque.

In App Store Connect, choose “iPhone with Dynamic Island (medium display)”
and upload these PNGs in the App Screenshots area, in filename order.

The App Previews area is for video. Its portrait 886 × 1920 size does not
apply to these screenshots. No video is included in this archive.

iPad files remain unchanged in the full source folder. Previous iPhone
large-display archives remain available separately.

Apple specification:
https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
'''
payload={'README.txt':readme.encode(),'validation.json':(json.dumps(checks,indent=2)+'\n').encode()}
for entry in manifest:
 src=root/entry['file'];payload[str(Path(entry['locale'])/src.name)]=src.read_bytes()
payload['SHA256SUMS.txt']=('\n'.join(hashlib.sha256(data).hexdigest()+'  '+name for name,data in sorted(payload.items()))+'\n').encode()
out=root.parent/'output'/'AirType-iPhone-Medium-1206x2622-2026-10-18.zip'
with ZipFile(out,'w',ZIP_DEFLATED,compresslevel=1) as z:
 for name,data in sorted(payload.items()):z.writestr(name,data)
with ZipFile(out) as z:
 assert z.testzip() is None
 for name,data in payload.items():assert z.read(name)==data
print(json.dumps({'archive':str(out),'screenshots':10,'dimensions':[1206,2622],'bytes':out.stat().st_size,'verified':True}))
