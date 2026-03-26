import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/widgets/app_logo.dart';
import 'package:decidish/services/auth_api_service.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  // New toggles
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // New validity for “B”
  bool _nameOk = false;
  bool _emailOk = false;
  bool _passwordOk = false;
  bool _confirmOk = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    _nameController.addListener(_recomputeValidity);
    _emailController.addListener(_recomputeValidity);
    _passwordController.addListener(_recomputeValidity);
    _confirmPasswordController.addListener(_recomputeValidity);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _recomputeValidity() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final nameValid = _validateName(name) == null && name.isNotEmpty;
    final emailValid = _validateEmail(email) == null && email.isNotEmpty;
    final passValid = _validatePassword(pass) == null && pass.isNotEmpty;
    final confirmValid =
        _validateConfirm(confirm) == null && confirm.isNotEmpty;

    if (nameValid != _nameOk ||
        emailValid != _emailOk ||
        passValid != _passwordOk ||
        confirmValid != _confirmOk) {
      setState(() {
        _nameOk = nameValid;
        _emailOk = emailValid;
        _passwordOk = passValid;
        _confirmOk = confirmValid;
      });
    }
  }

  String? _validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _signUp() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthApiService.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (response['success'] == true) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sign up failed')));
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pressSignUp() async {
    if (_isLoading) return;

    await _buttonController.forward();
    await _buttonController.reverse();

    await _signUp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Top green section (unchanged)
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const AppLogo(size: 100, backgroundColor: AppColors.white),
                    const SizedBox(height: 40),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(_fadeAnimation),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Name
                                TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: _validateName,
                                  decoration: InputDecoration(
                                    hintText: 'Your name',
                                    filled: true,
                                    fillColor: AppColors.white.withValues(
                                      alpha: 0.5,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    suffixIcon: _nameController.text.isEmpty
                                        ? null
                                        : Icon(
                                            _nameOk
                                                ? Icons.check_circle
                                                : Icons.error_outline,
                                            color: _nameOk
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: _validateEmail,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    filled: true,
                                    fillColor: AppColors.white.withValues(
                                      alpha: 0.5,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    suffixIcon: _emailController.text.isEmpty
                                        ? null
                                        : Icon(
                                            _emailOk
                                                ? Icons.check_circle
                                                : Icons.error_outline,
                                            color: _emailOk
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: _validatePassword,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    filled: true,
                                    fillColor: AppColors.white.withValues(
                                      alpha: 0.5,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_passwordController.text.isNotEmpty)
                                          Icon(
                                            _passwordOk
                                                ? Icons.check_circle
                                                : Icons.error_outline,
                                            color: _passwordOk
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: _validateConfirm,
                                  decoration: InputDecoration(
                                    hintText: 'Confirm your password',
                                    filled: true,
                                    fillColor: AppColors.white.withValues(
                                      alpha: 0.5,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_confirmPasswordController
                                            .text
                                            .isNotEmpty)
                                          Icon(
                                            _confirmOk
                                                ? Icons.check_circle
                                                : Icons.error_outline,
                                            color: _confirmOk
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirm =
                                                  !_obscureConfirm;
                                            });
                                          },
                                          icon: Icon(
                                            _obscureConfirm
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Sign Up Button (same placement)
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : ScaleTransition(
                                        scale: _buttonScaleAnimation,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _pressSignUp,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor: AppColors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: const Text(
                                              'sign up',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 20),

                                // OR Divider (unchanged)
                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text('OR'),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Google Sign Up (unchanged)
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.g_mobiledata,
                                    size: 30,
                                  ),
                                  label: const Text('Continue with Google'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textDark,
                                    side: const BorderSide(
                                      color: AppColors.textLight,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}
