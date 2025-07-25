import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:segreteria_medica/main.dart';
import 'package:segreteria_medica/models/paziente.dart';
import 'package:segreteria_medica/providers/profile_provider.dart';
import 'package:segreteria_medica/providers/settings_provider.dart';
import 'package:segreteria_medica/screens/farmaci_tab.dart';
import 'package:segreteria_medica/screens/appuntamenti_tab.dart';
import 'package:segreteria_medica/screens/gestisci_profili_screen.dart';
import 'package:segreteria_medica/screens/settings_screen.dart';
import 'package:segreteria_medica/screens/storico_farmaci_screen.dart'; // Importa la schermata dello storico farmaci
import 'package:segreteria_medica/screens/storico_visite_screen.dart'; // Importa la schermata dello storico visite


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _popupCfController = TextEditingController();
  final TextEditingController _popupPhoneController = TextEditingController();
  final TextEditingController _popupOtpController = TextEditingController();

  bool _popupOtpRequested = false;
  bool _popupIsLoading = false;
  String? _popupErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.loadAllData(); // Chiamata al metodo pubblico
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final token = await authRepository.getAuthToken();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    if (token != null) {
      final pazienteInfo = await pazienteRepository.getPazienteInfo(token);
      if (pazienteInfo != null) {
        if (profileProvider.activePaziente?.codiceFiscale == pazienteInfo.codiceFiscale &&
            profileProvider.activePaziente?.nome != pazienteInfo.nome) {
          profileProvider.addOrUpdateProfile(pazienteInfo.copyWith(isDefault: true));
          profileProvider.setActiveProfile(pazienteInfo.copyWith(isDefault: true));
        }
        profileProvider.isLoggedIn = true; // Aggiorna lo stato di login nel provider
      } else {
        await authRepository.logout();
        profileProvider.isLoggedIn = false; // Aggiorna lo stato di login nel provider
      }
    } else {
      profileProvider.isLoggedIn = false; // Aggiorna lo stato di login nel provider
    }
  }

  void _handleLoginLogout() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (profileProvider.isLoggedIn) {
      await authRepository.logout();
      profileProvider.isLoggedIn = false; // Aggiorna lo stato di login nel provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnessione effettuata.', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
      );
    } else {
      if (profileProvider.activePaziente == null || profileProvider.activePaziente!.codiceFiscale.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nessun profilo attivo. Vai su PROFILO per aggiungerne uno.', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))),
        );
        return;
      }
      _showLoginPopup(profileProvider.activePaziente!);
    }
  }

  void _showLoginPopup(Paziente pazienteToAuth) {
    _popupCfController.text = pazienteToAuth.codiceFiscale;
    _popupPhoneController.text = pazienteToAuth.numeroTelefono;

    _popupOtpRequested = false;
    _popupIsLoading = false;
    _popupErrorMessage = null;
    _popupOtpController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Center(
                child: Text(
                  _popupOtpRequested ? 'Inserisci Codice OTP' : 'Accedi al Tuo Profilo',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Profilo: ${pazienteToAuth.nome}\nTel: ${pazienteToAuth.numeroTelefono}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    if (!_popupOtpRequested) ...[
                      TextField(
                        controller: _popupCfController,
                        decoration: const InputDecoration(
                          labelText: 'Codice Fiscale',
                          prefixIcon: Icon(Icons.person),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        keyboardType: TextInputType.text,
                        enabled: !_popupIsLoading,
                        readOnly: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _popupPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Numero di Telefono',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        enabled: !_popupIsLoading,
                        readOnly: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ] else ...[
                      TextField(
                        controller: _popupOtpController,
                        decoration: const InputDecoration(
                          labelText: 'Codice OTP ricevuto via SMS',
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_popupIsLoading,
                        maxLength: 6,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    if (_popupErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _popupErrorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    _popupIsLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () async {
                              setStateInDialog(() { _popupIsLoading = true; _popupErrorMessage = null; });
                              if (!_popupOtpRequested) {
                                final success = await authRepository.richiestaOtp(
                                  _popupCfController.text.trim(),
                                  _popupPhoneController.text.trim(),
                                );
                                setStateInDialog(() {
                                  _popupIsLoading = false;
                                  if (success) {
                                    _popupOtpRequested = true;
                                  } else {
                                    _popupErrorMessage = "Richiesta OTP fallita. Verifica i dati.";
                                  }
                                });
                              } else {
                                if (_popupOtpController.text.trim().length != 6) {
                                  setStateInDialog(() {
                                    _popupIsLoading = false;
                                    _popupErrorMessage = "Il codice OTP deve essere di 6 cifre.";
                                  });
                                  return;
                                }
                                final token = await authRepository.loginConOtp(
                                  _popupCfController.text.trim(),
                                  _popupPhoneController.text.trim(),
                                  _popupOtpController.text.trim(),
                                );
                                setStateInDialog(() {
                                  _popupIsLoading = false;
                                  if (token != null) {
                                    Provider.of<ProfileProvider>(context, listen: false).isLoggedIn = true;
                                    pazienteRepository.getPazienteInfo(token).then((pazienteInfo) {
                                      if (pazienteInfo != null) {
                                        authRepository.setActivePazienteInfo(
                                          pazienteInfo.nome,
                                          pazienteInfo.codiceFiscale,
                                          pazienteInfo.numeroTelefono,
                                        );
                                        Provider.of<ProfileProvider>(context, listen: false).loadAllData();
                                      }
                                    });
                                    Navigator.of(context).pop();
                                  } else {
                                    _popupErrorMessage = "Login fallito. Codice OTP errato.";
                                  }
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _popupOtpRequested
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.primary,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: Text(
                              _popupOtpRequested ? 'Accedi' : 'Richiedi OTP',
                              style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white),
                            ),
                          ),
                    if (_popupOtpRequested)
                      TextButton(
                        onPressed: _popupIsLoading ? null : () {
                          setStateInDialog(() {
                            _popupOtpRequested = false;
                            _popupOtpController.clear();
                            _popupErrorMessage = null;
                          });
                        },
                        child: Text('Torna indietro / Richiedi nuovo OTP', style: Theme.of(context).textTheme.labelLarge),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Annulla', style: Theme.of(context).textTheme.labelLarge),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Segreteria Medico'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: TabBar(
              labelStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 24),
              tabs: const [
                Tab(text: '💙 FARMACI'),
                Tab(text: '💜 APPUNTAMENTI'),
              ],
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 4.0,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.format_size, size: 30),
              onPressed: () {
                double newScale = settingsProvider.fontSizeScale + 0.1;
                if (newScale > 1.5) newScale = 0.8;
                settingsProvider.setFontSizeScale(newScale);
              },
              tooltip: 'Aumenta/Diminuisci dimensione caratteri',
            ),
            PopupMenuButton<String>(
              onSelected: (String result) async {
                if (result == 'profilo') {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const GestisciProfiliScreen()),
                  );
                  profileProvider.loadAllData();
                } else if (result == 'cronologia_ordini') {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const StoricoFarmaciScreen()),
                  );
                } else if (result == 'cronologia_appuntamenti') {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const StoricoVisiteScreen()),
                  );
                } else if (result == 'frase_cortesia') {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'profilo',
                  child: Text('PROFILO', style: Theme.of(context).textTheme.titleMedium),
                ),
                PopupMenuItem<String>(
                  value: 'cronologia_ordini',
                  child: Text('CRONOLOGIA ORDINI', style: Theme.of(context).textTheme.titleMedium),
                ),
                PopupMenuItem<String>(
                  value: 'cronologia_appuntamenti',
                  child: Text('CRONOLOGIA APPUNTAMENTI', style: Theme.of(context).textTheme.titleMedium),
                ),
                PopupMenuItem<String>(
                  value: 'frase_cortesia',
                  child: Text('FRASE DI CORTESIA', style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
              icon: const Icon(Icons.more_vert, size: 30),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            FarmaciTab(backgroundColor: Colors.blue.shade50),
            AppuntamentiTab(backgroundColor: Colors.purple.shade50),
          ],
        ),
        bottomNavigationBar: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _handleLoginLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: profileProvider.isLoggedIn
                    ? Colors.red.shade600
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                textStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white),
              ),
              child: Text(profileProvider.isLoggedIn ? 'ESCI' : 'ACCEDI'),
            ),
          ),
        ),
      ),
    );
  }
}