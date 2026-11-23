import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class GoogleAuthWebViewScreen extends ConsumerStatefulWidget {
  const GoogleAuthWebViewScreen({super.key});

  @override
  ConsumerState<GoogleAuthWebViewScreen> createState() => _GoogleAuthWebViewScreenState();
}

class _GoogleAuthWebViewScreenState extends ConsumerState<GoogleAuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _tokenHandled = false;

  @override
  void initState() {
    super.initState();
    final origin = kBaseUrl.replaceFirst('/api/v1', '');
    final url = '$origin/api/v1/auth/google/redirect';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final urlString = request.url;
            if (!_tokenHandled && (urlString.contains('/social-auth') || urlString.contains('token='))) {
              try {
                final uri = Uri.parse(urlString);
                final token = uri.queryParameters['token'] ?? (uri.fragment.isNotEmpty ? uri.fragment : null);
                if (token != null && token.isNotEmpty) {
                  _tokenHandled = true;
                  final actualToken = token.startsWith('token=') ? token.replaceFirst('token=', '') : token;
                  _handleToken(actualToken);
                  return NavigationDecision.prevent;
                }
              } catch (_) {}
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _handleToken(String token) async {
    await ref.read(authProvider.notifier).handleSocialToken(token);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In successful! Welcome to GOSIKA.'),
          backgroundColor: kSuccess,
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Google'),
        backgroundColor: Colors.white,
        foregroundColor: kNavy,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: kPrimary)),
        ],
      ),
    );
  }
}
