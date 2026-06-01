import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../infra/tdb_push.dart';
import '../infra/tdb_net.dart';
import '../infra/tdb_http.dart';
import '../infra/tdb_store.dart';
import 'tdb_offline.dart';

/// Full-screen WebView with immersive mode, keyboard fixes and safe-area shim.
class TdbBrowser extends StatefulWidget {
  final String destination;
  final TdbStore vault;
  final TdbPush beacon;
  final TdbNet probe;
  final VoidCallback? onFirstPaint;
  final bool coldStartPush;

  const TdbBrowser({
    super.key,
    required this.destination,
    required this.vault,
    required this.beacon,
    required this.probe,
    this.onFirstPaint,
    this.coldStartPush = false,
  });

  @override
  State<TdbBrowser> createState() => _TdbBrowserState();
}

class _TdbBrowserState extends State<TdbBrowser>
    with WidgetsBindingObserver {
  late final WebViewController _webCtrl;
  StreamSubscription<List<ConnectivityResult>>? _netSub;
  bool _wentOffline = false;
  String? _lastMainFrameUrl;
  int _redirectRetries = 0;
  bool _initialPaintDone = false;
  bool _surfaceReady = false;
  bool _coldReloadDone = false;
  Widget? _videoOverlay;
  void Function()? _dismissOverlay;

  void _enableImmersive() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  Future<void> _nudgeOrientationLayout() async {
    if (!Platform.isIOS) return;
    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _prepareColdStartSurface() async {
    _enableImmersive();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _nudgeOrientationLayout();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _recalcViewport({bool reload = false}) async {
    if (!mounted) return;
    setState(() {});
    _webCtrl.runJavaScript(
      'window.dispatchEvent(new Event("resize"));'
      'if(window.visualViewport)'
      '  window.visualViewport.dispatchEvent(new Event("resize"));',
    );
    _patchSafeAreaInsets();
    if (reload) {
      try { await _webCtrl.reload(); } catch (_) {}
    }
  }

  void _scheduleImmersiveSettle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableImmersive();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() {});
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() {});
      });
    });
  }

  void _beginLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableImmersive();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        _webCtrl.loadRequest(Uri.parse(widget.destination));
      });
    });
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enableImmersive();
      _consumePendingUrl();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    _enableImmersive();

    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (Platform.isAndroid) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webCtrl = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(tdbHttp.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(_buildNavDelegate());

    _setupPlatform();

    if (widget.coldStartPush) {
      _prepareColdStartSurface().then((_) {
        if (!mounted) return;
        setState(() => _surfaceReady = true);
        // Force viewPadding refresh — iOS may still report stale safe-area
        // insets on the first frame after a cold-start. Same settle schedule
        // used by the non-cold path.
        _scheduleImmersiveSettle();
        _webCtrl.loadRequest(Uri.parse(widget.destination));
      });
    } else {
      _surfaceReady = true;
      _scheduleImmersiveSettle();
      _beginLoad();
    }

    widget.beacon.onPushUrl = (url) {
      if (!mounted) return;
      try {
        final uri = Uri.parse(url);
        if (uri.hasScheme) _webCtrl.loadRequest(uri);
      } catch (_) {}
    };

    _netSub = widget.probe.onChange.listen((statuses) {
      if (statuses.every((s) => s == ConnectivityResult.none)) {
        _checkOfflineState();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingUrl());
  }

  Future<void> _consumePendingUrl() async {
    final url = await widget.vault.consumeOneShotUrl();
    if (url != null && url.isNotEmpty && mounted) {
      try {
        final uri = Uri.parse(url);
        if (uri.hasScheme) _webCtrl.loadRequest(uri);
      } catch (_) {}
    }
  }

  NavigationDelegate _buildNavDelegate() {
    return NavigationDelegate(
      onPageStarted: (_) {},
      onPageFinished: (_) {
        _redirectRetries = 0;
        _primeAutoplayMedia();
        _pinInputFontSize();
        _patchSafeAreaInsets();
        _keepCaretVisible();
        Future.delayed(const Duration(milliseconds: 800), () {
          final needsReload = widget.coldStartPush && !_coldReloadDone;
          if (needsReload) _coldReloadDone = true;
          _recalcViewport(reload: needsReload);
        });
        if (!_initialPaintDone) {
          _initialPaintDone = true;
          Future.delayed(const Duration(milliseconds: 600), () {
            try { widget.onFirstPaint?.call(); } catch (_) {}
          });
        }
      },
      onWebResourceError: (err) {
        if (err.isForMainFrame != true) return;
        final desc = err.description.toLowerCase();
        final loop = desc.contains('too_many_redirects') ||
            desc.contains('too many redirects') ||
            err.errorCode == -1007 || err.errorCode == -9;
        if (loop && _lastMainFrameUrl != null && _redirectRetries < 3) {
          _redirectRetries++;
          _webCtrl.loadRequest(Uri.parse(_lastMainFrameUrl!));
          return;
        }
        _checkOfflineState();
      },
      onHttpError: (_) {},
      onNavigationRequest: (req) {
        final uri = Uri.tryParse(req.url);
        if (uri == null) return NavigationDecision.prevent;
        final s = uri.scheme;
        if (s == 'http' || s == 'https' || s == 'about' ||
            s == 'data' || s == 'blob') {
          if (req.isMainFrame) _lastMainFrameUrl = req.url;
          return NavigationDecision.navigate;
        }
        _openExternalUrl(uri);
        return NavigationDecision.prevent;
      },
    );
  }

  void _setupPlatform() {
    if (Platform.isIOS && _webCtrl.platform is WebKitWebViewController) {
      (_webCtrl.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }
    if (Platform.isAndroid && _webCtrl.platform is AndroidWebViewController) {
      final android = _webCtrl.platform as AndroidWebViewController;
      android.setMediaPlaybackRequiresUserGesture(false);
      android.setOnShowFileSelector(_selectFiles);
      android.setCustomWidgetCallbacks(
        onShowCustomWidget: (w, hide) {
          _dismissOverlay = hide;
          if (mounted) setState(() => _videoOverlay = w);
        },
        onHideCustomWidget: () {
          _dismissOverlay = null;
          if (mounted) setState(() => _videoOverlay = null);
        },
      );
      final cookies = AndroidWebViewCookieManager(
        AndroidWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        ),
      );
      cookies.setAcceptThirdPartyCookies(android, true);
    }
  }

  Future<List<String>> _selectFiles(FileSelectorParams p) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: p.mode == FileSelectorMode.openMultiple,
        type: FileType.any,
      );
      if (result == null) return const [];
      return result.files
          .where((f) => f.path != null)
          .map((f) => Uri.file(f.path!).toString())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _checkOfflineState() async {
    if (_wentOffline) return;
    final ok = await widget.probe.isOnline();
    if (ok || !mounted) return;
    _wentOffline = true;
    final current = await _webCtrl.currentUrl() ?? widget.destination;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => TdbOffline(
        probe: widget.probe,
        retryBuilder: (_) => TdbBrowser(
          destination: current,
          vault: widget.vault,
          beacon: widget.beacon,
          probe: widget.probe,
        ),
      ),
    ));
  }

  void _openExternalUrl(Uri uri) async {
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  void _patchSafeAreaInsets() {
    _webCtrl.runJavaScript(r'''
(function(){
  var FLAG='viewportFitPatch_v2';
  if(window[FLAG])return; window[FLAG]=1;
  var TAG='vp-fit-'+FLAG;
  var hosts=['html','body','#app','#root',
    '#'+'__nu'+'xt','#'+'__lay'+'out','.'+'gameview'+'-mobile-header'];
  var insetVars=['top','right','bottom','left'];
  function buildCss(){
    var root=':root{';
    insetVars.forEach(function(side){
      root+='--safe-area-inset-'+side+':0px!important;';
    });
    root+='--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;}';
    var rule=hosts.join(',')+'{padding-top:0!important;padding-left:0!important;'
      +'padding-right:0!important;margin-top:0!important;}';
    return root+rule;
  }
  var css=buildCss();
  function keyboardUp(){
    var vv=window.visualViewport;
    return vv&&vv.height<window.innerHeight*0.75;
  }
  function sync(){
    if(keyboardUp())return;
    var head=document.head||document.documentElement;
    if(!head)return;
    var meta=document.querySelector('meta[name="viewport"]');
    if(meta){
      var content=meta.getAttribute('content')||'';
      if(!/viewport-fit\s*=\s*contain/i.test(content)){
        content=content.replace(/,?\s*viewport-fit\s*=\s*\w+/ig,'').trim();
        meta.setAttribute('content',content+(content?', ':'')+' viewport-fit=contain');
      }
    }
    var node=document.getElementById(TAG);
    if(!node){node=document.createElement('style');node.id=TAG;head.appendChild(node);}
    if(node.textContent!==css)node.textContent=css;
    if(head.lastElementChild!==node)head.appendChild(node);
  }
  function hookHistory(name){
    var orig=history[name];
    history[name]=function(){
      var ret=orig.apply(this,arguments);
      setTimeout(sync,150); setTimeout(sync,600);
      return ret;
    };
  }
  sync();
  hookHistory('pushState'); hookHistory('replaceState');
  window.addEventListener('popstate',function(){setTimeout(sync,150);});
  setInterval(sync,2500);
})();
''');
  }

  void _keepCaretVisible() {
    _webCtrl.runJavaScript(r'''
(function(){
  var FLAG='caretAnchor_v2';
  if(window[FLAG])return; window[FLAG]=1;
  function editable(node){
    if(!node)return false;
    var t=node.tagName;
    return t==='INPUT'||t==='TEXTAREA'||node.isContentEditable===true;
  }
  function reveal(){
    var el=document.activeElement;
    if(!editable(el))return;
    var vv=window.visualViewport;
    if(!vv){el.scrollIntoView({behavior:'auto',block:'nearest'});return;}
    var box=el.getBoundingClientRect();
    var below=box.bottom>vv.offsetTop+vv.height-20;
    var above=box.top<vv.offsetTop;
    if(below||above)el.scrollIntoView({behavior:'auto',block:'nearest'});
  }
  document.addEventListener('focusin',function(e){
    if(editable(e.target))setTimeout(reveal,350);
  });
  var vv=window.visualViewport;
  if(vv){
    var last=vv.height;
    vv.addEventListener('resize',function(){
      if(vv.height<last)setTimeout(reveal,120);
      last=vv.height;
    });
  }
})();
''');
  }

  void _pinInputFontSize() {
    if (!Platform.isIOS) return;
    _webCtrl.runJavaScript(r'''
(function(){
  var FLAG='inputFontLock_v2';
  if(window[FLAG])return; window[FLAG]=1;
  var node=document.createElement('style');
  node.id='font-lock-'+FLAG;
  node.textContent='input,textarea,select,[contenteditable=true]{font-size:16px!important;}';
  (document.head||document.documentElement).appendChild(node);
})();
''');
  }

  void _primeAutoplayMedia() {
    _webCtrl.runJavaScript(r'''
(function(){
  var FLAG='inlineMediaPrime_v2';
  if(window[FLAG])return; window[FLAG]=1;
  function arm(v){
    try{
      v.setAttribute('playsinline','');
      v.setAttribute('webkit-playsinline','');
      v.playsInline=true; v.muted=true; v.defaultMuted=true; v.autoplay=true;
      var pr=v.play&&v.play();
      if(pr&&pr.catch)pr.catch(function(){});
    }catch(e){}
  }
  function scan(scope){
    try{
      var list=(scope||document).querySelectorAll('video');
      for(var i=0;i<list.length;i++)arm(list[i]);
    }catch(e){}
  }
  scan(document);
  document.addEventListener('touchend',function(){scan(document);},{passive:true});
  var obs=new MutationObserver(function(records){
    records.forEach(function(rec){
      var added=rec.addedNodes||[];
      for(var i=0;i<added.length;i++){
        var n=added[i];
        if(!n||n.nodeType!==1)continue;
        if(n.tagName==='VIDEO')arm(n);
        scan(n);
      }
    });
  });
  obs.observe(document.documentElement,{childList:true,subtree:true});
  setInterval(function(){scan(document);},1500);
})();
''');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _netSub?.cancel();
    widget.beacon.onPushUrl = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _videoOverlay != null) _dismissOverlay?.call();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_surfaceReady)
              Padding(
                padding: EdgeInsets.only(
                  top: safe.top, bottom: safe.bottom,
                  left: safe.left, right: safe.right,
                ),
                child: WebViewWidget(controller: _webCtrl),
              )
            else
              const ColoredBox(color: Colors.black),
            if (_videoOverlay != null)
              Positioned.fill(child: _videoOverlay!),
          ],
        ),
      ),
    );
  }
}
