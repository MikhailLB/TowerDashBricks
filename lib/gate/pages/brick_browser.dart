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

import '../infra/brick_beacon.dart';
import '../infra/network_probe.dart';
import '../infra/brick_agent.dart';
import '../infra/brick_vault.dart';
import 'offline_screen.dart';

/// Full-screen WebView with immersive mode, keyboard fixes and safe-area shim.
class BrickBrowser extends StatefulWidget {
  final String destination;
  final BrickVault vault;
  final BrickBeacon beacon;
  final NetworkProbe probe;
  final VoidCallback? onFirstPaint;
  final bool coldStartPush;

  const BrickBrowser({
    super.key,
    required this.destination,
    required this.vault,
    required this.beacon,
    required this.probe,
    this.onFirstPaint,
    this.coldStartPush = false,
  });

  @override
  State<BrickBrowser> createState() => _BrickBrowserState();
}

class _BrickBrowserState extends State<BrickBrowser>
    with WidgetsBindingObserver {
  late final WebViewController _webCtrl;
  StreamSubscription<List<ConnectivityResult>>? _netSub;
  bool _wentOffline = false;
  bool _initialPaintDone = false;
  String? _lastLoadedUrl;
  int _redirectRetries = 0;
  bool _viewportReady = false;
  bool _refreshDone = false;
  Widget? _videoOverlay;
  void Function()? _dismissOverlay;

  void _enableImmersive() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  /// Micro-rotation — forces the WKWebView native frame to recalculate.
  /// Equivalent to the user manually rotating the device (gray_flow_guide §2).
  Future<void> _forceLayoutRecalc() async {
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

  Future<void> _initColdStartView() async {
    _enableImmersive();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _forceLayoutRecalc();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _refreshLayout({bool reload = false}) async {
    if (!mounted) return;
    setState(() {});
    _webCtrl.runJavaScript(
      'window.dispatchEvent(new Event("resize"));'
      'if(window.visualViewport)'
      '  window.visualViewport.dispatchEvent(new Event("resize"));',
    );
    _applyViewportFix();
    if (reload) {
      try { await _webCtrl.reload(); } catch (_) {}
    }
  }

  void _deferImmersive() {
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
      ..setUserAgent(brickAgent.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(_buildNavDelegate());

    _setupPlatform();

    if (widget.coldStartPush) {
      _initColdStartView().then((_) {
        if (!mounted) return;
        setState(() => _viewportReady = true);
        _webCtrl.loadRequest(Uri.parse(widget.destination));
      });
    } else {
      _viewportReady = true;
      _deferImmersive();
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
      onPageStarted: (url) {
        if (url.isNotEmpty) _lastLoadedUrl = url;
      },
      onPageFinished: (url) {
        _redirectRetries = 0;
        _applyViewportFix();
        _applyKeyboardFix();
        _preventAutoZoom();
        _enableVideoAutoplay();
        // gray_flow_guide §2 — recalc viewport once immersive mode settles.
        // Also triggers setState so Flutter-side Padding recomputes viewPadding.
        // Snapshot the current URL so we only reload if the user hasn't navigated away.
        final loadedUrl = url;
        Future.delayed(const Duration(milliseconds: 800), () async {
          if (!mounted) return;
          // Do NOT reload if the user already navigated to another page.
          final currentUrl = await _webCtrl.currentUrl();
          final urlUnchanged = currentUrl == null || currentUrl == loadedUrl;
          final needsReload = widget.coldStartPush && !_refreshDone && urlUnchanged;
          if (needsReload) _refreshDone = true;
          if (mounted) setState(() {}); // re-read viewPadding after immersive settles
          _refreshLayout(reload: needsReload);
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
        // -999 = NSURLErrorCancelled — navigation intentionally cancelled
        // (e.g. by a new loadRequest or our 800ms reload). Not a real error.
        if (err.errorCode == -999) return;
        // -1007 = NSURLErrorHTTPTooManyRedirects — site's affiliate/tracking
        // redirect chain hit WKWebView's limit. Retry the same URL after a
        // short delay (resets WKWebView redirect counter); up to 3 attempts.
        // The retry fires a new loadRequest → WKWebView may cancel the current
        // request with -999, which is now harmlessly ignored above.
        if (err.errorCode == -1007) {
          if (_lastLoadedUrl != null && _redirectRetries < 3) {
            _redirectRetries++;
            final url = _lastLoadedUrl!;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _webCtrl.loadRequest(Uri.parse(url));
            });
          }
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
      builder: (_) => OfflineScreen(
        probe: widget.probe,
        retryBuilder: (_) => BrickBrowser(
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

  void _applyViewportFix() {
    _webCtrl.runJavaScript(r'''
(function(){
  if(window.__tdbSa)return; window.__tdbSa=true;
  var ID='__tdbSa';
  var CSS=':root{--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;'
    +'--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;'
    +'--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;}'
    +'html,body,#__nuxt,#__layout,#app,#root,.gameview-mobile-header{'
    +'padding-top:0!important;padding-left:0!important;padding-right:0!important;margin-top:0!important;}';
  function kbOpen(){return window.visualViewport&&window.visualViewport.height<window.innerHeight*0.75;}
  function apply(){
    if(kbOpen())return;
    var h=document.head||document.documentElement; if(!h)return;
    var vp=document.querySelector('meta[name="viewport"]');
    if(vp&&!/viewport-fit\s*=\s*contain/i.test(vp.getAttribute('content')||'')){
      var c=(vp.getAttribute('content')||'').replace(/,?\s*viewport-fit\s*=\s*\w+/ig,'').trim();
      vp.setAttribute('content',c+(c?', ':'')+' viewport-fit=contain');
    }
    var s=document.getElementById(ID);
    if(!s){s=document.createElement('style');s.id=ID;h.appendChild(s);}
    if(s.textContent!==CSS)s.textContent=CSS;
    if(h.lastElementChild!==s)h.appendChild(s);
  }
  apply();
  ['pushState','replaceState'].forEach(function(n){
    var o=history[n];history[n]=function(){var r=o.apply(this,arguments);setTimeout(apply,150);setTimeout(apply,600);return r;};
  });
  window.addEventListener('popstate',function(){setTimeout(apply,150);});
  setInterval(apply,2500);
})();
''');
  }

  void _applyKeyboardFix() {
    _webCtrl.runJavaScript(r'''
(function(){
  if(window.__tdbKb)return; window.__tdbKb=true;
  function iL(n){return n&&(n.tagName==='INPUT'||n.tagName==='TEXTAREA'||n.isContentEditable);}
  function roll(){
    var el=document.activeElement; if(!iL(el))return;
    var vp=window.visualViewport;
    if(vp){var r=el.getBoundingClientRect();
      if(r.bottom>vp.offsetTop+vp.height-20||r.top<vp.offsetTop)
        el.scrollIntoView({behavior:'auto',block:'nearest'});
    } else { el.scrollIntoView({behavior:'auto',block:'nearest'}); }
  }
  document.addEventListener('focusin',function(e){if(iL(e.target))setTimeout(roll,350);});
  if(window.visualViewport){
    var prev=window.visualViewport.height;
    window.visualViewport.addEventListener('resize',function(){
      var h=window.visualViewport.height;if(h<prev)setTimeout(roll,120);prev=h;
    });
  }
})();
''');
  }

  void _preventAutoZoom() {
    if (!Platform.isIOS) return;
    _webCtrl.runJavaScript(r'''
(function(){
  if(window.__tdbAz)return; window.__tdbAz=true;
  var s=document.createElement('style'); s.id='__tdbAz';
  s.textContent='input,textarea,select,[contenteditable=true]{font-size:16px!important;}';
  (document.head||document.documentElement).appendChild(s);
})();
''');
  }

  void _enableVideoAutoplay() {
    _webCtrl.runJavaScript(r'''
(function(){
  if(window.__tdbVideoAuto)return; window.__tdbVideoAuto=true;
  function prep(v){
    try{
      v.setAttribute('playsinline','');
      v.setAttribute('webkit-playsinline','');
      v.playsInline=true; v.muted=true; v.defaultMuted=true; v.autoplay=true;
      var p=v.play&&v.play(); if(p&&p.catch)p.catch(function(){});
    }catch(_){}
  }
  function sweep(root){
    try{var l=(root||document).querySelectorAll('video');for(var i=0;i<l.length;i++)prep(l[i]);}catch(_){}
  }
  sweep(document);
  document.addEventListener('touchend',function(){sweep(document);},{passive:true});
  var mo=new MutationObserver(function(recs){
    for(var i=0;i<recs.length;i++){
      var nodes=recs[i].addedNodes||[];
      for(var j=0;j<nodes.length;j++){
        var n=nodes[j]; if(!n||n.nodeType!==1)continue;
        if(n.tagName==='VIDEO')prep(n); sweep(n);
      }
    }
  });
  mo.observe(document.documentElement,{childList:true,subtree:true});
  setInterval(function(){sweep(document);},1500);
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
    // On cold-start push tap: don't apply viewPadding — immersiveSticky is still
    // settling (viewPadding is stale from before system UI was hidden).
    // Safe-area insets are zeroed by _applyViewportFix() JS injection instead.
    final safe = widget.coldStartPush ? EdgeInsets.zero
        : EdgeInsets.only(
            top: MediaQuery.of(context).viewPadding.top,
            bottom: MediaQuery.of(context).viewPadding.bottom,
            left: MediaQuery.of(context).viewPadding.left,
            right: MediaQuery.of(context).viewPadding.right,
          );
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
            if (_viewportReady)
              Padding(
                padding: safe,
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
