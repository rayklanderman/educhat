class JitsiConfig {
  static const String domain = 'meet.jit.si'; // You can use your own Jitsi server
  static const String roomPrefix = 'educhat_';
  
  static String generateRoomName(String chatId) {
    return '$roomPrefix$chatId';
  }
  
  static const Map<String, dynamic> defaultOptions = {
    'configOverwrite': {
      'startWithAudioMuted': false,
      'startWithVideoMuted': false,
      'enableWelcomePage': false,
      'enableClosePage': false,
    },
    'interfaceConfigOverwrite': {
      'TOOLBAR_BUTTONS': [
        'microphone',
        'camera',
        'closedcaptions',
        'desktop',
        'fullscreen',
        'fodeviceselection',
        'hangup',
        'profile',
        'recording',
        'livestreaming',
        'etherpad',
        'sharedvideo',
        'settings',
        'raisehand',
        'videoquality',
        'filmstrip',
        'feedback',
        'stats',
        'shortcuts',
        'tileview',
        'download',
        'help',
        'mute-everyone'
      ],
    },
  };
}
