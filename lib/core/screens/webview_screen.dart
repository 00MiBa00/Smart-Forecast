import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../services/sdk_initializer.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String? pushUrl; // URL from push notification (highest priority)

  const WebViewScreen({super.key, this.initialUrl = 'https://flutter.dev', this.pushUrl});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class UrlLauncherService {
  static Future<void> launchInBrowser({
    required String url,
    //required BuildContext context,
  }) async {
    try {
      final Uri uri = Uri.parse(url);

      // if (!await canLaunchUrl(uri)) {
      //   //  _showErrorSnackbar(context, 'Не удалось открыть ссылку');
      //   return;
      // }

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // Ошибка открытия настроек
    }
  }
}

// Removed unused _showErrorSnackbar function

Future<void> _launchURL(String url) async {
  // NativeMethodCaller.callSwiftMethodWithParams({'url': url});
  // await LaunchApp.openApp(
  //   iosUrlScheme: url, // Example for Instagram
  // );
  UrlLauncherService.launchInBrowser(
    url: url,
  );

  // if (await canLaunchUrl(Uri.parse(url))) {
  //   await launchUrl(
  //     Uri.parse(url),
  //     mode: LaunchMode.externalApplication, // Or other modes as needed
  //   );
  // } else {
  //   throw 'Could not launch $url';
  // }
}

class NativeMethodCaller {
  static const MethodChannel _channel =
      MethodChannel('com.yourapp/native_methods');

  static Future<void> callSwiftMethodWithParams(
      Map<String, dynamic> params) async {
    if (kDebugMode) {
      print("callSwiftMethodWithParams ${params.toString()}");
    }
    try {
      await _channel.invokeMethod('callSwiftMethodWithParams', params);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to call Swift method: '${e.message}'");
      }
    }
  }
}

class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
  late final PlatformWebViewController controller;
  bool isLoading = true;
  String currentUrl = '';

  bool get kDebugMode => true;

  @override
  void initState() {
    super.initState();
    
    // Register lifecycle observer to detect app resume from background
    WidgetsBinding.instance.addObserver(this);

    if (kDebugMode) {
      print('=== WEBVIEW INITSTATE START ===');
      print('widget.pushUrl (parameter): ${widget.pushUrl}');
      print('SdkInitializer.pushURL (global): ${SdkInitializer.pushURL}');
      print('receivedUrl: ${SdkInitializer.receivedUrl}');
      print('initialUrl: ${widget.initialUrl}');
    }

    // PRIORITY ORDER: widget.pushUrl (parameter) > SdkInitializer.pushURL (global) > receivedUrl (from AppsFlyer) > initialUrl
    String urlToLoad;
    
    // First check pushUrl parameter (passed directly from push handler)
    if (widget.pushUrl != null && widget.pushUrl!.isNotEmpty) {
      if (kDebugMode) {
        print('✅ WEBVIEW: Using widget.pushUrl parameter: ${widget.pushUrl}');
      }
      urlToLoad = widget.pushUrl!;
      // Clear global pushURL as we used the parameter
      SdkInitializer.pushURL = null;
    }
    // Then check global pushURL (for backward compatibility)
    else if (SdkInitializer.pushURL != null && SdkInitializer.pushURL!.isNotEmpty) {
      if (kDebugMode) {
        print('✅ WEBVIEW: Using global SdkInitializer.pushURL: ${SdkInitializer.pushURL}');
      }
      urlToLoad = SdkInitializer.pushURL!;
      // Clear pushURL after using it to prevent reuse on next WebView open
      SdkInitializer.pushURL = null;
      if (kDebugMode) {
        print('pushURL cleared after use');
      }
    } 
    // Finally fallback to receivedUrl or initialUrl
    else {
      if (kDebugMode) {
        print('⚠️ WEBVIEW: No pushURL, using receivedUrl or initialUrl');
        print('receivedUrl value: ${SdkInitializer.receivedUrl}');
      }
      String? savedUrl = SdkInitializer.receivedUrl;
      urlToLoad = savedUrl ?? widget.initialUrl;
    }
    if (kDebugMode) {
      print("=== FINAL URL TO LOAD: $urlToLoad ===");
    }
    controller = WebKitWebViewController(
      WebKitWebViewControllerCreationParams(
        mediaTypesRequiringUserAction: const {},
        allowsInlineMediaPlayback: true,
      ),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..setPlatformNavigationDelegate(
        WebKitNavigationDelegate(
          const PlatformNavigationDelegateCreationParams(),
        )
          ..setOnPageStarted((String url) {
            setState(() {
              isLoading = true;
              currentUrl = url;
            });
          })
          ..setOnPageFinished((String url) {
            setState(() async {
              await controller.runJavaScript('''
    // Сохраняем оригинальную функцию
    var originalWindowOpen = window.open;
    
    // Переопределяем window.open
    window.open = function(url, target, features) {
      // Всегда открываем в текущей вкладке
      window.location.href = url;
      return null;
    };
    
    // Также обрабатываем ссылки с target="_blank"
    document.addEventListener('click', function(e) {
      var target = e.target;
      while (target && target.nodeName !== 'A') {
        target = target.parentElement;
      }
      
      if (target && target.target === '_blank') {
        e.preventDefault();
        window.location.href = target.href;
      }
    });
  ''');
              isLoading = false;
              currentUrl = url;
            });
          })
          ..setOnHttpError((HttpResponseError error) {
            debugPrint(
              'Error occurred on page: ${error.response?.statusCode}',
            );
          })
          ..setOnWebResourceError((WebResourceError error) {
            // print(
            //   "error " +
            //       error.errorCode.toString() +
            //       "   url " +
            //       error.url!,
            // );
            if (error.errorCode == -1007 ||
                error.errorCode == -9 ||
                error.errorCode == -0) {
              if (error.url != null) {
                controller.loadRequest(
                  LoadRequestParams(uri: Uri.parse(error.url!)),
                );
                return;
              }
            }
            // if (error.url!.contains("http://")) return;
            // if (error.url!.contains("https://")) return;
            // _launchURL(error.url!);
          })
          ..setOnUrlChange((UrlChange change) {
            //  debugPrint('url change to ${change.url}');
            if (change.url!.contains("http://")) return;
            if (change.url!.contains("https://")) return;
            if (kDebugMode) {
              print(change.url);
            }
            _launchURL(change.url!); //change.url!);
          }),
      )
      ..setOnCanGoBackChange((onCanGoBackChangeCallback) {
        controller.canGoBack().then((onValue) {
          if (kDebugMode) {
            // print(
            //   "onValue " +
            //       onValue.toString() +
            //       " onCanGoBackChangeCallback " +
            //       onCanGoBackChangeCallback.toString(),
            // );
          }
          onCanGoBackChangeCallback = onValue;
        });
      })
      ..setOnPlatformPermissionRequest((
        PlatformWebViewPermissionRequest request,
      ) {
        debugPrint(
          'requesting permissions for ${request.types.map((WebViewPermissionResourceType type) => type.name)}',
        );
        request.grant();
      })
      ..setAllowsBackForwardNavigationGestures(true)
      ..getUserAgent().then((String? userAgent) {
        controller.setUserAgent(
          userAgent?.replaceAll("; wv", "").replaceAll("; wv", ""),
        );

        controller.loadRequest(
          LoadRequestParams(uri: Uri.parse(urlToLoad)),
        );
      });

    //controller.getSettings().setMediaPlaybackRequiresUserGesture(false);

    // Создаем контроллер WebView
    // controller = PlatformWebViewController(
    //   WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true),
    // );

    //   controller
    //   controller

    //     ..setJavaScriptMode(JavaScriptMode.unrestricted)
    //     // ..setAllowsBackForwardNavigationGestures(true)
    //     ..setPlatformNavigationDelegate(
    //       const PlatformNavigationDelegateCreationParams(),
    //     )
    //     ..setOnPageStarted((String url) {})
    //     ..setOnPageFinished((String url) {})
    //     ..setOnWebResourceError((WebResourceError error) {
    //       // print('Ошибка WebView: ${error.description}');
    //     })
    //     ..loadRequest(Uri.parse(urlToLoad));
    // });

    // if (controller is WebKitWebViewController) {
    //   (controller as WebKitWebViewController)
    //       .setAllowsBackForwardNavigationGestures(true);
    // }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      print('=== WebView AppLifecycleState changed to: $state ===');
    }
    
    // When app resumes from background, check if there's a new pushURL
    if (state == AppLifecycleState.resumed) {
      if (SdkInitializer.pushURL != null && SdkInitializer.pushURL!.isNotEmpty) {
        if (kDebugMode) {
          print('🔄 App resumed with pushURL: ${SdkInitializer.pushURL}');
          print('Loading new URL from push notification...');
        }
        
        // Load the new URL from push notification
        final newUrl = SdkInitializer.pushURL!;
        SdkInitializer.pushURL = null; // Clear after using
        
        controller.loadRequest(
          LoadRequestParams(uri: Uri.parse(newUrl)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        child: SafeArea(
          maintainBottomViewPadding: true,
          child: PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context),
        ));
  }
}
