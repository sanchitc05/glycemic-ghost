#!/usr/bin/env python3
import os
from pathlib import Path
from datetime import date

def main():
    root = Path(__file__).resolve().parents[1]
    excluded_dirs = {'.git', '.idea', '.vscode', 'node_modules', 'build', 'dist', '__pycache__'}
    files = []
    for p in root.rglob('*'):
        if p.is_file():
            rel = p.relative_to(root)
            if any(part in excluded_dirs for part in rel.parts):
                continue
            if rel.name == 'FILE_LIST_SORTED.md' or rel.name == Path(__file__).name:
                continue
            files.append(str(rel).replace('\\','/'))
    files = sorted(files, key=lambda s: s.lower())
    out = root / 'FILE_LIST_SORTED.md'
    with out.open('w', encoding='utf-8') as f:
        f.write('# FILE_LIST_SORTED.md\n\n')
        f.write(f'Generated on {date.today().isoformat()}\n\n')
        f.write(f'Total files: {len(files)}\n\n')
        for p in files:
            f.write(p + '\\n')

if __name__ == '__main__':
    main()
