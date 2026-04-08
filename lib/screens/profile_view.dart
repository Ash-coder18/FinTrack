import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // ── State ─────────────────────────────────────────────────
  bool _isLoading = true;
  String? _fullName;
  String? _email;
  String? _profession;
  String? _avatarUrl;

  // ── Profession Dropdown Options ───────────────────────────
  static const List<String> _professionOptions = [
    'Student',
    'Salaried Employee',
    'Business Owner',
    'Freelancer',
    'Self-Employed',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ── Fetch user metadata from Supabase Auth ────────────────
  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata;
      setState(() {
        _email = user.email;
        _fullName = meta?['full_name'] as String?;
        _profession = meta?['profession'] as String?;
        _avatarUrl = meta?['avatar_url'] as String?;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ── Main Screen ───────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Avatar ──────────────────────────────────────
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFBDBDBD),
              backgroundImage:
                  _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null
                  ? const Icon(Icons.person, size: 60, color: AppColors.white)
                  : null,
            ),
            const SizedBox(height: 24),

            // ── Full Name ───────────────────────────────────
            Text(
              _fullName ?? t['add_your_name']!,
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _fullName != null
                    ? Theme.of(context).colorScheme.onSurface
                    : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 8),

            // ── Email ───────────────────────────────────────
            Text(
              _email ?? '',
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),

            // ── Profession ──────────────────────────────────
            Text(
              _profession ?? t['add_your_profession']!,
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _profession != null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 32),

            // ── Edit Profile Button ─────────────────────────
            SizedBox(
              width: 200,
              height: 52,
              child: ElevatedButton(
                onPressed: _showEditProfileDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  t['edit_profile']!,
                  style: const TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ── Edit Profile Dialog ───────────────────────────────────
  void _showEditProfileDialog() {
    final lang = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
    final t = AppTranslations.of(lang);
    final nameController = TextEditingController(text: _fullName ?? '');

    // Determine initial dropdown value & custom text
    final bool isCustomProfession = _profession != null &&
        _profession!.isNotEmpty &&
        !_professionOptions
            .where((o) => o != 'Other')
            .contains(_profession);

    String dropdownValue = isCustomProfession
        ? 'Other'
        : (_professionOptions.contains(_profession)
            ? _profession!
            : _professionOptions.first);

    final customProfessionController = TextEditingController(
      text: isCustomProfession ? _profession : '',
    );

    String? dialogAvatarUrl = _avatarUrl;
    bool isUploadingAvatar = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              title: Text(
                t['edit_profile']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Avatar with tap-to-change ────────────
                    InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () => _showImageSourcePicker(
                        dialogContext: dialogContext,
                        setDialogState: setDialogState,
                        onUploaded: (url) {
                          dialogAvatarUrl = url;
                        },
                        setUploading: (val) {
                          isUploadingAvatar = val;
                        },
                        t: t,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFFBDBDBD),
                            backgroundImage: dialogAvatarUrl != null
                                ? NetworkImage(dialogAvatarUrl!)
                                : null,
                            child: dialogAvatarUrl == null
                                ? const Icon(Icons.person,
                                    size: 50, color: AppColors.white)
                                : null,
                          ),
                          if (isUploadingAvatar)
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          if (!isUploadingAvatar)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Name Field ──────────────────────────
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: t['name']!,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Profession Dropdown ─────────────────
                    DropdownButtonFormField<String>(
                      value: dropdownValue,
                      decoration: InputDecoration(
                        hintText: t['profession']!,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _professionOptions
                          .map((p) => DropdownMenuItem(
                              value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => dropdownValue = val);
                        }
                      },
                    ),

                    // ── Custom Profession (if "Other") ──────
                    if (dropdownValue == 'Other') ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: customProfessionController,
                        decoration: InputDecoration(
                          hintText: t['enter_your_profession']!,
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Actions ───────────────────────────────────
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          t['cancel']!,
                          style: const TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _saveProfile(
                          dialogContext: dialogContext,
                          newName: nameController.text.trim(),
                          dropdownValue: dropdownValue,
                          customProfession:
                              customProfessionController.text.trim(),
                          newAvatarUrl: dialogAvatarUrl,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          t['save']!,
                          style: const TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Image Source Picker (Camera / Gallery) ─────────────────
  void _showImageSourcePicker({
    required BuildContext dialogContext,
    required StateSetter setDialogState,
    required ValueChanged<String> onUploaded,
    required ValueChanged<bool> setUploading,
    required Map<String, String> t,
  }) {
    showModalBottomSheet(
      context: dialogContext,
      backgroundColor: Theme.of(dialogContext).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t['choose_photo']!,
                  style: TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(sheetContext).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                  title: Text(
                    t['camera']!,
                    style: const TextStyle(fontFamily: 'SF Pro', fontSize: 15),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadImage(
                      source: ImageSource.camera,
                      setDialogState: setDialogState,
                      onUploaded: onUploaded,
                      setUploading: setUploading,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                  title: Text(
                    t['gallery']!,
                    style: const TextStyle(fontFamily: 'SF Pro', fontSize: 15),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadImage(
                      source: ImageSource.gallery,
                      setDialogState: setDialogState,
                      onUploaded: onUploaded,
                      setUploading: setUploading,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Pick, Upload to Supabase Storage, Get Public URL ──────
  Future<void> _pickAndUploadImage({
    required ImageSource source,
    required StateSetter setDialogState,
    required ValueChanged<String> onUploaded,
    required ValueChanged<bool> setUploading,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: source, maxWidth: 512, imageQuality: 75);

      if (pickedFile == null) return; // User cancelled

      setDialogState(() => setUploading(true));

      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileExt = pickedFile.path.split('.').last;
      final filePath = '$userId/avatar.$fileExt';
      final fileBytes = await File(pickedFile.path).readAsBytes();

      // Upload (upsert) to the 'avatars' bucket
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions:
                const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get the public URL
      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Append a cache-buster so the NetworkImage refreshes
      final freshUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      setDialogState(() {
        onUploaded(freshUrl);
        setUploading(false);
      });
    } catch (e) {
      setDialogState(() => setUploading(false));
      if (!mounted) return;
      final lang2 = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t2 = AppTranslations.of(lang2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${t2['upload_failed']!}$e',
            style: const TextStyle(fontFamily: 'SF Pro'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Save Profile to Supabase Auth Metadata ────────────────
  Future<void> _saveProfile({
    required BuildContext dialogContext,
    required String newName,
    required String dropdownValue,
    required String customProfession,
    required String? newAvatarUrl,
  }) async {
    try {
      final finalProfession = dropdownValue == 'Other'
          ? customProfession
          : dropdownValue;

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': newName,
            'profession': finalProfession,
            'avatar_url': newAvatarUrl,
          },
        ),
      );

      // Update local state
      setState(() {
        _fullName = newName.isNotEmpty ? newName : null;
        _profession = finalProfession.isNotEmpty ? finalProfession : null;
        _avatarUrl = newAvatarUrl;
      });

      if (!mounted) return;
      Navigator.pop(dialogContext);

      final lang3 = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t3 = AppTranslations.of(lang3);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t3['profile_updated']!,
            style: const TextStyle(
              fontFamily: 'SF Pro',
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final lang4 = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
      final t4 = AppTranslations.of(lang4);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${t4['failed_to_update']!}$e',
            style: const TextStyle(fontFamily: 'SF Pro'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
