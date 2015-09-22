using System;
using System.Collections;
using System.ComponentModel;
using System.Configuration.Install;
using System.ServiceProcess;

namespace ConsulService
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
    }
}
