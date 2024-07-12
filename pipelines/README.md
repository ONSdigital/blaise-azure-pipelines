# Configure Blaise

Installs Blaise, installs database connector, opens ports on the VMs, sets up Blaise, and sets up the databases Blaise will use.

Note that the databases won't be setup again if their Blaise data interface file already exist on the management VM. This is because running the setup again will wipe any data on the database!

If the installed Blaise version differs from the version specified in the ENV_BLAISE_CURRENT_VERSION environment variable, the current Blaise version will be uninstalled, and the required version will be installed. The scripts will attempt to delete the dashboard IIS folders, as these can cause issues when changing versions. However, this process isn't always successful and may need to be done manually. Changing the Blaise version can sometimes result in the deletion of essential questionnaire files, such as BMIXs, which may need to be restored. Additionally, you will likely need to access Blaise Server Manager in admin mode to verify that the server roles are set correctly and re-commit them if necessary.

# Configure User Roles

When creating a new user role, ensure that the `root` permission is *NOT* given. This prevents the other permissions propagating.
