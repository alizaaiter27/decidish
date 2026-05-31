import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/l10n/app_strings.dart';
import 'package:decidish/l10n/locale_controller.dart';
import 'package:decidish/services/user_api_service.dart';
import 'package:decidish/services/auth_api_service.dart';
import 'package:decidish/services/api_service.dart' show ApiException;
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '...';
  String _userEmail = '...';
  String _dietType = 'None';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await UserApiService.getProfile();
      if (mounted) {
        setState(() {
          _userName = user.name;
          _userEmail = user.email;
          _dietType = user.dietType ?? 'None';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
    if (!mounted) return;
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).passwordUpdated)),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await AuthApiService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.of(
                context,
              ).logoutError(e.toString().replaceAll('ApiException: ', '')),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    strings.profile,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 20),
                            ValueListenableBuilder<Locale?>(
                              valueListenable: LocaleController.localeNotifier,
                              builder: (context, saved, _) {
                                return _buildSettingItem(
                                  context,
                                  Icons.language,
                                  strings.language,
                                  _languageChoiceSubtitle(strings, saved),
                                  () => _showLanguagePicker(context),
                                );
                              },
                            ),
                            const SizedBox(height: 8),

                            // Settings List
                            _buildSettingItem(
                              context,
                              Icons.group,
                              strings.friends,
                              strings.friendsSubtitle,
                              () {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pushNamed('/friends');
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildSettingItem(
                              context,
                              Icons.history_rounded,
                              strings.mealHistory,
                              strings.mealHistorySubtitle,
                              () {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pushNamed('/history');
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildSettingItem(
                              context,
                              Icons.settings,
                              strings.editPreferences,
                              strings.editPreferencesSubtitle,
                              () {
                                Navigator.pushNamed(
                                  context,
                                  '/preferences',
                                ).then((_) {
                                  _loadProfile(); // Reload profile after returning
                                });
                              },
                            ),
                            _buildSettingItem(
                              context,
                              Icons.lock_outline,
                              strings.changePassword,
                              strings.changePasswordSubtitle,
                              _showChangePasswordDialog,
                            ),
                            _buildSettingItem(
                              context,
                              Icons.notifications,
                              strings.notifications,
                              strings.notificationsSubtitle,
                              () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(strings.notifications),
                                    content: Text(
                                      strings.comingSoonNotificationSettings,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(strings.ok),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            _buildSettingItem(
                              context,
                              Icons.help_outline,
                              strings.helpAndSupport,
                              strings.helpAndSupportSubtitle,
                              () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(strings.helpAndSupport),
                                    content: Text(strings.supportEmailText),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(strings.close),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            _buildSettingItem(
                              context,
                              Icons.info_outline,
                              strings.about,
                              'Version 1.0.0',
                              () {
                                showAboutDialog(
                                  context: context,
                                  applicationName: 'DeciDish',
                                  applicationVersion: '1.0.0',
                                  applicationLegalese: '© 2025 DeciDish',
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // Logout Button
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _logout,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                      color: AppColors.error,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    strings.logout,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 120,
                            ), // Extra padding for bottom nav
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.secondary,
            child: Icon(Icons.person, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userEmail,
            style: TextStyle(fontSize: 14, color: AppColors.secondary),
          ),
          const SizedBox(height: 12),
          if (_dietType.isNotEmpty && _dietType != 'None')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.of(context).dietLabel(_dietType),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _languageChoiceSubtitle(AppStrings strings, Locale? saved) {
    if (saved == null) return strings.systemDefault;
    switch (saved.languageCode) {
      case 'tr':
        return strings.turkish;
      case 'en':
        return strings.english;
      default:
        return saved.languageCode;
    }
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final strings = AppStrings.of(context);
    final current = LocaleController.localeNotifier.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Widget optionTile({
          required String label,
          required bool selected,
          required VoidCallback onPick,
        }) {
          return ListTile(
            leading: Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.primary : AppColors.textLight,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
            onTap: onPick,
          );
        }

        final systemSelected = current == null;
        final enSelected = current?.languageCode == 'en';
        final trSelected = current?.languageCode == 'tr';

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(sheetContext).bottom + 16,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.language,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                        color: AppColors.textLight,
                      ),
                    ],
                  ),
                ),
                optionTile(
                  label: strings.systemDefault,
                  selected: systemSelected,
                  onPick: () async {
                    await LocaleController.setLocale(null);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                optionTile(
                  label: strings.english,
                  selected: enSelected,
                  onPick: () async {
                    await LocaleController.setLocale(const Locale('en'));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                optionTile(
                  label: strings.turkish,
                  selected: trSelected,
                  onPick: () async {
                    await LocaleController.setLocale(const Locale('tr'));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.textLight),
            const SizedBox(height: 20),
            Text(
              AppStrings.of(context).somethingWentWrong,
              style: TextStyle(fontSize: 18, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadProfile,
              child: Text(AppStrings.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textLight,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Owns [TextEditingController]s so they are disposed after the route is
/// removed — disposing them immediately after [showDialog] returns can crash
/// because the dialog subtree may still be unmounting.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _current;
  late final TextEditingController _next;
  late final TextEditingController _confirm;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _current = TextEditingController();
    _next = TextEditingController();
    _confirm = TextEditingController();
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _submitting = true);
    try {
      await AuthApiService.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AlertDialog(
      title: Text(strings.changePassword),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _current,
                obscureText: true,
                enabled: !_submitting,
                decoration: InputDecoration(labelText: strings.currentPassword),
                validator: (v) =>
                    (v == null || v.isEmpty) ? strings.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _next,
                obscureText: true,
                enabled: !_submitting,
                decoration: InputDecoration(labelText: strings.newPasswordMin6),
                validator: (v) {
                  if (v == null || v.isEmpty) return strings.required;
                  if (v.length < 6) return strings.atLeast6Chars;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                enabled: !_submitting,
                decoration: InputDecoration(
                  labelText: strings.confirmNewPassword,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return strings.required;
                  if (v != _next.text) return strings.doesNotMatch;
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(strings.save),
        ),
      ],
    );
  }
}
