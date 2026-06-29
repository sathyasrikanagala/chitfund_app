import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'dashboard_screen.dart';
import 'member_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  bool _showRegister = false;

  String _selectedRole = 'member';
  String? _errorText;

  Future<void> _register() async {
    if (_fullNameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _errorText = 'Please fill all fields');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final created = await ApiService.register({
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'role': _selectedRole,
      });

      SessionManager.instance.login(created);

      if (mounted) {
        Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => SessionManager.instance.isMember
        ? const MemberDashboardScreen()
        : const DashboardScreen(),
  ),
);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorText = '$e';
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final user = await ApiService.login(
  _usernameController.text.trim(),
  _passwordController.text.trim(),
);
print('LOGIN RESPONSE: $user');
SessionManager.instance.login(user);

      if (mounted) {
        Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => SessionManager.instance.isMember
        ? const MemberDashboardScreen()
        : const DashboardScreen(),
  ),
);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorText = '$e';
      });
    }
  }

  void _clearFields() {
    _usernameController.clear();
    _passwordController.clear();
    _fullNameController.clear();
    _mobileController.clear();
    _errorText = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance,
                    size: 80, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Chit Fund Manager',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _showRegister
                      ? 'Create a new account'
                      : 'Village Operations Platform',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _showRegister
                      ? _buildRegisterForm()
                      : _buildLoginForm(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        _nameField(),
        const SizedBox(height: 16),
        _mobileField(),
        const SizedBox(height: 16),
        _usernameField(),
        const SizedBox(height: 16),
        _passwordField(),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedRole,
          decoration: const InputDecoration(
            labelText: 'I am a...',
            prefixIcon: Icon(Icons.shield),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'member', child: Text('Member')),
            DropdownMenuItem(value: 'agent', child: Text('Agent')),
          ],
          onChanged: (val) => setState(() => _selectedRole = val!),
        ),
        if (_selectedRole == 'member')
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'After signing up, you can request to join your chit group.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        _errorRow(),
        const SizedBox(height: 24),
        _submitButton('Create Account', _register),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _showRegister = false;
              _errorText = null;
            });
            _clearFields();
          },
          child: const Text('Already have an account? Login'),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _usernameField(),
        const SizedBox(height: 16),
        _passwordField(),
        _errorRow(),
        const SizedBox(height: 24),
        _submitButton('Login', _login),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _showRegister = true;
              _errorText = null;
            });
            _clearFields();
          },
          child: const Text('New here? Create Account'),
        ),
      ],
    );
  }

  Widget _nameField() => TextField(
        controller: _fullNameController,
        decoration: const InputDecoration(
          labelText: 'Full Name',
          prefixIcon: Icon(Icons.badge),
          border: OutlineInputBorder(),
        ),
      );

  Widget _mobileField() => TextField(
        controller: _mobileController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Mobile Number',
          prefixIcon: Icon(Icons.phone),
          border: OutlineInputBorder(),
        ),
      );

  Widget _usernameField() => TextField(
        controller: _usernameController,
        decoration: const InputDecoration(
          labelText: 'Username',
          prefixIcon: Icon(Icons.person),
          border: OutlineInputBorder(),
        ),
      );

  Widget _passwordField() => TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
      );

  Widget _errorRow() => _errorText == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(_errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        );

  Widget _submitButton(String label, VoidCallback onPressed) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isSubmitting ? null : onPressed,
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(label, style: const TextStyle(fontSize: 16)),
        ),
      );
}