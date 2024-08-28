package com.ericsson.ci.simnet.test.operators;

/**
 * The user of this interface can execute scripts remotely and check the exit code.
 *
 * <p>
 * The user of this interface, while implement the interface should handle all prerequisite such as scripts to be executed should be placed under
 * src/main/resources/scripts folder.
 *
 * @author qfatonu
 *
 */
public interface netsimHCScriptExecutionOperator {

    /**
     * Executes user defined command||script and return its exit code.
     *
     * Example:
     *
     * <pre>
     *      verifyScriptExecution(/var/simnet/simdep/utils/ossmaster/runCleanVapp.sh -h);
     * </pre>
     *
     * @param command
     *            the full path of either script, or command
     * @return the exit code of either script, or command
     */
    int verifyScriptExecution(String command);

}
