import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg\_medico/providers/app\_provider.dart';
import 'package:seg\_medico/screens/home\_screen.dart'; // Per navigare alla home dopo il login

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State\<LoginScreen\> createState() =\> \_LoginScreenState();
}

class \_LoginScreenState extends State\<LoginScreen\> {
final TextEditingController \_fiscalCodeController = TextEditingController();
final TextEditingController \_phoneNumberController = TextEditingController();
final TextEditingController \_otpController = TextEditingController();
bool \_otpRequested = false;
bool \_isLoading = false;
String? \_errorMessage;

Future\<void\> \_requestOtp() async {
setState(() {
\_isLoading = true;
\_errorMessage = null;
});
try {
final appProvider = Provider.of\<AppProvider\>(context, listen: false);
final success = await appProvider.requestOtp(
\_fiscalCodeController.text,
\_phoneNumberController.text,
);
if (success) {
setState(() {
\_otpRequested = true;
});
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('OTP richiesto con successo\! Controlla i tuoi messaggi.')),
);
} else {
setState(() {
\_errorMessage = 'Richiesta OTP fallita. Verifica i dati inseriti.';
});
}
} catch (e) {
setState(() {
\_errorMessage = 'Errore: ${e.toString()}';
});
} finally {
setState(() {
\_isLoading = false;
});
}
}

Future\<void\> \_login() async {
setState(() {
\_isLoading = true;
\_errorMessage = null;
});
try {
final appProvider = Provider.of\<AppProvider\>(context, listen: false);
final success = await appProvider.login(
\_fiscalCodeController.text,
\_phoneNumberController.text,
\_otpController.text,
);
if (success) {
// Dopo il login, aggiorna l'utente e poi naviga alla Home
await appProvider.fetchUserInfo();
if (mounted) {
Navigator.of(context).pushReplacementNamed('/'); // Naviga alla Home
}
} else {
setState(() {
\_errorMessage = 'Login fallito. OTP non valido o dati errati.';
});
}
} catch (e) {
setState(() {
\_errorMessage = 'Errore: ${e.toString()}';
});
} finally {
setState(() {
\_isLoading = false;
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Accedi')),
body: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(16.0),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: \<Widget\>[
TextField(
controller: \_fiscalCodeController,
decoration: const InputDecoration(
labelText: 'Codice Fiscale',
border: OutlineInputBorder(),
),
),
const SizedBox(height: 16),
TextField(
controller: \_phoneNumberController,
decoration: const InputDecoration(
labelText: 'Numero di Telefono (es. 3331234567)',
border: OutlineInputBorder(),
),
keyboardType: TextInputType.phone,
),
const SizedBox(height: 16),
if (\!\_otpRequested)
\_isLoading
? const CircularProgressIndicator()
: ElevatedButton(
onPressed: \_requestOtp,
child: const Text('Richiedi OTP'),
),
if (\_otpRequested) ...[
TextField(
controller: \_otpController,
decoration: const InputDecoration(
labelText: 'OTP',
border: OutlineInputBorder(),
),
keyboardType: TextInputType.number,
),
const SizedBox(height: 16),
\_isLoading
? const CircularProgressIndicator()
: ElevatedButton(
onPressed: \_login,
child: const Text('Accedi'),
),
],
if (\_errorMessage \!= null)
Padding(
padding: const EdgeInsets.only(top: 16),
child: Text(
\_errorMessage\!,
style: const TextStyle(color: Colors.red),
textAlign: TextAlign.center,
),
),
],
),
),
),
);
}
}
