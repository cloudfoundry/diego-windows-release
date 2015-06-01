## AWS

This document will go over the steps required to setup a windows cell
on AWS.

## Requirements:

- A working deployment of cf-release and diego-release using micro
  bosh on AWS. See [this document](https://github.com/cloudfoundry-incubator/diego-release)
  for more info on how to bootstrap the environment.

## Creating the windows cell

1. Open the AWS console, and click on EC2.
   ![aws](../README_images/aws.png)

1. Click on" Instances" in the EC2 home screen.
   ![ec2](../README_images/ec2.png)

1. Click on "Launch Instance" in the Instances screen.
   ![instances](../README_images/instances.png)

1. Select Microsoft Windows Server 2012 R2 Base.
   ![select ami](../README_images/select_ami.png)

1. Select an instance type. It's not especially important what size we
   choose. In this example, we will choose m3.xlarge. Then, click "next".
   ![instance type](../README_images/instance_type.png)

1. Select a network and subnet. The network should the same VPC we
   have our micro bosh deployed in.
   ![instance details](../README_images/instance_details.png)
   The subnet should be be the same mask as the ip address of the job
   running etcd. For example, if we run
   ```
   bosh vms
   ```
   , we get

   ```
   VMs total: 30
   Deployment `cf-greenhaus1-diego'

   Director task 975

   Task 975 done

   +--------------------+---------+---------------+------------+
   | Job/index          | State   | Resource Pool | IPs        |
   +--------------------+---------+---------------+------------+
   | brain_z1/0         | running | large_z1      | 10.10.5.72 |
   | cc_bridge_z1/0     | running | bridge_z1     | 10.10.5.76 |
   | cell_windows_z1/0  | running | large_z1      | 10.10.5.73 |
   | cell_z1/0          | running | large_z1      | 10.10.5.74 |
   | consul_z1/0        | running | medium_z1     | 10.10.5.11 |
   | etcd_z1/0          | running | medium_z1     | 10.10.5.10 |
   | route_emitter_z1/0 | running | small_z1      | 10.10.5.77 |
   +--------------------+---------+---------------+------------+

   VMs total: 7
   ```
   . The etcd_z1/0 job has an ip address of

   ```
   10.10.5.10
   ```
   , so our subnet should be

   ```
   10.10.5.0/24
   ```
   . Then, click "Configure Security Group".

1. Create a new security group that allows traffic from anywhere. This
   is not recommended for production deployments, but is sufficient
   for development purposes. Then, click "review and launch".
   ![instance type](../README_images/security_groups.png)

1. Click "Launch".
   ![launch](../README_images/launch.png)

1. You can select your existing "bosh" key pair, check the check box
   to acknowledge you have the private key, and click "Launch
   Instances".
   ![key pairs](../README_images/key_pair.png)

1. It will take a minute or two for the instance to launch.

1. When the instance is ready, right click on it (in the list of
   instances) and select "Get Windows Password".  You can either
   upload your private key file or copy its contents into the dialog.
   ![retrieve password](../README_images/retrieve_password.png)
   ![retrieved password](../README_images/retrieve_password2.png)

## Connecting to your windows cell

This step is optional, you'll need it if you will be manually
installing the msi on the windows cell. Since the windows cell is
inside a private subnet, you'll need SSH tunnelling in order to be
able to RDP to the VM.

1. Get the public IP of your bosh director, which you can find by
   searching for an instance named "micro".
   ![director ip address](../README_images/director_ip.png)

1. Get the private ip of the windows VM
   ![instance ip address](../README_images/instance_ip.png)

1. At the command line, enter `ssh -L 3389:INSTANCE_PRIVATE_IP:3389 vcap@DIRECTOR_IP`,
   for example `ssh -L 3389:10.10.5.80:3389 vcap@52.20.21.23`.

1. Open Microsoft Remote Desktop and create a new remote desktop with
   the same properties shown, with the password you retrieved earlier
   ![remote desktop](../README_images/remote_desktop.png)

1. Double click the remote desktop you just created to connect to
   it. You may see a certificate warning which you can ignore by clicking
   "Continue".
   ![certificate warning](../README_images/certificate_warning.png)


**NOTE** It may take a minute to connect the first time as Windows
sets up your user account.
