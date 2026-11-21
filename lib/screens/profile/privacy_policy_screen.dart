import 'package:flutter/material.dart';
import '../../widgets/cms_html_renderer.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicCmsPageScaffold(
      slug: 'privacy-policy',
      fallbackTitle: 'Privacy Policy',
    );
  }
}
