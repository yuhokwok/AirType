from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib,json
root=Path(__file__).resolve().parents[1]
manifest=[x for x in json.loads((root/'manifest.json').read_text()) if x['device']=='ipad']
checks=[x for x in json.loads((root/'image-validation.json').read_text()) if '/ipad/' in x['file']]
assert len(manifest)==len(checks)==10
assert all(x['width']==2064 and x['height']==2752 and not x['hasAlpha'] and x['passed'] for x in checks)
assert all(x['width']==2064 and x['height']==2752 for x in manifest)
readme='''AirType — iPad 13-inch screenshots

10 static PNG screenshots: 5 Traditional Chinese + 5 English.
Resolution: 2064 × 2752 pixels. RGB, opaque.

In App Store Connect, choose the iPad 13-inch display slot and upload
these PNGs in the App Screenshots area, in filename order.

The App Previews area is for video. Its portrait 1200 × 1600 size does
not apply to these screenshots. No video is included in this archive.

Apple specification:
https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
'''
payload={'README.txt':readme.encode(),'validation.json':(json.dumps(checks,indent=2)+'\n').encode()}
for entry in manifest:
 src=root/entry['file'];payload[str(Path(entry['locale'])/src.name)]=src.read_bytes()
payload['SHA256SUMS.txt']=('\n'.join(hashlib.sha256(data).hexdigest()+'  '+name for name,data in sorted(payload.items()))+'\n').encode()
out=root.parent/'output'/'AirType-iPad-13-inch-2064x2752-2026-10-18.zip'
with ZipFile(out,'w',ZIP_DEFLATED,compresslevel=1) as z:
 for name,data in sorted(payload.items()):z.writestr(name,data)
with ZipFile(out) as z:
 assert z.testzip() is None
 for name,data in payload.items():assert z.read(name)==data
print(json.dumps({'archive':str(out),'screenshots':10,'dimensions':[2064,2752],'bytes':out.stat().st_size,'verified':True}))
