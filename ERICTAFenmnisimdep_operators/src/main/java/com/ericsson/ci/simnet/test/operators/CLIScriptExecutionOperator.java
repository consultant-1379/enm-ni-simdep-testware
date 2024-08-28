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
import com.ericsson.cifwk.taf.data.HostType;
import com.ericsson.cifwk.taf.data.User;
import com.ericsson.cifwk.taf.data.UserType;
import com.ericsson.cifwk.taf.tools.cli.handlers.impl.RemoteObjectHandler;
import com.ericsson.cifwk.taf.tools.cli.CLICommandHelper;
import com.ericsson.cifwk.taf.tools.http.HttpResponse;
import com.ericsson.cifwk.taf.tools.http.HttpTool;
import com.ericsson.de.tools.http.BasicHttpToolBuilder;
import com.ericsson.cifwk.taf.tools.http.constants.ContentType;
import com.google.inject.Singleton;
import com.ericsson.cifwk.taf.data.Ports;
import com.ericsson.cifwk.taf.tools.TargetHost;
import com.ericsson.de.tools.cli.CliCommandResult;
import com.ericsson.de.tools.cli.CliTool;
import com.ericsson.de.tools.cli.CliIntermediateResult;
import com.ericsson.de.tools.cli.CliTools;
import com.ericsson.de.tools.cli.*;
import com.ericsson.cifwk.meta.API;
import java.util.regex.Pattern;


/**
 * @author qfatonu
 *
 */
@Singleton
public class CLIScriptExecutionOperator implements ScriptExecutionOperator {
    
	/** Remote file location in unix format */
    private static final String REMOTE_FOLDER_TAF_SCRIPTS_LOCATION = "/var/simnet/enm-ni-simdep";

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
    private static final Logger logger = LoggerFactory.getLogger(CLIScriptExecutionOperator.class);

    /** Taf command handler instance */
      private CliTool sshShell;
	

    /**
     * Constructs a CLIScriptExecutionOperator instance
     */
    public CLIScriptExecutionOperator() {
		String hostAddress = null;
        try {
            hostAddress = DataHandler.getAttribute("serverName").toString();
        } catch (final NullPointerException e) {
            logger.debug("HostSetup::noServerNames");
	    hostAddress = "netsim";
        }

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
	    netsimBox = "netsim";
        }
	  String serverName = null;
        try {
            serverName = DataHandler.getAttribute("serverName").toString();
        } catch (final NullPointerException e) {
            logger.debug("HostSetup::noServerNames");
            serverName = "netsim";
        }
                String hostAddress = serverName;
                final String hostName = hostAddress;

        Boolean status = false;
		logger.debug("netsim Server is **************** :{}",hostAddress);
        try {
                // Setup cmd and file handlers
				   logger.debug("netsim Server is :{}",hostAddress);
                   CliTool sshShell = CliTools.sshShell(hostAddress).withUsername("netsim").withPassword("netsim").build();
                try {
                       status = setUpRemoteServerFolder(sshShell) && copyScriptsFolderToRemoteServer(sshShell)
                               && setUpRemoteFolderPermission(sshShell) && convertRemoteFolderFilesDosToUnix(sshShell);
                } finally {
                       sshShell.close();
                }
        }catch (final Exception e) {
                       logger.error("Attempt 1: Error occured while initialising the TAF env. \n", e);
                //Retry Mechanism for intialising TAF env with CLICommandHelper
                try {
					    logger.debug("netsim Server is :{}",hostAddress);
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
							  logger.debug("netsim Server is :{}",hostAddress);
                             CliTool sshShell2 = CliTools.sshShell(hostAddress).withUsername("netsim").withPassword("netsim").build();
                                 try { 
                                       status = setUpRemoteServerFolder(sshShell2) && copyScriptsFolderToRemoteServer(sshShell2)
                                                && setUpRemoteFolderPermission(sshShell2) && convertRemoteFolderFilesDosToUnix(sshShell2);
                                 } finally {
                                         sshShell2.close();
                                 }
                         } catch (final Exception e2) {
                                 logger.error("Attempt 3: Error occured while initialising the TAF env. \n",e2);
                           // Reset VM
                             try{
                                 HttpResponse result = resetVMApi(netsimBox);
                                 logger.info(result.getBody());
                                 logger.info("Sleep1: 6 min of sleep after triggering the reset of vm. \n");
                                 try {
                                   Thread.sleep(360000);
                                 } catch (final Exception se1) {
                                   logger.error("Error occured in sleep method. \n", se1);
                                 }              
                                 CliTool sshShell3 = CliTools.sshShell(hostAddress).withUsername("netsim").withPassword("netsim").build();
                                 try {
                                       status = setUpRemoteServerFolder(sshShell3) && copyScriptsFolderToRemoteServer(sshShell3)
                                                && setUpRemoteFolderPermission(sshShell3) && convertRemoteFolderFilesDosToUnix(sshShell3);
                                 } finally {
                                         sshShell3.close();
                                 }
                         } catch (final Exception e3) {
                                logger.error("Attempt 4: Error occured while initialising the TAF env. \n",e3);
                                try {
                                    CliTool sshShell4 = CliTools.sshShell(hostAddress).withUsername("netsim").withPassword("netsim").build();
                                    try {
                                        status = setUpRemoteServerFolder(sshShell4) && copyScriptsFolderToRemoteServer(sshShell4)
                                                && setUpRemoteFolderPermission(sshShell4) && convertRemoteFolderFilesDosToUnix(sshShell4);
                                    } finally {
                                            sshShell4.close();
                                    }
                                } catch (final Exception e4) {
                                       logger.error("Attempt 5: Error occured while initialising the TAF env. \n", e4);
                                       logger.info("Sleep2: 6 minutes of sleep.\n");
                                       try {
                                          Thread.sleep(360000);
                                       } catch (final Exception se2) {
                                          logger.error("Error occured in sleep method. \n", se2);
                                       }
                                       try {
                                           CliTool sshShell5 = CliTools.sshShell(hostAddress).withUsername("netsim").withPassword("netsim").build();
                                           try {
                                               status = setUpRemoteServerFolder(sshShell5) && copyScriptsFolderToRemoteServer(sshShell5)
                                                && setUpRemoteFolderPermission(sshShell5) && convertRemoteFolderFilesDosToUnix(sshShell5);
                                           } finally {
                                                   sshShell5.close();
                                           }
                                       } catch (final Exception e5) {
                                             logger.error("Attempt 6: Error occured while initialising the TAF env. \n", e5);
                                             logger.info("Sleep3: 6 minutes of sleep. \n");
                                             try { 
                                                 Thread.sleep(360000);
                                             } catch ( final Exception se3) {
                                                 logger.error("Error occured in sleep method. \n", se3);
                                             }
                                             try {
                                                 CliTool sshShell6 = CliTools.sshShell(hostAddress).withUsername("netsim").withPassword("netsim").build();
                                                 try {
                                                     status = setUpRemoteServerFolder(sshShell6) && copyScriptsFolderToRemoteServer(sshShell6)
                                                && setUpRemoteFolderPermission(sshShell6) && convertRemoteFolderFilesDosToUnix(sshShell6);
                                                 } finally {
                                                        sshShell6.close();
                                                 }
                                             } catch(final Exception e6) {
                                                 logger.error("Attempt 7: Error occured while initialising the TAF env. \n", e6);
                                                 logger.error("Error occured while connecting to server after resetting the server including 18 minutes of sleep. \n");
                                             }
                                         }
                                 }
                        }
                    }
               }       
        }
        return status;
   }
   public static HttpResponse resetVMApi(String netsimBox){
        final String HOST = "netsimvfarm.athtem.eei.ericsson.se";
        final int PORT = 8000;
        String uUid = "";
        String vCenterHost = "";
        // VM GET API
        HttpTool tool = BasicHttpToolBuilder.newBuilder(HOST).withPort(PORT).trustSslCertificates(true).build();
        HttpResponse response = tool.request().contentType(ContentType.APPLICATION_JSON).header("user", "administrator").body("").get("/search/".concat(netsimBox));
        tool.close();
        Map<String,String> myMap = new HashMap<String,String>();
        logger.info(response.getBody());
        String[] pairs = response.getBody().replaceAll("\\{", "").replaceAll("\\}", "").split(", \"");
        for (int i=0;i<pairs.length;i++) {
            String pair = pairs[i];
            String[] keyValue = pair.split("\":");
            myMap.put(keyValue[0], keyValue[1]);
        }
        uUid = myMap.get("instanceUUID").replaceAll("\"", "").trim();
        vCenterHost = myMap.get("vCenterHost").replaceAll("\"", "").trim();
        logger.info("Uuid is "+ uUid +" and vfarmHost is " + vCenterHost);
        // VM REST API
        tool = BasicHttpToolBuilder.newBuilder(HOST).withPort(PORT).trustSslCertificates(true).build();
        response = tool.request().contentType(ContentType.APPLICATION_JSON).header("user","administrator").header("vcenterhost",vCenterHost).post("/vm/".concat(uUid).concat("/reset"));
        tool.close();
        return response;
    }

    private static boolean setUpRemoteServerFolder(CliTool sshShell) {
        // Set up remote folder
        final String remoteFolderSetupOutput;
	  String serverName = null;
        try {
            serverName = DataHandler.getAttribute("serverName").toString();
        } catch (final NullPointerException e) {
            logger.debug("HostSetup::noServerNames");
            serverName = "netsim";
        }
                String hostAddress = serverName;
                final String hostName = hostAddress;

        sshShell = CliTools.sshShell(hostAddress).withUsername("root").withPassword("shroot").build();
        CliCommandResult result = sshShell.execute("mkdir -v -p /var/simnet/; chown -v netsim:netsim /var/simnet");
        final String changeOwnerSetupOutput = result.getOutput();
        logger.info("changeOwnerSetupOutput={}", changeOwnerSetupOutput);
        final int changeOwnerSetupCmdExitCode = result.getExitCode();
        logger.info("changeOwnerSetupCmdExitCode={} ", changeOwnerSetupCmdExitCode);
        //sshShell.disconnect(); // disconnect from the hop shell
        if (changeOwnerSetupCmdExitCode != 0) {
            return false;
        }

         final String cmd01 = "rm -rf " + REMOTE_FOLDER_TAF_SCRIPTS_LOCATION + "; mkdir -p " + REMOTE_FOLDER_TAF_SCRIPTS_LOCATION;
        //remoteFolderSetupOutput 
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
	    hostAddress = "netsim";
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
		logger.debug("remoteFileHandler  is: {}", remoteFileHandler);
		

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
          String serverName = null;
        try {
            serverName = DataHandler.getAttribute("serverName").toString();
        } catch (final NullPointerException e) {
            logger.debug("HostSetup::noServerNames");
            serverName = "netsim";
        }
                String hostAddress = serverName;
                final String hostName = hostAddress;

        sshShell = CliTools.sshShell(hostAddress).withUsername("root").withPassword("shroot").build();
        final String cmd03 = "whoami; cd " + REMOTE_FOLDER_TAF_SCRIPTS_LOCATION + "; chmod -R +x * ";
        CliCommandResult result = sshShell.execute(cmd03);
        final String filePermissionSetupOutput = result.getOutput();
        logger.info("filePermissionSetupOutput={}", filePermissionSetupOutput);
        final int filePermissionSetupCmd03ExitCode = result.getExitCode();
        logger.info("filePermissionSetupCmd03ExitCode={}", filePermissionSetupCmd03ExitCode);
        // sshShell.disconnect(); // disconnect from the hop shell
        if (filePermissionSetupCmd03ExitCode != 0) {
            return false;
        }
        return true;
    }

    private static boolean convertRemoteFolderFilesDosToUnix(CliTool sshShell) {
        // Convert dos files into unix format on remote server
	  String serverName = null;
        try {
            serverName = DataHandler.getAttribute("serverName").toString();
        } catch (final NullPointerException e) {
            logger.debug("HostSetup::noServerNames");
            serverName = "netsim";
        }
                String hostAddress = serverName;
                final String hostName = hostAddress;

	sshShell = CliTools.sshShell(hostAddress).withUsername("root").withPassword("shroot").build();
        final String convertionOutput;
        final String cmd04 = "whoami ; cd " + REMOTE_FOLDER_TAF_SCRIPTS_LOCATION + "; perl -i -pe 's/\\r//g' `find . -print | egrep -i 'sh|pl|txt'`";
	sshShell = CliTools.sshShell(hostAddress).withUsername("root").withPassword("shroot").build();
	CliCommandResult result = sshShell.execute(cmd04);
        convertionOutput = result.getOutput();
        logger.info("convertionOutput= {}", convertionOutput);
        final int convertionCmd04ExitCode =  result.getExitCode();
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
		     if( e1 instanceof com.ericsson.cifwk.taf.tools.cli.jsch.JSchCLIToolException || e1 instanceof com.google.inject.ProvisionException  || e1 instanceof com.jcraft.jsch.JSchException ) {
				try {
						logger.error("Error occured while executing command:{} \n", command);
						logger.error("Attempt 1: ssh connection to netsim VM  lost", e1);
						logger.error("Retrying ssh connection to netsim VM \n");
              final int exitcode = performScripExecution(command);
				return exitcode;
				}catch(final Exception e2){
					if( e2 instanceof com.ericsson.cifwk.taf.tools.cli.jsch.JSchCLIToolException || e2 instanceof com.google.inject.ProvisionException || e2 instanceof com.jcraft.jsch.JSchException ) { 
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
	  String serverName = null;
        try {
            serverName = DataHandler.getAttribute("serverName").toString();
        } catch (final NullPointerException e) {
            logger.debug("HostSetup::noServerNames");
            serverName = "netsim";
        }
                String hostAddress = serverName;
                final String hostName = hostAddress;

        final String debugCommandsOutput;
        String simLTE = "";
        String simWRAN = "";
        String simCORE = "";
        final String netsimParam = DataHandler.getAttribute("version").toString().trim();
        final String force = DataHandler.getAttribute("force").toString().trim();
        final String simdepRelease = DataHandler.getAttribute("simdep_release").toString();
        final String simPath = DataHandler.getAttribute("simPath").toString();
        final String deploymentType = DataHandler.getAttribute("deploymentType").toString();
        final String serverType = DataHandler.getAttribute("serverType").toString();
        final String patchMode = DataHandler.getAttribute("patchMode").toString();
	final CliTool sshShell = CliTools.sshShell(hostAddress).withUsername("root").withPassword("shroot").withDefaultTimeout(3600L * 4).build();

        String netsimPatchRelease;
        try {
            netsimPatchRelease = DataHandler.getAttribute("netsimPatchRelease").toString();
            if (netsimPatchRelease.isEmpty()) {
                netsimPatchRelease = simdepRelease;
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default netsimPatchRelease={}", simdepRelease);
            netsimPatchRelease = simdepRelease;
        }
        String ciPortal;
        try {
            ciPortal = DataHandler.getAttribute("ciPortal").toString();
            if (ciPortal.isEmpty()) {
                ciPortal = "no";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default ciPortal=no");
            ciPortal = "no";
        }
        String firstServer;
        try {
            firstServer = DataHandler.getAttribute("firstServer").toString();
            if (firstServer.isEmpty()) {
                 firstServer = "netsim";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default firstServer=netsim");
            firstServer = "netsim";
        }
        String Execute;
        try {
            Execute = DataHandler.getAttribute("Execute").toString();
            if (Execute.isEmpty()) {
                 Execute = "NotPassed";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default Execute=NotPassed");
            Execute = "NotPassed";
        }
        String IPV6Per;
        try{
            IPV6Per = DataHandler.getAttribute("IPV6Per").toString();
            if (IPV6Per.isEmpty()) {
                 IPV6Per = "yes";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default IPV6Per = yes");
            IPV6Per = "yes";
        }
        String rolloutType;
        try{
            rolloutType = DataHandler.getAttribute("rolloutType").toString();
            if (rolloutType.isEmpty()) {
                 rolloutType = "normal";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default rolloutType = normal");
            rolloutType = "normal";
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
        String securityTLS;
        try {
            securityTLS = DataHandler.getAttribute("securityTLS").toString();
            if (securityTLS.isEmpty()) {
                securityTLS = "OFF";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default securityTLS=OFF");
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

        String docker;
        try {
            docker = DataHandler.getAttribute("docker").toString();
            if (docker.isEmpty()) {
                docker = "no";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default docker=no");
            docker = "no";
        }
	String image_build;
        try {
            image_build = DataHandler.getAttribute("image_build").toString();
            if (image_build.isEmpty()) {
                image_build = "no";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default image_build=no");
            image_build = "no";
        }
       String switchToRv;
        try {
            switchToRv = DataHandler.getAttribute("switchToRv").toString();
            if (switchToRv.isEmpty()) {
                switchToRv = "no";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default switchToRv=no");
            switchToRv = "no";
        }
        String patchLink; 
        try {
            patchLink = DataHandler.getAttribute("patchLink").toString();
            if (patchLink.isEmpty()){
                patchLink = "null";
            }
        } catch  (final NullPointerException npe) {
            logger.debug("Switch to default patchLink=null");
            patchLink = "null";
        }
        String deltaContent;
        try {
            deltaContent = DataHandler.getAttribute("deltaContent").toString();
            if (deltaContent.isEmpty()) {
                switchToRv = "null";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default deltaContent=null");
            deltaContent = "null";
        }
        String ConfigType;
        try {
            ConfigType = DataHandler.getAttribute("ConfigType").toString();
            if (ConfigType.isEmpty()) {
                ConfigType = "NotPassed";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default ConfigType=NotPassed");
            ConfigType = "NotPassed";
        }
        String Number_Of_BSC_Nodes;
        try {
            Number_Of_BSC_Nodes = DataHandler.getAttribute("Number_Of_BSC_Nodes").toString();
            if (Number_Of_BSC_Nodes.isEmpty()) {
                Number_Of_BSC_Nodes = "NotPassed";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default Number_Of_BSC_Nodes=NotPassed");
            Number_Of_BSC_Nodes = "NotPassed";
        }
        String Number_Of_LTE_Nodes;
        try {
            Number_Of_LTE_Nodes = DataHandler.getAttribute("Number_Of_LTE_Nodes").toString();
            if (Number_Of_LTE_Nodes.isEmpty()) {
                Number_Of_LTE_Nodes = "NotPassed";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default Number_Of_LTE_Nodes=NotPassed");
            Number_Of_LTE_Nodes = "NotPassed";
        }
        String TlsMode;
        try {
            TlsMode = DataHandler.getAttribute("TlsMode").toString();
            if (TlsMode.isEmpty()) {
                TlsMode = "NotPassed";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default TlsMode=NotPassed");
            TlsMode = "NotPassed";
        }
        String AuthenticationDelay;
        try {
            AuthenticationDelay = DataHandler.getAttribute("AuthenticationDelay").toString();
            if (AuthenticationDelay.isEmpty()) {
                AuthenticationDelay = "NotPassed";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default AuthenticationDelay=NotPassed");
            AuthenticationDelay = "NotPassed";
        }
        String CLUSTER_ID;
        try {
            CLUSTER_ID = DataHandler.getAttribute("CLUSTER_ID").toString();
            if (CLUSTER_ID.isEmpty()) {
                CLUSTER_ID = "NotPassed";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default CLUSTER_ID=NotPassed");
            CLUSTER_ID = "NotPassed";
        }
        String Deployment;
        try {
            Deployment = DataHandler.getAttribute("Deployment").toString();
            if (Deployment.isEmpty()) {
                Deployment = "NotPassed";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default Deployment=NotPassed");
            Deployment = "NotPassed";
        }
        String ENM_URL;
        try {
            ENM_URL = DataHandler.getAttribute("ENM_URL").toString();
            if (ENM_URL.isEmpty()) {
                ENM_URL = "";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default ENM_URL=");
            ENM_URL = "";
        }
        String csvlink;
        try {
            csvlink = DataHandler.getAttribute("csvlink").toString();
            if (csvlink.isEmpty()) {
                csvlink = "null";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default csvlink=null");
            csvlink = "null";
        }
        String nssProductSetVersion;
        try {
            nssProductSetVersion = DataHandler.getAttribute("nssProductSetVersion").toString();
            if (nssProductSetVersion.isEmpty()) {
                nssProductSetVersion = "null";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default nssProductSetVersion=null");
            nssProductSetVersion = "null";
        }
        String Adaptive;
        try {
            Adaptive = DataHandler.getAttribute("Adaptive").toString();
            if (Adaptive.isEmpty()) {
                Adaptive = "no";
            }
        } catch (final NullPointerException npe) {
            logger.debug("Switch to default Adaptive=no");
            Adaptive = "no";
        }

        simLTE = convertToPerlCmdArg(DataHandler.getAttribute("simLTE").toString());
        simWRAN = convertToPerlCmdArg(DataHandler.getAttribute("simWRAN").toString());
        simCORE = convertToPerlCmdArg(DataHandler.getAttribute("simCORE").toString());
        String simdepParam = "";
        //try {

            if (logger.isDebugEnabled()) {
                final String debugCommands = "whoami";
                logger.debug("debugCommands to be executed: {}", debugCommands);
                //if (!hostName.equals("UNKNOWN development-netsim") && !hostName.equals("UNKNOWN physical-or-vm-netsim")) { 
		result2 = sshShell.execute(debugCommands);
		debugCommandsOutput =  result2.getOutput();
               // } else { 
	
                //}
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
		int exitCode = result2.getExitCode();
		logger.debug("exitCode: {}", exitCode );
                final String commandPathOutput = result2.getOutput();
                logger.debug("commandPathOutput: {}", commandPathOutput);
		String pwdCommand = "pwd";
		result2 = sshShell.execute(pwdCommand);
		final String commandPathOutput2 = result2.getOutput();
		logger.debug("commandPathOutput2: {}", commandPathOutput2);
            }

            if (command.contains("perlCount.pl")) {
                logger.info("Command to be executed: {}", command.concat("n ").concat(serverType).concat(" ").concat(installType).concat(" ").concat(rolloutType));
                result2 = sshShell.execute(command.concat("n ").concat(serverType).concat(" ").concat(installType).concat(" ").concat(rolloutType));
            } else if (command.contains("netsim_install") && command.contains("master.sh")) {
		//result2 = sshShell.execute("cd /var/simnet/enm-ni-simdep/scripts/netsim_install/bin/");
                logger.info("netsimParam is  " + netsimParam);
                if (command.contains("-c no")) {
                    logger.info("Taking back up of start_all_simnes.sh script");
                     result2 = sshShell.execute("yes | cp /netsim/inst/bin/start_all_simne.sh /netsim/start_all_simne.sh");
                }
                logger.info("Command to be executed: {}", command.concat("-v ").concat(netsimParam).concat(" -f ").concat(force).concat(" -n ")
                    .concat(patchMode).concat(" -s ").concat(netsimPatchRelease).concat(" -e ").concat(ciPortal).concat(" -i ").concat(installType).concat(" -g ").concat(rolloutType));
                result2 = sshShell.execute(command.concat("-v ").concat(netsimParam).concat(" -f ").concat(force).concat(" -n ").concat(patchMode)
                    .concat(" -s ").concat(netsimPatchRelease).concat(" -e ").concat(ciPortal).concat(" -i ").concat(installType).concat(" -g ").concat(rolloutType));
            } else if (command.contains("simdep") && command.contains("rollout.py")) {
				//result2 = sshShell.execute("cd /var/simnet/enm-ni-simdep/scripts/simdep/bin/");
				//String outPut = result2.getOutput();
				//logger.info("Changed path is : {}", outPut);
				String masterServerIp="0.0.0.0";
                simdepParam = " -overwrite " + "-release " + simdepRelease + " -serverType " + serverType + " -deploymentType " + deploymentType
                        + " -simLTE " + simLTE + " -simWRAN " + simWRAN + " -simCORE " + simCORE + " " + simPath + " -securityTLS " + securityTLS
                        + " -securitySL2 " + securitySL2 + " -masterServer " + masterServerIp + " -ciPortal " + ciPortal + " -docker " + docker +" -image_build " + image_build +" -switchToRv " + switchToRv + " -IPV6Per " + IPV6Per + " -installType " + installType + " -rolloutType " + rolloutType;
                logger.info("simdepParam is " + simdepParam);
                logger.info("Command to be executed: {}", command.concat(simdepParam));
                 result2 = sshShell.execute(new String("python ").concat(command.concat(simdepParam)));
            } else if (command.contains("start_all_simne.sh")) {
                logger.info("Copying start_all_simne.sh script to /netsim/inst/bin");
                 result2 = sshShell.execute("cp /netsim/start_all_simne.sh /netsim/inst/bin/start_all_simne.sh");
                String cmd = "su netsim -c '" + command + "|/netsim/inst/netsim_pipe'";
                logger.info("Command to be executed: {}", cmd);
                 result2 = sshShell.execute(cmd);
            } else if (command.contains("installPatch.sh")) {
                logger.info("Command to be executed: {}", command.concat(deltaContent));
                result2 = sshShell.execute(command.concat(deltaContent));
            } else if (command.contains("copyDeltaContents.sh")) {
                logger.info("Command to be executed: {}", command.concat(simLTE).concat(" ").concat(simWRAN).concat(" ").concat(simCORE));
                result2 = sshShell.execute(command.concat(simLTE).concat(" ").concat(simWRAN).concat(" ").concat(simCORE));
            } else if (logger.isInfoEnabled() && command.contains("loadConfig.sh")) {
                logger.info("Command to be executed: {}", command.concat(deploymentType));
                 result2  = sshShell.execute(command.concat(deploymentType));
            } else if (logger.isInfoEnabled() && (command.contains("updateCrontab.sh") || command.contains("pre_verification.sh") || command.contains("post_verification.sh") || command.contains("installPatch.py"))) {
                logger.info("Command to be executed: {}", command.concat(simdepRelease));
                 result2 = sshShell.execute(command.concat(simdepRelease));
            } else if (logger.isInfoEnabled() && command.contains("fetchNodeNames.sh")) {
                logger.info("Command to be executed: {}", command.concat(firstServer).concat(" ").concat(installType));
                result2 = sshShell.execute(command.concat(firstServer).concat(" ").concat(installType));
            } else if (logger.isInfoEnabled() && command.contains("duplicateNodes.sh")) {
                logger.info("Command to be executed: {}", command.concat(installType));
                 result2 = sshShell.execute(command.concat(installType));
            } else if (logger.isInfoEnabled() && command.contains("rootExecuteCmd.sh")) {
                logger.info("Command to be executed: {}", command.concat(Execute));
                 result2 = sshShell.execute(command.concat(Execute));
            } else if (logger.isInfoEnabled() && command.contains("patchLink.sh")) {
                logger.info("Command to be executed: {}", command.concat(patchLink));
                result2 = sshShell.execute(command.concat(patchLink));
             } else if (logger.isInfoEnabled() && command.contains("adaptiverollout.sh")) {
                logger.info("Command to be executed: {}", command.concat(simdepRelease).concat(" ").concat(csvlink).concat(" ").concat(nssProductSetVersion).concat(" ").concat(Adaptive));
                result2 = sshShell.execute(command.concat(simdepRelease).concat(" ").concat(csvlink).concat(" ").concat(nssProductSetVersion).concat(" ").concat(Adaptive));
             } else if (logger.isInfoEnabled() && command.contains("root_updateLdapAttributesOnNodesVM.sh")) {
                 logger.info("Command to be executed: {}",command.concat(ConfigType).concat(" ").concat(Number_Of_BSC_Nodes).concat(" ").concat(Number_Of_LTE_Nodes).concat(" ").concat(TlsMode).concat(" ").concat(AuthenticationDelay).concat(" ").concat(CLUSTER_ID).concat(" ").concat(Deployment).concat(" ").concat(ENM_URL));
                 result2 = sshShell.execute(command.concat(ConfigType).concat(" ").concat(Number_Of_BSC_Nodes).concat(" ").concat(Number_Of_LTE_Nodes).concat(" ").concat(TlsMode).concat(" ").concat(AuthenticationDelay).concat(" ").concat(CLUSTER_ID).concat(" ").concat(Deployment).concat(" ").concat(ENM_URL));
            } else if (logger.isInfoEnabled() && command.contains("InstallNodePopulatoronVMs.sh")) {
                logger.info("Command to be executed: {}", command.concat(Execute));
                 result2 = sshShell.execute(command.concat(Execute));
	     } else {
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

