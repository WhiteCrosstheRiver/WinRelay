"""Append the switchIme l10n key to every ARB file."""
import json
import os

D = os.path.join(os.path.dirname(__file__), '..', 'lib', 'l10n')

KEYS = {
    'en': 'Switch keyboard',
    'zh': '切换输入法',
    'zh_TW': '切換輸入法',
    'ja': '入力方法を切り替え',
    'ko': '입력기 전환',
    'es': 'Cambiar teclado',
    'fr': 'Changer de clavier',
    'de': 'Tastatur wechseln',
    'it': 'Cambia tastiera',
    'pt': 'Mudar teclado',
    'ru': 'Сменить клавиатуру',
}

for lang, val in KEYS.items():
    p = os.path.join(D, f'app_{lang}.arb')
    with open(p, encoding='utf-8') as f:
        data = json.load(f)
    data['switchIme'] = val
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print(lang, 'ok')
