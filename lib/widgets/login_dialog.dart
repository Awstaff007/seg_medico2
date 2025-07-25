// lib/widgets/login\_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg\_medico/models/models.dart';
import 'package:seg\_medico/providers/app\_provider.dart';
import 'package:seg\_medico/widgets/custom\_snackbar.dart';

class LoginDialog extends StatefulWidget {
final Profile profile;

const LoginDialog({super.key, required this.profile});

@override
State\<LoginDialog\> createState() =\> \_LoginDialogState();
}

class \_LoginDialogState extends State\<LoginDialog\> {
final TextEditingController \_otpController = TextEditingController();
bool \_otpRequested = false;
bool \_isLoading = false;
int \_cooldownSeconds = 0;
Timer? \_cooldownTimer;

@override
void dispose() {
\_otpController.dispose();
\_cooldownTimer?.cancel();
super.dispose();
}

void \_startCooldown() {
setState(() {
\_cooldownSeconds = 60;
});
\_cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
if (\_cooldownSeconds == 0) {
timer.cancel();
} else {
setState(() {
\_cooldownSeconds--;
});
}
});
}

Future\<void\> \_requestOtp() async {
setState(() {
\_isLoading = true;
});
final appProvider = Provider.of\<AppProvider\>(context, listen: false);
final success = await appProvider.requestOtp(
widget.profile.codFis,
widget.profile.phoneNumber,
);
setState(() {
\_isLoading = false;
});
if (success) {
setState(() {
\_otpRequested = true;
});
\_startCooldown();
CustomSnackBar.show(context, 'Codice SMS inviato\!');
} else {
CustomSnackBar.show(context, 'Errore durante la richiesta del codice. Riprova.', isError: true);
}
}

Future\<void\> \_login() async {
if (\_otpController.text.length \!= 6) {
CustomSnackBar.show(context, 'Il codice SMS deve essere di 6 cifre.', isError: true);
return;
}

```
setState(() {
  _isLoading = true;
});
final appProvider = Provider.of<AppProvider>(context, listen: false);
try {
  final success = await appProvider.login(
    widget.profile.codFis,
    widget.profile.phoneNumber,
    _otpController.text,
  );
  setState(() {
    _isLoading = false;
  });
  if (success) {
    CustomSnackBar.show(context, 'Accesso effettuato con successo!');
    Navigator.of(context).pop();
  } else {
    CustomSnackBar.show(context, 'Codice errato o scaduto. Riprova.', isError: true);
  }
} catch (e) {
  setState(() {
    _isLoading = false;
  });
  CustomSnackBar.show(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
}
```

}

@override
Widget build(BuildContext context) {
return AlertDialog(
title: Text(widget.profile.name),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text('Telefono: ${widget.profile.phoneNumber}'),
const SizedBox(height: 20),
if (\!\_otpRequested)
ElevatedButton(
onPressed: \_isLoading || \_cooldownSeconds \> 0 ? null : *requestOtp,
child: *isLoading
? const CircularProgressIndicator()
: Text(*cooldownSeconds \> 0
? 'Reinvia in $*cooldownSeconds s'
: 'RICHIEDI CODICE SMS'),
),
if (*otpRequested) ...[
const Text('Inserisci codice SMS (6 cifre)'),
TextField(
controller: *otpController,
keyboardType: TextInputType.number,
maxLength: 6,
decoration: const InputDecoration(
hintText: '******',
counterText: '', // Hide character counter
),
onChanged: (value) {
if (value.length == 6) {
FocusScope.of(context).unfocus(); // Dismiss keyboard
}
},
),
const SizedBox(height: 20),
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
ElevatedButton(
onPressed: \_isLoading ? null : \_login,
child: \_isLoading ? const CircularProgressIndicator() : const Text('ACCEDI'),
),
ElevatedButton(
onPressed: () {
Navigator.of(context).pop();
},
child: const Text('ANNULLA'),
),
],
),
],
],
),
actions: [
if (\!\_otpRequested)
TextButton(
onPressed: () {
Navigator.of(context).pop();
},
child: const Text('ANNULLA'),
),
],
);
}
}