import 'package:flutter/material.dart';

void showAuthError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Auth error: $error')),
  );
}
