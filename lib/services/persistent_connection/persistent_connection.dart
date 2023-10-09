// import 'dart:async';

// /// This class is used to subscribe server events.
// ///
// class Connect {
//   static final Connect _singleton = Connect._internal();
//   Connect._internal();

//   factory Connect() {
//     return _singleton;
//   }

//   bool isConnecting = false;

//   int reconnectSec = 1;
//   Timer? _reconnectTimer;

//   void connect() {}

//   void close() {}
// }

/// This class is used to subscribe server events.
///
/// I

abstract class PersistentConnection {
  void connect();

  void close();
}
