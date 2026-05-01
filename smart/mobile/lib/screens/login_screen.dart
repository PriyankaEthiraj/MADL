import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'admin_register_screen.dart';
import 'department_register_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';
import 'department_dashboard_screen.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.expectedRole = 'citizen',
    this.title = 'Citizen Login',
    this.showRoleAccessButton = true,
  });

  final String? expectedRole;
  final String title;
  final bool showRoleAccessButton;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _identifierError;
  String? _passwordError;
  String? _generalError;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isEmail(String input) {
    return input.contains('@');
  }

  bool _isPhoneNumber(String input) {
    return RegExp(r'^\d+$').hasMatch(input);
  }

  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or phone number is required';
    }

    final input = value.trim();
    
    if (_isEmail(input)) {
      // Validate email format
      final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
      if (!emailRegex.hasMatch(input)) {
        return 'Please enter a valid email address';
      }
    } else if (_isPhoneNumber(input)) {
      // Validate phone number
      final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length < 10) {
        return 'Please enter a valid phone number';
      }
    } else {
      return 'Please enter a valid email address or phone number';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> _submit() async {
    // Clear previous errors
    setState(() {
      _identifierError = null;
      _passwordError = null;
      _generalError = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthService>().login(
            _identifierController.text.trim(),
            _passwordController.text,
            expectedRole: widget.expectedRole,
          );
      
      if (!mounted) return;

      final role = context.read<AuthService>().user?['role']?.toString() ?? 'citizen';
      _navigateByRole(role);
    } catch (err) {
      if (!mounted) return;
      
      final errorMessage = err.toString().replaceAll('Exception: ', '');
      
      setState(() {
        // Map backend errors to specific fields or general error
        if (errorMessage.contains('email') && errorMessage.contains('valid')) {
          _identifierError = 'Please enter a valid email address';
        } else if (errorMessage.contains('phone') && errorMessage.contains('valid')) {
          _identifierError = 'Please enter a valid phone number';
        } else if (errorMessage.contains('Email or phone')) {
          _identifierError = 'Email or phone number is required';
        } else if (errorMessage.contains('Password is required')) {
          _passwordError = 'Password is required';
        } else if (errorMessage.contains('Invalid login credentials') || 
                   errorMessage.contains('Invalid credentials')) {
          _generalError = 'Invalid login credentials';
        } else if (errorMessage.toLowerCase().contains('network') || 
                   errorMessage.toLowerCase().contains('connection') ||
                   errorMessage.toLowerCase().contains('timeout')) {
          _generalError = 'Network error. Please try again';
        } else {
          _generalError = errorMessage;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateByRole(String role) {
    Widget destination;
    if (role == 'admin') {
      destination = const AdminDashboardScreen();
    } else if (role == 'department') {
      destination = const DepartmentDashboardScreen();
    } else {
      destination = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo and Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_city_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF9CA3AF),
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Email or Phone Number Field
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email or Phone Number',
                      hintText: 'Enter your email or phone number',
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: _identifierError,
                    ),
                    validator: _validateIdentifier,
                    onChanged: (_) {
                      if (_identifierError != null) {
                        setState(() => _identifierError = null);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword 
                              ? Icons.visibility_outlined 
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: _validatePassword,
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // General Error Message
                  if (_generalError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _generalError!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Login Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Register / Role Access
                  if (widget.expectedRole == 'citizen')
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                      child: const Text('Create Account'),
                    ),

                  // Create Account for Admin/Department
                  if (widget.expectedRole == 'admin')
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminRegisterScreen(),
                                ),
                              );
                            },
                      child: const Text('Create Admin Account'),
                    ),

                  if (widget.expectedRole == 'department')
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DepartmentRegisterScreen(),
                                ),
                              );
                            },
                      child: const Text('Create Department Account'),
                    ),

                  if (widget.showRoleAccessButton) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                              );
                            },
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Admin & Department Access'),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Footer
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF9CA3AF),
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}