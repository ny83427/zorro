package com.ny83427.zorro.utility;

import lombok.Data;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.*;

/**
 * Provide some utility methods for common usage
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class MFGUtility {

    /**
     * Validate whether the input SID, instance number and scs instance number is acceptable
     *
     * @param sid SID
     * @param nr1 JAVA AS Instance number
     * @param nr2 Message Server Instance number
     * @return sys info is valid or not
     */
    public static boolean validateSysInfo(String sid, String nr1, String nr2) {
        return sid != null && sid.length() == 3 && sid.matches("[A-Z]{1}[A-Z0-9]{2}") &&
            nr1 != null && nr1.length() == 2 && nr1.matches("[0-9]{2}") &&
            nr2 != null && nr2.length() == 2 && nr2.matches("[0-9]{2}");
    }

    /**
     * Get existing NW Java Server System information collection
     *
     * @return system information collection
     * @see SysInfo
     */
    public static List<SysInfo> getExistingSysInfosByScanServices() {
        Map<String, SysInfo> map = new HashMap<String, SysInfo>();
        try {
            Process p = Runtime.getRuntime().exec("net start");
            BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));

            String serviceName;
            while ((serviceName = br.readLine()) != null) {
                serviceName = serviceName.trim().toUpperCase();
                // Pattern: SAPAMU_00
                if (serviceName.matches("SAP[A-Z]{1}[A-Z0-9]{2}_[0-9]{2}")) {
                    String[] arr = serviceName.split("_");
                    String sid = arr[0].substring(3);
                    int no = Integer.parseInt(arr[1]);

                    SysInfo si = map.get(sid);
                    if (si == null) {
                        si = new SysInfo();
                    }
                    si.setSid(sid);
                    if (no % 2 == 0) {
                        si.setInstNo(no);
                    } else {
                        si.setScsInstNo(no);
                    }

                    map.put(sid, si);
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        List<SysInfo> list = new ArrayList<SysInfo>(map.values());
        Collections.sort(list);
        return list;
    }

    /**
     * Check whether a map is empty or not
     */
    public static <K, V> boolean isEmpty(Map<K, V> map) {
        return map == null || map.isEmpty();
    }

    /**
     * Check whether a collection is empty or not
     */
    public static <T> boolean isEmpty(Collection<T> col) {
        return col == null || col.size() == 0;
    }

    /**
     * NW Server Instance Basic Information, used in validation scenario
     *
     * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
     */
    @Data
    public static class SysInfo implements Comparable<SysInfo> {
        private String sid;
        private int instNo;
        private int scsInstNo;

        @Override
        public int compareTo(SysInfo o) {
            return this.instNo - o.getInstNo();
        }
    }

}
