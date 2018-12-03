package com.ny83427.zorro.handlers;

import java.io.File;
import java.io.IOException;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;
import com.ny83427.zorro.Handler;
import org.apache.commons.io.FileUtils;

/**
 * Add JAVA VM argument in NWDS inifile so that it can launch successfully without manual modification
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class AdjustNWDSIni implements Handler {

    public int handle(ContextInfo ctx) {
        String devPath = ctx.getBasePath();
        String path = devPath + "\\NWDS\\eclipse\\SapNetweaverDeveloperStudio.ini";
        File iniFile = new File(path);
        if (!iniFile.exists()) {
            System.err.println("NWDS not available!");
            return Constants.COMMON_ERROR_CODE;
        }

        try {
            String content = FileUtils.readFileToString(iniFile);
            if (content.contains("C:\\Program Files (x86)\\Java\\jdk1.6.0_45\\bin")) {
                System.out.println("NWDS ini file had been adjusted already.");
            } else {
                FileUtils.writeStringToFile(iniFile, "-vm\nC:\\Program Files (x86)\\Java\\jdk1.6.0_45\\bin\n" + content);
                System.out.println("NWDS ini file adjusted successfully.");
            }
        } catch (IOException e) {
            e.printStackTrace();
            return Constants.COMMON_ERROR_CODE;
        }

        return Constants.NO_ERROR_CODE;
    }

}
