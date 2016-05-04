using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Utilities;

namespace ConfigurationManager
{
    [RunInstaller(true)]
    public partial class ConfigurationManager : System.Configuration.Install.Installer
    {
        private const string eventSource = "Diego MSI Windows Features Installer";

        public ConfigurationManager()
        {
            InitializeComponent();

            if (!EventLog.SourceExists(eventSource))
                EventLog.CreateEventSource(eventSource, "Application");
            EventLog.WriteEntry(eventSource, "Service Initializing", EventLogEntryType.Information, 0);
        }

        protected override void OnBeforeUninstall(IDictionary savedState)
        {
            RemoveMiscellaneousFiles();
            Directory.Delete(Destination(), true);
            base.OnBeforeUninstall(savedState);
        }

        protected override void OnBeforeInstall(IDictionary savedState)
        {
            base.OnBeforeInstall(savedState);

            var missing = new List<string>();

            var required = new List<string>()
            {
                "CONSUL_DOMAIN",
                "CONSUL_IPS",
                "CF_ETCD_CLUSTER",
                "LOGGREGATOR_SHARED_SECRET",
                "REDUNDANCY_ZONE",
                "STACK",
                "MACHINE_IP",
            };

            var optional = new List<string>
            {
                "CONSUL_ENCRYPT_FILE",
                "CONSUL_CA_FILE",
                "CONSUL_AGENT_CERT_FILE",
                "CONSUL_AGENT_KEY_FILE",
                "BBS_CA_FILE",
                "BBS_CLIENT_CERT_FILE",
                "BBS_CLIENT_KEY_FILE",
                "METRON_CA_FILE",
                "METRON_AGENT_CERT_FILE",
                "METRON_AGENT_KEY_FILE",
                "MACHINE_NAME",
                "SYSLOG_HOST_IP",
                "SYSLOG_PORT"
            };

            foreach (var key in required)
            {
                if (Context.Parameters[key] == null || Context.Parameters[key] == "")
                    missing.Add(key);
            }

            if (missing.Count > 0)
            {
                throw new Exception("Please provide all of the following msiexec properties: " +
                                    string.Join(", ", missing));
            }

            try
            {
                new Uri(Context.Parameters["CF_ETCD_CLUSTER"]);
            }
            catch (UriFormatException)
            {
                throw new Exception(
                    "CF_ETCD_CLUSTER values must be URIs (i.e. http://192.168.0.1:4001 instead of 192.168.0.1:4001).");
            }

            var presentOptional = optional.Where(key => Context.Parameters[key] != null && Context.Parameters[key] != "");
            var keys = required.Concat(presentOptional).ToList();
            CopyMiscellaneousFiles(keys);
            WriteParametersFile(keys);
        }

        private void WriteParametersFile(IEnumerable<string> keys)
        {
            var parameters = new Dictionary<string, string>();
            foreach (string key in keys)
            {
                var value = Context.Parameters[key];
                if (key.EndsWith("_FILE"))
                {
                    value = DestinationFilename(value);
                }
                parameters.Add(key, value);
            }
            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            string jsonString = javaScriptSerializer.Serialize(parameters);
            var configFile = DestinationFilename("parameters.json");
            File.WriteAllText(configFile, jsonString);
        }

        private void RemoveMiscellaneousFiles()
        {
            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            var configFile = DestinationFilename("parameters.json");
            var content = File.ReadAllText(configFile);
            var parameters = javaScriptSerializer.Deserialize<Dictionary<string, string>>(content);
            foreach (var p in parameters.Where(i => i.Key.EndsWith("_FILE")))
            {
                if (File.Exists(p.Value))
                {
                    File.Delete(p.Value);
                }
            }
        }

        private void CopyMiscellaneousFiles(IEnumerable<string> keys)
        {
            Directory.CreateDirectory(Destination());
            foreach (string key in keys.Where(x => x.EndsWith("_FILE")))
            {
                var path = Context.Parameters[key];
                File.Copy(path, DestinationFilename(path), true);
            }
        }
        private string Destination()
        {
            return Config.ConfigDir();
        }

        private string DestinationFilename(string path)
        {
            var filename = Path.GetFileName(path);
            return Path.GetFullPath(Path.Combine(Destination(), filename));
        }
    }
}