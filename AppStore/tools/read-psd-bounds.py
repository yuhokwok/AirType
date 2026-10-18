import struct,json,sys
from pathlib import Path
for filename in sys.argv[1:]:
 b=Path(filename).read_bytes(); off=26
 u32=lambda p:struct.unpack_from('>I',b,p)[0]
 for _ in range(2):off+=4+u32(off)
 off+=4
 off+=4
 n=abs(struct.unpack_from('>h',b,off)[0])
 if n==0 and b'8BIMLr16' in b:
  off=b.index(b'8BIMLr16')+12;n=abs(struct.unpack_from('>h',b,off)[0])
 off+=2;out=[]
 for _ in range(n):
  top,left,bottom,right,channels=struct.unpack_from('>iiiiH',b,off);off+=18+channels*6
  off+=12;extra=u32(off);off+=4;end=off+extra
  off+=4+u32(off);off+=4+u32(off)
  l=b[off];name=b[off+1:off+1+l].decode('macroman',errors='replace');off=end
  out.append({'name':name,'x':left,'y':top,'width':right-left,'height':bottom-top})
 print(filename,json.dumps(out,indent=2))
