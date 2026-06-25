/// Public Supabase connection values for the Vita app.
///
/// The anon / publishable key is intentionally safe to ship in client code:
/// it only grants access allowed by the database's Row Level Security policies.
/// NEVER put the service_role key here — that one lives only in Edge Function
/// secrets on the server.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://mdcdugxgxfnpoymhiexv.supabase.co';
  static const String anonKey =
      'sb_publishable_mqOUf2ry68pK0ivLn8x-Kw_2dfdeTTv';
}
