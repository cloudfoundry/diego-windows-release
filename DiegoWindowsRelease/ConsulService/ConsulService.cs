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

namespace ConsulService
{

    public partial class ConsulService : ServiceBase
    {
        private Process process;
        private const string eventSource = "Consul";

        public ConsulService()
        {

            InitializeComponent();

            if (!EventLog.SourceExists(eventSource))
                EventLog.CreateEventSource(eventSource, "Application");
            EventLog.WriteEntry(eventSource, "Service Initializing", EventLogEntryType.Information, 0);
        }

        private void WriteConfigFile()
        {
            var config = Config.Params();
            var consulIps = config["CONSUL_IPS"].Split(new string[] { ",", " " }, StringSplitOptions.RemoveEmptyEntries);

            var encryptKey = System.IO.File.ReadAllText(config["CONSUL_ENCRYPT_FILE"]);

            var consulConfig = new
            {
                datacenter = "dc1",
                data_dir = "/tmp",
                node_name = config["MACHINE_NAME"],
                server = false,
                ports = new { dns = 53 },
                domain = "cf.internal",
                bind_addr = config["EXTERNAL_IP"],
                rejoin_after_leave = true,
                disable_remote_exec = true,
                disable_update_check = true,
                protocol = 2, 

                /* ssl options */
                verify_outgoing = true,
                verify_incoming = true,
                verify_server_hostname = true,
                ca_file = config["CONSUL_CA_FILE"],
                key_file = config["CONSUL_AGENT_KEY_FILE"],
                cert_file = config["CONSUL_AGENT_CERT_FILE"],
                encrypt = encryptKey,

                start_join = consulIps,
                retry_join = consulIps
            };

            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            string jsonString = javaScriptSerializer.Serialize(consulConfig);
            var configDir = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "consul"));
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
                    FileName = "consul.exe",
                    Arguments = @"agent -config-dir=consul",
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
