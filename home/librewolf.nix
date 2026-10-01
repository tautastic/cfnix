{ ... }:

{
  programs.librewolf = {
    enable = true;
    settings = {
      "browser.contentblocking.category" = "strict";
      "browser.dom.window.dump.enabled" = false;
      "browser.ml.linkPreview.enabled" = false;
      "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
      "browser.region.update.enabled" = false;
      "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
      "browser.safebrowsing.downloads.remote.block_uncommon" = false;
      "browser.safebrowsing.downloads.remote.enabled" = false;
      "browser.translations.enable" = false;
      "browser.urlbar.suggest.quickactions" = false;
      "dom.forms.autocomplete.formautofill" = true;
      "extensions.pictureinpicture.enable_picture_in_picture_overrides" = true;
      "findbar.highlightAll" = true;
      "layout.spellcheckDefault" = 0;
      "media.eme.enabled" = true;
      "network.captive-portal-service.enabled" = false;
      "network.connectivity-service.enabled" = false;
      "network.http.http3.enable_0rtt" = false;
      "network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation" = true;
      "network.http.speculative-parallel-limit" = 0;
      "network.prefetch-next" = false;
      "privacy.clearOnShutdown.cookies" = true;
      "privacy.clearOnShutdown.history" = true;
      "privacy.fingerprintingProtection" = true;
      "privacy.globalprivacycontrol.was_ever_enabled" = true;
      "privacy.query_stripping.enabled" = true;
      "privacy.query_stripping.enabled.pbmode" = true;
      "privacy.resistFingerprinting" = false;
      "privacy.trackingprotection.allow_list.convenience.enabled" = false;
      "privacy.trackingprotection.emailtracking.enabled" = true;
      "privacy.trackingprotection.enabled" = true;
      "privacy.trackingprotection.socialtracking.enabled" = true;
      "privacy.userContext.enabled" = false;
      "security.tls.enable_0rtt_data" = false;
      "signon.generation.enabled" = false;
      "signon.management.page.breach-alerts.enabled" = false;
      "toolkit.telemetry.reportingpolicy.firstRun" = false;
      "webgl.disabled" = false;
    };
  };
}
