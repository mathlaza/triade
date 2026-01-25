import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/providers/auth_provider.dart';
import 'package:triade_app/screens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Premium Dark Theme Colors
  static const _backgroundColor = Color(0xFF000000);
  static const _surfaceColor = Color(0xFF1C1C1E);
  static const _cardColor = Color(0xFF2C2C2E);
  static const _borderColor = Color(0xFF38383A);
  static const _goldAccent = Color(0xFFFFD60A);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFF8E8E93);

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _personalNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  File? _selectedPhoto;
  String? _usernameError;
  String? _emailError;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _usernameController.dispose();
    _personalNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        final size = await file.length();

        if (size > 2 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Imagem deve ter no máximo 2MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() => _selectedPhoto = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkUsername(String username) async {
    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final available = await authProvider.checkUsernameAvailable(username);

    if (!available && mounted) {
      setState(() => _usernameError = 'Username já está em uso');
    } else {
      setState(() => _usernameError = null);
    }
  }

  Future<void> _checkEmail(String email) async {
    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() => _emailError = null);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final available = await authProvider.checkEmailAvailable(email);

    if (!available && mounted) {
      setState(() => _emailError = 'Email já está cadastrado');
    } else {
      setState(() => _emailError = null);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'\d').hasMatch(password)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;\x27`~]').hasMatch(password)) return false;
    return true;
  }

  bool _isValidUsername(String username) {
    if (username.isEmpty || username.length > 10) return false;
    return RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameError != null || _emailError != null) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      username: _usernameController.text.trim().toLowerCase(),
      personalName: _personalNameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Upload da foto se selecionada
      if (_selectedPhoto != null) {
        final bytes = await _selectedPhoto!.readAsBytes();
        final base64Photo = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await authProvider.uploadProfilePhoto(base64Photo);
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Erro ao criar conta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? hintText,
    String? helperText,
    String? errorText,
    String? prefixText,
    int? helperMaxLines,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixText: prefixText,
      helperMaxLines: helperMaxLines,
      labelStyle: const TextStyle(color: _textSecondary),
      hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
      helperStyle: TextStyle(color: _textSecondary.withOpacity(0.8)),
      prefixIcon: Icon(prefixIcon, color: _textSecondary),
      suffixIcon: suffixIcon,
      counterStyle: const TextStyle(color: _textSecondary),
      filled: true,
      fillColor: _cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _goldAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Criar Conta',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: _goldAccent),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo e Avatar
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _cardColor,
                            border: Border.all(color: _borderColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _goldAccent.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _selectedPhoto != null
                              ? ClipOval(
                                  child: Image.file(
                                    _selectedPhoto!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: _textSecondary,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: _goldAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toque para adicionar foto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Username
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  maxLength: 10,
                  style: const TextStyle(color: _textPrimary),
                  cursorColor: _goldAccent,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return newValue.copyWith(
                        text: newValue.text.toLowerCase(),
                        selection: newValue.selection,
                      );
                    }),
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._-]')),
                  ],
                  decoration: _buildInputDecoration(
                    label: 'Username',
                    hintText: 'Ex: matheus',
                    prefixIcon: Icons.alternate_email,
                    prefixText: '@',
                    errorText: _usernameError,
                    helperText: 'Letras minúsculas, números, ".", "-" e "_" (máx 10)',
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _checkUsername(value.toLowerCase());
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username é obrigatório';
                    }
                    if (!_isValidUsername(value.trim())) {
                      return 'Username inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nome Pessoal
                TextFormField(
                  controller: _personalNameController,
                  textInputAction: TextInputAction.next,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: _textPrimary),
                  cursorColor: _goldAccent,
                  decoration: _buildInputDecoration(
                    label: 'Nome Pessoal',
                    hintText: 'Ex: Matheus Lazaro',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    if (value.trim().length > 30) {
                      return 'Nome deve ter no máximo 30 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: _textPrimary),
                  cursorColor: _goldAccent,
                  decoration: _buildInputDecoration(
                    label: 'Email',
                    hintText: 'seu@email.com',
                    prefixIcon: Icons.email_outlined,
                    errorText: _emailError,
                  ),
                  onChanged: (value) {
                    if (_isValidEmail(value)) {
                      _checkEmail(value.toLowerCase());
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email é obrigatório';
                    }
                    if (!_isValidEmail(value.trim())) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Senha
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: _textPrimary),
                  cursorColor: _goldAccent,
                  decoration: _buildInputDecoration(
                    label: 'Senha',
                    prefixIcon: Icons.lock_outline,
                    helperText: 'Mín 8 caracteres, 1 número e 1 especial',
                    helperMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Senha é obrigatória';
                    }
                    if (!_isValidPassword(value)) {
                      return 'Senha deve ter 8+ chars, 1 número e 1 especial';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmar Senha
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  style: const TextStyle(color: _textPrimary),
                  cursorColor: _goldAccent,
                  decoration: _buildInputDecoration(
                    label: 'Confirmar Senha',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _textSecondary,
                      ),
                      onPressed: () {
                        setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme sua senha';
                    }
                    if (value != _passwordController.text) {
                      return 'Senhas não conferem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botão Cadastrar
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: _goldAccent.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            'Criar Conta',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Link para Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Já tem conta? ',
                      style: TextStyle(color: _textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Fazer login',
                        style: TextStyle(
                          color: _goldAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
