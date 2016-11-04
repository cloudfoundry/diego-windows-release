using System;
using System.Collections;
using System.Collections.Generic;
using System.Configuration.Install;
using System.IO;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Web.Script.Serialization;
using Ploeh.AutoFixture.Xunit2;
using Xunit;

namespace Tests
{
    public class TempDirectory
    {
        private readonly string path;

        public TempDirectory()
        {
            path = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
            Directory.CreateDirectory(path);
        }

        public override string ToString()
        {
            return path;
        }
    }

    public class ConfigurationManagerWithOverridableDestinationPath : ConfigurationManager.ConfigurationManager
    {
        public string destinationPath { get; set; }

        protected override string Destination()
        {
            return destinationPath;
        }

        public new void OnBeforeInstall(IDictionary savedState)
        {
            base.OnBeforeInstall(savedState);
        }
    }

    public class ConfigurationManagerTest : IDisposable
    {
        private readonly ConfigurationManagerWithOverridableDestinationPath configurationManager;
        private readonly TempDirectory sourceDirectory = new TempDirectory();
        private readonly TempDirectory tempDirectory = new TempDirectory();

        public ConfigurationManagerTest()
        {
            configurationManager = new ConfigurationManagerWithOverridableDestinationPath();
            configurationManager.destinationPath = tempDirectory.ToString();
        }

        public void Dispose()
        {
            Directory.Delete(tempDirectory.ToString(), true);
            Directory.Delete(sourceDirectory.ToString(), true);
        }

        [Theory, AutoData]
        public void ItPersistsArgumentsInFile(
            string consulDomain, string consulIps, Uri cfEtcdCluster, string loggregatorSharedSecret,
            string redundancyZone, string stack, string machineIp)
        {
            var context = new InstallContext();
            var consulEncryptFile = Path.Combine(sourceDirectory.ToString(), "encrypt_key");
            File.WriteAllText(consulEncryptFile, "content");

            context.Parameters.Add("CONSUL_DOMAIN", consulDomain);
            context.Parameters.Add("CONSUL_IPS", consulIps);
            context.Parameters.Add("CF_ETCD_CLUSTER", cfEtcdCluster.ToString());
            context.Parameters.Add("LOGGREGATOR_SHARED_SECRET", loggregatorSharedSecret);
            context.Parameters.Add("REDUNDANCY_ZONE", redundancyZone);
            context.Parameters.Add("STACK", stack);
            context.Parameters.Add("MACHINE_IP", machineIp);
            context.Parameters.Add("CONSUL_ENCRYPT_FILE", consulEncryptFile);
            context.Parameters.Add("REP_REQUIRE_TLS", false.ToString());
            configurationManager.Context = context;
            configurationManager.OnBeforeInstall(null);

            DirectorySecurity directoryAcl = Directory.GetAccessControl(tempDirectory.ToString());
            AuthorizationRuleCollection accessRules = directoryAcl.GetAccessRules(true, true,
                typeof (SecurityIdentifier));
            Assert.Equal(accessRules.Count, 1);
            var rule = (FileSystemAccessRule) accessRules[0];
            Assert.Equal(rule.AccessControlType, AccessControlType.Allow);
            Assert.Equal(new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null), rule.IdentityReference);
            Assert.Equal(rule.FileSystemRights, FileSystemRights.FullControl);

            FileSecurity fileAcl = File.GetAccessControl(Path.Combine(tempDirectory.ToString(), "encrypt_key"));
            accessRules = fileAcl.GetAccessRules(true, true, typeof (SecurityIdentifier));
            Assert.Equal(accessRules.Count, 1);
            rule = (FileSystemAccessRule) accessRules[0];
            Assert.Equal(rule.AccessControlType, AccessControlType.Allow);
            Assert.Equal(new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null), rule.IdentityReference);
            Assert.Equal(rule.FileSystemRights, FileSystemRights.FullControl);

            var javaScriptSerializer = new JavaScriptSerializer();
            string parametersPath = Path.Combine(tempDirectory.ToString(), "parameters.json");
            string jsonString = File.ReadAllText(parametersPath);
            var hash = javaScriptSerializer.Deserialize<Dictionary<string, string>>(jsonString);
            Assert.Equal(hash["CONSUL_DOMAIN"], consulDomain);
            Assert.Equal(hash["CONSUL_IPS"], consulIps);
            Assert.Equal(hash["CF_ETCD_CLUSTER"], cfEtcdCluster.ToString());
            Assert.Equal(hash["LOGGREGATOR_SHARED_SECRET"], loggregatorSharedSecret);
            Assert.Equal(hash["REDUNDANCY_ZONE"], redundancyZone);
            Assert.Equal(hash["STACK"], stack);
            Assert.Equal(hash["MACHINE_IP"], machineIp);
            Assert.Equal(hash["CONSUL_ENCRYPT_FILE"], Path.Combine(tempDirectory.ToString(), "encrypt_key"));
            Assert.Equal(hash["REP_REQUIRE_TLS"], false.ToString());
        }
    }
}