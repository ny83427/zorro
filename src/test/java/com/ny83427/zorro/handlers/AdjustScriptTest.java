package com.ny83427.zorro.handlers;

import java.io.File;
import java.io.IOException;

import junit.framework.Assert;

import org.apache.commons.io.FileUtils;
import org.junit.Test;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;

public class AdjustScriptTest {

	@Test
	public void testHandle() throws IOException {
		String basePath = new File(AdjustSqlTest.class.getResource("/").getFile()).getAbsolutePath();
		AdjustScript as = new AdjustScript();
		// "AMU", "02", "03", "AMU345678", "D" cannot change or test case will fail
		ContextInfo ctx = new ContextInfo(Constants.SCENARIO_SQL, "AMU", "02", "03", "AMU345678", "D", basePath, Constants.DEFAULT_DATABASE_TYPE);
		as.handle(ctx);
		
		String desktop = "C:\\Users\\" + System.getenv("USERNAME") + "\\Desktop";
		for(String oper: AdjustScript.OPERATIONS) {
			File exp = new File(basePath + "\\NWInst\\utils\\sysoper\\" + oper + "2.bat");
			File script = new File(desktop + "\\" + oper + "_AMU.bat");
			Assert.assertEquals(FileUtils.readFileToString(script), FileUtils.readFileToString(exp));
			
			FileUtils.forceDelete(script);
		}
	}

}
