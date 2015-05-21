using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Utilities
{
    public enum SyslogFacility
    {
        Kernel = 0,
        User = 1,
        Mail = 2,
        Daemons = 3,
        Authorization = 4,
        Syslog = 5,
        Printer = 6,
        News = 7,
        Uucp = 8,
        Clock = 9,
        Authorization2 = 10,
        Ftp = 11,
        Ntp = 12,
        Audit = 13,
        Alert = 14,
        Clock2 = 15,
        Local0 = 16,
        Local1 = 17,
        Local2 = 18,
        Local3 = 19,
        Local4 = 20,
        Local5 = 21,
        Local6 = 22,
        Local7 = 23
    }

    public enum SyslogSeverity
    {
        Emergency = 0,
        Alert = 1,
        Critical = 2,
        Error = 3,
        Warning = 4,
        Notice = 5,
        Informational = 6,
        Debug = 7
    }
}
