# Developing Windows applications for Cloud Foundry 

When developing applications to run on Cloud Foundry for Windows, we recommend reading the Cloud Foundry [best practices](https://docs.cloudfoundry.org/devguide/deploy-apps/prepare-to-deploy.html) for designing Cloud-native applications.

These best practices include things like:

- Avoid Writing to the Local File System
- Cookies Accessible across Applications
- HTTP Sessions Not Persisted or Replicated
- HTTP Headers
- Port Limitations (do not specify a specific port)
- Cloud Foundry Updates and Your Application


Specific to Windows and .NET Applications, Cloud Foundry currently makes use of Windows 2012 R2 as its server. So applications must be designed to run on that platform (i.e. An application which will not run on Windows Server 2012 R2 is incompatible with the platform).


# How CF for Windows Works
In order to run .NET applications an isolated containers, Cloud Foundry utilizes the Windows [Hostable Web Core](https://msdn.microsoft.com/en-us/library/ms689327(v=vs.90).aspx) -- CF *does not* make use of Application Pools. The [WebAppServer](https://github.com/cloudfoundry/windows_app_lifecycle/tree/master/WebAppServer) project wraps your .NET application that implements the HWC API. Default [IIS configuration files](https://github.com/cloudfoundry/windows_app_lifecycle/tree/master/WebAppServer/Resources) are specified in this project and can be overriden on a per-app basis in the application's `Web.config` file.

When pushing an application, an ephemeral user account is created on the server, and the application is run in the context of that user. This is part of the security and permissions model. The implication here is that applications are run *as regular users*, so the platform does not support applications designed to run as a system service.

For more information on the implementation of containers and security for Cloud Foundry on Windows, engineers from the project put together a [blog post](http://engineering.pivotal.io/post/windows-containerization-deep-dive/) that offers a comparison to Linux containers.

# Types of Applications that run on the Platform

By default, CF on Windows will attempt to start an application in the HWC based on the presence of a `Web.config` file in the root directory of the project. If no Web.config is found, CF will fall back to looking for a executable in the root of the project.
The full logic for how to select and start a pushed application is [defined here](https://github.com/cloudfoundry/windows_app_lifecycle/blob/master/Builder/Program.cs#L15-L54).

Alternatively, any Windows application can be run using the [-c argument](http://docs.cloudfoundry.org/cf-cli/getting-started.html#push) to specify a "start command" for the application (e.g. `cf push APPNAME -c myWebServer.exe`) to bypass the default logic entirely.

Apps hosted by HWC (i.e. .NET applications) will automatically be configured to use the random port which is assigned by Cloud Foundry. However, if your application is not using HWC, it should read the appropriate `PORT` environment variable and bind to that port on startup. For more information on CF Environment Variables, see the [Cloud Foundry Documentation](https://docs.cloudfoundry.org/devguide/deploy-apps/environment-variable.html).

## Application Dependencies

It is highly recommended that any CF application be "bin deployable". This means that the app and all dependencies are included within the application folder that is being pushed. This is specifically called out as the [**Dependencies** factor](http://12factor.net/dependencies) of 12-Factor apps: _"A twelve-factor app never relies on implicit existence of system-wide packages."_


The default configuration for Windows servers for CF includes .NET 4.5, which **can** be relied upon as a system-wide package. Any other required libraries should be included in the application directory and referenced locally.

While 3rd party dependencies installed on the Cell by an operator are available to CF applications, this method is strongly discouraged as it makes effective maintenance of the CF cluster more difficult, and is a cloud-native anti-pattern.

CF on Windows does not automatically build or compile applications, so .NET applications are required to be [precompiled](https://msdn.microsoft.com/en-us/library/ms228015.aspx), which can be done either via the [ASP.NET Compilation Tool](https://msdn.microsoft.com/en-us/library/ms229863.aspx) or by publishing the project within Visual Studio. For non-.NET applications, binaries can be pushed directly.

## Handling state between application instances

If your ASP.NET application needs to store [session state](https://msdn.microsoft.com/en-us/library/75x4ha6s.aspx) and you plan to run multiple instances of your application, you will need to configure the [`machineKey`](https://msdn.microsoft.com/en-us/library/w8h3skw9(v=vs.100).aspx) attribute in your Web.config to be the same for all instances. 

# Logging and Cloud Foundry

As part of the standard configuration, Cloud Foundry will automatically aggregate and collect logs from all applications deployed to the platform centrally -- this component is known as [Loggregator](https://docs.pivotal.io/pivotalcf/devguide/deploy-apps/streaming-logs.html).

In order for your application's logs or output to be included in this log collection, it is expected that your output will be writtend to `STDOUT` and `STDERR`. While the Windows Event Viewer logs may be useful in debugging, they are not captured by the CF Loggregator component.



# Debugging Your Application
If your application is not starting when pushed to CF, there are a number of steps we recommend for diagnosing the issue. Disabling the health check via `cf set-health-check APPNAME none` is a first step that will let your app run despite failing health checks. 

If your application is showing only your ASP.NET error page, you can set the [customErrors element](https://msdn.microsoft.com/en-us/library/h0hfz6fc(v=vs.100).aspx) to 'off' in your Web.config file to allow your application to show stack traces to remote clients.
