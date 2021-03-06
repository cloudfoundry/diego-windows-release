﻿using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration.Install;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Web.Script.Serialization;
using Utilities;

namespace ConfigurationManager
{
    [RunInstaller(true)]
    public partial class ConfigurationManager : Installer
    {
        private const string eventSource = "Diego MSI Windows Features Installer";

        private readonly FileSystemAccessRule fileSystemAccessRule =
            new FileSystemAccessRule(new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null),
                FileSystemRights.FullControl, AccessControlType.Allow);

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

            var required = new List<string>
            {
                "CONSUL_DOMAIN",
                "CONSUL_IPS",
                "CF_ETCD_CLUSTER",
                "LOGGREGATOR_SHARED_SECRET",
                "REDUNDANCY_ZONE",
                "STACK",
                "MACHINE_IP",
                "REP_REQUIRE_TLS",
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
                "REP_CA_CERT_FILE",
                "REP_SERVER_CERT_FILE",
                "REP_SERVER_KEY_FILE",
                "METRON_CA_FILE",
                "METRON_AGENT_CERT_FILE",
                "METRON_AGENT_KEY_FILE",
                "MACHINE_NAME",
                "SYSLOG_HOST_IP",
                "SYSLOG_PORT"
            };

            foreach (string key in required)
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

            IEnumerable<string> presentOptional =
                optional.Where(key => Context.Parameters[key] != null && Context.Parameters[key] != "");
            List<string> keys = required.Concat(presentOptional).ToList();

            CreateDestination();
            CopyMiscellaneousFiles(keys);
            WriteParametersFile(keys);
        }

        private void CreateDestination()
        {
            Directory.CreateDirectory(Destination());
            var directorySecurity = new DirectorySecurity();
            directorySecurity.SetAccessRule(fileSystemAccessRule);
            Directory.SetAccessControl(Destination(), directorySecurity);
        }

        private void WriteParametersFile(IEnumerable<string> keys)
        {
            var parameters = new Dictionary<string, string>();
            foreach (string key in keys)
            {
                string value = Context.Parameters[key];
                if (key.EndsWith("_FILE"))
                {
                    value = DestinationFilename(value);
                }
                parameters.Add(key, value);
            }
            var javaScriptSerializer = new JavaScriptSerializer();
            string jsonString = javaScriptSerializer.Serialize(parameters);
            string configFile = DestinationFilename("parameters.json");
            File.WriteAllText(configFile, jsonString);
        }

        private void RemoveMiscellaneousFiles()
        {
            var javaScriptSerializer = new JavaScriptSerializer();
            string configFile = DestinationFilename("parameters.json");
            string content = File.ReadAllText(configFile);
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
            var fileSecurity = new FileSecurity();
            fileSecurity.SetAccessRule(fileSystemAccessRule);
            foreach (string key in keys.Where(x => x.EndsWith("_FILE")))
            {
                string path = Context.Parameters[key];
                string destFileName = DestinationFilename(path);
                File.Copy(path, destFileName, true);
                File.SetAccessControl(destFileName, fileSecurity);
            }
        }

        protected virtual string Destination()
        {
            return Config.ConfigDir();
        }

        private string DestinationFilename(string path)
        {
            string filename = Path.GetFileName(path);
            return Path.GetFullPath(Path.Combine(Destination(), filename));
        }
    }
}