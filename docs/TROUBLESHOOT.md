# Troubleshooting Failures

1. Use [hakim](https://github.com/cloudfoundry-incubator/hakim.git) to diagnose
   common installation issues. Compiled binaries are available in the releases
   of [diego-windows-release](https://github.com/cloudfoundry-incubator/diego-windows-release/releases).

1. Check `cf logs` for failures

    Example log output:

    * When no `*.exe` or `Web.config` present

      ```
    2015-12-02T10:55:27.04-0500 [APP/0]      ERR Could not determine a start command. Use the -c flag to 'cf push' to specify a custom start command.
      ```

    * When `Web.config` present but missing a required `.dll`

      ```
      2015-09-09T11:04:43.66-0400 [HEALTH/0]   ERR Got error response: <!DOCTYPE html>
      2015-09-09T11:04:43.66-0400 [HEALTH/0]   ERR <html>
      2015-09-09T11:04:43.66-0400 [HEALTH/0]   ERR         <title>Could not load file or assembly 'Newtonsoft.Json, Version=6.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed' or one of its dependencies. The system cannot find the file specified.</title>
      ...
      ```
1. Add global `Application_Error` handler. See [example app](https://github.com/cloudfoundry-incubator/wats/blob/eb8b93eb4f50c41d1bcdc4c07a4e378a1aee0569/assets/nora/Nora/Global.asax.cs#L14-L21).
