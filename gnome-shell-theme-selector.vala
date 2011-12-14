// -*- mode: vala; vala-indent-level: 4; indent-tabs-mode: nil -*-
using Gtk;
using GLib;

[DBus (name = "apps.nano77.gdm3setup")]
interface GDM3SETUP : Object {
    public abstract void SetUI (string name,string value) throws IOError;
    public abstract void StopDaemon () throws IOError;
}

const string THEME_SETTINGS_SCHEMA = "org.gnome.shell";
const string THEME_SETTINGS_KEY = "theme-name";
GLib.Settings Settings;
bool SETUP;

ComboBoxText ComboBox_shell;
Button Button_GDM;

GDM3SETUP gdm3setup;

void window_close()  {
    Gtk.main_quit();
    if (SETUP) {
        try {
            gdm3setup.StopDaemon();
        }
        catch {
            stderr.printf("");
        }
    }
}

void load_theme_list() {
    string name,file;
    var d = Dir.open("/usr/share/themes/");
    ComboBox_shell.append_text("Adwaita");
    while ((name = d.read_name()) != null) {
        file = "/usr/share/themes/%s/gnome-shell/".printf(name);
        if (FileUtils.test (file,FileTest.IS_DIR)) {
            ComboBox_shell.append_text(name);
        }
    }
}

Gtk.TreeIter get_iter(Gtk.TreeModel model,string target) {
    TreeIter target_iter;
    TreeIter iter_test;
    model.get_iter_first(out iter_test);

    target_iter = iter_test;
    
    do {
        Value name;
        model.get_value(iter_test,0,out name);
        if ( name.get_string() == target ) {
            target_iter = iter_test;
            break;
        }
    }
    while (model.iter_next(ref iter_test));

    return target_iter;
}

void get_theme() {
    string theme_name = Settings.get_string(THEME_SETTINGS_KEY);
    ComboBox_shell.set_active_iter(get_iter(ComboBox_shell.get_model(),theme_name));
}

void CheckGdmCompatibility() {
    string theme_name = ComboBox_shell.get_active_text();
    var file = File.new_for_path ("/usr/share/themes/%s/gnome-shell/gdm.css".printf(theme_name));
    bool state = file.query_exists ();
    if (state | theme_name=="Adwaita" ) {
        Button_GDM.set_sensitive(true);
    }
    else {
        Button_GDM.set_sensitive(false);
    }
}

void CheckGdm3setup() {
    SETUP = File.new_for_path("/usr/bin/gdm3setup-daemon.py").query_exists(null) | 
File.new_for_path("/usr/bin/gdm3setup-daemon").query_exists(null);
    if (SETUP) {
        gdm3setup = Bus.get_proxy_sync (BusType.SYSTEM,
                                        "apps.nano77.gdm3setup",
                                        "/apps/nano77/gdm3setup");
        Button_GDM.show();
    }
    else {
        Button_GDM.hide();
    }
}

void shell_theme_changed() {
    string shell_theme = ComboBox_shell.get_active_text();
    Settings.set_string(THEME_SETTINGS_KEY,shell_theme);
    CheckGdmCompatibility();
}

void gdm_button_clicked() {
    string theme_name = ComboBox_shell.get_active_text();
    gdm3setup.SetUI("SHELL_THEME",theme_name);
}

int main (string[] args) {
    Gtk.init (ref args);

    var window = new Window ();
    window.title = "GnomeShell theme Selector";
    window.border_width = 10;
    window.window_position = WindowPosition.CENTER;
    window.set_default_size (400, 300);
    window.set_resizable(false);
    window.set_icon_name("preferences-desktop-theme");
    window.destroy.connect (window_close);

    var VBox_Main = new Gtk.VBox (false, 4);
    window.add (VBox_Main);

    var HBox_1 = new Gtk.HBox (false, 4);
    VBox_Main.pack_start(HBox_1, false, false, 0);

    var Label_shell = new Gtk.Label("Shell theme");
    Label_shell.set_alignment(0,0.5f);
    HBox_1.pack_start(Label_shell, true, true, 4);

    ComboBox_shell = new Gtk.ComboBoxText ();
    ComboBox_shell.changed.connect(shell_theme_changed);
    HBox_1.pack_start (ComboBox_shell, true, true, 4);

    var HBox_2 = new Gtk.HBox (true, 4);
    VBox_Main.pack_end(HBox_2, true, true, 0);

    Button_GDM = new Gtk.Button();
    Button_GDM.label = "Set this theme for GDM";
    Button_GDM.clicked.connect(gdm_button_clicked);
    HBox_2.pack_end(Button_GDM, false, false, 0);

    Settings = new GLib.Settings(THEME_SETTINGS_SCHEMA);

    window.show_all ();
    load_theme_list();
    get_theme();
    CheckGdmCompatibility();
    CheckGdm3setup();

    Gtk.main ();
    return 0;
}


