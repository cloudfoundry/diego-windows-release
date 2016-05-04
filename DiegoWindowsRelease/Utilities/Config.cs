using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;

namespace Utilities
{
    public class Config
    {
        public static string ConfigDir()
        {
            return ConfigDir("");
        }

        public static string ConfigDir(string service)
        {
            return
                Path.GetFullPath(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData),
                    "DiegoWindows", service));
        }

        public static Dictionary<string, string> Params()
        {
            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            var parametersPath = Path.Combine(ConfigDir(), "parameters.json");
            var jsonString = File.ReadAllText(parametersPath);
            var hash = javaScriptSerializer.Deserialize<Dictionary<string, string>>(jsonString);
            SetMachineName(hash);
            SetBbsAddress(hash);
            return hash;
        }

        private static void SetMachineName(Dictionary<string, string> p)
        {
            if (!p.ContainsKey("MACHINE_NAME") || string.IsNullOrWhiteSpace(p["MACHINE_NAME"]))
            {
                p["MACHINE_NAME"] = Dns.GetHostName();
            }
        }

        private static void SetBbsAddress(Dictionary<string, string> p)
        {
            var sslValues = new string[] { "BBS_CA_FILE", "BBS_CLIENT_CERT_FILE", "BBS_CLIENT_KEY_FILE" };
            if (sslValues.All(keyName => p.ContainsKey(keyName) && !string.IsNullOrWhiteSpace(p[keyName])))
            {
                p["BBS_ADDRESS"] = "https://bbs.service." + p["CONSUL_DOMAIN"] + ":8889";
            }
            else
            {
                p["BBS_ADDRESS"] = "http://bbs.service." + p["CONSUL_DOMAIN"] + ":8889";
            }
        }
    }
}
