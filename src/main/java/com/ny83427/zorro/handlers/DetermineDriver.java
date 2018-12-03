package com.ny83427.zorro.handlers;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;
import com.ny83427.zorro.Handler;
import com.ny83427.zorro.utility.MFGUtility;
import com.ny83427.zorro.utility.MFGUtility.SysInfo;
import lombok.Getter;
import lombok.Setter;

import java.io.File;
import java.util.*;

/**
 * Determine hard disk driver as destination of installation
 *
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class DetermineDriver implements Handler {
    private static final int NO_NW_INSTALLED = 0;
    private static final int HAS_NW_INSTALLED = 1;
    private static Map<String, Integer> DRIVER_CODE_CACHE = new HashMap<String, Integer>();

    static {
        DRIVER_CODE_CACHE.put("C", 2);
        DRIVER_CODE_CACHE.put("D", 4);
        DRIVER_CODE_CACHE.put("E", 8);
        DRIVER_CODE_CACHE.put("F", 16);
        DRIVER_CODE_CACHE.put("G", 32);
        DRIVER_CODE_CACHE.put("H", 64);
        DRIVER_CODE_CACHE.put("I", 128);
    }

    public int handle(ContextInfo info) {
        List<SysInfo> list = MFGUtility.getExistingSysInfosByScanServices();
        if (list != null && !list.isEmpty()) {
            String dir = System.getenv("SAP_DIR_PERF");
            if (dir != null && dir.trim().length() > 0) {
                String root = dir.substring(0, 1).toUpperCase();
                System.out.println(dir + " indicates that NW Java Server Instance installed at Driver " + root + " already. We will use it.");
                return DRIVER_CODE_CACHE.get(root);
            }
        }

        File[] roots = File.listRoots();
        List<Driver> drivers = new ArrayList<Driver>();
        for (File f : roots) {
            String driverRoot = f.getAbsolutePath();
            String driverName = driverRoot.substring(0, 1).toUpperCase();
            Driver driver = new Driver(driverName, f.getFreeSpace() / (1024 * 1024 * 1024));
            File ccms = new File(driverName + ":/usr/sap/CCMS");
            File[] files = ccms.listFiles();
            if (ccms.exists() && files != null && files.length > 0) {
                driver.setSysInstalled(HAS_NW_INSTALLED);
                System.out.println("It seems that you have installed NW Server Instance at driver " + driverName + " before.");
            }

            System.out.println(driver.toString());
            drivers.add(driver);
        }

        Collections.sort(drivers);
        String result = drivers.get(0).getName();
        System.out.println("We will use driver " + result + " since it's largest in free space or have NW Server installed already.");
        Integer code = DRIVER_CODE_CACHE.get(result);
        if (code == null) {
            System.err.println("Sorry, your laptop is not made on this earth, but might be from Mars or a more mysterious place, I cannot hold out any more. Goodbye~");
            return Constants.FATAL_ERROR_CODE;
        }

        return code;
    }

    private static class Driver implements Comparable<Driver> {
        @Override
        public String toString() {
            return "Driver " + name + " Available space: " + space + "GB.";
        }

        Driver(String name, Long space) {
            super();
            this.name = name;
            this.space = space;
        }

        @Getter private String name;
        @Getter private Long space;
        @Getter @Setter private Integer sysInstalled = NO_NW_INSTALLED;

        @Override
        public int compareTo(Driver o) {
            int result = -this.space.compareTo(o.getSpace());
            return result != 0 ? result : -this.sysInstalled.compareTo(o.getSysInstalled());
        }
    }
}
