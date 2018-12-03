package com.ny83427.zorro.handlers;

import junit.framework.Assert;

import org.junit.Test;

import com.ny83427.zorro.Constants;
import com.ny83427.zorro.ContextInfo;

public class DetermineSidAndInstNoTest {
	@Test
	public void test_need_no_adjust() {
		// instance with given sid, nr1, nr2 exists, no adjustment needed
		DetermineSidAndInstNo ds = new DetermineSidAndInstNo();
		ds.setSysInfos(new String[]{"MFG_00", "NBA_02", "ORA_04"});
		
		ContextInfo ctx = new ContextInfo();
		ctx.setScenario(Constants.SCENARIO_SYSINFO);
		ctx.setSid(Constants.DEFAULT_SID);
		ctx.setInstNo(Constants.DEFAULT_INST_NO);
		ctx.setScsInstNo(Constants.DEFAULT_MSG_INST_NO);
		
		Assert.assertEquals(Constants.NO_ERROR_CODE, ds.handle(ctx));
	}
	
	@Test
	public void test_need_no_adjust2() {
		// sid doesn't exist, NR1 not used and between min and max exactly in sequence, no adjustment needed
		DetermineSidAndInstNo ds = new DetermineSidAndInstNo();
		ds.setSysInfos(new String[]{"MFG_00", "ORA_04"});
		
		ContextInfo ctx = new ContextInfo();
		ctx.setScenario(Constants.SCENARIO_SYSINFO);
		ctx.setSid("AMU");
		ctx.setInstNo("02");
		ctx.setScsInstNo("03");
		
		Assert.assertEquals(Constants.NO_ERROR_CODE, ds.handle(ctx));
	}
	
	@Test
	public void test_need_adjust_instno_sequence() {
		// sid doesn't exist, NR1 used already, need adjustment in sequence
		DetermineSidAndInstNo ds = new DetermineSidAndInstNo();
		ds.setSysInfos(new String[]{"MFG_00", "NBA_02", "ORA_04"});
		
		ContextInfo ctx = new ContextInfo();
		ctx.setScenario(Constants.SCENARIO_SYSINFO);
		ctx.setSid("AMU");
		ctx.setInstNo(Constants.DEFAULT_INST_NO);
		ctx.setScsInstNo(Constants.DEFAULT_MSG_INST_NO);
		
		Assert.assertEquals(6, ds.handle(ctx));
	}
	
	@Test
	public void test_need_adjust_instno_between() {
		// sid doesn't exist, NR1 used already, need adjustment between min and max in sequence
		DetermineSidAndInstNo ds = new DetermineSidAndInstNo();
		ds.setSysInfos(new String[]{"MFG_00", "ORA_04"});
		
		ContextInfo ctx = new ContextInfo();
		ctx.setScenario(Constants.SCENARIO_SYSINFO);
		ctx.setSid("AMU");
		ctx.setInstNo(Constants.DEFAULT_INST_NO);
		ctx.setScsInstNo(Constants.DEFAULT_MSG_INST_NO);
		
		Assert.assertEquals(2, ds.handle(ctx));
	}
	
	@Test
	public void test_need_adjust_instno_between2() {
		// sid doesn't exist, NR1 not used yet not in sequence, need adjustment in sequence
		DetermineSidAndInstNo ds = new DetermineSidAndInstNo();
		ds.setSysInfos(new String[]{"MFG_00", "ORA_08"});
		
		ContextInfo ctx = new ContextInfo();
		ctx.setScenario(Constants.SCENARIO_SYSINFO);
		ctx.setSid("AMU");
		ctx.setInstNo("06");
		ctx.setScsInstNo("07");
		
		Assert.assertEquals(2, ds.handle(ctx));
	}
	
	@Test
	public void test_need_adjust_instno_beyond_max() {
		// NR1 not used yet greater than existing max instance no, need adjustment in sequence
		DetermineSidAndInstNo ds = new DetermineSidAndInstNo();
		ds.setSysInfos(new String[]{"MFG_00", "NBA_02", "ORA_04"});
		
		ContextInfo ctx = new ContextInfo();
		ctx.setScenario(Constants.SCENARIO_SYSINFO);
		ctx.setSid("AMU");
		ctx.setInstNo("08");
		ctx.setScsInstNo("09");
		
		Assert.assertEquals(6, ds.handle(ctx));
	}
	
	@Test
	public void test_need_adjust_sid() {
		// NR1 & NR2 not used and in sequence, yet SID used, need adjust SID
		DetermineSidAndInstNo ds = new DetermineSidAndInstNo();
		ds.setSysInfos(new String[]{"MFG_00", "NBA_02", "ORA_04"});
		
		int instNo = 6;
		ContextInfo ctx = new ContextInfo();
		ctx.setScenario(Constants.SCENARIO_SYSINFO);
		ctx.setSid(Constants.DEFAULT_SID);
		ctx.setInstNo("06");
		ctx.setScsInstNo("07");
		
		Assert.assertEquals(instNo, ds.handle(ctx));
	}
	
}
