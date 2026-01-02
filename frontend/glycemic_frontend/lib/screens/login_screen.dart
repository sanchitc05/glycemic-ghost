import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;  // ✅ MISSING!
import '../screens/glucose_screen.dart';  // ✅ For navigation

class LoginScreen extends StatefulWidget {  // ✅ StatefulWidget, NOT StatefulBuilder
  final void Function(String userId, String token) onLogin;
  
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;  // ✅ Loading state

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _loading = true);
    
    try {
      final res = await http.post(
        Uri.parse('http://localhost:4000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
        }),
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        widget.onLogin(data['user']['id'], data['token']);  // ✅ Navigate to GlucoseScreen
      } else {
        final error = jsonDecode(res.body)['error'] ?? 'Login failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _register() async {
    // Same as login but POST /api/auth/register
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('http://localhost:4000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
        }),
      );
      
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        widget.onLogin(data['user']['id'], data['token']);
      } else {
        final error = jsonDecode(res.body)['error'] ?? 'Registration failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monitor_heart, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Glycemic Ghost',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your glucose journey',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading 
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Text('Login', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : _register,
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => widget.onLogin('123', 'dummy-token'),  // Demo mode
                child: const Text('Demo Mode (Skip Login)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
