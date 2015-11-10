using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Security.Policy;

namespace Utilities
{
    public class Config
    {
        public const string CONSUL_DNS_SUFFIX = ".cf.internal";

        public static Dictionary<string, string> Params()
        {
            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            var jsonString = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "parameters.json");
            var hash = javaScriptSerializer.Deserialize<Dictionary<string, string>>(jsonString);
            SetExternalIP(hash);
            SetMachineName(hash);
            SetBbsAddress(hash);
            return hash;
        }

        private static void SetExternalIP(Dictionary<string, string> p)
        {
            if (!p.ContainsKey("EXTERNAL_IP") || string.IsNullOrWhiteSpace(p["EXTERNAL_IP"]))
            {
                p["EXTERNAL_IP"] = findExternalIP(p["CONSUL_IPS"]);
            }
        }

        private static void SetMachineName(Dictionary<string, string> p)
        {
            if (!p.ContainsKey("MACHINE_NAME") || string.IsNullOrWhiteSpace(p["MACHINE_NAME"]))
            {
                p["MACHINE_NAME"] = Dns.GetHostName();
            }
        }

        private static string findExternalIP(string ips)
        {
            using (Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, 0))
            {
                socket.Connect(ips.Split(',')[0], 65530);
                var endPoint = socket.LocalEndPoint as IPEndPoint;
                return endPoint.Address.ToString();
            }
        }

        private static void SetBbsAddress(Dictionary<string, string> p)
        {
            var sslValues = new string[] { "BBS_CA_FILE", "BBS_CLIENT_CERT_FILE", "BBS_CLIENT_KEY_FILE" };
            if (sslValues.All(keyName => p.ContainsKey(keyName) && !string.IsNullOrWhiteSpace(p[keyName])))
            {
                p["BBS_ADDRESS"] = "https://bbs.service" + CONSUL_DNS_SUFFIX + ":8889";
            }
            else
            {
                p["BBS_ADDRESS"] = "http://bbs.service" + CONSUL_DNS_SUFFIX + ":8889";
            }
        }
    }
}
