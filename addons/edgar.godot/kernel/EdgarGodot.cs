using Godot;

[GlobalClass]
public partial class EdgarGodot : RefCounted
{
    const string KERNEL_PROXY_SETTING = "Edgar/kernel/edgar_kernel_proxy";
    const string EDGAR_YATI_PROXY_PATH = "res://addons/edgar.godot/proxy/yati/edgar_yati_proxy.gd";

    static GDScript _proxy;
    static string _cached_proxy_path = "";

    public static GDScript get_proxy()
    {
        var path = ProjectSettings.GetSetting(KERNEL_PROXY_SETTING, EDGAR_YATI_PROXY_PATH).AsString();

        if (_cached_proxy_path != path)
        {
            _cached_proxy_path = path;
            _proxy = ResourceLoader.Exists(path) ? GD.Load<GDScript>(path) : null;
        }

        return _proxy;
    }
}
