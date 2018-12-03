package com.ny83427.zorro.handlers;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;
import com.ny83427.zorro.Handler;
import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;

/**
 * Adjust scripts to start, stop or restart NW JAVA Server
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class AdjustScript implements Handler {
    static final String[] OPERATIONS = {"Start", "Stop", "Restart"};

    public int handle(ContextInfo ctx) {
        String basePath = ctx.getBasePath();
        String desktop = "C:\\Users\\" + System.getenv("USERNAME") + "\\Desktop";

        for (String operation : OPERATIONS) {
            File template = new File(basePath + "\\NWInst\\utils\\sysoper\\" + operation + ".bat");
            try {
                if (!template.exists()) {
                    continue;
                }
                File script = new File(desktop + "\\" + operation + "_" + ctx.getSid() + ".bat");
                FileUtils.copyFile(template, script);

                String s = FileUtils.readFileToString(script);
                s = s.replace("set SID=MFG", "set SID=" + ctx.getSid())
                    .replace("set NR1=00", "set NR1=" + ctx.getInstNo())
                    .replace("set NR2=01", "set NR2=" + ctx.getScsInstNo())
                    .replace("set DRIVER=C", "set DRIVER=" + ctx.getDriver());

                FileUtils.writeStringToFile(script, s);

                System.out.println("NW Server Instance " + operation + " script adjusted successfully.");
            } catch (IOException e) {
                e.printStackTrace();
                return Constants.COMMON_ERROR_CODE;
            }
        }

        return Constants.NO_ERROR_CODE;
    }

}
