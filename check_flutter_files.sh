#!/bin/bash

# Lista di file da controllare (relativi alla root del progetto)
declare -a files=(
  "lib/models/user_profile.dart"
  "lib/models/profilo.dart"
  "lib/screens/medicines_screen.dart"
  "lib/screens/appointments_screen.dart"
  "lib/screens/history_screen.dart"
  "lib/screens/profile_management_screen.dart"
  "lib/providers/app_provider.dart"
  "lib/providers/theme_provider.dart"
)

echo "🔍 Verifica dei file principali del progetto..."

for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    echo "✅ Trovato: $file"
  else
    echo "❌ Mancante: $file"
  fi
done

echo ""
echo "📦 Controllo di definizioni di classi chiave..."

# Controlla se certe classi sono presenti nei rispettivi file
declare -A classes
classes["lib/models/user_profile.dart"]="class UserProfile"
classes["lib/models/profilo.dart"]="class Profilo"
classes["lib/screens/medicines_screen.dart"]="class MedicinesScreen"
classes["lib/screens/appointments_screen.dart"]="class AppointmentsScreen"
classes["lib/screens/history_screen.dart"]="class HistoryScreen"
classes["lib/screens/profile_management_screen.dart"]="class ProfileManagementScreen"
classes["lib/providers/theme_provider.dart"]="class ThemeProvider"

for file in "${!classes[@]}"; do
  expected="${classes[$file]}"
  if grep -q "$expected" "$file" 2>/dev/null; then
    echo "✅ $expected definita in $file"
  else
    echo "⚠️ $expected NON trovata in $file"
  fi
done

echo ""
echo "👋 Fatto! Se vuoi, possiamo controllare anche i metodi in AppProvider."
