package com.ny83427.zorro.handlers;

import java.io.File;
import java.io.IOException;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;
import com.ny83427.zorro.Handler;
import org.apache.commons.io.FileUtils;

/**
 * Adjust Sql file to create/drop database, logins and user mappings for ME
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class AdjustSql implements Handler {
    static final String[] SQL_FILES = {"Create_DB_Logins", "Drop_DB_Logins"};

    public int handle(ContextInfo ctx) {
        String sid = ctx.getSid();
        String driver = ctx.getDriver();
        String password = ctx.getMasterPassword();

        for (String sqlFileName : SQL_FILES) {
            String templatePath = ctx.getBasePath() + "\\NWInst\\me_sql\\" + sqlFileName + ".sql";
            File template = new File(templatePath);
            if (!template.exists()) {
                System.err.println("Sql template file " + templatePath + " doesn't exist, please check and correct it.");
                return Constants.COMMON_ERROR_CODE;
            }

            try {
                String sqlPath = ctx.getBasePath() + "\\NWInst\\me_sql\\" + sqlFileName + "_" + sid + ".sql";
                File sqlFile = new File(sqlPath);
                FileUtils.copyFile(template, sqlFile);
                String sql = FileUtils.readFileToString(sqlFile);
                sql = sql.replace("C:\\SAP_MFG_DB", driver + ":\\SAP_MFG_DB")
                    .replace("SAPMEWIP", sid + "_ME_WIP")
                    .replace("SAPMEODS", sid + "_ME_ODS")
                    .replace("SAPMEINT", sid + "_ME_INT")
                    .replace("MFG123456", password);

                FileUtils.writeStringToFile(sqlFile, sql);

                System.out.println("NW JAVA Server " + sid + " ME " + sqlFileName + " sql file adjusted successfully.");
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        return Constants.NO_ERROR_CODE;
    }

}
