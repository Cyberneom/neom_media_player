/// Coordinates browser hover controls without ever starting audible autoplay.
/// The iframe itself owns its native, user-operated playback controls.
class YoutubeWebController {
  YoutubeWebController({required bool muted}) : _muted = muted;

  bool _muted;
  bool _ready = false;
  bool _hoverPlaying = false;
  void Function(String command)? _send;

  void attach(void Function(String command) send) {
    _send = send;
    _ready = false;
  }

  void markReady() {
    if (_ready || _send == null) return;
    _ready = true;
    _send!(_muted ? 'mute' : 'unMute');
    if (_hoverPlaying && _muted) _send!('playVideo');
  }

  void playMuted() {
    if (!_muted) return;
    _hoverPlaying = true;
    if (_ready) {
      _send?.call('mute');
      _send?.call('playVideo');
    }
  }

  void pause() {
    _hoverPlaying = false;
    if (_ready) _send?.call('pauseVideo');
  }

  void setMuted(bool muted) {
    // A preview started by hover must be paused before it can become audible.
    if (!muted && _hoverPlaying) pause();
    _muted = muted;
    if (_ready) _send?.call(muted ? 'mute' : 'unMute');
  }

  void detach() {
    _send = null;
    _ready = false;
    _hoverPlaying = false;
  }
}
