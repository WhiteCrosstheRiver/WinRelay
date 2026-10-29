"""Append web-mode l10n keys to every ARB file."""
import json
import os

D = os.path.join(os.path.dirname(__file__), '..', 'lib', 'l10n')

KEYS = {
    'en': {
        'webMode': 'Web',
        'webModeTip': 'Browse like on a phone; the PC follows your navigation',
        'loadFromPc': "Load the page the PC is showing",
    },
    'zh': {
        'webMode': '网页',
        'webModeTip': '像手机一样上网,电脑会跟随你的导航',
        'loadFromPc': '载入电脑当前页面',
    },
    'zh_TW': {
        'webMode': '網頁',
        'webModeTip': '像手機一樣上網,電腦會跟隨你的導覽',
        'loadFromPc': '載入電腦目前頁面',
    },
    'ja': {
        'webMode': 'ウェブ',
        'webModeTip': 'スマホのように閲覧でき、PC がナビゲーションに追従します',
        'loadFromPc': 'PC の現在のページを読み込む',
    },
    'ko': {
        'webMode': '웹',
        'webModeTip': '휴대폰처럼 탐색하며 PC가 탐색을 따라갑니다',
        'loadFromPc': 'PC의 현재 페이지 불러오기',
    },
    'es': {
        'webMode': 'Web',
        'webModeTip': 'Navega como en un teléfono; el PC sigue tu navegación',
        'loadFromPc': 'Cargar la página que muestra el PC',
    },
    'fr': {
        'webMode': 'Web',
        'webModeTip': 'Naviguez comme sur un téléphone ; le PC suit votre navigation',
        'loadFromPc': 'Charger la page affichée sur le PC',
    },
    'de': {
        'webMode': 'Web',
        'webModeTip': 'Surfe wie am Handy; der PC folgt deiner Navigation',
        'loadFromPc': 'Die gerade angezeigte PC-Seite laden',
    },
    'it': {
        'webMode': 'Web',
        'webModeTip': 'Naviga come su un telefono; il PC segue la tua navigazione',
        'loadFromPc': "Carica la pagina mostrata sul PC",
    },
    'pt': {
        'webMode': 'Web',
        'webModeTip': 'Navegue como no celular; o PC segue sua navegação',
        'loadFromPc': 'Carregar a página que o PC mostra',
    },
    'ru': {
        'webMode': 'Веб',
        'webModeTip': 'Сёрфите как на телефоне; ПК последует за вашей навигацией',
        'loadFromPc': 'Загрузить страницу, открытую на ПК',
    },
}

for lang, extra in KEYS.items():
    p = os.path.join(D, f'app_{lang}.arb')
    with open(p, encoding='utf-8') as f:
        data = json.load(f)
    data.update(extra)
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print(lang, 'ok')
