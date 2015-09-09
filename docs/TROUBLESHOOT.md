# Troubleshooting Failures

1. Check `cf logs` for failures

    Example log output:

    * When no `*.exe` or `Web.config` present

      ```
      2015-09-09T11:32:12.07-0400 [STG/0]      ERR No start command detected
      2015-09-09T11:32:30.96-0400 [APP/0]      ERR Unhandled Exception: System.InvalidOperationException: Cannot start process because a file name has not been provided.
      2015-09-09T11:32:30.96-0400 [APP/0]      ERR    at System.Diagnostics.Process.Start()
      2015-09-09T11:32:30.96-0400 [APP/0]      ERR    at System.Diagnostics.Process.Start(ProcessStartInfo startInfo)
      2015-09-09T11:32:30.96-0400 [APP/0]      ERR    at Launcher.Program.Main(String[] args) in c:\dwm\src\github.com\cloudfoundry-incubator\windows_app_lifecycle\Launcher\Program.cs:line 58
      2015-09-09T11:32:33.00-0400 [HEALTH/0]   OUT healthcheck failed
      ```

    * When `Web.config` present but missing a required `.dll`

      ```
      2015-09-09T11:04:43.66-0400 [HEALTH/0]   ERR Got error response: <!DOCTYPE html>
      2015-09-09T11:04:43.66-0400 [HEALTH/0]   ERR <html>
      2015-09-09T11:04:43.66-0400 [HEALTH/0]   ERR         <title>Could not load file or assembly 'Newtonsoft.Json, Version=6.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed' or one of its dependencies. The system cannot find the file specified.</title>
      ...
      ```
1. Add global `Application_Error` handler. See [example app](https://github.com/cloudfoundry-incubator/wats/blob/eb8b93eb4f50c41d1bcdc4c07a4e378a1aee0569/assets/nora/Nora/Global.asax.cs#L14-L21).
