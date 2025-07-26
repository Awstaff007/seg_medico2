import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seg_medico/models/models.dart';
import 'package:seg_medico/providers/app_provider.dart';
import 'package:seg_medico/widgets/main_drawer.dart';

class FarmaciScreen extends StatefulWidget {
  const FarmaciScreen({Key? key}) : super(key: key);

  @override
  _FarmaciScreenState createState() => _FarmaciScreenState();
}

class _FarmaciScreenState extends State<FarmaciScreen> {
  final _notesController = TextEditingController();
  bool _isEditMode = false;
  late List<Drug> _drugs;

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.fetchUserDrugs();
    _drugs = appProvider.userDrugs.map((d) => Drug(id: d.id, name: d.name, isSelected: false)).toList();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appProvider = Provider.of<AppProvider>(context);
    // Aggiorna la lista locale se quella nel provider cambia
    _drugs = appProvider.userDrugs.map((d) => Drug(id: d.id, name: d.name, isSelected: false)).toList();
  }

  @override
  void dispose(){
      _notesController.dispose();
      super.dispose();
  }

  void _orderDrugs() async {
    final selectedDrugs = _drugs.where((d) => d.isSelected).map((d) => d.id).toList();
    if (selectedDrugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un farmaco.')),
      );
      return;
    }

    final success = await Provider.of<AppProvider>(context, listen: false)
        .orderDrugs(selectedDrugs, _notesController.text);
    
    if (mounted) {
        if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ordine inviato con successo!')),
            );
            Navigator.of(context).pop();
        } else {
            final error = Provider.of<AppProvider>(context, listen: false).errorMessage;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error ?? 'Errore durante l\'invio dell\'ordine.')),
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = Provider.of<AppProvider>(context).fontSizeMultiplier;
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Farmaci', textScaler: TextScaler.linear(textScaler)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
                if (!_isEditMode) {
                  for (var drug in _drugs) {
                    drug.isSelected = false;
                  }
                }
              });
            },
            child: Text(_isEditMode ? 'FINE' : 'MODIFICA'),
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: appProvider.isLoading && _drugs.isEmpty ? const Center(child: CircularProgressIndicator())
      : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _drugs.isEmpty
              ? Center(child: Text("Nessun farmaco in elenco.", textScaler: TextScaler.linear(textScaler)))
              : ListView.builder(
                itemCount: _drugs.length,
                itemBuilder: (context, index) {
                  final drug = _drugs[index];
                  return CheckboxListTile(
                    title: Text(drug.name, textScaler: TextScaler.linear(textScaler)),
                    value: drug.isSelected,
                    onChanged: _isEditMode
                        ? (bool? value) {
                            setState(() {
                              drug.isSelected = value ?? false;
                            });
                          }
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
            ExpansionTile(
              title: Text(
                'Note personali (collassabile)',
                style: Theme.of(context).textTheme.titleMedium,
                textScaler: TextScaler.linear(textScaler),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Ho aumentato il dosaggio di integratori.',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('ANNULLA', textScaler: TextScaler.linear(textScaler)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isEditMode ? _orderDrugs : null,
                    child: Text('ORDINA', textScaler: TextScaler.linear(textScaler)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
