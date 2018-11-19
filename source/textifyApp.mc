using Toybox.WatchUi as Ui;

class textifyApp extends Toybox.Application.AppBase {
	hidden var t;
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
    	t = new textifyView();
        return [ t ];
    }

    function onSettingsChanged() {
        t.onSettingsChanged();
    }
}