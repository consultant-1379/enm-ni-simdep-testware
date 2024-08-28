package com.ericsson.ci.simnet.test.operators;

import java.io.IOException;
import java.util.*;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.ericsson.ci.simnet.test.utils.HostHandler;
import com.ericsson.ci.simnet.test.utils.TafFileUtils;
import com.ericsson.ci.simnet.test.utils.ZipUtility;
import com.ericsson.cifwk.taf.data.DataHandler;
import com.ericsson.cifwk.taf.data.Host;
import com.ericsson.cifwk.taf.data.User;
import com.ericsson.cifwk.taf.data.UserType;
import com.ericsson.cifwk.taf.tools.cli.handlers.impl.RemoteObjectHandler;
import com.ericsson.cifwk.taf.tools.cli.CLICommandHelper;
import com.ericsson.cifwk.taf.data.Ports;
import com.google.inject.Singleton;
import com.ericsson.de.tools.cli.*;
import com.ericsson.cifwk.taf.data.HostType;

/**
 * @author qfatonu
 *
 */
@Singleton
public class NetsimHealthCheckExecutionOperator implements netsimHCScriptExecutionOperator {

    /** Remote host where scripts going to be executed */
    
   private static String serverName = DataHandler.getAttribute("serverName").toString();
  private static String hostAddress = serverName;
      private static  final String hostName = hostAddress;

    /** Remote file location in unix format */
    private static final String REMOTE_FOLDER_TAF_SCRIPTS_LOCATION = "/var/simnet/HC/enm-ni-simdep";

    /** Local folder for embedded scripts */
    private static final String LOCAL_FOLDER_SCRIPTS_LOCATION = "scripts";

    /** Local zip folder for zipped embedded scripts */
    private static final String LOCAL_FOLDER_ZIP_FILES_LOCATION = "zips";

    /** Regular expression search term to find jar file list in Jenkins */
    private static final String JENKINS_JAR_FILE_SEARCH_TERM = ".jar";

    /** Regular expression search term to find enm_ni_simdep jar file in Jenkins */
    private static final String JENKINS_ENM_NI_SIMDEP_JAR_FILE_SEARCH_TERM = "lib.*CXP9031884";

    /** Local zip file name for zipped embedded scripts */
    private static final String ZIP_FILE_NAME = "enm-ni-simdep.zip";

    /** Logging utility */
    private static final Logger logger = LoggerFactory.getLogger(NetsimHealthCheckExecutionOperator.class);

    /** Taf command handler instance */
    //private CLICommandHelper cliCmdHelper;
     private CliTool sshShell;
    /**
     * Constructs a NetsimHealthCheckExecutionOperator instance
     */
    public NetsimHealthCheckExecutionOperator() {
		String hostAddress = null;
        try {
            hostAddress = DataHandler.getAttribute("serverName").toString();
        } catch (final NullPointerException e) {
            logger.debug("HostSetup::noServerNames");
        }
        //cliCmdHelper = new CLICommandHelper(host);
		sshShell = CliTools.sshShell(hostAddress).withUsername("netsim").withPassword("netsim").build();
		 sshShell.close();
    }

    /**
     * Prepare prerequisite test execution environment before test execution start.
     *
     * @return true if initial setup is successful, otherwise false
     */
    public static boolean initialise() {
        String netsimBox = null;
        try {
            netsimBox = DataHandler.getAttribute("serverName").toString();
        } catch (final NullPointerException e) {
            logger.debug("HostSetup::noServerNames");
        }
        Boolean status = false;
		logger.debug("netsim Server is **************** :{}",hostAddress);
        try {
            // Setup cmd and file handlers
            //CLICommandHelper.DEFAULT_COMMAND_TIMEOUT_VALUE = 3600L * 4;
            //final CLICommandHelper sshShell = new CLICommandHelper(host);
			logger.debug("netsim Server is :{}",hostAddress);
			CliTool sshShell = CliTools.sshShell(hostAddress).withUsername("netsim").withPassword("netsim").build();

            try {
                status = setUpRemoteServerFolder(sshShell) && copyScriptsFolderToRemoteServer(sshShell)
                        && setUpRemoteFolderPermission(sshShell) && convertRemoteFolderFilesDosToUnix(sshShell);
            } finally {
                sshShell.close();
            }
        } catch (final Exception e) {
           logger.error("Attempt 1: Error occured while initialising the TAF env. \n", e);
        // Retry Mechanism for intialising TAF env with CLICommandHelper
        try {
                //final CLICommandHelper sshShell1 = new CLICommandHelper(host);
				 CliTool sshShell1 = CliTools.sshShell(hostAddress).withUsername("netsim").withPassword("netsim").build();
                try {
                     status = setUpRemoteServerFolder(sshShell1) && copyScriptsFolderToRemoteServer(sshShell1)
                             && setUpRemoteFolderPermission(sshShell1) && convertRemoteFolderFilesDosToUnix(sshShell1);
                } finally {
                     sshShell1.close();
                }
                } catch (final Exception e1) {
                      logger.error("Attempt 2: Error occured while initialising the TAF env. \n", e1);
                      try {
                          //final CLICommandHelper sshShell2 = new CLICommandHelper(host);
						  CliTool sshShell2 = CliTools.sshShell(hostAddress).withUsername("netsim").withPassword("netsim").build();
                          try {
                                status = setUpRemoteServerFolder(sshShell2) && copyScriptsFolderToRemoteServer(sshShell2)
                                        && setUpRemoteFolderPermission(sshShell2) && convertRemoteFolderFilesDosToUnix(sshShell2);
                          } finally {
                                sshShell2.close();
                          }
                      } catch (final Exception e2) {
                          logger.error("Attempt 3: Error occured while initialising the TAF env. \n",e2);
                      }

                 }
          }
        return status;
    }

    private static boolean setUpRemoteServerFolder(CliTool sshShell) {
        // Set up remote folder
        final String remoteFolderSetupOutput;
     
		sshShell = CliTools.sshShell(hostAddress).withUsername("root").withPassword("shroot").build();
		
        //sshShell.newHopBuilder().hop(user).build();
        CliCommandResult result = sshShell.execute("mkdir -v -p /var/simnet/HC/; chown -v netsim:netsim /var/simnet/HC/");
        final String changeOwnerSetupOutput = result.getOutput();
        logger.info("changeOwnerSetupOutput={}", changeOwnerSetupOutput);
        final int changeOwnerSetupCmdExitCode = result.getExitCode();
        logger.info("changeOwnerSetupCmdExitCode={} ", changeOwnerSetupCmdExitCode);
        //sshShell.close(); // close from the hop shell
        if (changeOwnerSetupCmdExitCode != 0) {
            return false;
        }

        //sshShell.newHopBuilder().hop(user).build();
        final String cmd01 = "rm -rf " + REMOTE_FOLDER_TAF_SCRIPTS_LOCATION + "; mkdir -p " + REMOTE_FOLDER_TAF_SCRIPTS_LOCATION;
		CliCommandResult result1 = sshShell.execute(cmd01);
        remoteFolderSetupOutput = result1.getOutput();
        logger.info("remoteFolderSetupOutput={}", remoteFolderSetupOutput);
        final int remoteFolderSetupCmd01ExitCode = result1.getExitCode();
        logger.info("remoteFolderSetupCmd01ExitCode={}", remoteFolderSetupCmd01ExitCode);
        if (remoteFolderSetupCmd01ExitCode != 0) {
            return false;
        }
        return true;
    }

    private static boolean copyScriptsFolderToRemoteServer(CliTool sshShell) {
		String hostAddress = null;
        try {
            hostAddress = DataHandler.getAttribute("serverName").toString();
        } catch (final NullPointerException e) {
            logger.debug("HostSetup::noServerNames");
        }
        final User user = new User();
        user.setUsername("root");
        user.setPassword("shroot");
		final Host host = new Host();
		final Map<Ports, String> ports = new HashMap<>();
		ports.put(Ports.SSH, Integer.toString(22));
		host.setIp(hostAddress);
	    host.setType(HostType.NETSIM);
		host.setPort(ports);
		sshShell = CliTools.sshShell(hostAddress).withUsername("root").withPassword("shroot").build();
        final RemoteObjectHandler remoteFileHandler = new RemoteObjectHandler(host, user);

        // Create a zip file to pack all the local scripts
        String zipFile;
        String localFolderScriptsLocation;
        String currentPath;
        try {

            final Path currentRelativePath = Paths.get("");
            currentPath = currentRelativePath.toAbsolutePath().toString();
            logger.debug("currentPath: {}", currentPath);

            if (Pattern.compile("testware").matcher(currentPath).find()) {
                zipFile = TafFileUtils.getNewFilePath(LOCAL_FOLDER_ZIP_FILES_LOCATION, ZIP_FILE_NAME);
                localFolderScriptsLocation = TafFileUtils.getFilePath(LOCAL_FOLDER_SCRIPTS_LOCATION);
                logger.debug("1-localFolderScriptsLocation: {}", localFolderScriptsLocation);

            } else {
                zipFile = TafFileUtils.getNewFilePath(currentPath, ZIP_FILE_NAME);

                // Search all jar files and return a file name contains lib and CXP9031884 words.
                final String simdepJarFile = TafFileUtils.getFilePath(JENKINS_JAR_FILE_SEARCH_TERM, JENKINS_ENM_NI_SIMDEP_JAR_FILE_SEARCH_TERM);
                logger.debug("simdepJarFile:{}", simdepJarFile);

                final String destUnzipFolderName = "ENM-NI-SIMDEP";
                final String destUnzipFolder = TafFileUtils.getNewFilePath(currentPath, destUnzipFolderName);
                logger.debug("destUnzipFolder: {}", destUnzipFolder);
                ZipUtility.unzip(simdepJarFile, destUnzipFolder);
                logger.debug("Unzipping completed for file: {} |", simdepJarFile);

                localFolderScriptsLocation = destUnzipFolder + "/scripts";
                logger.debug("1-localFolderScriptsLocation: {}", localFolderScriptsLocation);
            }
            logger.debug("zipFile: {}", zipFile);
            ZipUtility.zip(zipFile, localFolderScriptsLocation);

        } catch (final IOException e) {
            logger.error("Unable to to zip/unzip the file: ", e);
            return false;
        }

        // Copy local files to remote location
        try {
            logger.debug("Start copying zipFile:{} to remote server", zipFile);
            final boolean filesCopied = remoteFileHandler.copyLocalFileToRemote(zipFile, REMOTE_FOLDER_TAF_SCRIPTS_LOCATION, currentPath);
            logger.info("filesCopied={}", filesCopied);
            if (!filesCopied) {
                return false;
            }

        } catch (final Exception e) {
            logger.error("Unable to locate scripts path ", e);
            return false;
        }

        // Unzip the zip file remotely
        final String cmd02 = "whoami; cd " + REMOTE_FOLDER_TAF_SCRIPTS_LOCATION + "; unzip " + ZIP_FILE_NAME + "; unzip -t " + ZIP_FILE_NAME;
		CliCommandResult result = sshShell.execute(cmd02);
        final String unzipOutput = result.getOutput();

        logger.info("convertionOutput3={}", unzipOutput);
        final int unzipCmd02ExitCode = result.getExitCode();
        logger.info("unzipCmd02ExitCode={}", unzipCmd02ExitCode);

        if (unzipCmd02ExitCode != 0) {
            return false;
        }

        return true;
    }

    private static boolean setUpRemoteFolderPermission(CliTool sshShell) {
        // Set up the remote file||folder permissions under unix
        
		sshShell = CliTools.sshShell(hostAddress).withUsername("root").withPassword("shroot").build();
        final String cmd03 = "whoami; cd " + REMOTE_FOLDER_TAF_SCRIPTS_LOCATION + "; chmod -R +x * ";
       // logger.info("Switching to admin user {}", user.toString());
        //sshShell.newHopBuilder().hop(user).build();
        CliCommandResult result = sshShell.execute(cmd03);
        final String filePermissionSetupOutput = result.getOutput();
        logger.info("filePermissionSetupOutput={}", filePermissionSetupOutput);
        final int filePermissionSetupCmd03ExitCode = result.getExitCode();
        logger.info("filePermissionSetupCmd03ExitCode={}", filePermissionSetupCmd03ExitCode);
        // sshShell.close(); // close from the hop shell
        if (filePermissionSetupCmd03ExitCode != 0) {
            return false;
        }
        return true;
    }

    private static boolean convertRemoteFolderFilesDosToUnix(CliTool sshShell) {
        // Convert dos files into unix format on remote server
		
		sshShell = CliTools.sshShell(hostAddress).withUsername("root").withPassword("shroot").build();
        final String convertionOutput;
        final String cmd04 = "whoami ; cd " + REMOTE_FOLDER_TAF_SCRIPTS_LOCATION + "; perl -i -pe 's/\\r//g' `find . -print | egrep -i 'sh|pl|txt'`";
		CliCommandResult result = sshShell.execute(cmd04);
        convertionOutput = result.getOutput();
        logger.info("convertionOutput= {}", convertionOutput);
        final int convertionCmd04ExitCode = result.getExitCode();
        logger.info("convertionCmd04ExitCode = {}", convertionCmd04ExitCode);
        if (convertionCmd04ExitCode != 0) {
            return false;
        }
        return true;
    }

    @Override
	public int verifyScriptExecution(final String command) {

    //int exitcode;
    try {
    final int exitcode = performScripExecution(command);
	return exitcode;
	}catch(final Exception e1) {
		     if( e1 instanceof com.ericsson.cifwk.taf.tools.cli.jsch.JSchCLIToolException || e1 instanceof com.google.inject.ProvisionException || e1 instanceof  com.jcraft.jsch.JSchException ) {
				try { 
						logger.error("Error occured while executing command:{} \n", command);
						logger.error("Attempt 1: ssh connection to netsim VM lost", e1);
						logger.error("Retrying ssh connection to netsim VM \n");
              final int exitcode = performScripExecution(command);
				return exitcode;
				}catch(final Exception e2){
					if( e2 instanceof com.ericsson.cifwk.taf.tools.cli.jsch.JSchCLIToolException || e2 instanceof com.google.inject.ProvisionException || e2 instanceof  com.jcraft.jsch.JSchException  ) {
						try {
							logger.error("Error occured while executing command:{} \n", command);
							logger.error("Attempt 2: ssh connection to netsim VM lost", e2);
                                                        Thread.sleep(360000);
						       logger.error("Retrying ssh connection to netsim VM \n");
              final int exitcode = performScripExecution(command);
				return exitcode;
				}
				catch(final Exception e){
				
		            logger.error("Error occured while executing command:{} \n", command, e);
		            return Integer.MIN_VALUE;
		              }
					}
					else
			          {
				       logger.error("Error occured while executing command:{} \n", command, e2);
				       return Integer.MIN_VALUE;
			             }
	           }
			 }
			   
			   else
			   {
				  logger.error("Error occured while executing command:{} \n", command, e1);
				 return Integer.MIN_VALUE;
			   }				 
				}
		} 
    public int performScripExecution(final String command) {

        
		CliCommandResult result2;
        final String debugCommandsOutput;
        final String simdepRelease = DataHandler.getAttribute("simdep_release").toString();
		final CliTool sshShell = CliTools.sshShell(hostAddress).withUsername("root").withPassword("shroot").withDefaultTimeout(3600L * 4).build();
        String securityTLS;
            securityTLS = DataHandler.getAttribute("securityTLS").toString();
            if (securityTLS.isEmpty()) {
                securityTLS = "OFF";
            }
        String securitySL2;
        try {
            securitySL2 = DataHandler.getAttribute("securitySL2").toString();
            if (securitySL2.isEmpty()) {
                securitySL2 = "OFF";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default securitySL2=OFF");
            securitySL2 = "OFF";
        }
        String installType;
        try{
            installType = DataHandler.getAttribute("installType").toString();
            if (installType.isEmpty()) {
                 installType = "online";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default installType = online");
            installType = "online";
        }
        //try {
            //cliCmdHelper = new CLICommandHelper(host, user);

            if (logger.isDebugEnabled()) {
                final String debugCommands = "whoami";
                logger.debug("debugCommands to be executed: {}", debugCommands);
                if (!hostName.equals("UNKNOWN development-netsim") && !hostName.equals("UNKNOWN physical-or-vm-netsim")) {
                    result2 = sshShell.execute(debugCommands);
					debugCommandsOutput =  result2.getOutput();
                } else {
                    result2 = sshShell.execute(debugCommands);
					debugCommandsOutput =  result2.getOutput();
                }
                logger.debug("debugCommandsOutput: {}", debugCommandsOutput);
            }
            // workAround to relative path within script
            // if script has a relative path reference within script
            // it will fail due to script is checking reference where the
            // script is executed
            if (command.contains("/")) {
                String tmpCommand = command;
                if (command.contains(" ")) {
                    final int endIndex = command.indexOf(" ");
                    tmpCommand = command.substring(0, endIndex);
                }
                final int endIndex = tmpCommand.lastIndexOf("/");
                final String commandPath = tmpCommand.substring(0, endIndex);
                final String cdToScriptLocationCmd = "cd " + commandPath;
                logger.debug("cdToScriptLocationCmd to be executed: {}", cdToScriptLocationCmd);
                // To leave the current shell open, here, execute command is used.
                // Hence, the script will be executed from the commandPath rather than a relative path.
                // In others words, the initial location for the next command will be the commandPath
                result2 = sshShell.execute(cdToScriptLocationCmd);
                final String commandPathOutput = result2.getOutput();
                logger.debug("commandPathOutput: {}", commandPathOutput);
            }

            if (logger.isInfoEnabled() && command.contains("netsimHealthCheck.sh")) {
                logger.info("Command to be executed: {}", command.concat(securityTLS).concat(" ").concat(securitySL2).concat(" ").concat(simdepRelease).concat(" ").concat(installType));
                result2 = sshShell.execute(command.concat(securityTLS).concat(" ").concat(securitySL2).concat(" ").concat(simdepRelease).concat(" ").concat(installType));
            }
            else {
            logger.info("Command to be executed: {}", command);
            result2 = sshShell.execute(command);
            }
            final String output = result2.getOutput();
            logger.info("Command output: {}", output);

            final int exitCode = result2.getExitCode();
            logger.info("ExitCode:{}, command:\"{}\" ", exitCode, command);

            sshShell.close();

            return exitCode;

    }

    private String convertToPerlCmdArg(final String arg) {
        return arg.isEmpty() ? "\"\"" : arg;
    }
}
