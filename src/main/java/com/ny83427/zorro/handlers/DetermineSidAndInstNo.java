package com.ny83427.zorro.handlers;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;
import com.ny83427.zorro.Handler;
import com.ny83427.zorro.utility.MFGUtility;
import lombok.Getter;
import lombok.Setter;

import java.util.*;

/**
 * <pre>
 * Determine SID, instance number and scs instance number
 * In case the input parameters cannot be used, we will adjust them automatically via exit code
 * Naming Convention: Adjusted SID will be M0%ERRORLEVEL%, instance number will be 0%ERRORLEVEL%
 * </pre>
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class DetermineSidAndInstNo implements Handler {
    @Getter
    @Setter
    private String[] sysInfos;

    @Override
    public int handle(ContextInfo ctx) {
        if (!MFGUtility.validateSysInfo(ctx.getSid(), ctx.getInstNo(), ctx.getScsInstNo())) {
            System.exit(Constants.FATAL_ERROR_CODE);
        }

        Map<String, Integer> sidCache = new HashMap<String, Integer>();
        Map<Integer, String> instNoCache = new HashMap<Integer, String>();
        List<Integer> nos = new ArrayList<Integer>();

        String[] sid_nos = this.getSysInfos();
        if (sid_nos == null || sid_nos.length == 0) {
            List<MFGUtility.SysInfo> sysInfos = MFGUtility.getExistingSysInfosByScanServices();
            if (sysInfos == null || sysInfos.isEmpty()) {
                // however, we might not be able to prevent input instance number that is not 00 in this case
                return Constants.NO_ERROR_CODE;
            }

            for (MFGUtility.SysInfo si : sysInfos) {
                nos.add(si.getInstNo());
                sidCache.put(si.getSid(), si.getInstNo());
                instNoCache.put(si.getInstNo(), si.getSid());
            }
        } else {
            for (String sysInfo : sid_nos) {
                String[] arr = sysInfo.split("_");
                String sid = arr[0];
                int instNo = Integer.parseInt(arr[1]);

                nos.add(instNo);
                sidCache.put(sid, instNo);
                instNoCache.put(instNo, sid);
            }
        }
        Collections.sort(nos);
        int maxNo = nos.get(nos.size() - 1);

        Integer no = sidCache.get(ctx.getSid());
        int inputNo = Integer.parseInt(ctx.getInstNo());
        boolean adjustSid = no != null && no != inputNo;

        String existSid = instNoCache.get(inputNo);
        boolean adjustInstNo = existSid == null || !existSid.equals(ctx.getSid());

        if (adjustSid) {
            System.out.println("SID " + ctx.getSid() + " cannot be used, adjusted to J" + (inputNo >= 10 ? "" : "0") + inputNo);
            return inputNo;
        }

        if (adjustInstNo) {
            int newInstNo = maxNo + 2;
            // we might need to insert a instance number between existing sequences
            if (maxNo != (nos.size() - 1) * 2) {
                for (int i = 0; i < nos.size(); i++) {
                    if (instNoCache.get(i * 2) == null) {
                        newInstNo = i * 2;
                        break;
                    }
                }
            }

            if (newInstNo != inputNo) {
                System.out.println("Instance Number " + ctx.getInstNo() + " cannot be used, adjusted to " + (newInstNo >= 10 ? "" : "0") + newInstNo + " automatically.");
                return newInstNo;
            }
        }

        return Constants.NO_ERROR_CODE;
    }

}
