import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';

/// ============================================================================
/// [SettingsTab] — Hồ sơ & Cài đặt
/// ============================================================================
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  // Settings state
  bool _notifyGeneral = true;
  bool _notifyFall = true;
  bool _notifyHeartRate = true;
  bool _autoSpeed = false;
  bool _darkMode = false;
  bool _hapticFeedback = true;

  // Profile state
  String _name = 'Nguyễn Văn An';
  int _age = 32;
  String _emergencyPhone = '0912345678';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyGeneral = prefs.getBool('notifyGeneral') ?? true;
      _notifyFall = prefs.getBool('notifyFall') ?? true;
      _notifyHeartRate = prefs.getBool('notifyHeartRate') ?? true;
      _autoSpeed = prefs.getBool('autoSpeed') ?? false;
      _darkMode = prefs.getBool('darkMode') ?? false;
      _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;

      _name = prefs.getString('profileName') ?? 'Nguyễn Văn An';
      _age = prefs.getInt('profileAge') ?? 32;
      _emergencyPhone = prefs.getString('emergencyPhone') ?? '0912 345 678';
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveProfile(String name, int age, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileName', name);
    await prefs.setInt('profileAge', age);
    await prefs.setString('emergencyPhone', phone);
    setState(() {
      _name = name;
      _age = age;
      _emergencyPhone = phone;
    });
  }

  Future<void> _callEmergency() async {
    final Uri url = Uri.parse('tel:$_emergencyPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thực hiện cuộc gọi')),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    final ageController = TextEditingController(text: _age.toString());
    final phoneController = TextEditingController(text: _emergencyPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Chỉnh sửa hồ sơ', style: AppTheme.headlineMd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tuổi'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'SĐT khẩn cấp'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () {
              final newAge = int.tryParse(ageController.text.trim()) ?? _age;
              _saveProfile(
                nameController.text.trim(),
                newAge,
                phoneController.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('CÀI ĐẶT', style: AppTheme.sectionLabel),
            Text('Hồ sơ & Cài đặt', style: AppTheme.headlineLg),
            const SizedBox(height: AppTheme.spacingLg),

            // Profile card
            GestureDetector(
              onTap: _showEditProfileDialog,
              child: _ProfileCard(name: _name, age: _age, phone: _emergencyPhone),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Notification section
            const _SectionHeader(icon: Icons.notifications_outlined, label: 'THÔNG BÁO'),
            const SizedBox(height: AppTheme.spacingSm),
            _SettingsGroup(
              children: [
                _ToggleTile(
                  title: 'Thông báo chung',
                  subtitle: 'Nhận thông báo từ ứng dụng',
                  value: _notifyGeneral,
                  onChanged: (v) {
                    setState(() => _notifyGeneral = v);
                    _saveBool('notifyGeneral', v);
                  },
                ),
                _ToggleTile(
                  title: 'Cảnh báo ngã',
                  subtitle: 'Phát hiện và báo động khi ngã',
                  value: _notifyFall,
                  onChanged: (v) {
                    setState(() => _notifyFall = v);
                    _saveBool('notifyFall', v);
                  },
                ),
                _ToggleTile(
                  title: 'Cảnh báo nhịp tim',
                  subtitle: 'Khi vượt ngưỡng an toàn',
                  value: _notifyHeartRate,
                  onChanged: (v) {
                    setState(() => _notifyHeartRate = v);
                    _saveBool('notifyHeartRate', v);
                  },
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Control section
            const _SectionHeader(icon: Icons.settings_remote_rounded, label: 'ĐIỀU KHIỂN'),
            const SizedBox(height: AppTheme.spacingSm),
            _SettingsGroup(
              children: [
                _ToggleTile(
                  title: 'Tốc độ tự động',
                  subtitle: 'Tự điều chỉnh theo địa hình',
                  value: _autoSpeed,
                  onChanged: (v) {
                    setState(() => _autoSpeed = v);
                    _saveBool('autoSpeed', v);
                  },
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // UI section
            const _SectionHeader(icon: Icons.palette_outlined, label: 'GIAO DIỆN'),
            const SizedBox(height: AppTheme.spacingSm),
            _SettingsGroup(
              children: [
                _ToggleTile(
                  title: 'Chế độ tối',
                  subtitle: 'Giao diện tối cho ban đêm',
                  value: _darkMode,
                  onChanged: (v) {
                    setState(() => _darkMode = v);
                    _saveBool('darkMode', v);
                  },
                ),
                _ToggleTile(
                  title: 'Rung phản hồi',
                  subtitle: 'Rung khi nhấn nút',
                  value: _hapticFeedback,
                  onChanged: (v) {
                    setState(() => _hapticFeedback = v);
                    _saveBool('hapticFeedback', v);
                  },
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Emergency call
            GestureDetector(
              onTap: _callEmergency,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.statusOffline.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: AppTheme.statusOffline.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.statusOffline.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_rounded,
                        color: AppTheme.statusOffline,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gọi khẩn cấp',
                            style: AppTheme.labelBold.copyWith(
                              color: AppTheme.statusOffline,
                            ),
                          ),
                          Text(
                            'Nhấn để gọi ngay: $_emergencyPhone',
                            style: AppTheme.bodySm,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.statusOffline,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Version footer
            Center(
              child: Text(
                'SmartWheel v1.0.0 · Được thiết kế với ❤️',
                style: AppTheme.caption,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PROFILE CARD
// =============================================================================
class _ProfileCard extends StatelessWidget {
  final String name;
  final int age;
  final String phone;

  const _ProfileCard({
    required this.name,
    required this.age,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.canvasWhite.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppTheme.headlineMd.copyWith(
                      color: AppTheme.canvasWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTheme.headlineMd.copyWith(
                        color: AppTheme.canvasWhite,
                        fontSize: 20,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Người dùng xe lăn điện\n$age tuổi',
                      style: AppTheme.bodySm.copyWith(
                        color: AppTheme.canvasWhite.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, color: AppTheme.canvasWhite, size: 20),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.canvasWhite.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Nhịp tim an toàn',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.canvasWhite.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '55–100 bpm',
                        style: AppTheme.labelBold.copyWith(
                          color: AppTheme.canvasWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.canvasWhite.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Liên hệ khẩn cấp',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.canvasWhite.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        phone,
                        style: AppTheme.labelBold.copyWith(
                          color: AppTheme.canvasWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.sectionLabel),
      ],
    );
  }
}

// =============================================================================
// SETTINGS GROUP
// =============================================================================
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

// =============================================================================
// TOGGLE TILE
// =============================================================================
class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.labelBold),
                    Text(subtitle, style: AppTheme.caption),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 0, indent: 16, endIndent: 16),
      ],
    );
  }
}

