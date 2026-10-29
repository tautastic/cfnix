{ lib, ... }:

{
  dconf.settings."com/github/neithern/g4music" = {
    # without this Gapless only rereads a playlist file when it restarts
    monitor-changes = true;
    # 0 never, 1 track, 2 album. mm writes track gain only (see its README),
    # so the volume of a loud and a quiet track is evened out.
    replay-gain = lib.hm.gvariant.mkUint32 1;
  };

  # Gapless does not list audio/mpeg in its desktop file, so it is not offered
  # as a default unless it is named here
  xdg.mimeApps.defaultApplications = {
    "audio/mpeg" = "com.github.neithern.g4music.desktop";
    "audio/x-mpegurl" = "com.github.neithern.g4music.desktop";
  };
}
