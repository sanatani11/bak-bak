import 'dart:io';

import 'package:bak_bak/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  File? _selectedIMage;
  var _isAuthenticating = false;

  void _submit() async {
    bool isValid = _form.currentState!.validate();
    if (!isValid) return;

    _form.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        //print(userCredentials);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_image')
            .child('${userCredentials.user!.uid}.jpg');
        await storageRef.putFile(_selectedIMage!);
        final imageUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('users')
            .doc('${userCredentials.user!.uid}')
            .set({
          'user-name': 'to be added..',
          'email': _enteredEmail,
          'image-url': imageUrl
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        //''
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authentification Failed!')));
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isLogin)
                              UserImagePicker(
                                onPickedImage: (image) {
                                  _selectedIMage = image;
                                },
                              ),
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Add Email Address'),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Enter a valid email';
                                }

                                return null;
                              },
                              onSaved: (newValue) {
                                _enteredEmail = newValue!;
                              },
                            ),
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Enter password'),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be of 6 or more characters';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                _enteredPassword = newValue!;
                              },
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            if (_isAuthenticating)
                              const CircularProgressIndicator(),
                            if (!_isAuthenticating)
                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                                child: Text(_isLogin ? 'LogIn' : 'SignUp'),
                              ),
                            if (!_isAuthenticating)
                              TextButton(
                                onPressed: () {
                                  setState(
                                    () {
                                      _isLogin = !_isLogin;
                                    },
                                  );
                                },
                                child: Text(_isLogin
                                    ? 'Create an Account'
                                    : 'Already have an account?'),
                              ),
                          ],
                        )),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
