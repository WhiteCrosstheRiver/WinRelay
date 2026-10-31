// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get pairPc => 'PC 페어링';

  @override
  String get pairScanHint => 'PC의 WinRelay에 표시된 코드를 스캔하세요.';

  @override
  String get pairOrPaste => '또는 링크 붙여넣기';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => '붙여넣기';

  @override
  String get connect => '연결';

  @override
  String get pairFooter => '연결 후 PC에서 승인을 클릭하세요. 링크는 한 번만 사용할 수 있습니다.';

  @override
  String get pairBadLink => 'WinRelay 링크가 아닙니다. PC의 WinRelay에서 다시 복사하세요.';

  @override
  String get pcsTitle => '내 PC';

  @override
  String get pcsEmpty => '먼저 PC를 페어링하세요.';

  @override
  String get settings => '설정';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · 포트 $port';
  }

  @override
  String get waitingApprovalSub => 'PC 승인 대기 중';

  @override
  String get renamePc => 'PC 이름 변경';

  @override
  String get rename => '이름 변경';

  @override
  String get remove => '제거';

  @override
  String get refresh => '새로고침';

  @override
  String connectingTo(String name) {
    return '$name에 연결 중…';
  }

  @override
  String get approveTitle => 'PC에서 이 휴대폰을 승인하세요';

  @override
  String approveBody(String name) {
    return 'PC에서 WinRelay를 열고 \"$name\" 옆의 승인을 클릭하세요.';
  }

  @override
  String get cantConnect => '연결할 수 없음';

  @override
  String errUnreachable(String name) {
    return '$name에 연결할 수 없습니다. PC가 켜져 있고 WinRelay가 실행 중이며 네트워크가 연결 가능한지 확인하세요.';
  }

  @override
  String errDropped(String name) {
    return '$name와의 연결이 끊겼습니다.';
  }

  @override
  String get searchWindows => '창 검색';

  @override
  String get hideOnPc => 'PC에서 창 숨기기';

  @override
  String get hideOnPcSub => '스텔스: 제어 중 PC 화면에는 창이 표시되지 않습니다';

  @override
  String get noMatch => '일치하는 창이 없습니다. 아래로 당겨서 새로고침하세요.';

  @override
  String get viewMode => '보기';

  @override
  String get tapMode => '탭';

  @override
  String get viewTip => '보기만 함: 탭은 PC를 클릭하지 않습니다';

  @override
  String get tapTip => '탭이 PC를 클릭합니다';

  @override
  String get stealthTip => '스텔스: PC에서 숨겨짐';

  @override
  String get reconnecting => 'PC에 다시 연결 중…';

  @override
  String get pcLocked => 'PC가 잠겨 있습니다. 잠금 해제 후 이 창을 계속 제어할 수 있습니다.';

  @override
  String get composeHint => '이 창에 보낼 메시지 입력';

  @override
  String get sendWithEnter => 'Enter로 보내기';

  @override
  String get settingsTitle => '설정';

  @override
  String get secThisPhone => '이 휴대폰';

  @override
  String get phoneName => '휴대폰 이름';

  @override
  String get phoneNameSub => '페어링 시 PC에 표시됩니다';

  @override
  String get secAppearance => '화면 모드';

  @override
  String get theme => '테마';

  @override
  String get themeSystem => '시스템';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 기본값';

  @override
  String get secTouch => '터치와 입력';

  @override
  String get defaultTouch => '기본 터치 모드';

  @override
  String get defaultTouchSub => '보기는 PC를 클릭하지 않고, 탭은 탭을 클릭으로 바꿉니다';

  @override
  String get composeMode => '작성 모드';

  @override
  String get composeModeSub =>
      '자동 수정과 함께 전체 메시지를 먼저 쓰고 보내세요. 끄기: 모든 키가 즉시 PC로 전송됩니다.';

  @override
  String get returnSends => 'Enter 키 전송';

  @override
  String get enterKeyEnter => 'Enter';

  @override
  String get enterKeyCtrlEnter => 'Ctrl+Enter';

  @override
  String get vibrate => '빠른 키 진동';

  @override
  String get secQuickKeys => '빠른 키';

  @override
  String get secPicture => '화면';

  @override
  String get textSize => '글자 크기';

  @override
  String get stealthDefault => '기본적으로 PC에서 창 숨기기';

  @override
  String get stealthDefaultSub => '스텔스. 창별로 전환할 수 있습니다.';

  @override
  String get keepScreenOn => '제어 중 화면 켜짐 유지';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get hideKeyboard => '키보드 숨기기';

  @override
  String get showKeyboard => '키보드 표시';

  @override
  String get qkNewLine => '줄바꿈';

  @override
  String get qkPaste => '붙여넣기';

  @override
  String get qkPageUp => '페이지 위로';

  @override
  String get qkPageDown => '페이지 아래로';

  @override
  String get qkDelete => '삭제';

  @override
  String get secStream => '스트림';

  @override
  String get rxFps => '수신 프레임레이트';

  @override
  String get rxFpsSub => '낮을수록 데이터를 절약하고 화면이 덜 부드럽습니다';

  @override
  String get rxScale => '수신 해상도';

  @override
  String get rxScaleSub => '화면이 작을수록 데이터를 크게 절약합니다';

  @override
  String get rxGray => '회색조 모드';

  @override
  String get rxGraySub => '흑백 화면으로 데이터 사용량을 크게 줄입니다';

  @override
  String get switchIme => '입력기 전환';

  @override
  String get webMode => '웹';

  @override
  String get webModeTip => '휴대폰처럼 탐색하며 PC가 탐색을 따라갑니다';

  @override
  String get loadFromPc => 'PC의 현재 페이지 불러오기';

  @override
  String get filesTitle => '파일';

  @override
  String get thisPc => '내 PC';

  @override
  String get upload => '업로드';

  @override
  String get download => '다운로드';

  @override
  String get newFolder => '새 폴더';

  @override
  String get folderName => '폴더 이름';

  @override
  String get deleteItem => '삭제';

  @override
  String get deleteConfirmTitle => '삭제할까요?';

  @override
  String deleteConfirmBody(Object name) {
    return '\"$name\" 항목은 휴지통으로 이동합니다.';
  }

  @override
  String get downloadDone => '다운로드 완료. 저장 위치를 선택하세요.';

  @override
  String get transferDone => '전송 완료';

  @override
  String get transferFailed => '전송 실패';

  @override
  String get emptyDir => '빈 폴더';

  @override
  String get grantStorage => '다음 화면에서 모든 파일 접근을 허용한 후 다시 시도하세요.';

  @override
  String get uploadFromPhone => '이 휴대폰에서 파일 보내기';

  @override
  String get goBack => '뒤로';

  @override
  String get goForward => '앞으로';

  @override
  String get addressBarHint => '검색 또는 URL 입력';

  @override
  String get followPc => 'PC 따라가기';

  @override
  String get pcScreen => 'PC 화면';

  @override
  String get clipCopyFromPc => '이 PC의 클립보드 복사';

  @override
  String get clipPasteToPc => '중계 텍스트를 이 PC에 붙여넣기';

  @override
  String get clipEmpty => '중계 클립보드가 비어 있습니다. 먼저 다른 PC에서 복사하세요.';

  @override
  String clipCopied(Object n) {
    return '복사됨($n자). 다른 PC에서 붙여넣기를 누르세요.';
  }

  @override
  String get clipPasted => 'PC에 붙여넣었습니다.';

  @override
  String get colorColor => '컬러';

  @override
  String get colorGray => '회색조';

  @override
  String get colorBw => '순흑백';

  @override
  String get jumpPath => '경로로 이동';

  @override
  String get pathHint => 'PC 경로 (예: C:\\Users\\me\\Desktop)';

  @override
  String get invalidPath => '그 경로를 열 수 없습니다.';

  @override
  String savedTo(Object name) {
    return '휴대폰 Download에 저장: $name';
  }

  @override
  String get share => '공유';

  @override
  String get appsTitle => '앱';

  @override
  String get searchApps => '앱 검색…';

  @override
  String get running => '실행 중';

  @override
  String get appOpen => '실행';

  @override
  String get appClose => '앱 종료';

  @override
  String get closeAppTitle => '종료할까요?';

  @override
  String closeAppBody(Object name) {
    return '\"$name\" 앱이 PC에서 종료됩니다(저장 여부를 물을 수 있음).';
  }

  @override
  String get appDone => '완료';

  @override
  String get appsEmpty => '일치하는 앱이 없습니다.';
}
