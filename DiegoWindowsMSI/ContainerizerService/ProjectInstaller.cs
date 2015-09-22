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
    public partial class ProjectInstaller : CommonService
    {
        public ProjectInstaller()
        {
            InitializeComponent();
        }

        public override string ServiceName()
        {
            return this.serviceInstaller.ServiceName;
        }

        protected override void OnBeforeInstall(IDictionary savedState)
        {
            this.serviceProcessInstaller.Account = System.ServiceProcess.ServiceAccount.User;
            this.serviceProcessInstaller.Username = @".\" + Context.Parameters["ADMIN_USERNAME"];
            this.serviceProcessInstaller.Password = Context.Parameters["ADMIN_PASSWORD"];

            base.OnBeforeInstall(savedState);
        }
    }
}
