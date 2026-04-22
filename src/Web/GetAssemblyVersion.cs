using System.Reflection;

namespace Microsoft.eShopWeb.Web;

public static class MyAppVersion
{
    public static string GetAssemblyVersion()
    {
        return Assembly.GetExecutingAssembly()
                       .GetName()
                       .Version?
                       .ToString() ?? "0.0.0.0";
    }

    public static string GetDateTimeFromVersion()
    {
        var version = Assembly.GetExecutingAssembly()
                               .GetName()
                               .Version;

        if (version == null) return "Unknown";

        // Version is encoded as: Major.Minor.Build.Revision
        // Build = days since 2000-01-01, Revision = seconds since midnight / 2
        try
        {
            var buildDate = new DateTime(2000, 1, 1)
                .AddDays(version.Build)
                .AddSeconds(version.Revision * 2);
            return buildDate.ToString("yyyy-MM-dd HH:mm");
        }
        catch
        {
            return "Unknown";
        }
    }
}
