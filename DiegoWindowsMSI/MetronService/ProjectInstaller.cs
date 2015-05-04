using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration.Install;
using System.ServiceProcess;

namespace MetronService
{
    [RunInstaller(true)]
    public partial class ProjectInstaller : System.Configuration.Install.Installer
    {
        public ProjectInstaller()
        {
            InitializeComponent();
        }

        protected override void OnBeforeInstall(IDictionary savedState)
        {
            base.OnBeforeInstall(savedState);
            var metronConfig = new
            {
                EtcdUrls = new List<string> { Context.Parameters["CF_ETCD_CLUSTER"] },
                EtcdMaxConcurrentRequests = 10,
                SharedSecret = Context.Parameters["LOGGREGATOR_SHARED_SECRET"],
                LegacyIncomingMessagesPort = 3456,
                DropsondeIncomingMessagesPort = 3457,
                Index = 0,
                Job = Context.Parameters["MACHINE_NAME"],
                VarzUser = "",
                VarzPass = "",
                VarzPort = 0,
                CollectorRegistrarIntervalMilliseconds = 60000,
                EtcdQueryIntervalMilliseconds = 5000,
                Zone = Context.Parameters["REDUNDANCY_ZONE"],
                LoggregatorLegacyPort = 3456,
                LoggregatorDropsondePort = 3457
            };
            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            string jsonString = javaScriptSerializer.Serialize(metronConfig);
            var configDir = System.IO.Path.GetFullPath(System.IO.Path.Combine(Context.Parameters["assemblypath"], "..", "metron"));
            System.IO.Directory.CreateDirectory(configDir);
            System.IO.File.WriteAllText(System.IO.Path.Combine(configDir, "config.json"), jsonString);
        }
        
        protected override void OnAfterInstall(IDictionary savedState)
        {
            using (ServiceController pc = new ServiceController(this.serviceInstaller.ServiceName))
            {
                pc.Start();
            }
        }

        protected override void OnCommitted(IDictionary savedState)
        {
            ServiceConfigurator.SetRecoveryOptions(this.serviceInstaller.ServiceName);
        }
    }
}
