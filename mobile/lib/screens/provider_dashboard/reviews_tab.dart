import 'package:flutter/material.dart';

class ReviewsTab extends StatefulWidget {
  const ReviewsTab({
    super.key,
    this.embedded = false,
    this.onOpenChat,
  });

  final bool embedded;

  final Future<void> Function(String customerName)? onOpenChat;

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  double overallRating = 4.2;
  int totalReviews = 23;
  int totalUsersRated = 17;
  String _sortOption = 'الأحدث';
  final Map<String, bool> _isReplying = {};
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, bool> _isLiked = {};
  // ✅ لحفظ الردود المرسلة
  final Map<String, List<Map<String, String>>> _replies = {};

  void _toggleLike(String customerName) {
    setState(() {
      _isLiked[customerName] = !(_isLiked[customerName] ?? false);
    });
  }

  void _toggleReply(String customerName) {
    setState(() {
      _isReplying[customerName] = !(_isReplying[customerName] ?? false);
    });
  }

  Future<void> _openChat(String customerName) async {
    if (widget.onOpenChat != null) {
      await widget.onOpenChat!(customerName);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة المحادثة غير مفعلة هنا.')),
    );
  }

  // ⭐ بناء النجوم
  Widget _buildStars(double rating, {double size = 22}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index < rating) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(
            Icons.star_border,
            color: Colors.grey.shade400,
            size: size,
          );
        }
      }),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⭐ التقييم العام (في المنتصف بدون كرت)
          Center(
            child: Column(
              children: [
                Text(
                  overallRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStars(overallRating, size: 34),
                const SizedBox(height: 6),
                Text(
                  "بناءً على $totalReviews مراجعة • $totalUsersRated مقيم",
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // 📊 تفاصيل البنود
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تفصيل البنود',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildCriteriaRow('سرعة الاستجابة', 4.0),
                _buildCriteriaRow('التكلفة مقابل الخدمة', 3.5),
                _buildCriteriaRow('جودة الخدمة', 4.5),
                _buildCriteriaRow('المصداقية', 4.0),
                _buildCriteriaRow('وقت الإنجاز', 4.2),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 🔽 عنوان + فلترة أسفله
          const Text(
            'مراجعات العملاء',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortOption,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: 'الأحدث', child: Text('الأحدث')),
                  DropdownMenuItem(
                    value: 'الأعلى تقييماً',
                    child: Text('الأعلى تقييماً'),
                  ),
                  DropdownMenuItem(
                    value: 'الأقل تقييماً',
                    child: Text('الأقل تقييماً'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortOption = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("تم الفرز حسب: $value")),
                    );
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 💬 المراجعات
          _buildReviewTile(
            'أبو محمد',
            4.5,
            'خدمة رائعة وسرعة في التنفيذ 👌',
            'قبل يومين',
          ),
          _buildReviewTile(
            'نورة',
            3.5,
            'جيدة عمومًا لكن السعر مرتفع قليلاً.',
            'قبل أسبوع',
          ),
          _buildReviewTile(
            'عبدالله',
            5.0,
            'أفضل تجربة تعاملت معها، أنصح به.',
            'قبل شهر',
          ),
        ],
      ),
    );
  }

  // 📊 بند تقييم فردي
  Widget _buildCriteriaRow(String title, double rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          _buildStars(rating, size: 18),
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // 💬 مراجعة عميل
  Widget _buildReviewTile(
    String name,
    double rating,
    String comment,
    String date,
  ) {
    _replyControllers.putIfAbsent(name, () => TextEditingController());
    final isLiked = _isLiked[name] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    name.characters.first,
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStars(rating, size: 18),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  tooltip: 'خيارات التقييم',
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                  onSelected: (value) async {
                    switch (value) {
                      case 'like':
                        _toggleLike(name);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isLiked
                                  ? 'تم إلغاء الإعجاب'
                                  : 'تم تسجيل الإعجاب',
                            ),
                          ),
                        );
                        break;
                      case 'reply':
                        _toggleReply(name);
                        break;
                      case 'chat':
                        await _openChat(name);
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          'خيارات التقييم',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'like',
                        child: Row(
                          children: [
                            Icon(
                              isLiked
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_alt_outlined,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 10),
                            Text(isLiked ? 'إلغاء الإعجاب' : 'الإعجاب'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'reply',
                        child: Row(
                          children: [
                            Icon(
                              Icons.reply,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 10),
                            Text('الرد على التقييم'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'chat',
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 10),
                            Text('فتح محادثة مع العميل'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(comment, style: const TextStyle(fontSize: 14, height: 1.4)),
            
            // ✅ عرض الردود المرسلة
            if (_replies[name] != null && _replies[name]!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...(_replies[name]!.map((reply) {
                return Container(
                  margin: const EdgeInsets.only(top: 8, right: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'رد من مقدم الخدمة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            reply['date'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reply['text'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()),
            ],
            
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _toggleReply(name);
                },
                icon: const Icon(
                  Icons.reply,
                  size: 18,
                  color: Colors.deepPurple,
                ),
                label: const Text(
                  "رد",
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ),
            ),
            if (_isReplying[name] ?? false) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _replyControllers[name],
                decoration: InputDecoration(
                  hintText: "اكتب ردك هنا...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    String reply = _replyControllers[name]?.text ?? '';
                    if (reply.isNotEmpty) {
                      setState(() {
                        // ✅ حفظ الرد
                        if (_replies[name] == null) {
                          _replies[name] = [];
                        }
                        _replies[name]!.add({
                          'text': reply,
                          'date': 'الآن',
                        });
                        
                        // إخفاء حقل الرد وتنظيفه
                        _isReplying[name] = false;
                        _replyControllers[name]?.clear();
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'تم إرسال الرد بنجاح',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "إرسال",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'المراجعات',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$totalReviews",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(context),
    );
  }
}
