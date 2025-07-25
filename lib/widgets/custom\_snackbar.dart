// lib/widgets/custom\_snackbar.dart

import 'package:flutter/material.dart';

class CustomSnackBar {
static void show(BuildContext context, String message, {bool isError = false}) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor: isError ? Colors.red : Colors.green,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10.0),
),
margin: const EdgeInsets.all(10.0),
),
);
}
}