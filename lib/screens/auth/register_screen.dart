import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../user/user_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final nimController = TextEditingController();
  final facultyController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    nimController.dispose();
    facultyController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      name: nameController.text,
      nim: nimController.text,
      faculty: facultyController.text,
      email: emailController.text,
      password: passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      _showError(authProvider.errorMessage ?? 'Register gagal.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Register berhasil. Selamat datang di UNESA SportHub.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }

    if (value.trim() != passwordController.text.trim()) {
      return 'Konfirmasi password tidak sama';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final headerHeight = size.height < 760 ? 286.0 : 316.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                _RegisterHeader(height: headerHeight),
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _RegisterFormCard(
                      formKey: formKey,
                      nameController: nameController,
                      nimController: nimController,
                      facultyController: facultyController,
                      emailController: emailController,
                      passwordController: passwordController,
                      confirmPasswordController: confirmPasswordController,
                      authProvider: authProvider,
                      onRegister: register,
                      validateConfirmPassword: validateConfirmPassword,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  final double height;

  const _RegisterHeader({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          const _RegisterHeaderPattern(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 24, 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        child: IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: _RegisterBrandMark()),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Bergabung dengan\nUNESA SportHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Daftarkan akunmu untuk mulai berolahraga!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController nimController;
  final TextEditingController facultyController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final AuthProvider authProvider;
  final VoidCallback onRegister;
  final String? Function(String?) validateConfirmPassword;

  const _RegisterFormCard({
    required this.formKey,
    required this.nameController,
    required this.nimController,
    required this.facultyController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.authProvider,
    required this.onRegister,
    required this.validateConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                _FormIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat Akun Mahasiswa',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Isi data sesuai identitas kampus.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            CustomTextField(
              controller: nameController,
              label: 'Nama Lengkap',
              hint: 'Nama sesuai data mahasiswa',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                return Validators.required(value, 'Nama lengkap');
              },
            ),
            const _FieldHelper('Gunakan nama lengkap tanpa singkatan.'),
            const SizedBox(height: 14),
            CustomTextField(
              controller: nimController,
              label: 'NIM',
              hint: 'Nomor Induk Mahasiswa',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              validator: Validators.nim,
            ),
            const _FieldHelper('Minimal 8 digit sesuai data kampus.'),
            const SizedBox(height: 14),
            CustomTextField(
              controller: facultyController,
              label: 'Fakultas',
              hint: 'Contoh: Fakultas Ilmu Keolahragaan',
              prefixIcon: Icons.school_outlined,
              validator: (value) {
                return Validators.required(value, 'Fakultas');
              },
            ),
            const _FieldHelper('Tulis fakultas aktif kamu di UNESA.'),
            const SizedBox(height: 14),
            CustomTextField(
              controller: emailController,
              label: 'Email',
              hint: 'nama@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const _FieldHelper('Email dipakai untuk masuk ke aplikasi.'),
            const SizedBox(height: 14),
            CustomTextField(
              controller: passwordController,
              label: 'Password',
              hint: 'Minimal 6 karakter',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: Validators.password,
            ),
            const _FieldHelper('Buat password yang mudah kamu ingat.'),
            const SizedBox(height: 14),
            CustomTextField(
              controller: confirmPasswordController,
              label: 'Konfirmasi Password',
              hint: 'Ulangi password',
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: true,
              validator: validateConfirmPassword,
            ),
            const _FieldHelper('Pastikan sama dengan password di atas.'),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Daftar',
              icon: Icons.person_add_alt_1,
              isLoading: authProvider.isLoading,
              onPressed: onRegister,
            ),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  TextButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => Navigator.maybePop(context),
                    child: const Text('Masuk'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldHelper extends StatelessWidget {
  final String text;

  const _FieldHelper(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _FormIcon extends StatelessWidget {
  const _FormIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.lightGreenSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.person_add_alt_1,
        color: AppColors.primaryDarkGreen,
        size: 26,
      ),
    );
  }
}

class _RegisterBrandMark extends StatelessWidget {
  const _RegisterBrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.sports_soccer,
            color: AppColors.primaryDarkGreen,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'UNESA SportHub',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterHeaderPattern extends StatelessWidget {
  const _RegisterHeaderPattern();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: Stack(
          children: [
            Positioned(
              right: -56,
              top: -54,
              child: _PatternCircle(size: 170, opacity: 0.12),
            ),
            Positioned(
              right: 28,
              bottom: 66,
              child: Icon(
                Icons.stadium_outlined,
                color: Colors.white.withValues(alpha: 0.08),
                size: 104,
              ),
            ),
            Positioned(
              left: -48,
              bottom: 34,
              child: _PatternCircle(size: 138, opacity: 0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _PatternCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 24,
        ),
      ),
    );
  }
}
