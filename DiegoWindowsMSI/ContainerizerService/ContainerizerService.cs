using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using Utilities;

namespace ContainerizerService
{
    public partial class ContainerizerService : ServiceBase
    {
        private Process process;
        private const string eventSource = "Containerizer";

        public ContainerizerService()
        {
            InitializeComponent();

            if (!EventLog.SourceExists(eventSource))
                EventLog.CreateEventSource(eventSource, "Application");
            EventLog.WriteEntry(eventSource, "Service Initializing", EventLogEntryType.Information, 0);
        }

        protected override void OnStart(string[] args)
        {
            var externalIp = Config.Params()["EXTERNAL_IP"];
            var syslog = Syslog.Build(Config.Params(), eventSource);
            process = new Process
            {
                StartInfo =
                {
                    FileName =  @"Containerizer.exe",
                    Arguments =  externalIp + " 1788",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                }
            };
            process.EnableRaisingEvents = true;
            process.Exited += process_Exited;

            process.OutputDataReceived += (object sender, DataReceivedEventArgs e) =>
            {
                EventLog.WriteEntry(eventSource, e.Data, EventLogEntryType.Information, 0);
                if(syslog != null) syslog.Send(e.Data, SyslogSeverity.Informational);
            };
            process.ErrorDataReceived += (object sender, DataReceivedEventArgs e) =>
            {
                EventLog.WriteEntry(eventSource, e.Data, EventLogEntryType.Warning, 0);
                if (syslog != null) syslog.Send(e.Data, SyslogSeverity.Warning);
            };

            EventLog.WriteEntry(eventSource, "Starting", EventLogEntryType.Information, 0);
            EventLog.WriteEntry(eventSource, ("Syslog is " + (syslog == null ? "NULL" : "ALIVE")), EventLogEntryType.Information, 0);

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
