import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'test');
  print('Running...');
}
