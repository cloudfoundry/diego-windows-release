using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;

public abstract class CommonService : System.Configuration.Install.Installer
{
    public override void Uninstall(System.Collections.IDictionary savedState)
    {
        try
        {
            base.Uninstall(savedState);
        }
        catch (Exception)
        {
        }
    }

    protected override void OnAfterInstall(System.Collections.IDictionary savedState)
    {
        ServiceConfigurator.SetRecoveryOptions(ServiceName());
        using (ServiceController pc = new ServiceController(ServiceName()))
        {
            pc.Start();
        }
    }

    public abstract string ServiceName();
}
