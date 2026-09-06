import 'package:flutter_test/flutter_test.dart';
import 'package:neom_media_player/ui/youtube/youtube_web_controller.dart';

void main() {
  test('readiness synchronizes mute without autoplay', () {
    final commands = <String>[];
    final controller = YoutubeWebController(muted: true)..attach(commands.add);
    controller.markReady();
    controller.markReady();
    expect(commands, ['mute']);
  });

  test('hover queued before ready starts only after mute', () {
    final commands = <String>[];
    final controller = YoutubeWebController(muted: true)..attach(commands.add);
    controller.playMuted();
    expect(commands, isEmpty);
    controller.markReady();
    expect(commands, ['mute', 'playVideo']);
  });

  test('leaving before ready cancels the pending preview', () {
    final commands = <String>[];
    final controller = YoutubeWebController(muted: true)..attach(commands.add);
    controller.playMuted();
    controller.pause();
    controller.markReady();
    expect(commands, ['mute']);
  });

  test('unmuted hover never starts playback', () {
    final commands = <String>[];
    final controller = YoutubeWebController(muted: false)..attach(commands.add);
    controller.playMuted();
    controller.markReady();
    controller.playMuted();
    expect(commands, ['unMute']);
  });

  test('unmuting pauses a hover preview before enabling sound', () {
    final commands = <String>[];
    final controller = YoutubeWebController(muted: true)..attach(commands.add);
    controller.markReady();
    controller.playMuted();
    controller.setMuted(false);
    controller.playMuted();
    expect(commands, ['mute', 'mute', 'playVideo', 'pauseVideo', 'unMute']);
  });

  test('detached/replaced frames cannot receive stale or queued commands', () {
    final oldCommands = <String>[];
    final newCommands = <String>[];
    final controller = YoutubeWebController(muted: true)
      ..attach(oldCommands.add);
    controller.playMuted();
    controller.detach();
    controller.markReady();
    controller.attach(newCommands.add);
    controller.markReady();
    expect(oldCommands, isEmpty);
    expect(newCommands, ['mute']);
  });
}
