using System;
using System.Collections;
using System.ComponentModel;
using System.Diagnostics;
using System.Net;
using System.ServiceProcess;

namespace RepService
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

        protected override void OnBeforeUninstall(IDictionary savedState)
        {
            ServiceConfigurator.SetRecoveryOptions(this.serviceInstaller.ServiceName, ServiceConfigurator.SC_ACTION_NONE);
            var request = WebRequest.Create(String.Format("http://localhost:{0}/evacuate", RepService.RepPort));
            request.Method = "POST";
            var response = request.GetResponse();
            var statusCode = ((HttpWebResponse) response).StatusCode;
            if (statusCode != HttpStatusCode.Accepted)
            {
                throw new Exception("unexpected status code received while evacuating: " + statusCode);
            }
            var sw = new Stopwatch();
            sw.Start();
            while(true)
            {
                request = WebRequest.Create(String.Format("http://localhost:{0}/ping", RepService.RepPort));
                try
                {
                    request.GetResponse();
                }
                catch (WebException)
                {
                    break;
                }
                if (sw.ElapsedMilliseconds > 5 * 60 * 1000) break;
            }
            base.OnBeforeUninstall(savedState);
        }
    }
}
