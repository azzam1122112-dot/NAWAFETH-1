import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

// ✅ استدعاء شاشة بروفايل مزود الخدمة
import 'package:nawafeth/screens/provider_profile_screen.dart';

class ProfilesSlider extends StatefulWidget {
  const ProfilesSlider({super.key});

  @override
  State<ProfilesSlider> createState() => _ProfilesSliderState();
}

class _ProfilesSliderState extends State<ProfilesSlider> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  double _scrollPosition = 0;

  static const List<Map<String, String>> _baseProfiles = [
    {'image': 'assets/images/1.png', 'label': 'محامي'},
    {'image': 'assets/images/12.png', 'label': 'طبيب'},
    {'image': 'assets/images/151.png', 'label': 'مهندس'},
    {'image': 'assets/images/551.png', 'label': 'إداري'},
  ];
  
  // ✅ مضاعفة العناصر للتمرير اللانهائي
  late final List<Map<String, String>> profiles;

  @override
  void initState() {
    super.initState();
    // مضاعفة القائمة عدة مرات لضمان التمرير السلس
    profiles = List.generate(10, (_) => _baseProfiles).expand((x) => x).toList();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients && mounted) {
        _scrollPosition += 1.0; // حركة سلسة

        // ✅ عندما نصل للمنتصف، نقفز للبداية بشكل غير محسوس
        final maxScroll = _scrollController.position.maxScrollExtent;
        final halfScroll = maxScroll / 2;
        
        if (_scrollPosition >= halfScroll) {
          _scrollController.jumpTo(0);
          _scrollPosition = 0;
        } else {
          _scrollController.jumpTo(_scrollPosition);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _openProfileDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProviderProfileScreen(), // ✅ التوجيه الصحيح
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return GestureDetector(
            onTap: () => _openProfileDetail(context),
            child: Container(
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: AppColors.softBlue,
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: AssetImage(profile['image']!),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Transform.translate(
                          offset: const Offset(6, 6),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile['label']!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      overflow: TextOverflow.ellipsis,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
