using System.Collections;
using System.ComponentModel;
using System.IO;

namespace MetronService
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

        protected override void OnAfterUninstall(IDictionary savedState)
        {
            base.OnAfterUninstall(savedState);
            var configDir = Path.Combine(Context.Parameters["assemblypath"], "..", "metron");
            Directory.Delete(configDir, true);
        }
    }
}
