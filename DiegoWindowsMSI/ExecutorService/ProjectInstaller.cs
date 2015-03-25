﻿using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration.Install;
using System.Linq;
using System.ServiceProcess;
using System.Threading.Tasks;

namespace ExecutorService
{
    [RunInstaller(true)]
    public partial class ProjectInstaller : System.Configuration.Install.Installer
    {
        public ProjectInstaller()
        {
            InitializeComponent();
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