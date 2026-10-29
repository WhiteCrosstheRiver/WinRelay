"""Patch control_screen.dart (web mode default) + l10n keys."""
import io
import json
import os

p = 'lib/screens/control_screen.dart'
s = io.open(p, encoding='utf-8').read()
orig = s

s = s.replace("""  bool _opened = false;
  /// Web mode (browser windows only): native phone web view instead of video.
  bool _webMode = false;""",
"""  bool _opened = false;
  /// Browser windows start in web mode (the whole point: the page renders
  /// natively on the phone); the video stream is one tap away.
  bool _webMode = true;""")

s = s.replace("""          // Browser windows can be taken over natively: the page opens in a
          // phone web view and the PC's browser follows the navigation.
          if (isBrowser)
            IconButton(
              icon: Icon(_webMode ? Icons.web : Icons.public),
              tooltip: l10n.webMode,
              isSelected: _webMode,
              onPressed: () => setState(() => _webMode = !_webMode),
            ),""",
"""          // Browser windows: web view by default; this toggles to the raw
          // video stream for touching the browser chrome itself.
          if (isBrowser)
            IconButton(
              icon: Icon(_webMode ? Icons.desktop_windows_outlined : Icons.language),
              tooltip: _webMode ? l10n.pcScreen : l10n.webMode,
              onPressed: () => setState(() => _webMode = !_webMode),
            ),""")

assert s != orig
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('control patched')

D = 'lib/l10n'
KEYS = {
    'en': {'goBack': 'Back', 'goForward': 'Forward', 'addressBarHint': 'Search or type a URL', 'followPc': 'Follow the PC', 'pcScreen': 'PC screen'},
    'zh': {'goBack': '后退', 'goForward': '前进', 'addressBarHint': '搜索或输入网址', 'followPc': '跟随电脑', 'pcScreen': '电脑画面'},
    'zh_TW': {'goBack': '後退', 'goForward': '前進', 'addressBarHint': '搜尋或輸入網址', 'followPc': '跟隨電腦', 'pcScreen': '電腦畫面'},
    'ja': {'goBack': '戻る', 'goForward': '進む', 'addressBarHint': '検索またはURLを入力', 'followPc': 'PCに追従', 'pcScreen': 'PC の画面'},
    'ko': {'goBack': '뒤로', 'goForward': '앞으로', 'addressBarHint': '검색 또는 URL 입력', 'followPc': 'PC 따라가기', 'pcScreen': 'PC 화면'},
    'es': {'goBack': 'Atrás', 'goForward': 'Adelante', 'addressBarHint': 'Buscar o escribir URL', 'followPc': 'Seguir al PC', 'pcScreen': 'Pantalla del PC'},
    'fr': {'goBack': 'Retour', 'goForward': 'Avancer', 'addressBarHint': 'Rechercher ou saisir une URL', 'followPc': 'Suivre le PC', 'pcScreen': 'Écran du PC'},
    'de': {'goBack': 'Zurück', 'goForward': 'Vor', 'addressBarHint': 'Suchen oder URL eingeben', 'followPc': 'Dem PC folgen', 'pcScreen': 'PC-Bildschirm'},
    'it': {'goBack': 'Indietro', 'goForward': 'Avanti', 'addressBarHint': 'Cerca o digita un URL', 'followPc': 'Segui il PC', 'pcScreen': 'Schermo PC'},
    'pt': {'goBack': 'Voltar', 'goForward': 'Avançar', 'addressBarHint': 'Pesquisar ou digitar URL', 'followPc': 'Seguir o PC', 'pcScreen': 'Tela do PC'},
    'ru': {'goBack': 'Назад', 'goForward': 'Вперёд', 'addressBarHint': 'Поиск или введите адрес', 'followPc': 'Следовать за ПК', 'pcScreen': 'Экран ПК'},
}
for lang, extra in KEYS.items():
    p = os.path.join(D, f'app_{lang}.arb')
    with open(p, encoding='utf-8') as f:
        data = json.load(f)
    data.update(extra)
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')
print('l10n patched')
