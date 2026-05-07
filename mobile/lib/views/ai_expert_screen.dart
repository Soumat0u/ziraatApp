import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../services/ai_service.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasProductContext;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.hasProductContext = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIExpertScreen extends StatefulWidget {
  final String? initialQuestion;
  const AIExpertScreen({super.key, this.initialQuestion});

  @override
  State<AIExpertScreen> createState() => _AIExpertScreenState();
}

class _AIExpertScreenState extends State<AIExpertScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Hoşgeldin mesajı
    _messages.add(_ChatMessage(
      text: 'Merhaba! 👋 Ben ZiraatBot, uzman ziraat mühendisiniz.\n\n'
          'Bana tarımsal ilaçlar, gübreler, bitki hastalıkları ve zararlılar '
          'hakkında her türlü soruyu sorabilirsiniz.\n\n'
          'Örnek sorular:\n'
          '• "Domates mildiyösüne hangi ilaç iyi gelir?"\n'
          '• "Magnezyum sülfat nasıl kullanılır?"\n'
          '• "NPK gübre nedir?"',
      isUser: false,
    ));

    // Eğer başka bir ekrandan soru ile gelindiyse otomatik gönder
    if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuestion!);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final result = await AIService.askQuestion(text.trim());

    setState(() {
      _isLoading = false;
      if (result.containsKey('error')) {
        _messages.add(_ChatMessage(
          text: '⚠️ ${result['error']}',
          isUser: false,
        ));
      } else {
        _messages.add(_ChatMessage(
          text: result['answer'] ?? 'Cevap alınamadı.',
          isUser: false,
          hasProductContext: result['has_product_context'] ?? false,
        ));
      }
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.leafGreen],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ZiraatBot',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _isLoading ? 'Düşünüyor...' : 'Tarım Uzmanı AI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _isLoading ? AppTheme.leafGreen : AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input Bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                          maxLines: 3,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Sorunuzu yazın...',
                            hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: (text) {
                            if (!_isLoading) _sendMessage(text);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (!_isLoading) {
                          HapticFeedback.mediumImpact();
                          _sendMessage(_controller.text);
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: _isLoading
                              ? null
                              : const LinearGradient(
                                  colors: [AppTheme.primaryGreen, AppTheme.leafGreen],
                                ),
                          color: _isLoading ? Colors.grey.shade300 : null,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: _isLoading ? Colors.grey : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.leafGreen],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('🌿', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryGreen : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                if (message.hasProductContext && !isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '📦 Veritabanınızdaki ürün bilgisi kullanıldı',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.leafGreen],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bouncingDot(0),
                const SizedBox(width: 4),
                _bouncingDot(1),
                const SizedBox(width: 4),
                _bouncingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bouncingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.leafGreen.withOpacity(0.4 + (value * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
