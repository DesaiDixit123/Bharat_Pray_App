import 'package:flutter/material.dart';
import '../../widgets/cms_html_renderer.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicCmsPageScaffold(
      slug: 'help-and-support',
      fallbackTitle: 'Help & Support',
      showContactCard: true,
    );
  }
}
