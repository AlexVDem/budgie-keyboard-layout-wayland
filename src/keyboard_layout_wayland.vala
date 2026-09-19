/*
 * Native Budgie Panel Applet for Wayland (Labwc)
 * Language Layout Switcher & Indicator (EN / RU)
 * Supports Ubuntu Budgie 24.04 / 26.04+ with libpeas-2 and libpeas-1.0
 */

public class KeyboardLayoutWaylandApplet : Budgie.Applet {
    private Gtk.Button button;
    private Gtk.Label label;
    private string current_layout = "EN";
    private string? led_file = null;
    private uint timeout_id = 0;
    public string uuid { get; construct set; }

    public KeyboardLayoutWaylandApplet(string uuid) {
        GLib.Object(uuid: uuid);

        this.button = new Gtk.Button();
        this.button.set_relief(Gtk.ReliefStyle.NONE);
        this.button.set_can_focus(false);

        this.label = new Gtk.Label(null);
        this.label.set_markup("<span font_weight='bold' font_size='11pt'>EN</span>");
        this.button.add(this.label);
        this.add(this.button);

        // Styling
        var provider = new Gtk.CssProvider();
        try {
            provider.load_from_data("button { padding: 0 8px; margin: 2px; }");
            this.button.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {}

        this.button.clicked.connect(this.on_clicked);

        this.led_file = this.find_led_file();
        this.timeout_id = GLib.Timeout.add(100, this.update_state);

        this.show_all();
    }

    private string? find_led_file() {
        string[] candidates = {
            "/sys/class/leds/input1::scrolllock/brightness",
            "/sys/devices/platform/i8042/serio0/input/input1/input1::scrolllock/brightness"
        };
        foreach (var c in candidates) {
            if (FileUtils.test(c, FileTest.EXISTS)) {
                return c;
            }
        }
        return null;
    }

    private string get_layout() {
        if (this.led_file != null && FileUtils.test(this.led_file, FileTest.EXISTS)) {
            try {
                string val;
                FileUtils.get_contents(this.led_file, out val);
                val = val.strip();
                if (val == "1") {
                    return "RU";
                } else if (val == "0") {
                    return "EN";
                }
            } catch (Error e) {}
        }

        // Fallback: ibus
        try {
            string stdout_buf;
            string stderr_buf;
            int exit_status;
            Process.spawn_command_line_sync("ibus engine", out stdout_buf, out stderr_buf, out exit_status);
            if (exit_status == 0) {
                var eng = stdout_buf.strip().down();
                if ("ru" in eng) {
                    return "RU";
                } else if ("us" in eng || "eng" in eng) {
                    return "EN";
                }
            }
        } catch (Error e) {}

        return this.current_layout;
    }

    private bool update_state() {
        string layout = this.get_layout();
        if (layout != this.current_layout) {
            this.current_layout = layout;
            if (layout == "RU") {
                this.label.set_markup("<span foreground='#3584e4' font_weight='bold' font_size='11pt'>RU</span>");
            } else {
                this.label.set_markup("<span font_weight='bold' font_size='11pt'>EN</span>");
            }
        }
        return true;
    }

    private void on_clicked() {
        try {
            string target = (this.current_layout == "EN") ? "xkb:ru::rus" : "xkb:us::eng";
            Process.spawn_command_line_async("ibus engine " + target);
        } catch (Error e) {}

        try {
            Process.spawn_command_line_async("wtype -M alt -k Shift_L -m alt");
        } catch (Error e) {}
    }

    public override void dispose() {
        if (this.timeout_id > 0) {
            Source.remove(this.timeout_id);
            this.timeout_id = 0;
        }
        base.dispose();
    }
}

public class KeyboardLayoutWaylandPlugin : Peas.ExtensionBase, Budgie.Plugin {
    public Budgie.Applet get_panel_widget(string uuid) {
        return new KeyboardLayoutWaylandApplet(uuid);
    }
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(KeyboardLayoutWaylandPlugin));
}
