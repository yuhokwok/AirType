from pathlib import Path
import subprocess,time,sys
root=Path(__file__).resolve().parents[1]
locale=sys.argv[1]
lang='zh-Hant' if locale=='zh-Hant' else 'en'
region='zh_HK' if locale=='zh-Hant' else 'en_US'
for name,device in [('iphone','43FB36DE-8FFF-4A3C-B5FF-1FC0EC0388F8'),('ipad','E19467BE-B8F9-424A-A4E6-117210AD61A0')]:
 out=root/'sources'/locale;out.mkdir(exist_ok=True)
 for state,args in [('qwerty',['--keyboard-qwerty']),('setup',[]),('web',['--keyboard-demo'])]:
  subprocess.run(['xcrun','simctl','terminate',device,'com.invivo.ios.AirType'],capture_output=True)
  subprocess.run(['xcrun','simctl','launch',device,'com.invivo.ios.AirType',*args,'-AppleLanguages',f'({lang})','-AppleLocale',region],check=True,capture_output=True)
  time.sleep(1)
  subprocess.run(['xcrun','simctl','io',device,'screenshot',str(out/f'{name}-{state}.png')],check=True,capture_output=True)
  print(locale,name,state,flush=True)
