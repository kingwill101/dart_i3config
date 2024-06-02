import 'package:i3config/i3config.dart';

void main() {
  final configContent = '''
order += "volume slave"
general {
    interval = 1
    colors = true
    color_good="#FFFFFF"
    color_degraded="#ffd75f"
    color_bad="#d75f5f"
}

# order += "tztime utc"
order += "tztime local"

tztime local {
    format = "  %a %Y-%m-%d %H:%M:%S"
}

tztime utc {
    format = " UTC %H:%M"
    timezone = "Etc/UTC"
}

  ''';

  final parser = I3ConfigParser(configContent);
  final config = parser.parse();

  for (var element in config.elements) {
    print(element);
  }

}
