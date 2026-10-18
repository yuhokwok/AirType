from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json,hashlib
root=Path(__file__).resolve().parents[1]
report=json.loads((root/'image-validation.json').read_text())
assert len(report)==26 and all(x['passed'] for x in report)
layout=json.loads((root/'layout-validation.json').read_text())
assert len(layout)==20 and all(x['allElementsInsideCanvas'] for x in layout)
for loc in ['zh-Hant','en-US']:
 for device in ['iphone','ipad']:
  audit=json.loads((root/'sources'/loc/f'{device}-capture.json').read_text())
  assert audit['paired'] and audit['sendClearedDraft'] and audit['locale']==loc
checks=[]
for p in sorted(root.rglob('*')):
 if p.is_file() and p.name!='SHA256SUMS.txt':checks.append(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+str(p.relative_to(root)))
(root/'SHA256SUMS.txt').write_text('\n'.join(checks)+'\n')
out=root.parent/'output'/'AirType-AppStore-2026-10-18-medium-display.zip'
with ZipFile(out,'w',ZIP_DEFLATED,compresslevel=1) as z:
 for p in sorted(root.rglob('*')):
  if p.is_file():z.write(p,Path('AppStore')/p.relative_to(root))
with ZipFile(out) as z:
 assert z.testzip() is None
 for p in root.rglob('*'):
  if p.is_file():assert z.read(str(Path('AppStore')/p.relative_to(root)))==p.read_bytes()
print(json.dumps({'archive':str(out),'bytes':out.stat().st_size,'imagesValidated':len(report),'layoutsValidated':len(layout),'archiveVerified':True}))
