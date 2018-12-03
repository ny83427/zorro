package com.ny83427.zorro.handlers;

import java.io.File;
import java.io.IOException;

import junit.framework.Assert;

import org.apache.commons.io.FileUtils;
import org.junit.Test;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;

public class AdjustProfileTest {
	
	@Test
	public void testHandle() throws IOException {
		String basePath = new File(AdjustSqlTest.class.getResource("/").getFile()).getAbsolutePath();
		File pflTemplate = new File(basePath + "\\NWInst\\utils\\DEFAULT1.PFL");
		File pfl = new File(basePath + "\\NWInst\\utils\\DEFAULT.PFL");
		File exp = new File(basePath + "\\NWInst\\utils\\DEFAULT2.PFL");
		
		FileUtils.copyFile(pflTemplate, pfl);
		
		AdjustProfile ap = new AdjustProfile();
		ContextInfo ctx = new ContextInfo();
		ctx.setScenario(Constants.SCENARIO_PROFILE);
		ctx.setBasePath(basePath + "\\NWInst\\utils");
		ap.handle(ctx);
		
		Assert.assertEquals(FileUtils.readFileToString(pfl), FileUtils.readFileToString(exp));
	}

}
