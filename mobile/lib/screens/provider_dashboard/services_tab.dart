import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/category.dart';
import '../../models/provider_service.dart';
import '../../services/providers_api.dart';
import '../../services/web_inline_banner.dart';
import '../../services/web_loading_overlay.dart';

class ServicesTab extends StatefulWidget {
  final bool embedded;
  final String? initialSearchQuery;
  final String? initialStatusFilter;

  const ServicesTab({
    super.key,
    this.embedded = false,
    this.initialSearchQuery,
    this.initialStatusFilter,
  });

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  static const Color _mainColor = Colors.deepPurple;

  bool _loading = true;
  List<ProviderService> _services = const [];
  List<Category> _categories = const [];
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'الكل';
  Timer? _searchRouteSyncDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = (widget.initialSearchQuery ?? '').trim();
    _statusFilter = _normalizeStatusFilter(widget.initialStatusFilter);
    _searchController.addListener(() {
      if (mounted) setState(() {});
      _scheduleWebUrlSync();
    });
    _refresh();
  }

  @override
  void dispose() {
    _searchRouteSyncDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final api = ProvidersApi();
    final results = await Future.wait([
      api.getCategories(),
      api.getMyServices(),
    ]);
    if (!mounted) return;
    setState(() {
      _categories = results[0] as List<Category>;
      _services = results[1] as List<ProviderService>;
      _loading = false;
    });
  }

  String _serviceSubtitle(ProviderService s) {
    final sub = s.subcategory?.name;
    if (sub != null && sub.trim().isNotEmpty) return sub;
    return 'بدون تصنيف فرعي';
  }

  Future<void> _refreshWithOverlay() {
    return WebLoadingOverlayController.instance.run(
      _refresh,
      message: 'جاري تحديث الخدمات...',
    );
  }

  String _serviceCategoryPath(ProviderService s) {
    final category = s.subcategory?.categoryName?.trim();
    final sub = s.subcategory?.name.trim();
    if ((category ?? '').isNotEmpty && (sub ?? '').isNotEmpty) {
      return '$category / $sub';
    }
    if ((sub ?? '').isNotEmpty) return sub!;
    return 'غير محدد';
  }

  String _normalizeStatusFilter(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    switch (v) {
      case 'active':
      case 'نشطة':
        return 'نشطة';
      case 'inactive':
      case 'hidden':
      case 'مخفية':
        return 'مخفية';
      case 'all':
      case 'الكل':
      default:
        return 'الكل';
    }
  }

  List<ProviderService> _filteredServices() {
    Iterable<ProviderService> out = _services;
    if (_statusFilter == 'نشطة') {
      out = out.where((s) => s.isActive == true);
    } else if (_statusFilter == 'مخفية') {
      out = out.where((s) => s.isActive == false);
    }

    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            _serviceCategoryPath(s).toLowerCase().contains(q);
      });
    }
    return out.toList();
  }

  void _scheduleWebUrlSync() {
    if (!(kIsWeb && widget.embedded)) return;
    _searchRouteSyncDebounce?.cancel();
    _searchRouteSyncDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _syncWebUrl();
    });
  }

  void _syncWebUrl() {
    if (!(kIsWeb && widget.embedded)) return;
    final status = switch (_statusFilter) {
      'نشطة' => 'active',
      'مخفية' => 'inactive',
      _ => 'all',
    };
    final query = <String, String>{
      'status': status,
      if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
    };
    SystemNavigator.routeInformationUpdated(
      uri: Uri(path: '/provider_dashboard/services', queryParameters: query),
      replace: true,
    );
  }

  void _setStatusFilter(String value) {
    if (_statusFilter == value) return;
    setState(() => _statusFilter = value);
    _syncWebUrl();
  }

  Future<void> _confirmDelete(ProviderService s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الخدمة', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل تريد حذف "${s.title}"؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final success = await ProvidersApi().deleteMyService(s.id);
    if (!mounted) return;
    if (!success) {
      WebInlineBannerController.instance.error('تعذر حذف الخدمة.');
      return;
    }
    WebInlineBannerController.instance.success('تم حذف الخدمة.');
    await _refreshWithOverlay();
  }

  Future<void> _openEditor({ProviderService? existing}) async {
    if (_categories.isEmpty) {
      await _refreshWithOverlay();
    }

    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    int? selectedCategoryId = existing?.subcategory?.categoryId;
    int? selectedSubId = existing?.subcategory?.id;
    bool isActive = existing?.isActive ?? true;

    if (selectedCategoryId == null && selectedSubId != null) {
      for (final c in _categories) {
        if (c.subcategories.any((s) => s.id == selectedSubId)) {
          selectedCategoryId = c.id;
          break;
        }
      }
    }
    selectedCategoryId ??= _categories.isNotEmpty ? _categories.first.id : null;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            final cats = _categories;
            final currentCat = (selectedCategoryId == null)
                ? null
                : cats.where((c) => c.id == selectedCategoryId).cast<Category?>().firstOrNull;
            final subs = currentCat?.subcategories ?? const <SubCategory>[];
            if (subs.isNotEmpty && selectedSubId == null) {
              selectedSubId = subs.first.id;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx2).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        existing == null ? 'إضافة خدمة' : 'تعديل خدمة',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم الخدمة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: selectedCategoryId,
                        items: cats
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.name, style: const TextStyle(fontFamily: 'Cairo')),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setModalState(() {
                            selectedCategoryId = v;
                            selectedSubId = null;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'التصنيف الرئيسي',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: selectedSubId,
                        items: subs
                            .map(
                              (s) => DropdownMenuItem<int>(
                                value: s.id,
                                child: Text(s.name, style: const TextStyle(fontFamily: 'Cairo')),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setModalState(() => selectedSubId = v),
                        decoration: const InputDecoration(
                          labelText: 'التصنيف الفرعي',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'الوصف',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (v) => setModalState(() => isActive = v),
                        title: const Text('عرض الخدمة للعملاء', style: TextStyle(fontFamily: 'Cairo')),
                        activeThumbColor: _mainColor,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final title = titleCtrl.text.trim();
                            final subId = selectedSubId;
                            if (title.isEmpty || subId == null) {
                              WebInlineBannerController.instance.info(
                                'أكمل اسم الخدمة والتصنيف.',
                              );
                              return;
                            }

                            final saved = await WebLoadingOverlayController.instance.run(() async {
                              if (existing == null) {
                                final created = await ProvidersApi().createMyService(
                                  title: title,
                                  subcategoryId: subId,
                                  description: descCtrl.text,
                                  isActive: isActive,
                                );
                                return created != null;
                              }

                              final patch = <String, dynamic>{
                                'title': title,
                                'description': descCtrl.text.trim(),
                                'is_active': isActive,
                                'subcategory_id': subId,
                              };
                              final updated = await ProvidersApi().updateMyService(existing.id, patch);
                              return updated != null;
                            }, message: existing == null ? 'جاري إضافة الخدمة...' : 'جاري حفظ الخدمة...');
                            if (!saved) {
                              if (!mounted) return;
                              WebInlineBannerController.instance.error(
                                existing == null ? 'تعذر إضافة الخدمة.' : 'تعذر حفظ التعديل.',
                              );
                              return;
                            }

                            if (!mounted || !ctx2.mounted) return;
                            Navigator.pop(ctx2);
                            WebInlineBannerController.instance.success(
                              existing == null ? 'تمت إضافة الخدمة.' : 'تم حفظ تعديلات الخدمة.',
                            );
                            await _refreshWithOverlay();
                          },
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _desktopStatsBar() {
    final activeCount = _services.where((s) => s.isActive == true).length;
    final inactiveCount = _services.where((s) => s.isActive == false).length;
    final visibleCount = _filteredServices().length;

    Widget chip({
      required IconData icon,
      required String label,
      required String value,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip(
          icon: Icons.design_services_rounded,
          label: 'إجمالي الخدمات',
          value: _services.length.toString(),
          color: _mainColor,
        ),
        chip(
          icon: Icons.visibility_rounded,
          label: 'نشطة',
          value: activeCount.toString(),
          color: Colors.green,
        ),
        chip(
          icon: Icons.visibility_off_rounded,
          label: 'مخفية',
          value: inactiveCount.toString(),
          color: Colors.orange,
        ),
        chip(
          icon: Icons.filter_alt_rounded,
          label: 'المعروضة',
          value: visibleCount.toString(),
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _servicesFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, color: _mainColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _syncWebUrl(),
                  decoration: const InputDecoration(
                    hintText: 'بحث في اسم الخدمة أو الوصف أو التصنيف...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                ),
              ),
              if (_searchController.text.trim().isNotEmpty)
                IconButton(
                  tooltip: 'مسح',
                  onPressed: () {
                    _searchController.clear();
                    _syncWebUrl();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['الكل', 'نشطة', 'مخفية'].map((label) {
              return ChoiceChip(
                selected: _statusFilter == label,
                onSelected: (_) => _setStatusFilter(label),
                label: Text(label, style: const TextStyle(fontFamily: 'Cairo')),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _desktopTableHeader() {
    const headerStyle = TextStyle(
      fontFamily: 'Cairo',
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
      color: Colors.black54,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text('الخدمة', style: headerStyle)),
          Expanded(flex: 3, child: Text('التصنيف', style: headerStyle)),
          Expanded(flex: 2, child: Text('التسعير', style: headerStyle)),
          Expanded(flex: 2, child: Text('الحالة', style: headerStyle)),
          SizedBox(width: 96),
        ],
      ),
    );
  }

  Widget _desktopServiceRow(ProviderService s) {
    final active = s.isActive != false;
    final statusColor = active ? Colors.green : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (s.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.description.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _serviceCategoryPath(s),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              s.priceText(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  active ? 'نشطة' : 'مخفية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _openEditor(existing: s),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'تعديل',
              ),
              IconButton(
                onPressed: () => _confirmDelete(s),
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                tooltip: 'حذف',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBody() {
    final filtered = _filteredServices();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          _desktopStatsBar(),
          const SizedBox(height: 12),
          _servicesFilterPanel(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إدارة الخدمات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        'لا توجد خدمات مطابقة للفلاتر الحالية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else ...[
                  _desktopTableHeader(),
                  ...filtered.map(_desktopServiceRow),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredServices();
    final desktopLike = widget.embedded && MediaQuery.of(context).size.width >= 980;
    if (desktopLike) {
      return _buildDesktopBody();
    }

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            _servicesFilterPanel(),
            const SizedBox(height: 60),
            const Center(
              child: Text(
                'لا توجد خدمات مطابقة للفلاتر الحالية',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length + 1,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) return _servicesFilterPanel();
          final s = filtered[index - 1];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              title: Text(s.title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              subtitle: Text(_serviceSubtitle(s), style: const TextStyle(fontFamily: 'Cairo')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _openEditor(existing: s),
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'تعديل',
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(s),
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        _buildBody(),
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add_service_fab',
            backgroundColor: _mainColor,
            foregroundColor: Colors.white,
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ),
      ],
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: widget.embedded
          ? content
          : Scaffold(
              appBar: AppBar(
                backgroundColor: _mainColor,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'خدماتي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'تحديث',
                    onPressed: _loading ? null : _refreshWithOverlay,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              body: content,
            ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/*
                            children: [
                              _buildLabel("اقتراح تصنيف فرعي"),
                              TextFormField(
                                initialValue: customSub,
                                onChanged:
                                    (val) =>
                                        setModalState(() => customSub = val),
                                decoration: _inputDecoration().copyWith(
                                  hintText: "اكتب تصنيفاً مناسباً للخدمة",
                                  suffixIcon: const Icon(Icons.lightbulb),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),
                      _buildLabel("اسم الخدمة"),
                      TextFormField(
                        initialValue: title,
                        onChanged: (val) => title = val,
                        decoration: _inputDecoration(
                          hint: "مثال: استشارة قضائية",
                        ),
                      ),

                      const SizedBox(height: 12),
                      _buildLabel("نوع الخدمة"),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text("عاجلة"),
                              value: true,
                              groupValue: urgent,
                              onChanged:
                                  (val) => setModalState(() => urgent = val!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text("عادية"),
                              value: false,
                              groupValue: urgent,
                              onChanged:
                                  (val) => setModalState(() => urgent = val!),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      _buildLabel("نوع التسعير"),
                      DropdownButtonFormField<String>(
                        value: pricingType,
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'fixed',
                            child: Text('سعر ثابت'),
                          ),
                          DropdownMenuItem(
                            value: 'negotiable',
                            child: Text('سعر + قابل للتفاوض'),
                          ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text('تسعير حسب الطلب'),
                          ),
                        ],
                        onChanged:
                            (val) => setModalState(
                              () => pricingType = val ?? 'fixed',
                            ),
                      ),

                      if (pricingType != 'custom') ...[
                        const SizedBox(height: 12),
                        _buildLabel("السعر"),
                        TextFormField(
                          initialValue: price,
                          keyboardType: TextInputType.number,
                          onChanged: (val) => price = val,
                          decoration: _inputDecoration(hint: "مثال: 500"),
                        ),
                      ],

                      const SizedBox(height: 28),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              services[index] = {
                                'title': title,
                                'description': description,
                                'price': pricingType == 'custom' ? '' : price,
                                'pricingType': pricingType,
                                'urgent': urgent,
                                'mainCategory': selectedMain,
                                'subCategory': selectedSub ?? customSub ?? '',
                              };
                            });
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text(
                            "حفظ التعديلات",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'خدماتي',
          style: TextStyle(color: Colors.white), // ✅ نص العنوان أبيض
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // ✅ أيقونة الرجوع بيضاء
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            services.isEmpty
                ? const Center(child: Text("لا توجد خدمات مضافة بعد"))
                : ListView.separated(
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return InkWell(
                      onTap: () => _editService(index),
                      borderRadius: BorderRadius.circular(16),
                      child: _buildServiceCard(service, () {
                        _editService(index);
                      }),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, VoidCallback onEdit) {
    final bool isUrgent = service['urgent'] == true;
    final String pricingType = service['pricingType'] ?? 'fixed';
    final String priceText =
        pricingType == 'custom'
            ? 'تسعير حسب الطلب'
            : pricingType == 'negotiable'
            ? 'قابل للتفاوض (${service['price']} ر.س)'
            : '${service['price']} ر.س';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                FontAwesomeIcons.briefcase,
                color: Colors.deepPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  service['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'عاجلة',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            service['description'] ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.category, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${service['mainCategory']} > ${service['subCategory']}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.price_check, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                priceText,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: Colors.white, size: 16),
              label: const Text(
                "تعديل",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.deepPurple,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      isDense: true,
    );
  }
}

*/
