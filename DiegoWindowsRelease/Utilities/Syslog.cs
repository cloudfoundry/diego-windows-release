using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Net.Sockets;
using System.Text;

namespace Utilities
{
    public class Syslog
    {
        const SyslogFacility Facility = SyslogFacility.Daemons;
        private const string EventSource = "InstallerSyslog";
        private readonly UdpClient udp;
        private readonly string prefix;

        public Syslog(string host, int port, string machineName, string sender)
        {
            udp = new UdpClient(host, port);
            prefix = machineName + " " + sender + ": ";
        }

        public static Syslog Build(Dictionary<string, string> p, string eventSource)
        {
            if (!p.ContainsKey("SYSLOG_HOST_IP") || !p.ContainsKey("SYSLOG_PORT"))
                return null;
            var port = SafeStringToInt(p["SYSLOG_PORT"]);
            if (p["SYSLOG_HOST_IP"].Length > 0 && port > 0)
            {
                try
                {
                    return new Syslog(p["SYSLOG_HOST_IP"], port, p["MACHINE_NAME"], eventSource);
                }
                catch (SocketException e)
                {
                   EventLog.WriteEntry(EventSource, String.Format("Failed to connect to syslog for service: {0}\r\n{1}", eventSource, e), EventLogEntryType.Error);
                }
            }
            return null;
        }
        public void Send(string message, SyslogSeverity priority)
        {
            var msg = Message(message, priority);
            udp.Send(msg, msg.Length);
        }

        private byte[] Message(string message, SyslogSeverity priority)
        {
            string timeString = new DateTime().ToString("MMM dd HH:mm:ss ");
            return Encoding.ASCII.GetBytes(Priority(priority) + timeString + prefix + message);
        }

        private string Priority(SyslogSeverity priority)
        {
            int calculatedPriority = (int)Facility * 8 + (int)priority;
            return "<" + calculatedPriority.ToString(CultureInfo.InvariantCulture) + ">";
        }

        private static int SafeStringToInt(string num)
        {
            try
            {
                return Convert.ToInt32(num);
            }
            catch (Exception)
            {
                return 0;
            }
        }
    }
}
