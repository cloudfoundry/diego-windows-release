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
        public static Dictionary<string, string> Params()
        {
            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            var jsonString = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "parameters.json");
            var hash = javaScriptSerializer.Deserialize<Dictionary<string, string>>(jsonString);
            SetExternalIP(hash);
            SetMachineName(hash);
            return hash;
        }

        private static void SetExternalIP(Dictionary<string, string> p)
        {
            if (!p.ContainsKey("EXTERNAL_IP") || string.IsNullOrWhiteSpace(p["EXTERNAL_IP"]))
            {
                p["EXTERNAL_IP"] = findExternalIP();
            }
        }

        private static void SetMachineName(Dictionary<string, string> p)
        {
            if (!p.ContainsKey("MACHINE_NAME") || string.IsNullOrWhiteSpace(p["MACHINE_NAME"]))
            {
                p["MACHINE_NAME"] = Dns.GetHostName();
            }
        }

        private static string findExternalIP()
        {
            IPHostEntry host;
            string localIP = "";
            host = Dns.GetHostEntry(Dns.GetHostName());
            foreach (IPAddress ip in host.AddressList)
            {
                if (ip.AddressFamily == AddressFamily.InterNetwork)
                {
                    localIP = ip.ToString();
                }
            }
            return localIP;
        }

        private static void SetEtcdCluster(Dictionary<string, string> p)
        {
            if (!p.ContainsKey("ETCD_CLUSTER") || string.IsNullOrWhiteSpace(p["ETCD_CLUSTER"]))
            {
                var sslValues = new string[] {"ETCD_CERT_FILE", "ETCD_KEY_FILE", "ETCD_CA_FILE"};
                if (sslValues.All(keyName => p.ContainsKey(keyName) && !string.IsNullOrWhiteSpace(keyName)))
                {
                    p["ETCD_CLUSTER"] = "https://etcd.service.consul:4001";
                }
                else
                {
                    p["ETCD_CLUSTER"] = "http://etcd.service.consul:4001";
                }
            }
        }
    }
}
