package com.ny83427.zorro.handlers;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;
import com.ny83427.zorro.Handler;
import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;

/**
 * <pre>
 * Adjust inifile.xml for NW Java Server installation or uninstallation
 * We might need to replace host name, sid, instance number
 * message instance number, destination driver, master password and etc
 * </pre>
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class AdjustInifile implements Handler {
    /**
     * computer name varies, to pass the test we need a workaround
     */
    private boolean testMode = false;
    /**
     * Joker's computer name that will replace template in test mode
     */
    private static final String TEST_MODE_HOST = "PVGN50865909A";
    /**
     * Base path that will replace template in test mode
     */
    private static final String TEST_BASE_PATH = "D:\\MFG_INST";

    /**
     * Host name(Laptop of Rex Yin) in template file that will be replaced by current host name
     */
    private static final String TEMPLATE_HOST = "PVGN50865911A";
    /**
     * Fully qualified domain name in template file that will be replaced by current FQDN
     */
    private static final String TEMPLATE_FQDN = "apj.global.corp.sap";

    public int handle(ContextInfo ctx) {
        boolean needReplaceSysInfo = !Constants.DEFAULT_SID.equals(ctx.getSid()) ||
            !Constants.DEFAULT_INST_NO.equals(ctx.getInstNo()) ||
            !Constants.DEFAULT_MSG_INST_NO.equals(ctx.getScsInstNo()) ||
            !Constants.DEFAULT_DRIVER.equals(ctx.getDriver());
        boolean needReplacePwd = !Constants.DEFAULT_MASTER_PASSWORD.equals(ctx.getMasterPassword());

        String scenario = ctx.getScenario().toLowerCase();
        String path = ctx.getBasePath() + "\\NWInst\\custom_" + scenario + "\\inifile.xml";
        File inifileXml = new File(path);
        if (!inifileXml.exists()) {
            System.err.println("INIFILE.xml for " + scenario + "allation does not exist!");
            return Constants.COMMON_ERROR_CODE;
        }

        // handle inifile.xml
        String basePath2Replace = testMode ? TEST_BASE_PATH : ctx.getBasePath();
        String basePathLinuxSep2Replace = testMode ? TEST_BASE_PATH.replace("\\", "/") : ctx.getBasePath().replace("\\", "/");
        String host2Replace = testMode ? TEST_MODE_HOST : System.getenv("COMPUTERNAME");
        String fqdn2Replace = testMode ? TEMPLATE_FQDN : System.getenv("FQDN");
        try {
            String xmlContent = FileUtils.readFileToString(inifileXml);
            // replace host/FQDN name in the template
            if (xmlContent.contains(TEMPLATE_HOST)) {
                xmlContent = xmlContent.replace(TEMPLATE_HOST, host2Replace);
            }
            if (fqdn2Replace != null && fqdn2Replace.trim().length() > 0) {
                xmlContent = xmlContent.replace(TEMPLATE_FQDN, fqdn2Replace);
            }

            // replace base path
            xmlContent = xmlContent.replace(Constants.DEFAULT_BASE_PATH, basePath2Replace)
                .replace(Constants.DEFAULT_BASE_PATH.replace("\\", "/"), basePathLinuxSep2Replace);

            // replace sys info if necessary
            if (needReplaceSysInfo) {
                xmlContent = replaceSysInfo(xmlContent, ctx);
            }

            // replace master password, first we need to deactivate encode flag, then replace with customized password
            if (needReplacePwd) {
                xmlContent = xmlContent.replace(
                    "<property name =\"ENCODE_VALUE\" value =\"YES\" />",
                    "<property name =\"ENCODE_VALUE\" value =\"NO\" />")
                    .replace(
                        "<strval><![CDATA[des24(81|44|188|215|176|88|46|126|85|59|250|49|124|199|126|53|233|208|)]]>",
                        "<strval><![CDATA[" + ctx.getMasterPassword() + "]]>");
            }

            FileUtils.writeStringToFile(inifileXml, xmlContent);
            System.out.println("INIFILE.xml for " + scenario + "allation adjusted.");
        } catch (IOException e) {
            e.printStackTrace();
            return Constants.COMMON_ERROR_CODE;
        }

        // handle start_dir.cd
        path = ctx.getBasePath() + "\\NWInst\\dir_" + scenario + "\\start_dir.cd";
        File startDirCd = new File(path);
        if (!startDirCd.exists()) {
            System.err.println("start_dir.cd for " + scenario + "allation does not exist!");
            return Constants.COMMON_ERROR_CODE;
        }

        try {
            String startDir = FileUtils.readFileToString(startDirCd);
            startDir = startDir.replace(Constants.DEFAULT_BASE_PATH, basePath2Replace);
            FileUtils.writeStringToFile(startDirCd, startDir);
            System.out.println("start_dir.cd for " + scenario + "allation adjusted.");
        } catch (IOException e) {
            e.printStackTrace();
            return Constants.COMMON_ERROR_CODE;
        }

        // handle SILENT_ORACLE.rsp in installation scenario
        if (Constants.SCENARIO_INST.equals(ctx.getScenario())) {
            path = ctx.getBasePath() + "\\NWInst\\custom_" + scenario + "\\SILENT_ORACLE.rsp";
            File rsp = new File(path);
            if (!rsp.exists()) {
                System.err.println("SILENT_ORACLE.rsp for " + scenario + "allation does not exist!");
                return Constants.COMMON_ERROR_CODE;
            }

            try {
                String rspContent = FileUtils.readFileToString(rsp);
                rspContent = rspContent.replace("PVGN50865911A", host2Replace)
                    .replace("C:\\oracle\\MFG", ctx.getDriver() + ":\\oracle\\" + ctx.getSid())
                    .replace("C:\\oracle", ctx.getDriver() + ":\\oracle");
                FileUtils.writeStringToFile(rsp, rspContent);
                System.out.println("SILENT_ORACLE.rsp for " + scenario + "allation adjusted.");
            } catch (IOException e) {
                e.printStackTrace();
                return Constants.COMMON_ERROR_CODE;
            }
        }

        return Constants.NO_ERROR_CODE;
    }

    private String replaceSysInfo(String src, ContextInfo ctx) {
        String sid = ctx.getSid(), nr1 = ctx.getInstNo(), nr2 = ctx.getScsInstNo(), driver = ctx.getDriver(), databaseType = ctx.getDatabaseType();
        // replace SID, profile path, destination driver specific first
        String result = src.replace("<strval><![CDATA[MFG]]>", "<strval><![CDATA[" + sid + "]]>")
            .replace("sapmnt\\MFG\\SYS\\profile", "sapmnt\\" + sid + "\\SYS\\profile")
            .replace("<![CDATA[C:]]>", "<![CDATA[" + driver + ":]]>");

        // oracle specific replacement
        if (Constants.DBTYPE_ORACLE.equals(databaseType)) {
            result = result.replace("<strval><![CDATA[C:\\oracle\\MFG", "<strval><![CDATA[" + driver + ":\\oracle\\" + sid)
                .replace("<strval><![CDATA[C:\\ORACLE\\MFG", "<strval><![CDATA[" + driver + ":\\ORACLE\\" + sid)
                .replace("<strval><![CDATA[/oracle/MFG\\sapdata", "<strval><![CDATA[/oracle/" + sid + "\\sapdata")
                .replace("CNTRL\\CNTRLMFG.DBF", "CNTRL\\CNTRL" + sid + ".DBF")
                .replace("<strval><![CDATA[MFG\\", "<strval><![CDATA[" + sid + "\\")
                .replace("MFG.ora", sid + ".ora")
                .replace("MFG.dba", sid + ".dba")
                .replace("MFG.sap", sid + ".sap");
        }

        // maxdb specific replacement
        if (Constants.DBTYPE_MAXDB.equals(databaseType)) {
            result = result.replace("<strval><![CDATA[sqdmfg]]>", "<strval><![CDATA[sqd" + sid.toLowerCase() + "]]>")
                .replace("<strval><![CDATA[C:\\sapdb\\MFG", "<strval><![CDATA[" + driver + ":\\sapdb\\" + sid)
                .replace("<strval><![CDATA[C:\\sapdb\\clients\\MFG]]>", "<strval><![CDATA[" + driver + ":\\sapdb\\clients\\" + sid + "]]>")
                .replace("<strval><![CDATA[CL_MFG]]>", "<strval><![CDATA[CL_" + sid + "]]>");
        }

        // account specific, instance number and scs instance number specific replacement
        result = result.replace("<strval><![CDATA[SAPMFGDB]]>", "<strval><![CDATA[SAP" + sid + "DB]]>")
            .replace("SAPSERVICEMFG", "SAPSERVICE" + sid)
            .replace("MFGADM", sid + "ADM")
            .replace("<strval><![CDATA[C:\\usr\\sap\\MFG\\J00]]>", "<strval><![CDATA[" + driver + ":\\usr\\sap\\" + sid + "\\J" + nr1 + "]]>")
            .replace("<strval><![CDATA[C:\\usr\\sap\\MFG\\SYS", "<strval><![CDATA[" + driver + ":\\usr\\sap\\" + sid + "\\SYS")
            .replace("<strval><![CDATA[J00]]>", "<strval><![CDATA[J" + nr1 + "]]>")
            .replace("<strval><![CDATA[00]]>", "<strval><![CDATA[" + nr1 + "]]>")
            .replace("<strval><![CDATA[SCS01]]>", "<strval><![CDATA[SCS" + nr2 + "]]>")
            .replace("<strval><![CDATA[01]]>", "<strval><![CDATA[" + nr2 + "]]>");

        return result;
    }

}
