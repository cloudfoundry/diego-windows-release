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

            process = new Process
            {
                /*
                 *  -cellID="": the ID used by the rep to identify itself to external systems - must be specified
 -communicationTimeout=10s: Timeout applied to all HTTP requests.
 -consulCluster="": comma-separated list of consul server URLs (scheme://ip:port)
 -evacuationPollingInterval=10s: the interval on which to scan the executor during evacuation
 -evacuationTimeout=10m0s: Timeout to wait for evacuation to complete
 -executorURL="http://127.0.0.1:1700": location of executor to represent
 -heartbeatRetryInterval=5s: interval to wait before retrying a failed lock acquisition
 -listenAddr="0.0.0.0:1800": host:port to serve auction and LRP stop requests on
 -lockTTL=1m0s: TTL for service lock
 -logLevel="info": log level: debug, info, error or fatal
 -receptorTaskHandlerURL="http://127.0.0.1:1169": location of receptor task handler
 -rootFSProvider=[]: List of RootFS providers
                 */
                StartInfo =
                {
                    FileName = "rep.exe",
                    // REMOVED //-rootFSProvider docker //-containerInodeLimit=200000
                    Arguments = " -etcdCluster=" + hash["ETCD_CLUSTER"] +
                                " -consulCluster=http://127.0.0.1:8500" +
                                " -receptorTaskHandlerURL=http://receptor.service.consul:1169" +
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
                                " -allowPrivileged=false" +
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
