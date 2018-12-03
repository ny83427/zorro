package com.ny83427.zorro.handlers;

import java.io.File;
import java.io.IOException;

import junit.framework.Assert;

import org.apache.commons.io.FileUtils;
import org.junit.Test;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;

public class AdjustInifileTest {
	@Test
	public void test_handle_mss_inst() throws IOException {
		handle(Constants.SCENARIO_INST, Constants.DBTYPE_SQLSERVER);
	}
	
	@Test
	public void test_handle_mss_uninst() throws IOException {
		handle(Constants.SCENARIO_UNINST, Constants.DBTYPE_SQLSERVER);
	}
	
	@Test
	public void test_handle_ada_inst() throws IOException {
		handle(Constants.SCENARIO_INST, Constants.DBTYPE_MAXDB);
	}
	
	@Test
	public void test_handle_ada_uninst() throws IOException {
		handle(Constants.SCENARIO_UNINST, Constants.DBTYPE_MAXDB);
	}
	
	@Test
	public void test_handle_ora_inst() throws IOException {
		handle(Constants.SCENARIO_INST, Constants.DBTYPE_ORACLE);
	}
	
	@Test
	public void test_handle_ora_uninst() throws IOException {
		handle(Constants.SCENARIO_UNINST, Constants.DBTYPE_ORACLE);
	}

	private void handle(String sce, String dbType) throws IOException {
		System.out.println("Test Case: " + sce + ", " + dbType);
		String basePath = new File(AdjustInifileTest.class.getResource("/").getFile()).getAbsolutePath();
		AdjustInifile ai = new AdjustInifile();
		ai.setTestMode(true);
		
		// "AMU", "02", "03", "AMU345678", "D" cannot change or test case will fail
		ContextInfo ctx = new ContextInfo(sce, "AMU", "02", "03", "AMU345678", "D", basePath, dbType);
		String scenario = ctx.getScenario().toLowerCase();
		
		File destFile = new File(basePath + "\\NWInst\\custom_" + scenario + "\\inifile.xml");
		File destDirFile = new File(basePath + "\\NWInst\\dir_" + scenario + "\\start_dir.cd");
		File destRspFile = new File(basePath + "\\NWInst\\custom_" + scenario + "\\SILENT_ORACLE.rsp");
		
		File srcFile = new File(basePath + "\\NWInst\\custom_" + scenario + "\\inifile_" + dbType + ".xml");
		File expFile = new File(basePath + "\\NWInst\\custom_" + scenario + "\\inifile_" + dbType + "2.xml");
		FileUtils.copyFile(srcFile, destFile);
		
		File srcDirFile = new File(basePath + "\\NWInst\\dir_" + scenario + "\\start_dir_template.cd");
		File expDirFile = new File(basePath + "\\NWInst\\dir_" + scenario + "\\start_dir2.cd");
		FileUtils.copyFile(srcDirFile, destDirFile);
		
		File srcRspFile = new File(basePath + "\\NWInst\\custom_" + scenario + "\\SILENT_ORACLE_Template.rsp");
		File expRspFile = new File(basePath + "\\NWInst\\custom_" + scenario + "\\SILENT_ORACLE2.rsp");
		if(Constants.SCENARIO_INST.equals(sce)) {
			FileUtils.copyFile(srcRspFile, destRspFile);
		}
		
		ai.handle(ctx);
		
		String ini1 = FileUtils.readFileToString(destFile);
		String ini2 = FileUtils.readFileToString(expFile);
		Assert.assertEquals(ini1, ini2);
		
		String dir1 = FileUtils.readFileToString(destDirFile);
		String dir2 = FileUtils.readFileToString(expDirFile);
		Assert.assertEquals(dir1, dir2);
		
		if(Constants.SCENARIO_INST.equals(sce)) {
			String rsp1 = FileUtils.readFileToString(destRspFile);
			String rsp2 = FileUtils.readFileToString(expRspFile);
			Assert.assertEquals(rsp1, rsp2);
		}
	}

}
