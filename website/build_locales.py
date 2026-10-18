"""Regenerate the static English homepage from Chinese markup and reviewed copy.

The exported site does not need a Python runtime, JS translation, cookies, or a build step.
"""
from pathlib import Path
from html import escape
from html.parser import HTMLParser
import json,re

root=Path(__file__).resolve().parent
translations=json.loads((root/'locales/en.json').read_text())
chinese=re.compile('[\u3400-\u9fff]')

def text(value):
    stripped=value.strip()
    if stripped in translations:
        return value.replace(stripped, translations[stripped], 1)
    if chinese.search(value):
        raise ValueError(f'Missing English translation: {value!r}')
    return value

def link(value):
    if value.startswith('assets/') or value in ('style.css','app.js'):
        return '../'+value
    if value.startswith('privacy/'):
        return '../'+value
    return value

class EnglishPage(HTMLParser):
    def __init__(self):super().__init__(convert_charrefs=False);self.parts=[]
    def handle_decl(self,value):self.parts.append('<!'+value+'>')
    def handle_comment(self,value):self.parts.append('<!--'+value+'-->')
    def start(self,tag,attrs,close='>'):
        result=[]
        for key,value in attrs:
            if value is not None:
                if tag=='html' and key=='lang':value='en'
                elif key in ('alt','title','aria-label','content'):value=text(value)
                elif key in ('href','src'):value=link(value)
                result.append(f'{key}="{escape(value,quote=True)}"')
            else:result.append(key)
        self.parts.append('<'+tag+(' '+' '.join(result) if result else '')+close)
    def handle_starttag(self,tag,attrs):self.start(tag,attrs)
    def handle_startendtag(self,tag,attrs):self.start(tag,attrs,'/>')
    def handle_endtag(self,tag):self.parts.append('</'+tag+'>')
    def handle_data(self,value):self.parts.append(text(value))
    def handle_entityref(self,name):self.parts.append('&'+name+';')
    def handle_charref(self,name):self.parts.append('&#'+name+';')

page=EnglishPage();page.feed((root/'dist/index.html').read_text());html=''.join(page.parts)
html=re.sub(r'<!-- language-switch -->.*?<!-- /language-switch -->','''<!-- language-switch -->
  <div class="language-switch" role="navigation" aria-label="Website language"><a href="../" lang="zh-Hant">繁體中文</a><a href="./" lang="en" aria-current="page">English</a></div>
  <!-- /language-switch -->''',html,flags=re.S)
html=html.replace('<link rel="canonical" href="https://www.invivointeractive.com/airtype/">','<link rel="canonical" href="https://www.invivointeractive.com/airtype/en/">')
html=html.replace('<a href="../privacy/">Privacy Policy</a>','<a href="../privacy/en/">Privacy Policy</a>')
html=html.replace('<a href="../privacy/en/">Privacy Policy</a><a href="../privacy/en/" lang="en">Privacy Policy</a>','<a href="../privacy/en/">Privacy Policy</a>')
# Keep the translated privacy notice’s Chinese-policy link in its native language.
html=html.replace('<a href="../privacy/">Traditional Chinese</a>','<a href="../privacy/" lang="zh-Hant">繁體中文</a>')
output=root/'dist/en/index.html';output.parent.mkdir(exist_ok=True);output.write_text(html)
print(output)
