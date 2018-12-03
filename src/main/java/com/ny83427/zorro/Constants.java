package com.ny83427.zorro;

/**
 * Constants Definition
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class Constants { 
	/**
	 * Scenario: Determine hard disk driver as destination
	 */
	public static final String SCENARIO_DRIVER = "DETERMINE_DRIVER";
	/**
	 * Scenario: Determine whether input sid and instance number can be used, or we will adjust it
	 */
	public static final String SCENARIO_SYSINFO = "DETERMINE_SYSINFO";
	/**
	 * Scenario: NetWeaver JAVA Server installation, inifile.xml needs to be adjusted
	 */
	public static final String SCENARIO_INST = "INST";
	/**
	 * Scenario: NetWeaver JAVA Server uninstallation, inifile.xml needs to be adjusted
	 */
	public static final String SCENARIO_UNINST = "UNINST";
	/**
	 * Scenario: We will launch JSPM to apply support packages, DEFAULT.PFL needs to be adjusted
	 */
	public static final String SCENARIO_PROFILE = "PROFILE";
	/**
	 * Scenario: We will launch NWDS, SapNetweaverDeveloperStudio.ini needs to be adjusted
	 */
	public static final String SCENARIO_NWDS = "NWDS";
	/**
	 * Scenario: We will create databases, logins, user mappings for ME, sql files need to be adjusted
	 */
	public static final String SCENARIO_SQL = "SQL";
	/**
	 * Scenario: We will generate scrips for NetWeaver JAVA Server operations, scripts need to be adjusted
	 */
	public static final String SCENARIO_BAT = "BAT";
	/**
	 * Scenario: We will assign SAP_XMII_Administrator role to NWA administrator so that MEINT/MEINTCTC can be deployed successfully
	 */
	public static final String SCENARIO_XMII_ROLE = "ASSIGN_XMII_ADMIN_ROLE";
	/**
	 * Scenario: We will execute 2 CTCs for ME
	 */
	public static final String SCENARIO_MECTC_1 = "MECTC1";
	/**
	 * Scenario: We will execute the left 2 CTCs for ME and MEINT after NetWeaver restart
	 */
	public static final String SCENARIO_MECTC_2 = "MECTC2";
	
	public static final String DBTYPE_MAXDB = "ADA";
	public static final String DBTYPE_SQLSERVER = "MSS";
	public static final String DBTYPE_ORACLE = "ORA";
	
	public static final String DEFAULT_SID = "MFG";
	public static final String DEFAULT_INST_NO = "00";
	public static final String DEFAULT_MSG_INST_NO = "01";
	public static final String DEFAULT_MASTER_PASSWORD = "MFG123456";
	public static final String DEFAULT_DRIVER = "C";
	public static final String DEFAULT_BASE_PATH = "C:\\MFG_INST";
	public static final String DEFAULT_DATABASE_TYPE = DBTYPE_MAXDB;
	
	/**
	 * Webdynpro JAVA AJAX event key
	 */
	public static final String EVENT_KEY = "SAPEVENTQUEUE";
	
	/**
	 * JAVA exit code indicate no error occurred: command will continue
	 */
	public static final int NO_ERROR_CODE = 0;
	/**
	 * JAVA exit code indicate a common error occurred: command will response and continue
	 */
	public static final int COMMON_ERROR_CODE = 8;
	/**
	 * JAVA exit code indicate a fatal error occurred: command will pause and exit
	 */
	public static final int FATAL_ERROR_CODE = 256;
	
}
