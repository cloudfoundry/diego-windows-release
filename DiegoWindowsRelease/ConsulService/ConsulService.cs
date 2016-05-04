using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.ServiceProcess;
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

            var enableSSl = false;
            var caFile = "";
            var keyFile = "";
            var certFile = "";
            var encrypt = "";

            var sslKeys = new string[] {"CONSUL_CA_FILE", "CONSUL_AGENT_KEY_FILE", "CONSUL_AGENT_CERT_FILE"};
            if (sslKeys.All((x) => config.ContainsKey(x) && !string.IsNullOrWhiteSpace(config[x])))
            {
                /* ssl options */
                enableSSl = true;
                caFile = config["CONSUL_CA_FILE"];
                keyFile = config["CONSUL_AGENT_KEY_FILE"];
                certFile = config["CONSUL_AGENT_CERT_FILE"];
                encrypt = System.IO.File.ReadAllText(config["CONSUL_ENCRYPT_FILE"]);
            }

            var dataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "ConsulService");
            Directory.CreateDirectory(dataDir);

            var consulConfig = new
            {
                datacenter = "dc1",
                data_dir = dataDir,
                node_name = config["MACHINE_NAME"],
                server = false,
                ports = new { dns = 53 },
                domain = config["CONSUL_DOMAIN"],
                bind_addr = config["MACHINE_IP"],
                rejoin_after_leave = true,
                disable_remote_exec = true,
                disable_update_check = true,
                protocol = 2,

                verify_outgoing = enableSSl,
                verify_incoming = enableSSl,
                verify_server_hostname = enableSSl,
                ca_file = caFile,
                key_file = keyFile,
                cert_file = certFile,
                encrypt,

                start_join = consulIps,
                retry_join = consulIps
            };

            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            string jsonString = javaScriptSerializer.Serialize(consulConfig);
            var configDir = Config.ConfigDir("consul");
            Directory.CreateDirectory(configDir);
            File.WriteAllText(Path.Combine(configDir, "config.json"), jsonString);
        }

        protected override void OnStart(string[] args)
        {
            WriteConfigFile();
            process = new Process
            {
                StartInfo =
                {
                    FileName = "consul.exe",
                    Arguments = @"agent -config-dir="+Config.ConfigDir("consul"),
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
