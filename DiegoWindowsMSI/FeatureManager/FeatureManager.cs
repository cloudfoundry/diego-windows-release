using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;

namespace FeatureManager
{
    [RunInstaller(true)]
    public partial class FeatureManager : System.Configuration.Install.Installer
    {
        private const string eventSource = "Diego MSI Windows Features Installer";

        public FeatureManager()
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
                "CONTAINERIZER_USERNAME",
                "CONTAINERIZER_PASSWORD",
                "EXTERNAL_IP",
                "CONSUL_IPS",
                "ETCD_CLUSTER",
                "MACHINE_NAME",
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

            writePropertiesToFile(required);
        }

        private void writePropertiesToFile(List<string> keys)
        {
            var parameters = new Dictionary<string, string>();
            foreach (string key in keys.Where(x => x != "CONTAINERIZER_PASSWORD"))
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

