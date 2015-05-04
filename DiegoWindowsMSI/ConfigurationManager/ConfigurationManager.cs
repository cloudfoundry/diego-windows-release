using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;

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

        protected override void OnBeforeInstall(IDictionary savedState)
        {
            base.OnBeforeInstall(savedState);

            var missing = new List<string>();

            var required = new List<string>() {
                "ADMIN_USERNAME",
                "ADMIN_PASSWORD",
                "EXTERNAL_IP",
                "CONSUL_IPS",
                "ETCD_CLUSTER",
                "CF_ETCD_CLUSTER",
                "MACHINE_NAME",
                "LOGGREGATOR_SHARED_SECRET",
                "ZONE",
                "STACK"
            };

            foreach (var key in required) {
                if (Context.Parameters[key] == null || Context.Parameters[key] == "")
                    missing.Add(key);
            }

            if(missing.Count > 0) {
                throw new Exception("Please provide all of the following msiexec properties: " + string.Join(", ", missing));
            }

            try
            {
                new Uri(Context.Parameters["ETCD_CLUSTER"]);
                new Uri(Context.Parameters["CF_ETCD_CLUSTER"]);
            }
            catch (UriFormatException)
            {
                throw new Exception("ETCD_CLUSTER and CF_ETCD_CLUSTER values must be URIs (i.e. http://192.168.0.1:4001 instead of 192.168.0.1:4001).");
            }

            writePropertiesToFile(required);
        }

        private void writePropertiesToFile(List<string> keys)
        {
            var parameters = new Dictionary<string, string>();
            foreach (string key in keys.Where(x => x != "ADMIN_USERNAME"))
            {
                parameters.Add(key, Context.Parameters[key]);
            }
            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            string jsonString = javaScriptSerializer.Serialize(parameters);
            var configFile = System.IO.Path.GetFullPath(System.IO.Path.Combine(Context.Parameters["assemblypath"], "..", "parameters.json"));
            System.IO.File.WriteAllText(configFile, jsonString);
        }
    }
}

