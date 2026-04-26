import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_micro_journal/authentication/services/authentication_service.dart';
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/main.dart';
import 'package:project_micro_journal/utils/snackbar_service.dart';

class GoogleSignUpPage extends StatefulWidget {
  final String googleId;
  final String email;
  final String displayName;
  final String picture;

  const GoogleSignUpPage({
    super.key,
    required this.googleId,
    required this.email,
    required this.displayName,
    required this.picture,
  });

  @override
  GoogleSignUpPageState createState() => GoogleSignUpPageState();
}

class GoogleSignUpPageState extends State<GoogleSignUpPage> {
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  late final _displayNameController = TextEditingController(
    text: widget.displayName,
  );
  final _dobController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDob;

  final authService = AuthenticationService();
  final snackbarService = SnackbarService();
  final authenticationTokenStorageService = AuthenticationTokenStorageService();

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      snackbarService.showErrorSnackBar(context, 'Please select your gender');
      return;
    }
    if (_selectedDob == null) {
      snackbarService.showErrorSnackBar(
        context,
        'Please select your date of birth',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await authService.completeGoogleSignUp(
        googleId: widget.googleId,
        email: widget.email,
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        dob: DateFormat('yyyy-MM-dd').format(_selectedDob!),
        gender: _selectedGender!,
      );

      await authenticationTokenStorageService.saveTokensAndId(
        response['access_token'],
        response['refresh_token'],
        response['user_id'],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppTabs()),
        );
      }
    } catch (err) {
      snackbarService.showErrorSnackBar(context, err.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 400),
                padding: EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            const AssetImage('assets/icon.png')
                                as ImageProvider,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Almost There!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Just a few more details to set up your account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      // Show the email being used (read-only, just informational)
                      Text(
                        widget.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          if (value.trim().length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                            return 'Only letters, numbers, and underscores';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Display Name (pre-filled from Google)
                      TextFormField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your display name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Date of Birth
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your date of birth';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Gender
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                          DropdownMenuItem(
                            value: 'prefer_not_to_say',
                            child: Text('Prefer not to say'),
                          ),
                        ],
                        onChanged:
                            (value) => setState(() => _selectedGender = value),
                        validator: (value) {
                          if (value == null) return 'Please select your gender';
                          return null;
                        },
                      ),
                      SizedBox(height: 32),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              isLoading
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    'Complete Sign Up',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
