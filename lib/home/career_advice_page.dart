import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CareerAdvicePage extends StatefulWidget {
  @override
  _CareerAdvicePageState createState() => _CareerAdvicePageState();
}

class _CareerAdvicePageState extends State<CareerAdvicePage> {
  String? htmlContent;
  String? url;
  bool isLoading = true;

  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted); // ✅ Enable JavaScript

    _fetchCareerAdvice();
  }

 Future<void> _fetchCareerAdvice() async {
  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('career_advice')
        .doc('latest_advice')
        .get();

    if (doc.exists) {
      setState(() {
        htmlContent = doc['htmlContent'] ?? "";
        url = doc['url'] ?? "";
        isLoading = false;
      });

      if (htmlContent != null && htmlContent!.isNotEmpty) {
        // ✅ If HTML content exists, load it instead of URL
        _webViewController.loadHtmlString(htmlContent!);
      } else if (url != null && url!.isNotEmpty) {
        // ✅ Load URL only if HTML content is not available
        _webViewController.loadRequest(Uri.parse(url!));
      } else {
        // ✅ Load default message if both are empty
        _webViewController.loadHtmlString("<p>No content available</p>");
      }
    } else {
      setState(() => isLoading = false);
    }
  } catch (e) {
    print("Error fetching career advice: $e");
    setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Career Advice")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _webViewController), // ✅ Correct widget
    );
  }
}
