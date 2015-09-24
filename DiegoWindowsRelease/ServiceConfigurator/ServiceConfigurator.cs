using System;
using System.Runtime.InteropServices;
using System.ServiceProcess;

public class ServiceConfigurator
{
    private const int SERVICE_CONFIG_FAILURE_ACTIONS = 0x2;
    private const int ERROR_ACCESS_DENIED = 5;

    /* sc_action constants */
    public const int SC_ACTION_NONE = 0;
    public const int SC_ACTION_RESTART = 1;
    private const int DELAY_IN_MILLISECONDS = 0;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct SERVICE_FAILURE_ACTIONS
    {
        public int dwResetPeriod;
        [MarshalAs(UnmanagedType.LPWStr)]
        public string lpRebootMsg;
        [MarshalAs(UnmanagedType.LPWStr)]
        public string lpCommand;
        public int cActions;
        public IntPtr lpsaActions;
    }

    [DllImport("advapi32.dll", EntryPoint = "ChangeServiceConfig2")]
    private static extern bool ChangeServiceFailureActions(IntPtr hService, int dwInfoLevel, [MarshalAs(UnmanagedType.Struct)] ref SERVICE_FAILURE_ACTIONS lpInfo);

    [DllImport("kernel32.dll")]
    private static extern int GetLastError();


    public static void SetRecoveryOptions(String serviceName, int action = SC_ACTION_RESTART, int pDaysToResetFailureCount = 0)
    {
        ServiceController svcController = new ServiceController(serviceName);
        IntPtr _ServiceHandle = svcController.ServiceHandle.DangerousGetHandle();

        int NUM_ACTIONS = 3;
        int[] arrActions = new int[NUM_ACTIONS * 2];
        int index = 0;
        arrActions[index++] = action;
        arrActions[index++] = DELAY_IN_MILLISECONDS;
        arrActions[index++] = action;
        arrActions[index++] = DELAY_IN_MILLISECONDS;
        arrActions[index++] = action;
        arrActions[index++] = DELAY_IN_MILLISECONDS;

        IntPtr tmpBuff = Marshal.AllocHGlobal(NUM_ACTIONS * 8);

        try
        {
            Marshal.Copy(arrActions, 0, tmpBuff, NUM_ACTIONS * 2);
            SERVICE_FAILURE_ACTIONS sfa = new SERVICE_FAILURE_ACTIONS();
            sfa.cActions = 3;
            sfa.dwResetPeriod = pDaysToResetFailureCount;
            sfa.lpCommand = null;
            sfa.lpRebootMsg = null;
            sfa.lpsaActions = new IntPtr(tmpBuff.ToInt32());

            bool success = ChangeServiceFailureActions(_ServiceHandle, SERVICE_CONFIG_FAILURE_ACTIONS, ref sfa);
            if (!success)
            {
                if (GetLastError() == ERROR_ACCESS_DENIED)
                    throw new Exception("Access denied while setting failure actions.");
                else
                    throw new Exception("Unknown error while setting failure actions.");
            }
        }
        finally
        {
            Marshal.FreeHGlobal(tmpBuff);
            tmpBuff = IntPtr.Zero;
        }
    }
}