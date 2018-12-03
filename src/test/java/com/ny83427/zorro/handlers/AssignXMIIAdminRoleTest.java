package com.ny83427.zorro.handlers;

import org.junit.Ignore;
import org.junit.Test;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;

/**
 * <pre>
 * {@link AssignXMIIAdminRole} "Unit" Test: NW JAVA Server must be running to perform this test
 * It will be ignored in the process of package
 * </pre>
 * @author <a href="mailto:joker.yang@sap.com">I069721(Joker Yang)</a>
 */
public class AssignXMIIAdminRoleTest {
	
	@Ignore
	@Test
	public void testHandle() {
		ContextInfo ctx = new ContextInfo();
		ctx.setInstNo(Constants.DEFAULT_INST_NO);
		ctx.setMasterPassword(Constants.DEFAULT_MASTER_PASSWORD);
		
		AssignXMIIAdminRole axa = new AssignXMIIAdminRole();
		axa.handle(ctx);
	}

}
