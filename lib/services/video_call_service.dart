import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

class VideoCallService {
  static final VideoCallService _instance = VideoCallService._internal();
  final _uuid = const Uuid();

  factory VideoCallService() {
    return _instance;
  }

  VideoCallService._internal();

  Future<void> startCall({
    required String chatId,
    required UserModel currentUser,
    required List<UserModel> participants,
  }) async {
    final roomName = 'educhat_${chatId}_${_uuid.v4()}';

    // Prepare meeting options
    final options = JitsiMeetingOptions(
      roomNameOrUrl: roomName,
      serverUrl: AppConfig.jitsiServerUrl,
      isAudioMuted: false,
      isVideoMuted: false,
      userDisplayName: currentUser.name,
      userEmail: currentUser.email,
      userAvatarUrl: currentUser.avatarUrl,
      featureFlags: {
        'invite.enabled': false,
        'chat.enabled': false,
        'raise-hand.enabled': false,
        'meeting-password.enabled': false,
        'calendar.enabled': false,
      },
    );

    try {
      // Create call record in database
      // TODO: Store call details in Supabase

      // Join the meeting
      await JitsiMeetWrapper.joinMeeting(options: options);

      // Handle call ended
      // TODO: Update call record in database
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinCall({
    required String roomName,
    required UserModel user,
  }) async {
    final options = JitsiMeetingOptions(
      roomNameOrUrl: roomName,
      serverUrl: AppConfig.jitsiServerUrl,
      isAudioMuted: false,
      isVideoMuted: false,
      userDisplayName: user.name,
      userEmail: user.email,
      userAvatarUrl: user.avatarUrl,
      featureFlags: {
        'invite.enabled': false,
        'chat.enabled': false,
        'raise-hand.enabled': false,
        'meeting-password.enabled': false,
        'calendar.enabled': false,
      },
    );

    try {
      await JitsiMeetWrapper.joinMeeting(options: options);
    } catch (e) {
      rethrow;
    }
  }
}
