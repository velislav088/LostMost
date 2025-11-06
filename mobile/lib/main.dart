import 'package:flutter/material.dart';
import 'package:mobile/auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // supabase setup
  await Supabase.initialize(
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyZ25zaHNvZ2l4Y215dW9pdHFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI0Mjg1MzEsImV4cCI6MjA3ODAwNDUzMX0.ndi_l6YeNslAs3QvA-7i5a0qjZW4-4_YNYdCU--ffao',
    url: 'https://srgnshsogixcmyuoitqh.supabase.co',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: AuthGate());
  }
}
