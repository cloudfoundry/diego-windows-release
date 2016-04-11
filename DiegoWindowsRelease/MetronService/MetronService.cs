using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using Utilities;

namespace MetronService
{

    public partial class MetronService : ServiceBase
    {
        private Process process;
        private const string eventSource = "Metron";

        public MetronService()
        {

            InitializeComponent();

            if (!EventLog.SourceExists(eventSource))
                EventLog.CreateEventSource(eventSource, "Application");
            EventLog.WriteEntry(eventSource, "Service Initializing", EventLogEntryType.Information, 0);
        }

        private void WriteConfigFile()
        {
            var hash = Config.Params();

            string preferredProtocol;
            object tlsConfig;

            var metronTlsKeys = new string[] { "METRON_CA_FILE", "METRON_AGENT_CERT_FILE", "METRON_AGENT_KEY_FILE" };
            if (metronTlsKeys.All(keyName => hash.ContainsKey(keyName) && !string.IsNullOrWhiteSpace(hash[keyName])))
            {
                preferredProtocol = "tls";
                tlsConfig = new
                {
                    KeyFile = hash["METRON_AGENT_KEY_FILE"],
                    CertFile = hash["METRON_AGENT_CERT_FILE"],
                    CAFile = hash["METRON_CA_FILE"],
                };
            }
            else
            {
                preferredProtocol = "udp";
                tlsConfig = null;
            }

            var metronConfig = new
            {
                EtcdUrls = new List<string> { hash["CF_ETCD_CLUSTER"] },
                EtcdMaxConcurrentRequests = 10,
                EtcdQueryIntervalMilliseconds = 5000,
                SharedSecret = hash["LOGGREGATOR_SHARED_SECRET"],
                DropsondeIncomingMessagesPort = 3457,
                Index = 0,
                Job = hash["MACHINE_NAME"],
                LoggregatorDropsondePort = 3457,
                PreferredProtocol = preferredProtocol,
                TLSConfig = tlsConfig,
                Deployment = "cf"
            };

            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            string jsonString = javaScriptSerializer.Serialize(metronConfig);
            var configDir = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "metron"));
            System.IO.Directory.CreateDirectory(configDir);
            System.IO.File.WriteAllText(System.IO.Path.Combine(configDir, "config.json"), jsonString);
        }

        protected override void OnStart(string[] args)
        {
            WriteConfigFile();
            process = new Process
            {
                StartInfo =
                {
                    FileName = "metron.exe",
                    Arguments = @"--config=metron\config.json",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    WorkingDirectory = AppDomain.CurrentDomain.BaseDirectory
                }
            };
            process.EnableRaisingEvents = true;
            process.Exited += process_Exited;

            var syslog = Syslog.Build(Config.Params(), eventSource);
            process.OutputDataReceived += (object sender, DataReceivedEventArgs e) =>
            {
                EventLog.WriteEntry(eventSource, e.Data, EventLogEntryType.Information, 0);
                if (syslog != null) syslog.Send(e.Data, SyslogSeverity.Informational);
            };
            process.ErrorDataReceived += (object sender, DataReceivedEventArgs e) =>
            {
                EventLog.WriteEntry(eventSource, e.Data, EventLogEntryType.Warning, 0);
                if (syslog != null) syslog.Send(e.Data, SyslogSeverity.Warning);
            };

            EventLog.WriteEntry(eventSource, "Starting", EventLogEntryType.Information, 0);
            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
        }

        void process_Exited(object sender, EventArgs e)
        {
            EventLog.WriteEntry(eventSource, "Exiting", EventLogEntryType.Error, 0);
            this.ExitCode = 0XDEAD;
            System.Environment.Exit(this.ExitCode);
        }

        protected override void OnStop()
        {
            base.OnStop();
            if (!process.HasExited)
            {
                process.Kill();
            }
        }
    }
}
