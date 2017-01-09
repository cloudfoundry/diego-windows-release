using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using Utilities;

namespace RepService
{
    public partial class RepService : ServiceBase
    {
        private Process process;
        private const string eventSource = "Rep";
        internal const int RepPort = 1800;

        public RepService()
        {
            InitializeComponent();

            if (!EventLog.SourceExists(eventSource))
                EventLog.CreateEventSource(eventSource, "Application");
            EventLog.WriteEntry(eventSource, "Service Initializing", EventLogEntryType.Information, 0);
        }

        private string WriteConfigFile()
        {
            var hash = Config.Params();
            Func<Dictionary<string, string>, string, string> tryGetKey = (d, s) => d.ContainsKey(s) ? d[s] : "";

            var repConfig = new
            {
                dropsonde_port = 3457,
                consul_cluster = "http://127.0.0.1:8500",
                debug_address = "127.0.0.1:17008",
                listen_addr = "0.0.0.0:" + RepPort,
                listen_addr_securable = "0.0.0.0:1801",
                require_tls = (hash["REP_REQUIRE_TLS"] == "true"),
                ca_cert_file = tryGetKey(hash, "REP_CA_CERT_FILE"),
                server_cert_file = tryGetKey(hash, "REP_SERVER_CERT_FILE"),
                server_key_file = tryGetKey(hash, "REP_SERVER_KEY_FILE"),
                advertise_domain = "cell.service.cf.internal",
                enable_legacy_api_endpoints = true,
                preloaded_root_fs = new string[] {hash["STACK"] + ":/tmp/"+ hash["STACK"]},
                placement_tags = new string[] {},
                optional_placement_tags = new string[] {},
                cell_id = hash["MACHINE_NAME"],
                zone = hash["REDUNDANCY_ZONE"],
                polling_interval = "30s",
                evacuation_polling_interval = "10s",
                evacuation_timeout = "600s",
                skip_cert_verify = true,
                garden_network = "tcp",
                garden_addr = "127.0.0.1:9241",
                memory_mb = "auto",
                disk_mb = "auto",
                container_inode_limit = 200000,
                container_max_cpu_shares = 1,
                cache_path = Path.Combine(Path.GetTempPath(), "executor", "cache"),
                max_cache_size_in_bytes = 5000000000,
                export_network_env_vars = true,
                healthy_monitoring_interval = "30s",
                unhealthy_monitoring_interval = "0.5s",
                create_work_pool_size = 32,
                delete_work_pool_size = 32,
                read_work_pool_size = 64,
                metrics_work_pool_size = 8,
                healthcheck_work_pool_size = 64,
                max_concurrent_downloads = 5,
                temp_dir = Path.Combine(Path.GetTempPath(), "executor", "tmp"),
                log_level = "info",
                garden_healthcheck_interval = "10m",
                garden_healthcheck_timeout = "10m",
                garden_healthcheck_command_retry_pause = "1s",
                garden_healthcheck_process_path = Path.Combine(Environment.SystemDirectory, "cmd.exe"),
                garden_healthcheck_process_user = "vcap",
                volman_driver_paths = Config.ConfigDir("voldrivers"),
                bbs_ca_cert_file = tryGetKey(hash, "BBS_CA_FILE"),
                bbs_client_cert_file = tryGetKey(hash, "BBS_CLIENT_CERT_FILE"),
                bbs_client_key_file = tryGetKey(hash, "BBS_CLIENT_KEY_FILE"),
                bbs_api_url = hash["BBS_ADDRESS"],
                garden_healthcheck_process_args = new string[] { "/c","dir" },
            };

            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            string jsonString = javaScriptSerializer.Serialize(repConfig);
            var configDir = Config.ConfigDir("rep");
            Directory.CreateDirectory(configDir);
            var configPath = Path.Combine(configDir, "rep.json");
            File.WriteAllText(configPath, jsonString);
            return configPath;
        }

        protected override void OnStart(string[] args)
        {
            var configPath = WriteConfigFile();

            process = new Process
            {
                StartInfo =
                {
                    FileName = "rep.exe",
                    Arguments = @"-config="+configPath,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
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
