import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage; // ← tambah

  static SupabaseQueryBuilder table(String tableName) {
    return client.from(tableName);
  }
}
