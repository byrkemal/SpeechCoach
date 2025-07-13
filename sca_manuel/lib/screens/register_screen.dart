import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hata", style: TextStyle(color: Colors.red[700])),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Tamam"),
          ),
        ],
      ),
    );
  }

  void _register() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog("Lütfen tüm alanları doldurun");
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog("Şifreler uyuşmuyor");
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Başarılı", style: TextStyle(color: Colors.green[700])),
          content: Text("Kayıt başarılı! Giriş ekranına yönlendiriliyorsunuz."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
              },
              child: Text("Tamam"),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog("Hata: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Color(0xFF1E1E2C), Color(0xFF121217)]
                : [Color(0xFF8AA0FF), Color(0xFFC1D4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF2A2D3E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : Colors.black12,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Kayıt Ol",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white70 : theme.colorScheme.primary,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28),
                    _buildInputField(
                      controller: _emailController,
                      label: "E-posta",
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                    ),
                    SizedBox(height: 16),
                    _buildInputField(
                      controller: _passwordController,
                      label: "Şifre",
                      obscureText: true,
                      isDark: isDark,
                    ),
                    SizedBox(height: 16),
                    _buildInputField(
                      controller: _confirmPasswordController,
                      label: "Şifre Tekrar",
                      obscureText: true,
                      isDark: isDark,
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Color(0xFF556EE6)
                              : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor:
                              isDark ? Colors.black54 : Colors.blueAccent,
                          animationDuration: Duration(milliseconds: 350),
                        ),
                        child: Text(
                          "Kayıt Ol",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Zaten hesabın var mı? Giriş Yap",
                        style: TextStyle(
                          color: isDark
                              ? Colors.blue[300]
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: ButtonStyle(
                        overlayColor: MaterialStateProperty.all(
                            Colors.blue.withOpacity(0.1)),
                        animationDuration: Duration(milliseconds: 250),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: isDark ? Colors.white70 : Colors.black87,
      style: TextStyle(
        color: isDark ? Colors.white70 : Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: isDark ? Color(0xFF3A3E57) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }
}
