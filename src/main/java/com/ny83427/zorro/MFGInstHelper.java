package com.ny83427.zorro;

import com.ny83427.zorro.handlers.*;

import java.util.HashMap;
import java.util.Map;

/**
 * <pre>
 * MFG Development Enviroment Installation Helper that will be invoked like this:
 * java -cp mfginst.jar MFGInstHelper INST,MFG,00,01,MFG123456,D,D:\\MFG_INST
 * </pre>
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class MFGInstHelper {
    /**
     * Handlers mapping cache: key - Scenario, value - Handler instance
     */
    private static Map<String, Handler> HANDLERS = new HashMap<String, Handler>();

    static {
        HANDLERS.put(Constants.SCENARIO_DRIVER, new DetermineDriver());
        HANDLERS.put(Constants.SCENARIO_SYSINFO, new DetermineSidAndInstNo());
        HANDLERS.put(Constants.SCENARIO_INST, new AdjustInifile());
        HANDLERS.put(Constants.SCENARIO_UNINST, new AdjustInifile());
        HANDLERS.put(Constants.SCENARIO_PROFILE, new AdjustProfile());
        HANDLERS.put(Constants.SCENARIO_NWDS, new AdjustNWDSIni());
        HANDLERS.put(Constants.SCENARIO_SQL, new AdjustSql());
        HANDLERS.put(Constants.SCENARIO_BAT, new AdjustScript());
        HANDLERS.put(Constants.SCENARIO_XMII_ROLE, new AssignXMIIAdminRole());
    }

    public static void main(String[] args) {
        try {
            ContextInfo ctx = parse(args);
            String scenario = ctx.getScenario();
            Handler handler = HANDLERS.get(scenario);
            int rc = handler.handle(ctx);
            if (rc != Constants.NO_ERROR_CODE) {
                System.exit(rc);
            }

        } catch (Exception e) {
            System.err.println(e.getMessage());
            System.exit(Constants.COMMON_ERROR_CODE);
        }
    }

    /**
     * Get context information via parsing passed arguments
     *
     * @param args passed arguments, for example: INST,MFG,00,01,MFG123456,D,D:\\MFG_INST
     */
    static ContextInfo parse(String[] args) {
        if (args == null || args.length == 0) {
            throw new IllegalArgumentException("No context information was provided, please check MFG_INST.bat where MFGInstHelper was invoked");
        }

        String[] parameters = args[0].split(",");
        // check whether we can handle current scenario
        String scenario = parameters[0];
        Handler handler = HANDLERS.get(scenario);
        if (handler == null) {
            throw new IllegalArgumentException("No handler was defined for current scenario: " + scenario);
        }

        // build context information
        String sid = parameters.length >= 2 ? parameters[1].toUpperCase() : null;
        String instNo = parameters.length >= 3 ? parameters[2].trim() : null;
        String scsInstNo = parameters.length >= 4 ? parameters[3].trim() : null;
        String masterPassword = parameters.length >= 5 ? parameters[4] : null;
        String driver = parameters.length >= 6 ? parameters[5].toUpperCase() : null;
        String basePath = parameters.length >= 7 ? parameters[6] : null;
        String databaseType = parameters.length >= 8 ? parameters[7] : null;

        return new ContextInfo(scenario, sid, instNo, scsInstNo, masterPassword, driver, basePath, databaseType);
    }
}
