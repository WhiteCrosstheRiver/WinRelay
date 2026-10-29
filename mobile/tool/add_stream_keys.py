"""Append the stream-tuning l10n keys to every ARB file."""
import json
import os

D = os.path.join(os.path.dirname(__file__), '..', 'lib', 'l10n')

KEYS = {
    'en': {
        'secStream': 'Stream',
        'rxFps': 'Frame rate',
        'rxFpsSub': 'Lower = smoother network, choppier picture',
        'rxScale': 'Picture size',
        'rxScaleSub': 'Smaller picture = much less data',
        'rxGray': 'Grayscale mode',
        'rxGraySub': 'Black-and-white picture; cuts data use sharply',
    },
    'zh': {
        'secStream': '画面传输',
        'rxFps': '接收帧率',
        'rxFpsSub': '越低越省网络,画面越不连贯',
        'rxScale': '接收分辨率',
        'rxScaleSub': '画面越小,流量越省',
        'rxGray': '灰度模式',
        'rxGraySub': '黑白画面,大幅节省流量',
    },
    'zh_TW': {
        'secStream': '畫面傳輸',
        'rxFps': '接收幀率',
        'rxFpsSub': '越低越省網路,畫面越不連貫',
        'rxScale': '接收解析度',
        'rxScaleSub': '畫面越小,流量越省',
        'rxGray': '灰階模式',
        'rxGraySub': '黑白畫面,大幅節省流量',
    },
    'ja': {
        'secStream': 'ストリーム',
        'rxFps': '受信フレームレート',
        'rxFpsSub': '低いほど通信を節約し、映像は滑らかでなくなります',
        'rxScale': '受信画像サイズ',
        'rxScaleSub': '画像が小さいほど通信量を大きく節約できます',
        'rxGray': 'グレースケール',
        'rxGraySub': '白黒画像で通信量を大幅に削減',
    },
    'ko': {
        'secStream': '스트림',
        'rxFps': '수신 프레임레이트',
        'rxFpsSub': '낮을수록 데이터를 절약하고 화면이 덜 부드럽습니다',
        'rxScale': '수신 해상도',
        'rxScaleSub': '화면이 작을수록 데이터를 크게 절약합니다',
        'rxGray': '회색조 모드',
        'rxGraySub': '흑백 화면으로 데이터 사용량을 크게 줄입니다',
    },
    'es': {
        'secStream': 'Transmisión',
        'rxFps': 'Fotogramas recibidos',
        'rxFpsSub': 'Más bajo = red más ligera, imagen menos fluida',
        'rxScale': 'Tamaño de imagen',
        'rxScaleSub': 'Imagen más pequeña = muchos menos datos',
        'rxGray': 'Modo de escala de grises',
        'rxGraySub': 'Imagen en blanco y negro; reduce mucho los datos',
    },
    'fr': {
        'secStream': 'Transmission',
        'rxFps': 'Fréquence de réception',
        'rxFpsSub': 'Plus basse = réseau plus léger, image moins fluide',
        'rxScale': "Taille de l'image",
        'rxScaleSub': "Image plus petite = beaucoup moins de données",
        'rxGray': 'Mode niveaux de gris',
        'rxGraySub': "Image en noir et blanc ; réduit nettement les données",
    },
    'de': {
        'secStream': 'Übertragung',
        'rxFps': 'Bildrate (Empfang)',
        'rxFpsSub': 'Niedriger = schont das Netz, Bild ruckelt eher',
        'rxScale': 'Bildgröße',
        'rxScaleSub': 'Kleineres Bild = deutlich weniger Daten',
        'rxGray': 'Graustufenmodus',
        'rxGraySub': 'Schwarzweißbild; spart deutlich Datenvolumen',
    },
    'it': {
        'secStream': 'Trasmissione',
        'rxFps': 'Framerate in ricezione',
        'rxFpsSub': 'Più basso = rete più leggera, immagine meno fluida',
        'rxScale': 'Dimensione immagine',
        'rxScaleSub': 'Immagine più piccola = molti meno dati',
        'rxGray': 'Modalità scala di grigi',
        'rxGraySub': 'Immagine in bianco e nero; riduce molto i dati',
    },
    'pt': {
        'secStream': 'Transmissão',
        'rxFps': 'Taxa de quadros recebida',
        'rxFpsSub': 'Menor = rede mais leve, imagem menos fluida',
        'rxScale': 'Tamanho da imagem',
        'rxScaleSub': 'Imagem menor = muito menos dados',
        'rxGray': 'Modo tons de cinza',
        'rxGraySub': 'Imagem em preto e branco; reduz muito os dados',
    },
    'ru': {
        'secStream': 'Трансляция',
        'rxFps': 'Частота кадров приёма',
        'rxFpsSub': 'Ниже = меньше нагрузка на сеть, менее плавная картинка',
        'rxScale': 'Размер картинки',
        'rxScaleSub': 'Меньше картинка = намного меньше трафика',
        'rxGray': 'Оттенки серого',
        'rxGraySub': 'Чёрно-белая картинка; резко сокращает трафик',
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
    print(lang, 'ok,', len(data), 'keys')
