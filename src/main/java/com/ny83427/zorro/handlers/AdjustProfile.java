package com.ny83427.zorro.handlers;

import java.io.File;
import java.io.IOException;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;
import com.ny83427.zorro.Handler;
import org.apache.commons.io.FileUtils;

/**
 * Adjust profile before applying support packages via JSPM, or JSPM would fail to launch
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class AdjustProfile implements Handler {

    public int handle(ContextInfo ctx) {
        String path = ctx.getBasePath() + "\\DEFAULT.PFL";
        File pfl = new File(path);
        if (!pfl.exists()) {
            System.err.println("Profile file " + path + " doesn't exist");
            return Constants.COMMON_ERROR_CODE;
        }

        try {
            String profileContent = FileUtils.readFileToString(pfl);
            if (profileContent.contains("service/protectedwebmethods = SDEFAULT")) {
                profileContent = profileContent.replace("= SDEFAULT", "= DEFAULT");
                // backup previous profile file first
                FileUtils.copyFile(pfl, new File(path + ".BAK"));
                FileUtils.writeStringToFile(pfl, profileContent);

                System.out.println("Profile file adjusted successfully.");
            } else {
                System.out.println("Profile file had been adjusted already.");
            }
        } catch (IOException e) {
            e.printStackTrace();
            return Constants.COMMON_ERROR_CODE;
        }

        return Constants.NO_ERROR_CODE;
    }

}
