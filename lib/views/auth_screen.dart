import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum AuthState { login, signup, forgotPassword, verifyOtp, resetPassword }

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  AuthState _authState = AuthState.login;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _submit() async {
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    try {
      if (_authState == AuthState.login) {
        await authService.signInWithEmail(
            _emailController.text.trim(), _passwordController.text.trim());
      } else if (_authState == AuthState.signup) {
        final cred = await authService.signUpWithEmail(
            _emailController.text.trim(), _passwordController.text.trim());
        final newUser = UserModel(
          uid: cred.user!.uid,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          emergencyContacts: [],
          isActive: true,
        );
        await authService.saveUser(newUser);
      } else if (_authState == AuthState.forgotPassword) {
        // Mock send OTP
        setState(() => _authState = AuthState.verifyOtp);
      } else if (_authState == AuthState.verifyOtp) {
        // Mock verify
        setState(() => _authState = AuthState.resetPassword);
      } else if (_authState == AuthState.resetPassword) {
        // Mock reset
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset successful")));
        setState(() => _authState = AuthState.login);
      }
    } on FirebaseAuthException catch (e) {
      String message = "Authentication failed";
      
      switch (e.code) {
        case 'user-not-found':
          message = "No user found with this email.";
          break;
        case 'wrong-password':
          message = "Incorrect password. Please try again.";
          break;
        case 'email-already-in-use':
          message = "This email is already registered.";
          break;
        case 'weak-password':
          message = "The password provided is too weak.";
          break;
        case 'invalid-email':
          message = "The email address is not valid.";
          break;
        case 'user-disabled':
          message = "This user account has been disabled.";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please try again later.";
          break;
        case 'network-request-failed':
          message = "Network error. Please check your internet connection.";
          break;
        default:
          message = e.message ?? "An unexpected error occurred.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (_authState != AuthState.login && _authState != AuthState.signup)
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => setState(() => _authState = AuthState.login),
              ),
              title: Text(_getAppBarTitle()),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_authState == AuthState.login || _authState == AuthState.signup) ...[
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    width: 120,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _authState == AuthState.login ? "Sign In" : "Sign Up",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _authState == AuthState.login ? "welcome back\nyou've been missed" : "create account\njoin us to stay safe",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                        fontSize: 18,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 48),
              ] else ...[
                const SizedBox(height: 20),
                Center(
                  child: Icon(
                    _getIconForState(),
                    size: 100,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    _getInstructionText(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 40),
              ],
              
              _buildFormFields(),

              if (_authState == AuthState.login) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _authState = AuthState.forgotPassword),
                    child: const Text(
                      "forgot password?",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ],
                
              const SizedBox(height: 40),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.black))
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(_getButtonText()),
                    ),
              
              if (_authState == AuthState.login || _authState == AuthState.signup) ...[
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _authState = _authState == AuthState.login ? AuthState.signup : AuthState.login;
                    }),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black54, fontSize: 16),
                        children: [
                          TextSpan(text: _authState == AuthState.login ? "Don't have an account? " : "Already have an account? "),
                          TextSpan(
                            text: _authState == AuthState.login ? "sign up" : "sign in",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_authState) {
      case AuthState.forgotPassword: return "forgot password";
      case AuthState.verifyOtp: return "Verify Your Email";
      case AuthState.resetPassword: return "Create New Password";
      default: return "";
    }
  }

  IconData _getIconForState() {
    switch (_authState) {
      case AuthState.forgotPassword: return Icons.lock_outline;
      case AuthState.verifyOtp: return Icons.mail_outline;
      case AuthState.resetPassword: return Icons.lock_open;
      default: return Icons.help_outline;
    }
  }

  String _getInstructionText() {
    switch (_authState) {
      case AuthState.forgotPassword: return "Please Enter Your Email Address To\nReceive a verification code";
      case AuthState.verifyOtp: return "Please Enter Four Digit Code Sent\nTo Your Email";
      case AuthState.resetPassword: return "Your New Password Must Be Different\nFrom Previously used password";
      default: return "";
    }
  }

  String _getButtonText() {
    switch (_authState) {
      case AuthState.login: return "Sign In";
      case AuthState.signup: return "Sign Up";
      case AuthState.forgotPassword: return "Send";
      case AuthState.verifyOtp: return "Verify";
      case AuthState.resetPassword: return "Save";
    }
  }

  Widget _buildFormFields() {
    switch (_authState) {
      case AuthState.login:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel("Email ID"),
            TextField(controller: _emailController, decoration: const InputDecoration(hintText: "Enter Email ID")),
            const SizedBox(height: 20),
            _buildFieldLabel("Password"),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Enter Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: Colors.black54,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ],
        );
      case AuthState.signup:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel("Full Name"),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: "Enter Full Name")),
            const SizedBox(height: 20),
            _buildFieldLabel("Phone Number"),
            TextField(controller: _phoneController, decoration: const InputDecoration(hintText: "Enter Phone Number"), keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            _buildFieldLabel("Email ID"),
            TextField(controller: _emailController, decoration: const InputDecoration(hintText: "Enter Email ID")),
            const SizedBox(height: 20),
            _buildFieldLabel("Password"),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Enter Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: Colors.black54,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ],
        );
      case AuthState.forgotPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel("Email ID"),
            TextField(controller: _emailController, decoration: const InputDecoration(hintText: "Enter Email ID")),
          ],
        );
      case AuthState.verifyOtp:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) => _buildOtpSquare()),
        );
      case AuthState.resetPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel("New Password"),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Enter New Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: Colors.black54,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildFieldLabel("Confirm Password"),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: "Enter confirm Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: Colors.black54,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildOtpSquare() {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      child: const TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(border: InputBorder.none, filled: false),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
      ),
    );
  }
}
