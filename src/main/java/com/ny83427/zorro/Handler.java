package com.ny83427.zorro;

/**
 * Handler interface: do something that batch command cannot handle easily
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public interface Handler {
	
	/**
	 * <pre>
	 * Currently there might be such scenarios:
	 * 0. determine hard disk driver as destination
	 * 1. adjust inifile.xml before installation
	 * 2. adjust inifile.xml before uninstallation
	 * 3. adjust SapNetweaverDeveloperStudio.ini for successful launch of NWDS
	 * 4. adjust DEFAULT.PFL for successful launch of JSPM
	 * 5. adjust Create_DB_Logins.sql
	 * 6. adjust generated batch command scripts for NW Server Operations
	 * 7. assign SAP_XMII_Administrator role to NWA administrator
	 * </pre>
	 * @param  ctx	context information
	 * @return exit code that will be used in command line
	 * @see ContextInfo
	 */
	int handle(ContextInfo ctx);
	
}
