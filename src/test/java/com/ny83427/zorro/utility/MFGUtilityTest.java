package com.ny83427.zorro.utility;

import java.util.List;

import junit.framework.Assert;

import org.junit.Test;

public class MFGUtilityTest {

	@Test
	public void testGetNWServices() {
		List<MFGUtility.SysInfo> sysInfos = MFGUtility.getExistingSysInfosByScanServices();
		for(MFGUtility.SysInfo si : sysInfos) {
			System.out.println(si);
		}
	}

	@Test
	public void test_validateSysInfo() {
		Assert.assertTrue(MFGUtility.validateSysInfo("MFG", "00", "01"));
		
		Assert.assertFalse(MFGUtility.validateSysInfo("1ME", "00", "01"));
		Assert.assertFalse(MFGUtility.validateSysInfo("MFG1", "00", "01"));
		Assert.assertFalse(MFGUtility.validateSysInfo("MFG", "AB", "CD"));
		Assert.assertFalse(MFGUtility.validateSysInfo("MFG", "000", "001"));
	}
	
}
