import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../domain/topup_constants.dart';

/// Hosts the Paystack checkout. When Paystack redirects to the Worker's
/// callback path (payment submitted), the screen closes and the flow advances
/// to the status screen.
class CheckoutWebViewScreen extends StatefulWidget {
  final String authorizationUrl;
  const CheckoutWebViewScreen({super.key, required this.authorizationUrl});

  @override
  State<CheckoutWebViewScreen> createState() => _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends State<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          if (p >= 100 && mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (req) {
          if (req.url.contains(TopUpConstants.paystackCallbackPath)) {
            _finish();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  void _finish() {
    if (_closed) return;
    _closed = true;
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
