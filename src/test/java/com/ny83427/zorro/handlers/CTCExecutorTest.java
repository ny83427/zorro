package com.ny83427.zorro.handlers;

import java.io.File;
import java.io.IOException;

import junit.framework.Assert;

import org.apache.commons.io.FileUtils;
import org.junit.Test;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;

public class CTCExecutorTest {

	@Test
	public void testGetMsgContent() throws IOException {
		String[] params = {CTCExecutor.PARAM_ME_NW_CONFIG , CTCExecutor.PARAM_ME_MAIN_CONFIG,
						   CTCExecutor.PARAM_ME_INST, CTCExecutor.PARAM_MEINT_STANDARD_INTERFACE};
		
		compareResults(params);
	}
	
	@Test(expected=IOException.class)
	public void testGetMsgContentFail() throws IOException {
		String[] params = {"PARAMS_DOES_NOT_EXIST"};

		compareResults(params);
	}

	private void compareResults(String[] params) throws IOException {
		ContextInfo ctx = new ContextInfo(Constants.SCENARIO_MECTC_1, "AMU", "02", "03", "AMU345678", "D", Constants.DEFAULT_BASE_PATH, Constants.DEFAULT_DATABASE_TYPE);
		
		CTCExecutor ectc = new CTCExecutor();
		ectc.setTestMode(true);
		
		String basePath = new File(CTCExecutorTest.class.getResource("/").getFile()).getAbsolutePath();
		
		for( String msgName : params ) {
			String msgContent = ectc.getMsgContent(msgName, ctx);
			String expContent = FileUtils.readFileToString(new File(basePath + "\\" + msgName + "2.xml"));
			Assert.assertEquals(msgContent, expContent);
		}
	}

}
