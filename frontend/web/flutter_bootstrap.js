{{flutter_js}}
{{flutter_build_config}}

// FANDOM VERSE - custom web bootstrapper.
//
// It keeps the branded splash (artwork + loading bar) on screen for the whole
// engine start-up and only fades it out once Flutter has painted its first
// frame, so the user never sees a bare loading bar on an empty background.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();

    const splash = document.getElementById('fv-boot-splash');
    if (splash) {
      splash.style.opacity = '0';
      window.setTimeout(function () {
        splash.remove();
      }, 600);
    }
  },
});
