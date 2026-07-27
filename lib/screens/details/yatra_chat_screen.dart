import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum YatraChatType { single, group }

class YatraChatMessage {
  const YatraChatMessage({
    required this.senderName,
    required this.text,
    required this.time,
    required this.isCurrentUser,
    this.avatarAsset,
  });

  final String senderName;
  final String text;
  final String time;
  final bool isCurrentUser;
  final String? avatarAsset;
}

class YatraChatScreen extends StatefulWidget {
  const YatraChatScreen({
    super.key,
    required this.chatType,
    required this.title,
    required this.subtitle,
    required this.messages,
    this.headerAvatarAsset,
    this.groupMembersText,
  });

  final YatraChatType chatType;
  final String title;
  final String subtitle;
  final List<YatraChatMessage> messages;
  final String? headerAvatarAsset;
  final String? groupMembersText;

  @override
  State<YatraChatScreen> createState() => _YatraChatScreenState();
}

class _YatraChatScreenState extends State<YatraChatScreen> {
  late final List<YatraChatMessage> _messages;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool get _isLightTheme => true;

  Color get _backgroundColor =>
      const Color(0xFFFFE8D6);

  Color get _headerTitleColor =>
      const Color(0xFFFF7A00);

  Color get _subtitleColor =>
      const Color(0xFFD3B99B);

  Color get _leftBubbleColor =>
      Colors.white;

  Color get _rightBubbleColor =>
      Colors.white;

  Color get _bubbleBorderColor =>
      const Color(0xFFCFA87B);

  Color get _messageColor => const Color(0xFF2D2D2D);

  Color get _inputBackground =>
      const Color(0xFFFFE8D6);

  Color get _inputBorderColor =>
      const Color(0xFFCFA87B);

  Color get _inputHintColor =>
      const Color(0xFFA88B6A);

  @override
  void initState() {
    super.initState();
    _messages = List<YatraChatMessage>.from(widget.messages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        YatraChatMessage(
          senderName: 'You',
          text: text,
          time: 'Now',
          isCurrentUser: true,
          avatarAsset: widget.headerAvatarAsset,
        ),
      );
    });

    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final showGroupHeader = widget.chatType == YatraChatType.group;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _isLightTheme ? Colors.white : const Color(0xFF5A5A5A),
                        shape: BoxShape.circle,
                        border: Border.all(color: _bubbleBorderColor, width: 1),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: _isLightTheme ? const Color(0xFFC79A65) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _bubbleBorderColor, width: 1),
                    ),
                    child: ClipOval(
                      child: showGroupHeader
                          ? Container(
                              color: _isLightTheme ? Colors.white : const Color(0xFF272727),
                              child: Icon(
                                Icons.groups_rounded,
                                color: _isLightTheme
                                    ? const Color(0xFFC79A65)
                                    : const Color(0xFFE8D2B8),
                                size: 26,
                              ),
                            )
                          : Image.asset(
                              widget.headerAvatarAsset ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => ColoredBox(
                                color: _isLightTheme
                                    ? const Color(0xFFE9D4BF)
                                    : const Color(0xFF2A2A2A),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: _headerTitleColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          showGroupHeader
                              ? (widget.groupMembersText ?? widget.subtitle)
                              : widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: _subtitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _ChatBubble(
                    message: message,
                    leftBubbleColor: _leftBubbleColor,
                    rightBubbleColor: _rightBubbleColor,
                    borderColor: _bubbleBorderColor,
                    messageColor: _messageColor,
                    useLightTheme: _isLightTheme,
                    fallbackAvatarAsset: widget.headerAvatarAsset,
                    senderColor: _senderColor(index),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: _inputBackground,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _inputBorderColor, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.outfit(
                          color: _messageColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Type message here...',
                          hintStyle: GoogleFonts.outfit(
                            color: _inputHintColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _isLightTheme ? const Color(0xFFFFE8D6) : const Color(0xFF6A6A6A),
                        shape: BoxShape.circle,
                        border: Border.all(color: _inputBorderColor, width: 1),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: _isLightTheme ? const Color(0xFFC79A65) : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _senderColor(int index) {
    if (_messages[index].isCurrentUser) return const Color(0xFF0088FF);
    final palette = <Color>[
      const Color(0xFF2ECC40),
      const Color(0xFFFFB000),
      const Color(0xFFFF3B30),
    ];
    return palette[index % palette.length];
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.leftBubbleColor,
    required this.rightBubbleColor,
    required this.borderColor,
    required this.messageColor,
    required this.useLightTheme,
    required this.fallbackAvatarAsset,
    required this.senderColor,
  });

  final YatraChatMessage message;
  final Color leftBubbleColor;
  final Color rightBubbleColor;
  final Color borderColor;
  final Color messageColor;
  final bool useLightTheme;
  final String? fallbackAvatarAsset;
  final Color senderColor;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isCurrentUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _Avatar(asset: message.avatarAsset ?? fallbackAvatarAsset, lightTheme: useLightTheme),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 230),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                color: isMe ? rightBubbleColor : leftBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 2),
                  bottomRight: Radius.circular(isMe ? 2 : 14),
                ),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.senderName,
                    style: GoogleFonts.outfit(
                      color: senderColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.text,
                    style: GoogleFonts.outfit(
                      color: messageColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      message.time,
                      style: GoogleFonts.outfit(
                        color: useLightTheme
                            ? const Color(0xFF5B5B5B)
                            : const Color(0xFFCFCFCF),
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _Avatar(asset: message.avatarAsset ?? fallbackAvatarAsset, lightTheme: useLightTheme),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.asset, required this.lightTheme});

  final String? asset;
  final bool lightTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: lightTheme ? const Color(0xFFCFA87B) : const Color(0xFFB1885A),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          asset ?? '',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: lightTheme ? const Color(0xFFE9D4BF) : const Color(0xFF2A2A2A),
          ),
        ),
      ),
    );
  }
}
