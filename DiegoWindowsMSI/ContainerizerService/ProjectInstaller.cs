using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration.Install;
using System.Linq;
using System.ServiceProcess;
using System.Threading.Tasks;

namespace ContainerizerService
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
            this.serviceProcessInstaller.Account = System.ServiceProcess.ServiceAccount.User;
            this.serviceProcessInstaller.Username = @".\" + Context.Parameters["ADMIN_USERNAME"];
            this.serviceProcessInstaller.Password = Context.Parameters["ADMIN_PASSWORD"];

            base.OnBeforeInstall(savedState);
        }

        protected override void OnAfterInstall(IDictionary savedState)
        {
            ServiceConfigurator.SetRecoveryOptions(this.serviceInstaller.ServiceName);
            using (ServiceController pc = new ServiceController(this.serviceInstaller.ServiceName))
            {
                pc.Start();
            }
        }
    }
}
