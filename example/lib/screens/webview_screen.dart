import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({required this.url, super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  int progress = 0;
  late WebViewController controller;
  bool hasError = false; 

  @override
  void initState() {
    super.initState();
    String validatedUrl = _validateUrl(widget.url);
    log("url for web view......$validatedUrl");

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progressValue) {
          if (mounted) {
            setState(() {
              progress = progressValue;
              hasError = false; 
            });
          }

          log('WebView is loading (progress: $progressValue%)');
        },
        onPageStarted: (String url) {
          setState(() {
            progress = 0;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            progress = 100;
          });
        },
        onWebResourceError: (WebResourceError error) {
          log('Error loading URL: ${error.description}');
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              setState(() {
                hasError = true; 
              });
              log('Has error set to true');
            });
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(validatedUrl));
  }

@override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
  }


@override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(7.0),
            child: InkWell(
              onTap: () {
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                ]);
                Navigator.pop(context);
              },
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                padding: const EdgeInsets.only(left: 10.0),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        extendBody: true,
        extendBodyBehindAppBar: false,
        body: Stack(
          children: [
            if (hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outlined, color: Colors.red, size: 50),
                    const SizedBox(height: 20),
                    const Text(
                      'Failed to load page',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          hasError = false;
                        });
                        controller.reload(); // Reload the page on retry
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 24.0), 
                        shape: RoundedRectangleBorder(
                          // Shape of the button
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 5, 
                        backgroundColor: Colors.green,
                        side: const BorderSide(
                            color: Colors.green,
                            width: 2), 
                      ),
                      child: Container(
                          padding: const EdgeInsets.all(5),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          )),
                    ),
                  ],
                ),
              )
            else
              WebViewWidget(controller: controller),
            if (progress < 100 && !hasError)
              Center(
                child: CircularProgressIndicator(
                  value: progress / 100.0,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper function to ensure URL has a scheme
  String _validateUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url'; // Add default scheme if missing
    }
    return url;
  }
}