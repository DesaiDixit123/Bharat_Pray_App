import 'package:flutter/material.dart';
import '../../widgets/cms_html_renderer.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicCmsPageScaffold(
      slug: 'terms-and-conditions',
      fallbackTitle: 'Terms & Conditions',
    );
  }
}
