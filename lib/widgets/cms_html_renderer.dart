import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

/// Lightweight native HTML-to-Flutter widget renderer for Rich Text Editor CMS pages.
class CmsHtmlRenderer extends StatelessWidget {
  final String html;
  const CmsHtmlRenderer({super.key, required this.html});

  static String _decodeEntities(String input) {
    return input
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }

  static List<TextSpan> _parseInlineSpans(String rawHtml, TextStyle baseStyle) {
    final normalized = rawHtml.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    final tokenRegex = RegExp(r'<(/?)(b|strong|i|em|u)\b[^>]*>', caseSensitive: false);
    final spans = <TextSpan>[];

    bool isBold = false;
    bool isItalic = false;
    bool isUnderline = false;
    int lastIndex = 0;

    for (final match in tokenRegex.allMatches(normalized)) {
      if (match.start > lastIndex) {
        final chunk = _decodeEntities(
          normalized.substring(lastIndex, match.start).replaceAll(RegExp(r'<[^>]+>'), ''),
        );
        if (chunk.isNotEmpty) {
          spans.add(TextSpan(
            text: chunk,
            style: baseStyle.copyWith(
              fontWeight: isBold ? FontWeight.w700 : baseStyle.fontWeight,
              fontStyle: isItalic ? FontStyle.italic : baseStyle.fontStyle,
              decoration: isUnderline ? TextDecoration.underline : baseStyle.decoration,
            ),
          ));
        }
      }

      final closing = match.group(1) == '/';
      final tag = (match.group(2) ?? '').toLowerCase();
      if (tag == 'b' || tag == 'strong') isBold = !closing;
      if (tag == 'i' || tag == 'em') isItalic = !closing;
      if (tag == 'u') isUnderline = !closing;
      lastIndex = match.end;
    }

    if (lastIndex < normalized.length) {
      final tail = _decodeEntities(
        normalized.substring(lastIndex).replaceAll(RegExp(r'<[^>]+>'), ''),
      );
      if (tail.isNotEmpty) {
        spans.add(TextSpan(
          text: tail,
          style: baseStyle.copyWith(
            fontWeight: isBold ? FontWeight.w700 : baseStyle.fontWeight,
            fontStyle: isItalic ? FontStyle.italic : baseStyle.fontStyle,
            decoration: isUnderline ? TextDecoration.underline : baseStyle.decoration,
          ),
        ));
      }
    }

    if (spans.isEmpty) {
      final plain = _decodeEntities(normalized.replaceAll(RegExp(r'<[^>]+>'), '').trim());
      if (plain.isNotEmpty) {
        spans.add(TextSpan(text: plain, style: baseStyle));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final cleaned = html.trim();
    if (cleaned.isEmpty) {
      return Text(
        'Content will be updated soon.',
        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF7B7066)),
      );
    }

    final blockRegex = RegExp(
      r'<(h1|h2|h3|p|li|blockquote|div)\b[^>]*>([\s\S]*?)</\1>',
      caseSensitive: false,
    );
    final matches = blockRegex.allMatches(cleaned).toList();

    final baseBody = GoogleFonts.outfit(
      fontSize: 14,
      height: 1.6,
      color: const Color(0xFF4A4252),
    );

    if (matches.isEmpty) {
      return RichText(text: TextSpan(children: _parseInlineSpans(cleaned, baseBody)));
    }

    final widgets = <Widget>[];
    for (final m in matches) {
      final tag = (m.group(1) ?? 'p').toLowerCase();
      final inner = (m.group(2) ?? '').trim();
      if (inner.isEmpty) continue;

      if (tag == 'h1') {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: RichText(
            text: TextSpan(
              children: _parseInlineSpans(
                inner,
                GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E2A36),
                ),
              ),
            ),
          ),
        ));
      } else if (tag == 'h2') {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: RichText(
            text: TextSpan(
              children: _parseInlineSpans(
                inner,
                GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E2A36),
                ),
              ),
            ),
          ),
        ));
      } else if (tag == 'h3') {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: RichText(
            text: TextSpan(
              children: _parseInlineSpans(
                inner,
                GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF7700),
                ),
              ),
            ),
          ),
        ));
      } else if (tag == 'li') {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 8),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7700),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(children: _parseInlineSpans(inner, baseBody)),
                ),
              ),
            ],
          ),
        ));
      } else if (tag == 'blockquote') {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EE),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFFFF7700), width: 3.5),
            ),
          ),
          child: RichText(
            text: TextSpan(
              children: _parseInlineSpans(
                inner,
                baseBody.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RichText(
            text: TextSpan(children: _parseInlineSpans(inner, baseBody)),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

/// Reusable dynamic screen shell for Terms, Privacy Policy, Help & Support, etc.
class DynamicCmsPageScaffold extends StatefulWidget {
  final String slug;
  final String fallbackTitle;
  final bool showContactCard;
  final Widget? bottomFooter;

  const DynamicCmsPageScaffold({
    super.key,
    required this.slug,
    required this.fallbackTitle,
    this.showContactCard = false,
    this.bottomFooter,
  });

  @override
  State<DynamicCmsPageScaffold> createState() => _DynamicCmsPageScaffoldState();
}

class _DynamicCmsPageScaffoldState extends State<DynamicCmsPageScaffold> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getCmsPage(widget.slug);
      if (mounted) {
        setState(() {
          _data = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_data['title']?.toString().trim().isNotEmpty == true)
        ? _data['title'].toString()
        : widget.fallbackTitle;
    final subtitle = _data['subtitle']?.toString() ?? '';
    final version = _data['version']?.toString() ?? '';
    final contentHtml = _data['contentHtml']?.toString() ?? '';
    final supportEmail = _data['supportEmail']?.toString() ?? '';
    final supportPhone = _data['supportPhone']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7700)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 44, color: Color(0xFFFF7700)),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load content',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7700),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFF7700),
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEFE6DB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (subtitle.isNotEmpty || version.isNotEmpty) ...[
                                Row(
                                  children: [
                                    if (subtitle.isNotEmpty)
                                      Expanded(
                                        child: Text(
                                          subtitle,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12.5,
                                            color: const Color(0xFF8A7E72),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    if (version.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF4E6),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'v$version',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFFF7700),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const Divider(
                                    color: Color(0xFFF3ECE3), height: 22),
                              ],
                              CmsHtmlRenderer(html: contentHtml),
                            ],
                          ),
                        ),
                        if (widget.showContactCard &&
                            (supportEmail.isNotEmpty ||
                                supportPhone.isNotEmpty)) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8EE),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFE2BC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contact Support',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2E2A36),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (supportEmail.isNotEmpty)
                                  Text(
                                    'Email: $supportEmail',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFF5A5260),
                                    ),
                                  ),
                                if (supportPhone.isNotEmpty)
                                  Text(
                                    'Phone: $supportPhone',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFF5A5260),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        if (widget.bottomFooter != null) ...[
                          const SizedBox(height: 18),
                          widget.bottomFooter!,
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}
