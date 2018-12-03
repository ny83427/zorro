package com.ny83427.zorro.handlers;

import java.io.File;
import java.io.IOException;

import junit.framework.Assert;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.junit.Test;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;

public class AdjustNWDSIniTest {

	@Test
	public void testHandle() throws IOException {
		String basePath = new File(AdjustNWDSIniTest.class.getResource("/NWInst").getFile()).getAbsolutePath();
		File destFile = new File(basePath + "\\NWDS\\eclipse\\SapNetweaverDeveloperStudio.ini");
		FileUtils.copyFile(new File(basePath + "\\NWDS\\SapNetweaverDeveloperStudio.ini"), destFile);
		
		ContextInfo ctx = new ContextInfo(Constants.SCENARIO_NWDS, Constants.DEFAULT_SID, Constants.DEFAULT_INST_NO, 
										  Constants.DEFAULT_MSG_INST_NO, Constants.DEFAULT_MASTER_PASSWORD, 
										  Constants.DEFAULT_DRIVER, basePath, Constants.DEFAULT_DATABASE_TYPE);
		AdjustNWDSIni ani = new AdjustNWDSIni();
		ani.handle(ctx);
		
		String ini1 = IOUtils.toString(AdjustNWDSIniTest.class.getResourceAsStream("/NWInst/NWDS/eclipse/SapNetweaverDeveloperStudio.ini"));
		String ini2 = IOUtils.toString(AdjustNWDSIniTest.class.getResourceAsStream("/NWInst/NWDS/SapNetweaverDeveloperStudio2.ini"));
		Assert.assertEquals(ini1, ini2);
	}

}
