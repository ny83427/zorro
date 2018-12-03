package com.ny83427.zorro;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * <pre>
 * Context information of installation or uninstall:
 * 0. scenario			Current scenario, for example, "INST"
 * 1. sid: 				SID of NW Java Server Instance, for example, "MFG"
 * 2. instNo: 			Java Server Instance Number, for example, "00"
 * 3. scsInstNo:		Message Server Instance Number, for example "01" 
 * 4. masterPassword:	Master Password: NWA administrator, {sid}adm in OS level, dba and etc
 * 5. driver:			Hard Disk Driver that will be used, for example, "C"
 * 6. basePath:			Base Path of installation or development directory, for example, "C:\MFG_INST", "C:\MFG_DEV"
 * 7. databaseType:		Database that NetWeaver based on, for example: MAXDB(ADA), SqlServer(MSS), Oracle(ORA)
 * </pre>
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ContextInfo {
	private String scenario;

	private String sid;

	private String instNo;

	private String scsInstNo;

	private String masterPassword;

	private String driver;

	private String basePath;

	private String databaseType;
}
