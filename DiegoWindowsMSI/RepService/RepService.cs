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

        public RepService()
        {
            InitializeComponent();

            if (!EventLog.SourceExists(eventSource))
                EventLog.CreateEventSource(eventSource, "Application");
            EventLog.WriteEntry(eventSource, "Service Initializing", EventLogEntryType.Information, 0);
        }

        protected override void OnStart(string[] args)
        {
            var hash = Config.Params();

            Func<Dictionary<string, string>, string, string> tryGetKey = (d, s) => d.ContainsKey(s) ? d[s] : "";

            process = new Process
            {
                /*
 Usage of c:\dwm\bin\rep.exe:
  -bbsAddress="": Address to the BBS Server
  -cachePath="/tmp/cache": location to cache assets
  -cellID="": the ID used by the rep to identify itself to external systems - must be specified
  -communicationTimeout=10s: Timeout applied to all HTTP requests.
  -consulCluster="": comma-separated list of consul server URLs (scheme://ip:port)
  -containerInodeLimit=200000: max number of inodes per container
  -containerMaxCpuShares=0: cpu shares allocatable to a container
  -containerOwnerName="executor": owner name with which to tag containers
  -createWorkPoolSize=32: Number of concurrent create operations in garden
  -debugAddr="": host:port for serving pprof debugging info
  -deleteWorkPoolSize=32: Number of concurrent delete operations in garden
  -diskMB="auto": the amount of disk the executor has available in megabytes
  -etcdCaFile="": Location of the CA certificate for mutual auth
  -etcdCertFile="": Location of the client certificate for mutual auth
  -etcdCluster="http://127.0.0.1:4001": comma-separated list of etcd URLs (scheme://ip:port)
  -etcdKeyFile="": Location of the client key for mutual auth
  -evacuationPollingInterval=10s: the interval on which to scan the executor during evacuation
  -evacuationTimeout=10m0s: Timeout to wait for evacuation to complete
  -exportNetworkEnvVars=false: export network environment variables into container (e.g. CF_INSTANCE_IP, CF_INSTANCE_PORT)
  -gardenAddr="/tmp/garden.sock": network address for garden server
  -gardenNetwork="unix": network mode for garden server (tcp, unix)
  -healthCheckWorkPoolSize=64: Number of concurrent ping operations in garden
  -healthyMonitoringInterval=30s: interval on which to check healthy containers
  -listenAddr="0.0.0.0:1800": host:port to serve auction and LRP stop requests on
  -lockRetryInterval=5s: interval to wait before retrying a failed lock acquisition
  -lockTTL=10s: TTL for service lock
  -logLevel="info": log level: debug, info, error or fatal
  -maxCacheSizeInBytes=10737418240: maximum size of the cache (in bytes) - you should include a healthy amount of overhead
  -memoryMB="auto": the amount of memory the executor has available in megabytes
  -metricsWorkPoolSize=8: Number of concurrent metrics operations in garden
  -pollingInterval=30s: the interval on which to scan the executor
  -preloadedRootFS=map[]: List of preloaded RootFSes
  -pruneInterval=1m0s: amount of time during which a container can remain in the allocated state
  -readWorkPoolSize=64: Number of concurrent read operations in garden
  -rootFSProvider=[]: List of RootFS providers
  -sessionName="rep": consul session name
  -skipCertVerify=false: skip SSL certificate verification
  -tempDir="/tmp": location to store temporary assets
  -unhealthyMonitoringInterval=500ms: interval on which to check unhealthy containers
  -zone="": the availability zone associated with the rep
                 */
                StartInfo =
                {
                    FileName = "rep.exe",
                    // REMOVED //-rootFSProvider docker //-containerInodeLimit=200000
                    Arguments = " -etcdCluster=" + hash["ETCD_CLUSTER"] +
                                " -etcdCaFile=\"" + tryGetKey(hash, "ETCD_CA_FILE") + "\"" +
                                " -etcdCertFile=\"" + tryGetKey(hash, "ETCD_CERT_FILE") + "\"" +
                                " -etcdKeyFile=\"" + tryGetKey(hash, "ETCD_KEY_FILE") + "\"" +
                                " -bbsAddress=http://bbs.service" + Config.CONSUL_DNS_SUFFIX + ":8889" +
                                " -consulCluster=http://127.0.0.1:8500" +
                                " -debugAddr=0.0.0.0:17008" +
                                " -listenAddr=0.0.0.0:1800" +
                                " -preloadedRootFS=" + hash["STACK"] + ":/tmp/"+ hash["STACK"] +
                                " -cellID="+hash["MACHINE_NAME"] +
                                " -zone="+hash["REDUNDANCY_ZONE"] +
                                " -pollingInterval=30s" +
                                " -evacuationPollingInterval=10s" +
                                " -evacuationTimeout=600s" +
                                " -skipCertVerify=true" +
                                " -gardenNetwork=tcp" +
                                " -gardenAddr=127.0.0.1:9241" +
                                " -memoryMB=auto" +
                                " -diskMB=auto" +
                                " -containerMaxCpuShares=10000" +
                                " -cachePath=/c/tmp/executor/cache" +
                                " -maxCacheSizeInBytes=10000000000" +
                                " -exportNetworkEnvVars=true" +
                                " -healthyMonitoringInterval=30s" +
                                " -unhealthyMonitoringInterval=0.5s" +
                                " -createWorkPoolSize=32" +
                                " -deleteWorkPoolSize=32" +
                                " -readWorkPoolSize=64" +
                                " -metricsWorkPoolSize=8" +
                                " -healthCheckWorkPoolSize=64" +
                                " -tempDir=/c/tmp/executor/tmp" +
                                " -logLevel=debug",
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
