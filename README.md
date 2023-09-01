# Logik.io Integration with Salesforce Commerce Cloud

## Preconditions
This guide assumes the following in Salesforce:
- Commerce is enabled
- Logik.io Base Managed Package is installed
- System Administrator or similar access is available in order to perform the steps listed.

## Installing the Components to Salesforce
1. If it isn't already installed, download and install the Salesforce Command Line Interface (CLI) using the instructions here: https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm
2. Download and extract the *logik-b2b.zip* file, which contains the components used for the B2B integration.
   - On Windows, right click and select "*Extract All...*". Follow the prompts that appear on screen.
   - On Mac, double click the file and its contents will be extracted automatically in the same location.
3. Launch the program *Terminal* (on Mac or Linux) or *Powershell* (on Windows).
4. Use the change directory (cd) command to navigate to the unzipped directory. For example, if the files were extracted in the *Downloads* folder, type and enter the command "cd Downloads/logik-b2b".
   - For an in-depth guide to navigation using the command line, refer the following:
     - Windows: https://www.howtogeek.com/659411/how-to-change-directories-in-command-prompt-on-windows-10/
	 - Mac/Linux: https://www.macworld.com/article/221277/command-line-navigating-files-folders-mac-terminal.html
5. Type and enter the command "ls" and a list of files and folders in that directory will be returned. Included in the list should be the folder "*src*" and the file "*sfdx-project.json*", along with this README.
6. Run the command "sfdx auth:web:login --setalias *myOrg* -r *https://example-dev-ed.my.salesforce.com*"
   - Replace the URL following "-r " with the one that the Logik-B2B integration will be set up on.
   - The text following "--setalias " is a nickname that is used to identify and reference the correct Salesforce org (multiple Salesforce orgs can be connected to a single machine). The example "myOrg" will be used for the purposes of this guide; if using another alias here, be sure to use that same alias in the following steps.
7. The URL specified in the previous login command will be opened in the default browser. Log in and authorize the "Salesforce CLI" connected app.
8. In the command line, run the command "sfdx force:source:deploy -p src -u myOrg". After a few moments, the command line will return a confirmation message, "Deploy Succeeded."
9. (Optional) If the Salesforce org isn’t already open in a browser, it can be opened and logged in by running the command “sfdx force:org:open -u myOrg”.

## Post-Install Setup in Salesforce
Next steps depend on the type of integration with Logik: the pre-built Logik UI embedded on the product detail page, a REST API to consume, or both. To use the Logik's native UI, refer to "*iFrame Integration Setup*" in the *docs* folder. To use the REST API to add configurations to carts, refer to "*REST API Integration*", also in the *docs* folder.
