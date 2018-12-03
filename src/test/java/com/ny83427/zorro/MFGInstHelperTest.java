package com.ny83427.zorro;

import org.junit.Test;

public class MFGInstHelperTest {

	@Test(expected=IllegalArgumentException.class)
	public void test_parse_no_args() {
		MFGInstHelper.parse(null);
	}
	
	@Test(expected=IllegalArgumentException.class)
	public void test_parse_empty_args() {
		MFGInstHelper.parse(new String[]{});
	}
	
	@Test(expected=IllegalArgumentException.class)
	public void test_parse_args_invalid() {
		String[] args = {"INVALID_SCENARIO,MFG,00,01,MFG123456,C,C:\\MFG_INST"};
		MFGInstHelper.parse(args);
	}
	
	@Test
	public void test_parse_args_exact() {
		String[] args = {"INST,MFG,00,01,MFG123456,C,C:\\MFG_INST"};
		MFGInstHelper.parse(args);
	}

}
