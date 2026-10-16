"""Package only static landing-page files for a standard web host."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parent
with ZipFile(root / 'airtype-website.zip', 'w', ZIP_DEFLATED) as archive:
    for file in sorted((root / 'dist').rglob('*')):
        if file.is_file():
            archive.write(file, file.relative_to(root / 'dist'))
print(root / 'airtype-website.zip')
